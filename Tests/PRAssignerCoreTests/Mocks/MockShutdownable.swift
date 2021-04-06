//
//  MockShutdownable.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation
@testable import PRAssignerCore

class MockShutdownable: Shutdownable {
    var syncShutdownCallCount = 0
    func syncShutdown() throws {
        syncShutdownCallCount += 1
    }
}
