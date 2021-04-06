//
//  SlackMessageBuilderTests.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import XCTest
@testable import PRAssignerCore

final class SlackMessageBuilderTests: XCTestCase {
    var env: MockEnviriableVariables!
    var messageBuilder: SlackMessageBuilder!
    
    static var allTests = [
        ("test1Reviewer", test1Reviewer),
        ("test2Reviewers", test2Reviewers)
    ]
    
    override func setUp() {
        super.setUp()
        env = MockEnviriableVariables()
        messageBuilder = SlackMessageBuilder()
    }
    
    override func tearDown() {
        env = nil
        messageBuilder = nil
        super.tearDown()
    }
    
    func test1Reviewer() {
        let pr = GitHub.PullRequest(url: "https://github.com/justeat/PRAssigner/pull/1",
                                    title: "Pull Request Title",
                                    isDraft: false,
                                    author: GitHub.User(username: "author-username"),
                                    requestedReviewers: [])
        let reviewers = [Engineer(githubUsername: "username-a", slackID: "slackID-a")]
        
        let message = messageBuilder.buildBody(reviewers: reviewers,
                                               pr: pr,
                                               repoName: "JustEat/PRAssigner",
                                               slackChannel: "#pr-channel")
        
        XCTAssertEqual(message, oneReviewerJSON)
    }
    
    func test2Reviewers() throws {
        let pr = GitHub.PullRequest(url: "https://github.com/justeat/PRAssigner/pull/1",
                                    title: "Pull Request Title",
                                    isDraft: false,
                                    author: GitHub.User(username: "author-username"),
                                    requestedReviewers: [])
        let reviewers = [Engineer(githubUsername: "username-a", slackID: "slackID-a"),
                         Engineer(githubUsername: "username-b", slackID: "slackID-b")]
        
        let message = messageBuilder.buildBody(reviewers: reviewers,
                                               pr: pr,
                                               repoName: "JustEat/PRAssigner",
                                               slackChannel: "#pr-channel")
        
        XCTAssertEqual(message, twoReviewersJSON)
    }
}
