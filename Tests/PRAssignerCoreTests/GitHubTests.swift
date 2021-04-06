//
//  GitHubTests.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import XCTest
@testable import PRAssignerCore

class GitHubTests: XCTestCase {

    static var allTests = [
        ("testDecoding", testDecoding)
    ]
    
    func testDecoding() throws {
        let expectedEvent = GitHub.Event(action: "opened",
                                         number: 2,
                                         pullRequest: GitHub.PullRequest(url: "https://github.com/Codertocat/Hello-World/pull/2",
                                                                         title: "Update the README with new information.",
                                                                         isDraft: false,
                                                                         author: GitHub.User(username: "Codertocat"),
                                                                         requestedReviewers: []),
                                         repository: GitHub.Repository(fullName: "Codertocat/Hello-World"))
        
        let file = try Resource(name: "test-event", type: "json")
        let data = try Data(contentsOf: file.url, options: .mappedIfSafe)
        let decodedEvent = try JSONDecoder().decode(GitHub.Event.self, from: data)
        
        XCTAssertEqual(decodedEvent, expectedEvent)
    }
}
