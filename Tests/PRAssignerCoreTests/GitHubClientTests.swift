//
//  GitHubClientTests.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import XCTest
import AsyncHTTPClient
import NIO
import Logging
@testable import PRAssignerCore

class GitHubClientTests: XCTestCase {
    var env: MockEnviriableVariables!
    var dispatcher: MockDispatcher!
    var sut: GitHubClient!
    
    static var allTests = [
        ("testGivenFetchConfigFile_WhenMissingGitHubToken_ThenThrowsAnError", testGivenFetchConfigFile_WhenMissingGitHubToken_ThenThrowsAnError),
        ("testGivenFetchConfigFile_WhenRequestIsValid_ThenParamsAreEncoded", testGivenFetchConfigFile_WhenRequestIsValid_ThenParamsAreEncoded),
        ("testGivenFetchAssignees_WhenMissingGitHubToken_ThenThrowsAnError", testGivenFetchAssignees_WhenMissingGitHubToken_ThenThrowsAnError),
        ("testGivenFetchAssignees_WhenRequestIsValid_ThenParamsAreEncoded", testGivenFetchAssignees_WhenRequestIsValid_ThenParamsAreEncoded),
        ("testGivenFetchAssignees_WhenExecuted_ThenAssigneesAreReturned", testGivenFetchAssignees_WhenExecuted_ThenAssigneesAreReturned),
        ("testGivenAssignPullRequest_WhenMissingGitHubToken_ThenThrowsAnError", testGivenAssignPullRequest_WhenMissingGitHubToken_ThenThrowsAnError),
        ("testGivenAssignPullRequest_WhenRequestIsValid_ThenParamsAreEncoded", testGivenAssignPullRequest_WhenRequestIsValid_ThenParamsAreEncoded)
    ]
    
    override func setUp() {
        env = MockEnviriableVariables()
        dispatcher = MockDispatcher()
        sut = GitHubClient(dispatcher: dispatcher, env: env, logger: Logger(label: "test"))
    }
    
    override func tearDown() {
        env = nil
        dispatcher = nil
        sut = nil
    }
    
    func testGivenFetchConfigFile_WhenMissingGitHubToken_ThenThrowsAnError() {
        env.githubUrlAPI = nil
        
        XCTAssertThrowsError(try sut.fetchConfigFile(inRepo: ""))
    }
    
    func testGivenFetchConfigFile_WhenRequestIsValid_ThenParamsAreEncoded() throws {
        let githubUrlAPI = "http://www.github.com"
        let githubAccessToken = "githubAccessToken"
        let repoFullName = "JustEat/PRAssigner"
        env.githubUrlAPI = URL(string: githubUrlAPI)!
        sut.setAccessToken(githubAccessToken)
        let expectedRequest = try HTTPClient.Request(url: githubUrlAPI + "/repos/\(repoFullName)/contents/.pr-assigner.yml",
                                                 method: .GET,
                                                 headers: ["Accept": "application/vnd.github.v3.raw",
                                                           "Authorization": "token \(githubAccessToken)"],
                                                 body: nil)
        
        _ = try sut.fetchConfigFile(inRepo: repoFullName)
        
        let request = try XCTUnwrap(dispatcher.requestData)
        verify(request, expectedRequest)
    }
    
    func testGivenFetchAssignees_WhenMissingGitHubToken_ThenThrowsAnError() {
        env.githubUrlAPI = nil
        
        XCTAssertThrowsError(try sut.fetchAssignees(forPullRequest: 0, inRepo: ""))
    }
    
    func testGivenFetchAssignees_WhenRequestIsValid_ThenParamsAreEncoded() throws {
        let githubUrlAPI = "http://www.github.com"
        let githubAccessToken = "githubAccessToken"
        let repoFullName = "JustEat/PRAssigner"
        let prNumber: UInt = 1
        env.githubUrlAPI = URL(string: githubUrlAPI)!
        sut.setAccessToken(githubAccessToken)
        let expectedRequest = try HTTPClient.Request(url: githubUrlAPI + "/repos/\(repoFullName)/issues/\(prNumber)",
                                                 method: .GET,
                                                 headers: ["Content-Type": "application/json",
                                                           "Authorization": "token \(githubAccessToken)"],
                                                 body: nil)
        
        _ = try sut.fetchAssignees(forPullRequest: prNumber, inRepo: repoFullName)
        
        let request = try XCTUnwrap(dispatcher.request)
        verify(request, expectedRequest)
    }
    
    func testGivenFetchAssignees_WhenExecuted_ThenAssigneesAreReturned() throws {
        env.githubUrlAPI = URL(string: "http://www.github.com")!
        sut.setAccessToken("githubAccessToken")
        let json: JSON = ["assignees": [["login": "assignee_1"], ["login": "assignee_2"], ["login": "assignee_3"]]]
        dispatcher.json = json
        let expectedUsers = [GitHub.User(username: "assignee_1"), GitHub.User(username: "assignee_2"), GitHub.User(username: "assignee_3")]
        let expectation = XCTestExpectation(description: #function)
        
        _ = try sut.fetchAssignees(forPullRequest: 0, inRepo: "")
            .whenSuccess { (users) in
                XCTAssertEqual(users, expectedUsers)
                expectation.fulfill()
            }
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testGivenAssignPullRequest_WhenMissingGitHubToken_ThenThrowsAnError() {
        env.githubUrlAPI = nil
        
        XCTAssertThrowsError(try sut.assignPullRequest(0, inRepo: "", to: []))
    }
    
    func testGivenAssignPullRequest_WhenRequestIsValid_ThenParamsAreEncoded() throws {
        let githubUrlAPI = "http://www.github.com"
        let githubAccessToken = "githubAccessToken"
        let repoFullName = "JustEat/PRAssigner"
        let prNumber: UInt = 1
        env.githubUrlAPI = URL(string: githubUrlAPI)!
        sut.setAccessToken(githubAccessToken)
        let engineers = [Engineer(githubUsername: "githubUsername-1", slackID: "slackID-1"), Engineer(githubUsername: "githubUsername-2", slackID: "slackID-2")]
        let rawBody = ["assignees": ["githubUsername-1", "githubUsername-2"]]
        let body = try JSONEncoder().encode(rawBody, using: ByteBufferAllocator())
        
        let expectedRequest = try HTTPClient.Request(url: githubUrlAPI + "/repos/\(repoFullName)/issues/\(prNumber)",
                                                 method: .PATCH,
                                                 headers: ["Content-Type": "application/json",
                                                           "Authorization": "token \(githubAccessToken)"],
                                                 body: .byteBuffer(body))
        
        _ = try sut.assignPullRequest(prNumber, inRepo: repoFullName, to: engineers)
        
        let request = try XCTUnwrap(dispatcher.request)
        verify(request, expectedRequest)
    }
}
