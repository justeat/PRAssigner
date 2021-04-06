//
//  MockServiceFacade.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation
import NIO
@testable import PRAssignerCore

class MockServiceFacade: ServiceFacadeProtocol {
    private let eventLoop: EventLoop
    
    init(eventLoop: EventLoop) {
        self.eventLoop = eventLoop
        fetchConfigFileFuture = eventLoop.makeSucceededFuture(ConfigFile.fake())
        fetchAssigneesFuture = eventLoop.makeSucceededFuture([GitHub.User]())
        assignPullFuture = eventLoop.makeSucceededFuture(())
        fetchStatusFuture = eventLoop.makeSucceededFuture("")
        postMessageFuture = eventLoop.makeSucceededFuture(())
    }
    
    var secrets: Secrets?
    var setSecretsCallCount = 0
    func setSecrets(_ secrets: Secrets) {
        setSecretsCallCount += 1
        self.secrets = secrets
    }
    
    var fetchConfigFileCallCount = 0
    var fetchConfigFileFuture: EventLoopFuture<ConfigFile>
    func fetchConfigFile(inRepo repoFullName: String) -> EventLoopFuture<ConfigFile> {
        fetchConfigFileCallCount += 1
        return fetchConfigFileFuture
    }
    
    var fetchAssigneesCallCount = 0
    var fetchAssigneesFuture: EventLoopFuture<[GitHub.User]>
    func fetchAssignees(forPullRequest prNumber: UInt, inRepo repoFullName: String) -> EventLoopFuture<[GitHub.User]> {
        fetchAssigneesCallCount += 1
        return fetchAssigneesFuture
    }
    
    var assignPullRequestCallCount = 0
    var assignPullPrNumber: UInt?
    var assignPullRepoFullName: String?
    var assignPullEngieners: [Engineer]?
    var assignPullFuture: EventLoopFuture<Void>
    func assignPullRequest(_ prNumber: UInt, inRepo repoFullName: String, to engineers: [Engineer]) -> EventLoopFuture<Void> {
        assignPullRequestCallCount += 1
        assignPullPrNumber = prNumber
        assignPullRepoFullName = repoFullName
        assignPullEngieners = engineers
        return assignPullFuture
    }
    
    var fetchStatusDict: [Engineer: String]?
    var fetchStatusFuture: EventLoopFuture<String>
    func fetchStatus(of engineer: Engineer) -> EventLoopFuture<String> {
        if let status = fetchStatusDict?[engineer] {
            return eventLoop.makeSucceededFuture(status)
        } else {
            return fetchStatusFuture
        }
    }
    
    var postMessageBody: String?
    var postMessageFuture: EventLoopFuture<Void>
    func postMessage(_ rawBody: String) -> EventLoopFuture<Void> {
        postMessageBody = rawBody
        return postMessageFuture
    }
}
