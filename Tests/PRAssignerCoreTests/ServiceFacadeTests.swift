//
//  ServiceFacadeTests.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import XCTest
import NIO
@testable import PRAssignerCore

class ServiceFacadeTests: XCTestCase {
    var eventLoop: EventLoop!
    var gitHubClient: MockGitHubClient!
    var slackClient: MockSlackClient!
    var sut: ServiceFacade!
    
    static var allTests = [
        ("testGivenFetchConfigFile_WhenCalled_ThenGitHubClientIsCalledWithCorrectParams", testGivenFetchConfigFile_WhenCalled_ThenGitHubClientIsCalledWithCorrectParams),
        ("testGivenFetchConfigFile_WhenGitHubClientThrowsError_ThenFutureFails", testGivenFetchConfigFile_WhenGitHubClientThrowsError_ThenFutureFails),
        ("testGivenFetchAssignees_WhenCalled_ThenGitHubClientIsCalledWithCorrectParams", testGivenFetchAssignees_WhenCalled_ThenGitHubClientIsCalledWithCorrectParams),
        ("testGivenAssignPullRequest_WhenCalled_ThenGitHubClientIsCalledWithCorrectParams", testGivenAssignPullRequest_WhenCalled_ThenGitHubClientIsCalledWithCorrectParams),
        ("testGivenFetchStatus_WhenCalled_ThenSlackClientIsCalledWithCorrectParams", testGivenFetchStatus_WhenCalled_ThenSlackClientIsCalledWithCorrectParams),
        ("testGivenPostMessage_WhenCalled_ThenSlackClientIsCalledWithCorrectParams", testGivenPostMessage_WhenCalled_ThenSlackClientIsCalledWithCorrectParams)
    ]
    
    override func setUp() {
        eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount).next()
        gitHubClient = MockGitHubClient(eventLoop: eventLoop)
        slackClient = MockSlackClient(eventLoop: eventLoop)
        sut = ServiceFacade(gitHubClient: gitHubClient, slackClient: slackClient, eventLoop: eventLoop)
    }
    
    override func tearDown() {
        eventLoop = nil
        gitHubClient = nil
        slackClient = nil
        sut = nil
    }
    
    func testGivenSetSecrets_WhenCalled_ThenCorrectAccessTokenAreSetForGitHubAndSlack() {
        let gitHubAccessToken = "gitHubAccessToken"
        let slackAccessToken = "slackAccessToken"
        
        sut.setSecrets(Secrets(gitHubAccessToken: gitHubAccessToken, slackAccessToken: slackAccessToken))
        
        XCTAssertEqual(gitHubClient.accessToken, gitHubAccessToken)
        XCTAssertEqual(slackClient.accessToken, slackAccessToken)
    }
    
    func testGivenFetchConfigFile_WhenCalled_ThenGitHubClientIsCalledWithCorrectParams() {
        let repoFullName = "justeat/PRAssigner"
        let expectation = XCTestExpectation(description: #function)
        
        sut.fetchConfigFile(inRepo: repoFullName)
            .whenSuccess { _ in
                XCTAssertEqual(self.gitHubClient.fetchConfigFileRepoFullName, repoFullName)
                expectation.fulfill()
            }
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testGivenFetchConfigFile_WhenGitHubClientThrowsError_ThenFutureFails() {
        gitHubClient.errorException = NetworkError.errorInvalidRequest
        let expectation = XCTestExpectation(description: #function)
        
        sut.fetchConfigFile(inRepo: "")
            .whenComplete { result in
                switch result {
                case .success:
                    XCTFail("future should have failed")
                case .failure:
                    XCTAssertTrue(true)
                }
                expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testGivenFetchAssignees_WhenCalled_ThenGitHubClientIsCalledWithCorrectParams() {
        let prNumber: UInt = 1
        let repoFullName = "justeat/PRAssigner"
        let expectation = XCTestExpectation(description: #function)
        
        sut.fetchAssignees(forPullRequest: prNumber, inRepo: repoFullName)
            .whenSuccess { _ in
                XCTAssertEqual(self.gitHubClient.fetchAssigneesCallCount, 1)
                XCTAssertEqual(self.gitHubClient.fetchAssigneesPrNumber, prNumber)
                XCTAssertEqual(self.gitHubClient.fetchAssigneesRepoFullName, repoFullName)
                expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testGivenAssignPullRequest_WhenCalled_ThenGitHubClientIsCalledWithCorrectParams() {
        let prNumber: UInt = 1
        let repoFullName = "justeat/PRAssigner"
        let engineers = [Engineer(githubUsername: "githubUsername", slackID: "slackID")]
        let expectation = XCTestExpectation(description: #function)
        
        sut.assignPullRequest(prNumber, inRepo: repoFullName, to: engineers)
            .whenSuccess { _ in
                XCTAssertEqual(self.gitHubClient.assignPullRequestCallCount, 1)
                XCTAssertEqual(self.gitHubClient.assignPullRequestPrNumber, prNumber)
                XCTAssertEqual(self.gitHubClient.assignPullRequestRepoFullName, repoFullName)
                XCTAssertEqual(self.gitHubClient.assignPullRequestEngineers, engineers)
                expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testGivenFetchStatus_WhenCalled_ThenSlackClientIsCalledWithCorrectParams() {
        let engineer = Engineer(githubUsername: "githubUsername", slackID: "slackID")
        let expectation = XCTestExpectation(description: #function)
        
        sut.fetchStatus(of: engineer)
            .whenSuccess { _ in
                XCTAssertEqual(self.slackClient.fetchStatusCallCount, 1)
                XCTAssertEqual(self.slackClient.fetchStatusReviewer, engineer)
                expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testGivenPostMessage_WhenCalled_ThenSlackClientIsCalledWithCorrectParams() {
        let body = "test-message"
        let expectation = XCTestExpectation(description: #function)
        
        sut.postMessage(body)
            .whenSuccess { _ in
                XCTAssertEqual(self.slackClient.postMessageCallCount, 1)
                XCTAssertEqual(self.slackClient.postMessageRawBody, body)
                expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }
}
