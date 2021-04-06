//
//  Dispatcher.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation
import AsyncHTTPClient
import NIO

typealias JSON = [String: Any]

protocol DispatcherProtocol {
    func execute(_ request: HTTPClient.Request) throws -> EventLoopFuture<JSON>
    func executeData(_ request: HTTPClient.Request) throws -> EventLoopFuture<Data>
}

class Dispatcher: DispatcherProtocol {
    private let httpClient: HTTPClient
    
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
    
    func executeData(_ request: HTTPClient.Request) throws -> EventLoopFuture<Data> {
        var tmpRequest = request
        tmpRequest.headers.add(name: "User-Agent", value: "PRAssigner")
        
        return httpClient
            .execute(request: tmpRequest, deadline: .now() + .seconds(3))
            .flatMapThrowing { response -> Data in
                guard (200..<300).contains(response.status.code) else {
                    throw NetworkError.errorResponseNotSuccessful(response)
                }
                guard var body = response.body,
                    let data = body.readData(length: body.readableBytes) else {
                        throw NetworkError.errorBody
                }
                
                return data
            }
    }
    
    func execute(_ request: HTTPClient.Request) throws -> EventLoopFuture<JSON> {
        return try executeData(request)
            .flatMapThrowing { data -> JSON in
                guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? JSON else {
                        throw NetworkError.errorBody
                }
                
                return json
            }
    }
}
