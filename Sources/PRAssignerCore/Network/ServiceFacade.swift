//
//  ServiceFacade.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation
import NIO
import Logging

protocol ServiceFacadeProtocol {
    func setSecrets(_ secrets: Secrets)
    func fetchConfigFile(inRepo repoFullName: String) -> EventLoopFuture<ConfigFile>
    func fetchAssignees(forPullRequest prNumber: UInt, inRepo repoFullName: String) -> EventLoopFuture<[GitHub.User]>
    func assignPullRequest(_ prNumber: UInt, inRepo repoFullName: String, to engineers: [Engineer]) -> EventLoopFuture<Void>
    func fetchStatus(of engineer: Engineer) -> EventLoopFuture<String>
    func postMessage(_ rawBody: String) -> EventLoopFuture<Void>
}

class ServiceFacade: ServiceFacadeProtocol {
    private let gitHubClient: GitHubClientProtocol
    private let slackClient: SlackClientProtocol
    private let eventLoop: EventLoop
    
    convenience init(dispatcher: DispatcherProtocol,
                     env: EnvironmentVariablesProvider,
                     eventLoop: EventLoop,
                     logger: Logger) {
        self.init(gitHubClient: GitHubClient(dispatcher: dispatcher, env: env, logger: logger),
                  slackClient: SlackClient(dispatcher: dispatcher, env: env, logger: logger),
                  eventLoop: eventLoop)
    }
    
    init(gitHubClient: GitHubClientProtocol,
         slackClient: SlackClientProtocol,
         eventLoop: EventLoop) {
        self.gitHubClient = gitHubClient
        self.slackClient = slackClient
        self.eventLoop = eventLoop
    }
    
    func setSecrets(_ secrets: Secrets) {
        gitHubClient.setAccessToken(secrets.gitHubAccessToken)
        slackClient.setAccessToken(secrets.slackAccessToken)
    }
    
    // MARK: - GitHub APIs
    
    func fetchConfigFile(inRepo repoFullName: String) -> EventLoopFuture<ConfigFile> {
        execute {
            try gitHubClient.fetchConfigFile(inRepo: repoFullName)
        }
    }
    
    func fetchAssignees(forPullRequest prNumber: UInt, inRepo repoFullName: String) -> EventLoopFuture<[GitHub.User]> {
        execute {
            try gitHubClient.fetchAssignees(forPullRequest: prNumber, inRepo: repoFullName)
        }
    }
    
    func assignPullRequest(_ prNumber: UInt, inRepo repoFullName: String, to engineers: [Engineer]) -> EventLoopFuture<Void> {
        execute {
            try gitHubClient.assignPullRequest(prNumber, inRepo: repoFullName, to: engineers)
        }
    }
    
    // MARK: - Slack APIs
    
    func fetchStatus(of engineer: Engineer) -> EventLoopFuture<String> {
        execute {
            try slackClient.fetchStatus(of: engineer)
        }
    }
    
    func postMessage(_ rawBody: String) -> EventLoopFuture<Void> {
        execute {
            try slackClient.postMessage(rawBody)
        }
    }
}

private extension ServiceFacade {
    func execute<T>(callBlock: (() throws -> EventLoopFuture<T>)) -> EventLoopFuture<T> {
        do {
            return try callBlock()
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}
