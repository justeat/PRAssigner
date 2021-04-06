//
//  MockGitHubClient.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation
import NIO
@testable import PRAssignerCore

class MockGitHubClient: GitHubClientProtocol {
    private let eventLoop: EventLoop
    
    var errorException: Error?
    
    init(eventLoop: EventLoop) {
        self.eventLoop = eventLoop
        fetchConfigFileFuture = eventLoop.makeSucceededFuture(ConfigFile.fake())
        fetchAssigneesFuture = eventLoop.makeSucceededFuture([GitHub.User]())
        assignPullRequestFuture = eventLoop.makeSucceededFuture(())
    }
    
    var accessToken: String?
    func setAccessToken(_ accessToken: String) {
        self.accessToken = accessToken
    }
    
    var fetchConfigFileCallCount = 0
    var fetchConfigFileRepoFullName: String?
    var fetchConfigFileFuture: EventLoopFuture<ConfigFile>
    func fetchConfigFile(inRepo repoFullName: String) throws -> EventLoopFuture<ConfigFile> {
        fetchConfigFileCallCount += 1
        fetchConfigFileRepoFullName = repoFullName
        if let errorException = errorException {
            throw errorException
        }
        return fetchConfigFileFuture
    }
    
    var fetchAssigneesCallCount = 0
    var fetchAssigneesPrNumber: UInt?
    var fetchAssigneesRepoFullName: String?
    var fetchAssigneesFuture: EventLoopFuture<[GitHub.User]>
    func fetchAssignees(forPullRequest prNumber: UInt, inRepo repoFullName: String) throws -> EventLoopFuture<[GitHub.User]> {
        fetchAssigneesCallCount += 1
        fetchAssigneesPrNumber = prNumber
        fetchAssigneesRepoFullName = repoFullName
        if let errorException = errorException {
            throw errorException
        }
        return fetchAssigneesFuture
    }
    
    var assignPullRequestCallCount = 0
    var assignPullRequestPrNumber: UInt?
    var assignPullRequestRepoFullName: String?
    var assignPullRequestEngineers: [Engineer]?
    var assignPullRequestFuture: EventLoopFuture<Void>
    func assignPullRequest(_ prNumber: UInt, inRepo repoFullName: String, to engineers: [Engineer]) throws -> EventLoopFuture<Void> {
        assignPullRequestCallCount += 1
        assignPullRequestPrNumber = prNumber
        assignPullRequestRepoFullName = repoFullName
        assignPullRequestEngineers = engineers
        if let errorException = errorException {
            throw errorException
        }
        return assignPullRequestFuture
    }
}
