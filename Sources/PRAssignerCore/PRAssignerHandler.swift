//
//  PRAssignerHandler.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation
import AWSLambdaRuntime
import SotoSecretsManager
import AsyncHTTPClient
import NIO

public struct PRAssignerHandler: EventLoopLambdaHandler {
    public typealias In = GitHub.Event
    public typealias Out = Void
    
    private let env: EnvironmentVariablesProvider
    private let logger: Logger
    private let httpClient: Shutdownable
    private let service: ServiceFacadeProtocol
    private let awsClient: Shutdownable
    private let secretsManager: SecretsManagerProtocol
    private let slackMessageBuilder: SlackMessageBuilderProtocol
    
    public init(eventLoop: EventLoop, logger: Logger) {
        self.logger = logger
        self.env = EnvironmentVariables()
        let httpClient = HTTPClient(eventLoopGroupProvider: .shared(eventLoop))
        self.httpClient = httpClient
        let dispatcher = Dispatcher(httpClient: httpClient)
        self.service = ServiceFacade(dispatcher: dispatcher, env: env, eventLoop: eventLoop, logger: logger)
        let awsClient = AWSClient(httpClientProvider: .createNew)
        self.awsClient = awsClient
        self.secretsManager = SecretsManager(client: awsClient, region: env.awsRegion)
        self.slackMessageBuilder = SlackMessageBuilder()
    }
    
    init(env: EnvironmentVariablesProvider,
         httpClient: Shutdownable,
         service: ServiceFacadeProtocol,
         awsClient: Shutdownable,
         secretsManager: SecretsManagerProtocol,
         slackMessageBuilder: SlackMessageBuilderProtocol,
         logger: Logger) {
        self.env = env
        self.httpClient = httpClient
        self.service = service
        self.awsClient = awsClient
        self.secretsManager = secretsManager
        self.slackMessageBuilder = slackMessageBuilder
        self.logger = logger
    }
    
    // MARK: - Swift Lambda methods
    
    public func handle(context: Lambda.Context, event: GitHub.Event) -> EventLoopFuture<Void> {
        logger.debug("Received GitHub event\n\(event)")
        logger.info("Triggered by \(event.repository.fullName) PR #\(event.number) with action \(event.action)")
        
        // Skipping test PRs
        if !env.isDebug, event.pullRequest.title.hasPrefix("Test") {
            logger.info("Test PR skipped.")
            return context.eventLoop.makeSucceededFuture(())
        }
        
        return secretsManager.getSecretValue(SecretsManager.GetSecretValueRequest(secretId: env.secretsName), logger: logger, on: nil)
            .flatMap { response -> EventLoopFuture<Void> in
                logger.info("Secrets successfully fetched")
                
                guard let rawSecrets = response.secretString,
                      let dataSecrets = rawSecrets.data(using: .utf8) else {
                    return context.eventLoop.makeFailedFuture(PRAssignerError.secretsNotFetched)
                }
                guard let secrets = try? JSONDecoder().decode(Secrets.self, from: dataSecrets) else {
                    return context.eventLoop.makeFailedFuture(PRAssignerError.parsingError)
                }
                logger.info("Secrets parsed successfully")
                service.setSecrets(secrets)
                return context.eventLoop.makeSucceededFuture(())
                
            }.flatMap { _ -> EventLoopFuture<Void> in
                return service.fetchConfigFile(inRepo: event.repository.fullName)
                    .flatMap { configFile -> EventLoopFuture<Void> in

                        if event.pullRequest.isDraft, configFile.shouldSkipDraftPR {
                            logger.info("Draft PR skipped.")
                            return context.eventLoop.makeSucceededFuture(())
                        }

                        // Check triggered action is valid to continue the run
                        guard configFile.prActions.contains(event.action) else {
                            logger.info("PR action \(event.action) skipped")
                            return context.eventLoop.makeSucceededFuture(())
                        }

                        return service.fetchAssignees(forPullRequest: event.number, inRepo: event.repository.fullName)
                            .map { fetchedGitHubAssignees -> [GitHub.User] in
                                logger.debug("The PR is currently assigned to \(fetchedGitHubAssignees)")

                                // GitHub users already assigned by the PR author + CODEOWNERS
                                return fetchedGitHubAssignees + event.pullRequest.requestedReviewers
                            }.flatMap { assignedGitHubUsers -> EventLoopFuture<([Engineer], [Engineer])> in
                                let assignedEngineersOnGitHub = configFile.engineers.filter {
                                    return assignedGitHubUsers.contains(GitHub.User(username: $0.githubUsername))
                                }

                                let engineers = configFile.engineers.filter { $0.githubUsername != event.pullRequest.author.username }
                                logger.debug("\(event.pullRequest.author.username) removed from the reviewers array (if they were in the array)")

                                var elegibleEngineers = Set(engineers)
                                let assignedEngineers = Set(assignedEngineersOnGitHub)
                                elegibleEngineers.subtract(assignedEngineers)

                                return context.eventLoop.makeSucceededFuture((Array(elegibleEngineers), assignedEngineersOnGitHub))
                            }.flatMap { (elegibleEngineers, assignedEngineers) -> EventLoopFuture<[Engineer]> in
                                let promiseRandomEngineers = context.eventLoop.makePromise(of: [Engineer].self)
                                // If assigned engineers + CODEOWNERS don't meet the number of reviewers,
                                // missing engineers are randomly selected
                                if assignedEngineers.count < configFile.numberOfReviewers {
                                    self.selectEngineer(from: elegibleEngineers,
                                                        numberOfEngineersToSelect: configFile.numberOfReviewers - assignedEngineers.count,
                                                        discardableSlackStatus: configFile.discardableSlackStatus,
                                                        promise: promiseRandomEngineers)
                                } else {
                                    promiseRandomEngineers.succeed([])
                                }

                                return promiseRandomEngineers.futureResult.map {
                                    return $0 + assignedEngineers
                                }
                            }.flatMap { reviewers -> EventLoopFuture<Void> in
                                logger.debug("Reviewers: \(reviewers)")

                                let assignPRFuture = self.assign(event: event, to: reviewers, eventLoop: context.eventLoop)
                                let sendMessageOnSlackFuture = self.sendMessageOnSlack(for: event, reviewers: reviewers, slackChannel: configFile.slackPRChannel, eventLoop: context.eventLoop)
                                return EventLoopFuture.andAllSucceed([assignPRFuture, sendMessageOnSlackFuture], on: context.eventLoop)
                            }
                    }
            }
    }
    
    public func shutdown(context: Lambda.ShutdownContext) -> EventLoopFuture<Void> {
        try? httpClient.syncShutdown()
        try? awsClient.syncShutdown()
        return context.eventLoop.makeSucceededFuture(())
    }
    
    /// Fullfil the promise parameter with an array of engineers that are elegible to be assigned to the PR.
    ///
    /// Engineers are randomly picked and checked they are elegile to be assigned to the PR. The array may
    /// contains less elements than `numberOfEngineersToSelect` depending on elegibility rules.
    /// - Parameters:
    ///   - candidates: An array of engineers used as resource where to pick up random elements
    ///   - numberOfEngineersToSelect: Number of elements you request to have fulfilled in the promise.
    ///   - selectedEngineers: Array of engineers picked up. This must be empty when you first call the method.
    ///   - promise: A promise fullfilled with an array of engineers
    func selectEngineer(from candidates: [Engineer],
                        numberOfEngineersToSelect: Int,
                        discardableSlackStatus: [String],
                        selectedEngineers: [Engineer] = [],
                        promise: EventLoopPromise<[Engineer]>) {
        if selectedEngineers.count == numberOfEngineersToSelect || candidates.isEmpty {
            promise.succeed(selectedEngineers)
            return
        }
        
        var copyOfCandidates = candidates
        guard let indexOfRandomCandidate = copyOfCandidates.indices.shuffled().randomElement() else { return }
        let randomCandidate = copyOfCandidates[indexOfRandomCandidate]
        logger.debug("Randomly picked \(randomCandidate.githubUsername)")
        
        // Removed to avoid picking them at the next iteration
        copyOfCandidates.remove(at: indexOfRandomCandidate)
        
        service.fetchStatus(of: randomCandidate)
            .whenComplete { result in
                switch result {
                case .success(let status):
                    var copyOfSelectedCandidates = selectedEngineers
                    
                    if discardableSlackStatus.contains(status) {
                        logger.debug("Discarding \(randomCandidate.githubUsername)")
                    } else {
                        logger.debug("\(randomCandidate.githubUsername) is elegible to be picked")
                        copyOfSelectedCandidates.append(randomCandidate)
                    }
                    
                    self.selectEngineer(from: copyOfCandidates,
                                        numberOfEngineersToSelect: numberOfEngineersToSelect,
                                        discardableSlackStatus: discardableSlackStatus,
                                        selectedEngineers: copyOfSelectedCandidates,
                                        promise: promise)
                    
                case .failure(let error):
                    promise.fail(error)
                }
            }
    }
    
    func assign(event: GitHub.Event,
                to engineers: [Engineer],
                eventLoop: EventLoop) -> EventLoopFuture<Void> {
        if env.isDebug {
            return eventLoop.makeSucceededFuture(())
        } else {
            return service.assignPullRequest(event.number, inRepo: event.repository.fullName, to: engineers)
        }
    }
    
    func sendMessageOnSlack(for event: GitHub.Event,
                            reviewers: [Engineer],
                            slackChannel: String,
                            eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let body = slackMessageBuilder.buildBody(reviewers: reviewers,
                                                 pr: event.pullRequest,
                                                 repoName: event.repository.fullName,
                                                 slackChannel: slackChannel)
        return service.postMessage(body)
    }
}
