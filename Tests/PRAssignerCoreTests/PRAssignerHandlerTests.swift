//
//  PRAssignerHandlerTests.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import XCTest
import Logging
import NIO
import Dispatch
import SotoSecretsManager
@testable import AWSLambdaRuntime
@testable import AWSLambdaRuntimeCore
@testable import PRAssignerCore

class PRAssignerHandlerTests: XCTestCase {
    var eventLoop: EventLoop!
    var env: MockEnviriableVariables!
    var service: MockServiceFacade!
    var httpClient: MockShutdownable!
    var awsClient: MockShutdownable!
    var secretsManager: MockSecretsManager!
    var slackMessageBuilder: MockSlackMessageBuilder!
    var sut: PRAssignerHandler!

    static var allTests = [
        ("testGivenHandler_WhenDebugIsFalseAndPRTitleHasPrefixTest_ThenReturns", testGivenHandler_WhenDebugIsFalseAndPRTitleHasPrefixTest_ThenReturns),
        ("testGivenHandler_WhenGetSecrets_ThenSecretsNameIsCorrect", testGivenHandler_WhenGetSecrets_ThenSecretsNameIsCorrect),
        ("testGivenHandler_WhenGetSecretsReturnsNil_ThenReturnsWithFailure", testGivenHandler_WhenGetSecretsReturnsNil_ThenReturnsWithFailure),
        ("testGivenHandlerAndValidSecrets_WhenGetSecretsSucceded_ThenSecretsAreParsed", testGivenHandlerAndValidSecrets_WhenGetSecretsSucceded_ThenSecretsAreParsed),
        ("testGivenHandlerAndInvalidSecrets_WhenGetSecretsSucceded_ThenReturnsWithFailure", testGivenHandlerAndInvalidSecrets_WhenGetSecretsSucceded_ThenReturnsWithFailure),
        ("testGivenHandler_WhenPRIsDraft_ThenReturns", testGivenHandler_WhenPRIsDraft_ThenReturns),
        ("testGivenHandler_WhenEventActionIsntValid_ThenReturns", testGivenHandler_WhenEventActionIsntValid_ThenReturns),
        ("testGivenABC_WhenAIsPRAuthor_ThenBCAreAssignedAndNotified", testGivenABC_WhenAIsPRAuthor_ThenBCAreAssignedAndNotified),
        ("testGivenAB_WhenCIsPRAuthorAndAIsAssigned_ThenABAreAssignedAndNotified", testGivenAB_WhenCIsPRAuthorAndAIsAssigned_ThenABAreAssignedAndNotified),
        ("testGivenAB_WhenCIsPRAuthorAndABAreRequestedReviewersAndNotAvailable_ThenABAreNotified", testGivenAB_WhenCIsPRAuthorAndABAreRequestedReviewersAndNotAvailable_ThenABAreNotified),
        ("testGivenABCD_WhenDIsPRAuthorAndAIsRequestedReviewersAndBIsAssignedAndCIsAndNotAvailable_ThenABAreNotified", testGivenABCD_WhenDIsPRAuthorAndAIsRequestedReviewersAndBIsAssignedAndCIsAndNotAvailable_ThenABAreNotified),
        ("testGivenSelectEngineer_WhenSelectedEngineersCountIsEqualToNumberToSelect_ThenSelectedEngineersIsReturned", testGivenSelectEngineer_WhenSelectedEngineersCountIsEqualToNumberToSelect_ThenSelectedEngineersIsReturned),
        ("testGivenSelectEngineer_WhenCandidatesIsEmpty_ThenSelectedEngineersIsReturned", testGivenSelectEngineer_WhenCandidatesIsEmpty_ThenSelectedEngineersIsReturned),
        ("testGivenSelectEngineerAnd2ToSelect_WhenAAndBHaveDiscardableStatus_ThenCAndDAreSelected", testGivenSelectEngineerAnd2ToSelect_WhenAAndBHaveDiscardableStatus_ThenCAndDAreSelected),
        ("testGivenSelectEngineerAnd2ToSelect_WhenOnlyAIsAvailable_ThenAIsSelected", testGivenSelectEngineerAnd2ToSelect_WhenOnlyAIsAvailable_ThenAIsSelected),
        ("testGivenEventAndEngineers_WhenIsDebugTrueAndAssignIsCalled_ThenAssignPullRequestIsntCalled", testGivenEventAndEngineers_WhenIsDebugTrueAndAssignIsCalled_ThenAssignPullRequestIsntCalled),
        ("testGivenEventAndEngineers_WhenIsDebugFalseAndAssignIsCalled_ThenAssignPullRequestIsCalled", testGivenEventAndEngineers_WhenIsDebugFalseAndAssignIsCalled_ThenAssignPullRequestIsCalled),
        ("testGivenEventAndReviewers_WhenSendMessageOnSlackIsCalled_ThenCorrectBodyIsSentAsMessage", testGivenEventAndReviewers_WhenSendMessageOnSlackIsCalled_ThenCorrectBodyIsSentAsMessage)
    ]

    override func setUp() {
        eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount).next()
        env = MockEnviriableVariables()
        service = MockServiceFacade(eventLoop: eventLoop)
        httpClient = MockShutdownable()
        awsClient = MockShutdownable()
        secretsManager = MockSecretsManager(eventLoop: eventLoop)
        slackMessageBuilder = MockSlackMessageBuilder()
        sut = PRAssignerHandler(env: env,
                                httpClient: httpClient,
                                service: service,
                                awsClient: awsClient,
                                secretsManager: secretsManager,
                                slackMessageBuilder: slackMessageBuilder,
                                logger: Logger(label: "test"))
    }

    override func tearDown() {
        eventLoop = nil
        env = nil
        service = nil
        httpClient = nil
        awsClient = nil
        secretsManager = nil
        slackMessageBuilder = nil
        sut = nil
    }

    // MARK: - Handler

    func testGivenHandler_WhenDebugIsFalseAndPRTitleHasPrefixTest_ThenReturns() {
        env.isDebug = false
        let event = GitHub.Event(action: "opened",
                                 number: 2,
                                 pullRequest: GitHub.PullRequest(url: "https://github.com/Codertocat/Hello-World/pull/2",
                                                                 title: "Test: Update the README with new information.",
                                                                 isDraft: false,
                                                                 author: GitHub.User(username: "Codertocat"),
                                                                 requestedReviewers: []),
                                 repository: GitHub.Repository(fullName: "Codertocat/Hello-World"))

        XCTAssertNoThrow(try Lambda.test(sut, with: event))
        XCTAssertEqual(service.setSecretsCallCount, 0)
    }

    func testGivenHandler_WhenGetSecrets_ThenSecretsNameIsCorrect() {
        env.isDebug = false
        let secretsName = "secretsName"
        env.secretsName = secretsName

        XCTAssertNoThrow(try Lambda.test(sut, with: .fake()))
        XCTAssertEqual(secretsManager.request!.secretId, secretsName)
    }

    func testGivenHandler_WhenGetSecretsReturnsNil_ThenReturnsWithFailure() {
        env.isDebug = false
        secretsManager.getSecretValueFuture = eventLoop.makeSucceededFuture(SecretsManager.GetSecretValueResponse(arn: nil, createdDate: nil, name: nil, secretBinary: nil, secretString: nil, versionId: nil, versionStages: nil))

        XCTAssertThrowsError(try Lambda.test(sut, with: .fake()))
        XCTAssertEqual(secretsManager.getSecretValueCallCount, 1)
        XCTAssertEqual(service.fetchConfigFileCallCount, 0)
    }

    func testGivenHandlerAndValidSecrets_WhenGetSecretsSucceded_ThenSecretsAreParsed() {
        env.isDebug = false
        let rawSecretsString = "{ \"github-access-token\": \"gitHubAccessToken\", \"slack-access-token\": \"slackAccessToken\" }"
        let expectedSecrets = Secrets(gitHubAccessToken: "gitHubAccessToken", slackAccessToken: "slackAccessToken")
        secretsManager.getSecretValueFuture = eventLoop.makeSucceededFuture(SecretsManager.GetSecretValueResponse(arn: nil, createdDate: nil, name: nil, secretBinary: nil, secretString: rawSecretsString, versionId: nil, versionStages: nil))

        XCTAssertNoThrow(try Lambda.test(sut, with: .fake()))
        XCTAssertEqual(secretsManager.getSecretValueCallCount, 1)
        XCTAssertEqual(service.setSecretsCallCount, 1)
        XCTAssertEqual(service.secrets, expectedSecrets)
    }

    func testGivenHandlerAndInvalidSecrets_WhenGetSecretsSucceded_ThenReturnsWithFailure() {
        env.isDebug = false
        secretsManager.getSecretValueFuture = eventLoop.makeSucceededFuture(SecretsManager.GetSecretValueResponse(arn: nil, createdDate: nil, name: nil, secretBinary: nil, secretString: "invalid-json", versionId: nil, versionStages: nil))

        XCTAssertThrowsError(try Lambda.test(sut, with: .fake()))
        XCTAssertEqual(secretsManager.getSecretValueCallCount, 1)
        XCTAssertEqual(service.fetchConfigFileCallCount, 0)
    }

    func testGivenHandler_WhenPRIsDraft_ThenReturns() {
        env.isDebug = false
        let config = ConfigFile(shouldSkipDraftPR: true)
        service.fetchConfigFileFuture = eventLoop.makeSucceededFuture(config)
        let event = GitHub.Event(action: "opened",
                                 number: 2,
                                 pullRequest: GitHub.PullRequest(url: "https://github.com/Codertocat/Hello-World/pull/2",
                                                                 title: "Update the README with new information.",
                                                                 isDraft: true,
                                                                 author: GitHub.User(username: "Codertocat"),
                                                                 requestedReviewers: []),
                                 repository: GitHub.Repository(fullName: "Codertocat/Hello-World"))

        XCTAssertNoThrow(try Lambda.test(sut, with: event))
        XCTAssertEqual(service.fetchAssigneesCallCount, 0)
    }

    func testGivenHandler_WhenEventActionIsntValid_ThenReturns() {
        env.isDebug = false
        let config = ConfigFile(prActions: ["opened"])
        service.fetchConfigFileFuture = eventLoop.makeSucceededFuture(config)
        let event = GitHub.Event(action: "invalid-action",
                                 number: 2,
                                 pullRequest: GitHub.PullRequest(url: "https://github.com/Codertocat/Hello-World/pull/2",
                                                                 title: "Update the README with new information.",
                                                                 isDraft: false,
                                                                 author: GitHub.User(username: "Codertocat"),
                                                                 requestedReviewers: []),
                                 repository: GitHub.Repository(fullName: "Codertocat/Hello-World"))

        XCTAssertNoThrow(try Lambda.test(sut, with: event))
        XCTAssertEqual(service.fetchAssigneesCallCount, 0)
    }

    // Given isDebug = false, numberOfReviewers = 2, engineersFetched = [A, B, C], requestedReviewers = [], assignedEngineer = [], discardableStatus = []
    // When prAuthor = A
    // Then assignedAndNotified = [B, C]
    func testGivenABC_WhenAIsPRAuthor_ThenBCAreAssignedAndNotified() {
        env.isDebug = false
        let engineerA = Engineer(githubUsername: "githubUsername-A", slackID: "slackID-A")
        let engineerB = Engineer(githubUsername: "githubUsername-B", slackID: "slackID-B")
        let engineerC = Engineer(githubUsername: "githubUsername-C", slackID: "slackID-C")
        let config = ConfigFile(prActions: ["opened"],
                                numberOfReviewers: 2,
                                reviewers: [engineerA, engineerB, engineerC])
        service.fetchConfigFileFuture = eventLoop.makeSucceededFuture(config)
        let event = GitHub.Event(action: "opened",
                                 number: 1,
                                 pullRequest: GitHub.PullRequest(url: "https://github.com/Codertocat/Hello-World/pull/2",
                                                                 title: "Update the README with new information.",
                                                                 isDraft: false,
                                                                 author: engineerA.asGitHubUser(),
                                                                 requestedReviewers: []),
                                 repository: GitHub.Repository(fullName: "Codertocat/Hello-World"))
        service.fetchAssigneesFuture = eventLoop.makeSucceededFuture([])
        service.fetchStatusDict = nil

        XCTAssertNoThrow(try Lambda.test(sut, with: event))

        XCTAssertEqual(service.assignPullRequestCallCount, 1)
        XCTAssertEqual(service.assignPullPrNumber, event.number)
        XCTAssertEqual(service.assignPullRepoFullName, event.repository.fullName)
        XCTAssertEqual(service.assignPullEngieners?.sorted(), [engineerB, engineerC].sorted())

        XCTAssertEqual(slackMessageBuilder.buildBodyCallCount, 1)
        XCTAssertEqual(slackMessageBuilder.buildBodyPr, event.pullRequest)
        XCTAssertEqual(slackMessageBuilder.buildBodyRepoName, event.repository.fullName)
        XCTAssertEqual(slackMessageBuilder.buildBodyReviewers?.sorted(), [engineerB, engineerC].sorted())
    }

    // Given isDebug = false, numberOfReviewers = 2, engineersFetched = [A, B], requestedReviewers = [], assignedEngineer = [A], discardableStatus = []
    // When prAuthor = C
    // Then assignedAndNotified = [A, B]
    func testGivenAB_WhenCIsPRAuthorAndAIsAssigned_ThenABAreAssignedAndNotified() {
        env.isDebug = false
        let engineerA = Engineer(githubUsername: "githubUsername-A", slackID: "slackID-A")
        let engineerB = Engineer(githubUsername: "githubUsername-B", slackID: "slackID-B")
        let engineerC = Engineer(githubUsername: "githubUsername-C", slackID: "slackID-C")
        let config = ConfigFile(prActions: ["opened"],
                                numberOfReviewers: 2,
                                reviewers: [engineerA, engineerB])
        service.fetchConfigFileFuture = eventLoop.makeSucceededFuture(config)
        let event = GitHub.Event(action: "opened",
                                 number: 1,
                                 pullRequest: GitHub.PullRequest(url: "https://github.com/Codertocat/Hello-World/pull/2",
                                                                 title: "Update the README with new information.",
                                                                 isDraft: false,
                                                                 author: engineerC.asGitHubUser(),
                                                                 requestedReviewers: []),
                                 repository: GitHub.Repository(fullName: "Codertocat/Hello-World"))
        service.fetchAssigneesFuture = eventLoop.makeSucceededFuture([engineerA.asGitHubUser()])
        service.fetchStatusDict = nil

        XCTAssertNoThrow(try Lambda.test(sut, with: event))

        XCTAssertEqual(service.assignPullRequestCallCount, 1)
        XCTAssertEqual(service.assignPullPrNumber, event.number)
        XCTAssertEqual(service.assignPullRepoFullName, event.repository.fullName)
        XCTAssertEqual(service.assignPullEngieners?.sorted(), [engineerA, engineerB].sorted())

        XCTAssertEqual(slackMessageBuilder.buildBodyCallCount, 1)
        XCTAssertEqual(slackMessageBuilder.buildBodyPr, event.pullRequest)
        XCTAssertEqual(slackMessageBuilder.buildBodyRepoName, event.repository.fullName)
        XCTAssertEqual(slackMessageBuilder.buildBodyReviewers?.sorted(), [engineerA, engineerB].sorted())
    }

    // Given isDebug = false, numberOfReviewers = 2, engineersFetched = [A, B], requestedReviewers = [A, B], assignedEngineer = [], discardableStatus = [A, B]
    // When prAuthor = C
    // Then assignedAndNotified = [A, B]
    func testGivenAB_WhenCIsPRAuthorAndABAreRequestedReviewersAndNotAvailable_ThenABAreNotified() {
        env.isDebug = false
        let engineerA = Engineer(githubUsername: "githubUsername-A", slackID: "slackID-A")
        let engineerB = Engineer(githubUsername: "githubUsername-B", slackID: "slackID-B")
        let engineerC = Engineer(githubUsername: "githubUsername-C", slackID: "slackID-C")
        let config = ConfigFile(prActions: ["opened"],
                                numberOfReviewers: 2,
                                discardableSlackStatus: [":books:"],
                                reviewers: [engineerA, engineerB])
        service.fetchConfigFileFuture = eventLoop.makeSucceededFuture(config)
        let event = GitHub.Event(action: "opened",
                                 number: 1,
                                 pullRequest: GitHub.PullRequest(url: "https://github.com/Codertocat/Hello-World/pull/2",
                                                                 title: "Update the README with new information.",
                                                                 isDraft: false,
                                                                 author: engineerC.asGitHubUser(),
                                                                 requestedReviewers: [engineerA.asGitHubUser(), engineerB.asGitHubUser()]),
                                 repository: GitHub.Repository(fullName: "Codertocat/Hello-World"))
        service.fetchAssigneesFuture = eventLoop.makeSucceededFuture([])
        service.fetchStatusDict = [engineerA: ":books:", engineerB: ":books:"]

        XCTAssertNoThrow(try Lambda.test(sut, with: event))

        XCTAssertEqual(service.assignPullRequestCallCount, 1)
        XCTAssertEqual(service.assignPullPrNumber, event.number)
        XCTAssertEqual(service.assignPullRepoFullName, event.repository.fullName)
        XCTAssertEqual(service.assignPullEngieners?.sorted(), [engineerA, engineerB].sorted())

        XCTAssertEqual(slackMessageBuilder.buildBodyCallCount, 1)
        XCTAssertEqual(slackMessageBuilder.buildBodyPr, event.pullRequest)
        XCTAssertEqual(slackMessageBuilder.buildBodyRepoName, event.repository.fullName)
        XCTAssertEqual(slackMessageBuilder.buildBodyReviewers?.sorted(), [engineerA, engineerB].sorted())
    }

    // Given isDebug = false, numberOfReviewers = 3, engineersFetched = [A, B, C, D], requestedReviewers = [A], assignedEngineer = [B], discardableStatus = [C]
    // When prAuthor = D
    // Then assignedAndNotified = [A, B]
    func testGivenABCD_WhenDIsPRAuthorAndAIsRequestedReviewersAndBIsAssignedAndCIsAndNotAvailable_ThenABAreNotified() {
        env.isDebug = false
        let engineerA = Engineer(githubUsername: "githubUsername-A", slackID: "slackID-A")
        let engineerB = Engineer(githubUsername: "githubUsername-B", slackID: "slackID-B")
        let engineerC = Engineer(githubUsername: "githubUsername-C", slackID: "slackID-C")
        let engineerD = Engineer(githubUsername: "githubUsername-D", slackID: "slackID-D")
        let config = ConfigFile(prActions: ["opened"],
                                numberOfReviewers: 3,
                                discardableSlackStatus: [":books:"],
                                reviewers: [engineerA, engineerB, engineerC, engineerD])
        service.fetchConfigFileFuture = eventLoop.makeSucceededFuture(config)
        let event = GitHub.Event(action: "opened",
                                 number: 1,
                                 pullRequest: GitHub.PullRequest(url: "https://github.com/Codertocat/Hello-World/pull/2",
                                                                 title: "Update the README with new information.",
                                                                 isDraft: false,
                                                                 author: engineerD.asGitHubUser(),
                                                                 requestedReviewers: [engineerA.asGitHubUser()]),
                                 repository: GitHub.Repository(fullName: "Codertocat/Hello-World"))
        service.fetchAssigneesFuture = eventLoop.makeSucceededFuture([engineerB.asGitHubUser()])
        service.fetchStatusDict = [engineerC: ":books:"]

        XCTAssertNoThrow(try Lambda.test(sut, with: event))

        XCTAssertEqual(service.assignPullRequestCallCount, 1)
        XCTAssertEqual(service.assignPullPrNumber, event.number)
        XCTAssertEqual(service.assignPullRepoFullName, event.repository.fullName)
        XCTAssertEqual(service.assignPullEngieners?.sorted(), [engineerA, engineerB].sorted())

        XCTAssertEqual(slackMessageBuilder.buildBodyCallCount, 1)
        XCTAssertEqual(slackMessageBuilder.buildBodyPr, event.pullRequest)
        XCTAssertEqual(slackMessageBuilder.buildBodyRepoName, event.repository.fullName)
        XCTAssertEqual(slackMessageBuilder.buildBodyReviewers?.sorted(), [engineerA, engineerB].sorted())
    }

    func testGivenLambda_WhenShutdown_ThenClientsShutdownAreClassed() {
        let expectation = XCTestExpectation(description: #function)
        sut.shutdown(context: Lambda.ShutdownContext(logger: Logger(label: "test"), eventLoop: eventLoop))
            .whenComplete { result in
                switch result {
                case .success:
                    XCTAssertEqual(self.httpClient.syncShutdownCallCount, 1)
                    XCTAssertEqual(self.awsClient.syncShutdownCallCount, 1)
                    expectation.fulfill()
                case .failure:
                    XCTFail("Should have succeded")
                }
            }

        wait(for: [expectation], timeout: 2)
    }

    // MARK: - Select random engineer

    func testGivenSelectEngineer_WhenSelectedEngineersCountIsEqualToNumberToSelect_ThenSelectedEngineersIsReturned() {
        let promise = eventLoop.makePromise(of: [Engineer].self)
        let selectedEngineers = [Engineer(githubUsername: "githubUsername", slackID: "slackID")]
        let expectation = XCTestExpectation(description: #function)

        sut.selectEngineer(from: [Engineer(githubUsername: "", slackID: "")],
                           numberOfEngineersToSelect: 1,
                           discardableSlackStatus: [],
                           selectedEngineers: selectedEngineers,
                           promise: promise)

        promise.futureResult.whenSuccess {
            XCTAssertEqual($0, selectedEngineers)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)
    }

    func testGivenSelectEngineer_WhenCandidatesIsEmpty_ThenSelectedEngineersIsReturned() {
        let promise = eventLoop.makePromise(of: [Engineer].self)
        let selectedEngineers = [Engineer(githubUsername: "githubUsername", slackID: "slackID")]
        let expectation = XCTestExpectation(description: #function)

        sut.selectEngineer(from: [],
                           numberOfEngineersToSelect: 10,
                           discardableSlackStatus: [],
                           selectedEngineers: selectedEngineers,
                           promise: promise)

        promise.futureResult.whenSuccess {
            XCTAssertEqual($0, selectedEngineers)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)
    }

    func testGivenSelectEngineerAnd2ToSelect_WhenAAndBHaveDiscardableStatus_ThenCAndDAreSelected() {
        let promise = eventLoop.makePromise(of: [Engineer].self)
        let expectation = XCTestExpectation(description: #function)
        let engineerA = Engineer(githubUsername: "githubUsername-A", slackID: "slackID-A")
        let engineerB = Engineer(githubUsername: "githubUsername-B", slackID: "slackID-B")
        let engineerC = Engineer(githubUsername: "githubUsername-C", slackID: "slackID-C")
        let engineerD = Engineer(githubUsername: "githubUsername-D", slackID: "slackID-D")
        service.fetchStatusDict = [engineerA: ":palm_tree:", engineerB: ":books:"]

        sut.selectEngineer(from: [engineerA, engineerB, engineerC, engineerD],
                           numberOfEngineersToSelect: 2,
                           discardableSlackStatus: [":palm_tree:", ":books:"],
                           promise: promise)

        promise.futureResult.whenSuccess {
            XCTAssertEqual($0.count, 2)
            XCTAssertTrue($0.contains(engineerC))
            XCTAssertTrue($0.contains(engineerD))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)
    }

    func testGivenSelectEngineerAnd2ToSelect_WhenOnlyAIsAvailable_ThenAIsSelected() {
        let promise = eventLoop.makePromise(of: [Engineer].self)
        let expectation = XCTestExpectation(description: #function)
        let engineerA = Engineer(githubUsername: "githubUsername-A", slackID: "slackID-A")
        let engineerB = Engineer(githubUsername: "githubUsername-B", slackID: "slackID-B")
        let engineerC = Engineer(githubUsername: "githubUsername-C", slackID: "slackID-C")
        let engineerD = Engineer(githubUsername: "githubUsername-D", slackID: "slackID-D")
        service.fetchStatusDict = [engineerB: ":palm_tree:", engineerC: ":books:", engineerD: ":face_with_thermometer:"]

        sut.selectEngineer(from: [engineerA, engineerB, engineerC, engineerD],
                           numberOfEngineersToSelect: 2,
                           discardableSlackStatus: [":palm_tree:", ":books:", ":face_with_thermometer:"],
                           promise: promise)

        promise.futureResult.whenSuccess {
            XCTAssertEqual($0.count, 1)
            XCTAssertTrue($0.contains(engineerA))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)
    }


    // MARK: - Assign PR

    func testGivenEventAndEngineers_WhenIsDebugTrueAndAssignIsCalled_ThenAssignPullRequestIsntCalled() {
        env.isDebug = true
        let event = GitHub.Event(action: "",
                                 number: 1,
                                 pullRequest: GitHub.PullRequest(url: "", title: "", isDraft: false, author: GitHub.User(username: ""), requestedReviewers: []),
                                 repository: GitHub.Repository(fullName: "justeat/PRAssigner"))
        let engineers = [Engineer(githubUsername: "githubUsername", slackID: "slackID")]
        let expectation = XCTestExpectation(description: #function)

        sut.assign(event: event, to: engineers, eventLoop: eventLoop)
            .whenSuccess { _ in
                XCTAssertEqual(self.service.assignPullRequestCallCount, 0)
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 2)
    }

    // MARK: - Send Message on Slack

    func testGivenEventAndEngineers_WhenIsDebugFalseAndAssignIsCalled_ThenAssignPullRequestIsCalled() {
        env.isDebug = false
        let event = GitHub.Event(action: "",
                                 number: 1,
                                 pullRequest: GitHub.PullRequest(url: "", title: "", isDraft: false, author: GitHub.User(username: ""), requestedReviewers: []),
                                 repository: GitHub.Repository(fullName: "justeat/PRAssigner"))
        let engineers = [Engineer(githubUsername: "githubUsername", slackID: "slackID")]
        let expectation = XCTestExpectation(description: #function)

        sut.assign(event: event, to: engineers, eventLoop: eventLoop)
            .whenSuccess { _ in
                XCTAssertEqual(self.service.assignPullRequestCallCount, 1)
                XCTAssertEqual(self.service.assignPullPrNumber, 1)
                XCTAssertEqual(self.service.assignPullRepoFullName, event.repository.fullName)
                XCTAssertEqual(self.service.assignPullEngieners, engineers)
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 2)
    }

    func testGivenEventAndReviewers_WhenSendMessageOnSlackIsCalled_ThenCorrectBodyIsSentAsMessage() {
        let event = GitHub.Event(action: "",
                                 number: 1,
                                 pullRequest: GitHub.PullRequest(url: "", title: "", isDraft: false, author: GitHub.User(username: ""), requestedReviewers: []),
                                 repository: GitHub.Repository(fullName: "justeat/PRAssigner"))
        let reviewers = [Engineer(githubUsername: "githubUsername", slackID: "slackID")]
        let expectation = XCTestExpectation(description: #function)
        let slackChannel = "#ios-pr"

        let testBody = "test-body"
        slackMessageBuilder.buildBody = testBody

        sut.sendMessageOnSlack(for: event, reviewers: reviewers, slackChannel: slackChannel, eventLoop: eventLoop)
            .whenSuccess { _ in
                XCTAssertEqual(self.slackMessageBuilder.buildBodyCallCount, 1)
                XCTAssertEqual(self.slackMessageBuilder.buildBodyReviewers, reviewers)
                XCTAssertEqual(self.slackMessageBuilder.buildBodyPr, event.pullRequest)
                XCTAssertEqual(self.slackMessageBuilder.buildBodyRepoName, event.repository.fullName)
                XCTAssertEqual(self.slackMessageBuilder.buildBodySlackChannel, slackChannel)

                XCTAssertEqual(self.service.postMessageBody, testBody)

                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 2)
    }
}

extension Lambda {
    public struct TestConfig {
        public var requestID: String
        public var traceID: String
        public var invokedFunctionARN: String
        public var timeout: DispatchTimeInterval

        public init(requestID: String = "\(DispatchTime.now().uptimeNanoseconds)",
                    traceID: String = "Root=\(DispatchTime.now().uptimeNanoseconds);Parent=\(DispatchTime.now().uptimeNanoseconds);Sampled=1",
                    invokedFunctionARN: String = "arn:aws:lambda:us-west-1:\(DispatchTime.now().uptimeNanoseconds):function:custom-runtime",
                    timeout: DispatchTimeInterval = .seconds(5)) {
            self.requestID = requestID
            self.traceID = traceID
            self.invokedFunctionARN = invokedFunctionARN
            self.timeout = timeout
        }
    }

    public static func test<In, Out, Handler: EventLoopLambdaHandler>(
        _ handler: Handler,
        with event: In,
        using config: TestConfig = .init()
    ) throws -> Out where Handler.In == In, Handler.Out == Out {
        let logger = Logger(label: "test")
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer {
            try! eventLoopGroup.syncShutdownGracefully()
        }
        let eventLoop = eventLoopGroup.next()
        let context = Context(requestID: config.requestID,
                              traceID: config.traceID,
                              invokedFunctionARN: config.invokedFunctionARN,
                              deadline: .now() + config.timeout,
                              logger: logger,
                              eventLoop: eventLoop,
                              allocator: ByteBufferAllocator())

        return try eventLoop.flatSubmit {
            handler.handle(context: context, event: event)
        }.wait()
    }
}

extension Engineer: Comparable {
    public static func < (lhs: Engineer, rhs: Engineer) -> Bool {
        return lhs.githubUsername < rhs.githubUsername
    }

    func asGitHubUser() -> GitHub.User {
        return GitHub.User(username: githubUsername)
    }
}
