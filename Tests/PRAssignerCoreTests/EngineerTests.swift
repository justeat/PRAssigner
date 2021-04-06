//
//  EngineerTests.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import XCTest
@testable import PRAssignerCore

class EngineerTests: XCTestCase {
    static var allTests = [
        ("testGivenEngineer_WhenRawValueIsntValid_ThenReturnsNil", testGivenEngineer_WhenRawValueIsntValid_ThenReturnsNil),
        ("testGivenEngineer_WhenRawValueIsValid_ThenReturnsEngineer", testGivenEngineer_WhenRawValueIsValid_ThenReturnsEngineer)
    ]
    
    func testGivenEngineer_WhenRawValueIsntValid_ThenReturnsNil() {
        XCTAssertNil(Engineer(rawValue: "invalid_value"))
    }
    
    func testGivenEngineer_WhenRawValueIsValid_ThenReturnsEngineer() throws {
        let engineer = try XCTUnwrap(Engineer(rawValue: "valid:ABC1234"))
        XCTAssertEqual(engineer.githubUsername, "valid")
        XCTAssertEqual(engineer.slackID, "ABC1234")
    }
}
