//
//  MockDispatcher.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation
import AsyncHTTPClient
import NIO
@testable import PRAssignerCore

class MockDispatcher: DispatcherProtocol {
    let group: EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    
    var request: HTTPClient.Request?
    var json: JSON = ["": ""]
    func execute(_ request: HTTPClient.Request) throws -> EventLoopFuture<JSON> {
        self.request = request
        return group.next().makeSucceededFuture(json)
    }
    
    var requestData: HTTPClient.Request?
    var data: Data = Data()
    func executeData(_ request: HTTPClient.Request) throws -> EventLoopFuture<Data> {
        self.requestData = request
        return group.next().makeSucceededFuture(data)
    }
}
