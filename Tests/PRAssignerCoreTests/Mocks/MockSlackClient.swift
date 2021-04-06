//
//  MockSlackClient.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation
import NIO
@testable import PRAssignerCore

class MockSlackClient: SlackClientProtocol {
    private let eventLoop: EventLoop
    
    init(eventLoop: EventLoop) {
        self.eventLoop = eventLoop
        fetchStatusFuture = eventLoop.makeSucceededFuture("")
        postMessageFuture = eventLoop.makeSucceededFuture(())
    }
    
    var accessToken: String?
    func setAccessToken(_ accessToken: String) {
        self.accessToken = accessToken
    }
    
    var fetchStatusCallCount = 0
    var fetchStatusReviewer: Engineer?
    var fetchStatusFuture: EventLoopFuture<String>
    func fetchStatus(of reviewer: Engineer) throws -> EventLoopFuture<String> {
        fetchStatusCallCount += 1
        fetchStatusReviewer = reviewer
        return fetchStatusFuture
    }
    
    var postMessageCallCount = 0
    var postMessageRawBody: String?
    var postMessageFuture: EventLoopFuture<Void>
    func postMessage(_ rawBody: String) throws -> EventLoopFuture<Void> {
        postMessageCallCount += 1
        postMessageRawBody = rawBody
        return postMessageFuture
    }
}
