//
//  GitHubClient.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation
import AWSLambdaRuntime
import AsyncHTTPClient
import NIO
import Logging
import Yams

protocol GitHubClientProtocol {
    func setAccessToken(_ accessToken: String)
    func fetchConfigFile(inRepo repoFullName: String) throws -> EventLoopFuture<ConfigFile>
    func fetchAssignees(forPullRequest prNumber: UInt, inRepo repoFullName: String) throws -> EventLoopFuture<[GitHub.User]>
    func assignPullRequest(_ prNumber: UInt, inRepo repoFullName: String, to engineers: [Engineer]) throws -> EventLoopFuture<Void>
}

class GitHubClient: GitHubClientProtocol {
    private let dispatcher: DispatcherProtocol
    private let env: EnvironmentVariablesProvider
    private let logger: Logger
    private let allocator = ByteBufferAllocator()
    private let encoder = JSONEncoder()
    
    private var accessToken: String?
    
    init(dispatcher: DispatcherProtocol,
         env: EnvironmentVariablesProvider,
         logger: Logger) {
        self.dispatcher = dispatcher
        self.env = env
        self.logger = logger
    }
    
    func setAccessToken(_ accessToken: String) {
        self.accessToken = accessToken
    }
    
    /// - Note: This API works only for GitHub API v3 and later.
    ///
    /// - GitHub Content Doc: https://docs.github.com/en/rest/reference/repos#contents
    func fetchConfigFile(inRepo repoFullName: String) throws -> EventLoopFuture<ConfigFile> {
        logger.debug("Will fetch config file from GitHub")
        
        guard let githubAccessToken = accessToken,
            var githubUrlAPI = env.githubUrlAPI else {
                throw PRAssignerError.envVariableParsingError("GITHUB_API_URL + GITHUB_ACCESS_TOKEN")
        }
        githubUrlAPI.appendPathComponent("/repos/\(repoFullName)/contents/.pr-assigner.yml")
        
        guard let request = try? HTTPClient.Request(
            url: githubUrlAPI,
            method: .GET,
            headers: ["Accept": "application/vnd.github.v3.raw",
                      "Authorization": "token \(githubAccessToken)"]) else {
                        throw NetworkError.errorInvalidRequest
        }
        
        logger.debug("Request - Fetch config file: \(request)")
        
        return try dispatcher.executeData(request)
            .flatMapThrowing { [weak self] data -> ConfigFile in
                let decoder = YAMLDecoder()
                let configFile =  try decoder.decode(ConfigFile.self, from: data)
                
                self?.logger.debug("Response - Fetch config file: \(configFile)")
                
                return configFile
            }
    }
    
    /// - Note: On GitHub, all pull requests are considered issues.
    ///
    /// - GitHub Authentication Doc: https://developer.github.com/v3/#authentication
    /// - GitHub GET Issue API Doc: https://developer.github.com/v3/issues/#get-an-issue
    func fetchAssignees(forPullRequest prNumber: UInt,
                        inRepo repoFullName: String) throws -> EventLoopFuture<[GitHub.User]> {
        logger.debug("Will fetch assignees of PR")
        
        guard let githubAccessToken = accessToken,
            var githubUrlAPI = env.githubUrlAPI else {
                throw PRAssignerError.envVariableParsingError("GITHUB_API_URL + GITHUB_ACCESS_TOKEN")
        }
        githubUrlAPI.appendPathComponent("/repos/\(repoFullName)")
        githubUrlAPI.appendPathComponent("/issues/\(prNumber)")
        
        guard let request = try? HTTPClient.Request(
            url: githubUrlAPI,
            method: .GET,
            headers: ["Content-Type": "application/json",
                      "Authorization": "token \(githubAccessToken)"]) else {
                        throw NetworkError.errorInvalidRequest
        }
        
        logger.debug("Request - Fetch assignees of PR: \(request)")
        
        return try dispatcher.execute(request)
            .flatMapThrowing { [weak self] json -> [GitHub.User] in
                self?.logger.debug("JSON Body Response - Fetch assignees of PR: \(json)")
                
                guard let assignees = json["assignees"] as? [JSON] else {
                    throw NetworkError.errorParsingResponse
                }
                
                let users = assignees.compactMap { assignee -> GitHub.User? in
                    guard let username = assignee["login"] as? String else { return nil }
                    return GitHub.User(username: username)
                }
                
                return users
            }
    }
    
    /// - Note: On GitHub, all pull requests are considered issues.
    /// Only users with push access can set assignees for new issues. Assignees are silently dropped otherwise.
    ///
    /// - GitHub Authentication Doc: https://developer.github.com/v3/#authentication
    /// - GitHub PATCH Issue API Doc: https://developer.github.com/v3/issues/#update-an-issue
    func assignPullRequest(_ prNumber: UInt,
                           inRepo repoFullName: String,
                           to engineers: [Engineer]) throws -> EventLoopFuture<Void> {
        logger.debug("Will assign pull request")
        
        guard let githubAccessToken = accessToken,
            var githubUrlAPI = env.githubUrlAPI else {
                throw PRAssignerError.envVariableParsingError("GITHUB_API_URL + GITHUB_ACCESS_TOKEN")
        }
        githubUrlAPI.appendPathComponent("/repos/\(repoFullName)")
        githubUrlAPI.appendPathComponent("/issues/\(prNumber)")
        
        let rawBody = ["assignees": engineers.compactMap { $0.githubUsername }]
        guard let body = try? encoder.encode(rawBody, using: allocator) else {
            throw NetworkError.errorEncodingBody(rawBody)
        }
        
        guard let request = try? HTTPClient.Request(
            url: githubUrlAPI,
            method: .PATCH,
            headers: ["Content-Type": "application/json",
                      "Authorization": "token \(githubAccessToken)"],
            body: .byteBuffer(body)) else {
                throw NetworkError.errorInvalidRequest
        }
        
        logger.debug("Request - Assign Pull Request: \(request)")
        
        return try dispatcher.execute(request)
            .flatMapThrowing { [weak self] json -> Void in
                self?.logger.debug("Successfully assigend to the PR #\(prNumber): \(engineers)")
            }
    }
}
