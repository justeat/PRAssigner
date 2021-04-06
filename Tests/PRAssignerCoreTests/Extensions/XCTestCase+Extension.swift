//
//  XCTestCase+Extension.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import XCTest
import AsyncHTTPClient

extension XCTestCase {
    func verify(_ lhs: HTTPClient.Request, _ rhs: HTTPClient.Request, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(lhs.url, rhs.url, file: file, line: line)
        XCTAssertEqual(lhs.method, rhs.method, file: file, line: line)
        XCTAssertEqual(lhs.headers, rhs.headers, file: file, line: line)
        XCTAssertEqual(lhs.body?.length, rhs.body?.length, file: file, line: line)
    }
}
