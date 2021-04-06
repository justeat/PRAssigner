//
//  SlackClientTests.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import XCTest
import AsyncHTTPClient
import Logging
@testable import PRAssignerCore

class SlackClientTests: XCTestCase {
    var env: MockEnviriableVariables!
    var dispatcher: MockDispatcher!
    var sut: SlackClient!
    
    static var allTests = [
        ("testGivenFetchStatus_WhenMissingSlackAccessToken_ThenThrowsAnError", testGivenFetchStatus_WhenMissingSlackAccessToken_ThenThrowsAnError),
        ("testGivenFetchStatusAndSlackAccessToken_WhenRequestIsValid_ThenParamsAreEncoded", testGivenFetchStatusAndSlackAccessToken_WhenRequestIsValid_ThenParamsAreEncoded),
        ("testGivenFetchStatus_WhenExecuted_ThenSlackStatusIsReturned", testGivenFetchStatus_WhenExecuted_ThenSlackStatusIsReturned),
        ("testGivenPostMessage_WhenMissingSlackAccessToken_ThenThrowsAnError", testGivenPostMessage_WhenMissingSlackAccessToken_ThenThrowsAnError),
        ("testGivenPostMessageAndSlackAccessToken_WhenRequestIsValid_ThenParamsAreEncoded", testGivenPostMessageAndSlackAccessToken_WhenRequestIsValid_ThenParamsAreEncoded)
    ]
    
    override func setUp() {
        env = MockEnviriableVariables()
        dispatcher = MockDispatcher()
        sut = SlackClient(dispatcher: dispatcher, env: env, logger: Logger(label: "test"))
    }
    
    override func tearDown() {
        env = nil
        dispatcher = nil
        sut = nil
    }
    
    func testGivenFetchStatus_WhenMissingSlackAccessToken_ThenThrowsAnError() {
        XCTAssertThrowsError(try sut.fetchStatus(of: .fake()))
    }
    
    func testGivenFetchStatusAndSlackAccessToken_WhenRequestIsValid_ThenParamsAreEncoded() throws {
        let slackAccessToken = "slackAccessToken"
        sut.setAccessToken(slackAccessToken)
        let expectedRequest = try HTTPClient.Request(url: "https://slack.com/api/users.info?user=slackID",
                                                     method: .GET,
                                                     headers: ["Content-Type": "application/x-www-form-urlencoded",
                                                               "Authorization": "Bearer \(slackAccessToken)"],
                                                     body: nil)
        
        _ = try sut.fetchStatus(of: Engineer(githubUsername: "", slackID: "slackID"))
        
        let request = try XCTUnwrap(dispatcher.request)
        verify(request, expectedRequest)
    }
    
    func testGivenFetchStatus_WhenExecuted_ThenSlackStatusIsReturned() throws {
        sut.setAccessToken("slackAccessToken")
        let expectedStatus = ":smile:"
        dispatcher.json = ["user": ["profile": ["status_emoji": expectedStatus]]]
        let expectation = XCTestExpectation(description: #function)
        
        try sut.fetchStatus(of: .fake()).whenSuccess({ (status) in
            XCTAssertEqual(status, expectedStatus)
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testGivenPostMessage_WhenMissingSlackAccessToken_ThenThrowsAnError() {
        XCTAssertThrowsError(try sut.postMessage(""))
    }
    
    func testGivenPostMessageAndSlackAccessToken_WhenRequestIsValid_ThenParamsAreEncoded() throws {
        let slackAccessToken = "slackAccessToken"
        sut.setAccessToken(slackAccessToken)
        let body = "test-body"
        let expectedRequest = try HTTPClient.Request(url: "https://slack.com/api/chat.postMessage",
                                                     method: .POST,
                                                     headers: ["Content-Type": "application/json; charset=utf-8",
                                                               "Authorization": "Bearer \(slackAccessToken)"],
                                                     body: .string(body))
        
        _ = try sut.postMessage(body)
        let request = try XCTUnwrap(dispatcher.request)
        
        verify(request, expectedRequest)
    }
}
