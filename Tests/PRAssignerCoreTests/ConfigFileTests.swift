//
//  ConfigFileTests.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import XCTest
@testable import PRAssignerCore

class ConfigFileTests: XCTestCase {
    static var allTests = [
        ("testGivenConfigFile_WhenRawReviewersContainsInvalidElements_ThenEngineersContainsOnlyValidElements", testGivenConfigFile_WhenRawReviewersContainsInvalidElements_ThenEngineersContainsOnlyValidElements)
    ]
    
    func testGivenConfigFile_WhenRawReviewersContainsInvalidElements_ThenEngineersContainsOnlyValidElements() {
        let rawReviewers = ["invalid-1", "invalid-2", "valid:ABC1234"]
        let config = ConfigFile(prActions: [], numberOfReviewers: 0, discardableSlackStatus: [], shouldSkipDraftPR: false, slackPRChannel: "", rawReviewers: rawReviewers)
        
        XCTAssertEqual(config.engineers, [Engineer(githubUsername: "valid", slackID: "ABC1234")])
    }
}
