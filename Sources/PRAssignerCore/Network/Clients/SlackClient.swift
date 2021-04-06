//
//  SlackClient.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation
import AWSLambdaRuntime
import AsyncHTTPClient
import NIO
import Logging

protocol SlackClientProtocol {
    func setAccessToken(_ accessToken: String)
    func fetchStatus(of reviewer: Engineer) throws -> EventLoopFuture<String>
    func postMessage(_ rawBody: String) throws -> EventLoopFuture<Void>
}

class SlackClient: SlackClientProtocol {
    private let dispatcher: DispatcherProtocol
    private let env: EnvironmentVariablesProvider
    private let logger: Logger
    
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
    
    /// Returns the Slack status emoji in the Slack emoji format (ex :smile:)
    /// - Doc: https://api.slack.com/methods/users.info
    func fetchStatus(of reviewer: Engineer) throws -> EventLoopFuture<String> {
        logger.debug("Will fetch slack status of \(reviewer.githubUsername)")
        
        guard let slackAccessToken = accessToken else {
            throw PRAssignerError.envVariableParsingError("SLACK_ACCESS_TOKEN")
        }
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "slack.com"
        urlComponents.path = "/api/users.info"
        urlComponents.queryItems = [
            URLQueryItem(name: "user", value: reviewer.slackID)
        ]
        
        guard let url = urlComponents.url,
              let request = try? HTTPClient.Request(
                url: url,
                method: .GET,
                headers: ["Content-Type": "application/x-www-form-urlencoded",
                          "Authorization": "Bearer \(slackAccessToken)"]) else {
            throw NetworkError.errorInvalidRequest
        }
        
        logger.debug("Request - Slack GET User Info: \(request)")
        
        return try dispatcher.execute(request)
            .flatMapThrowing { [weak self] json -> String in
                self?.logger.debug("JSON Body Response - Slack GET User Info \(json)")
                
                guard let user = json["user"] as? JSON,
                      let profile = user["profile"] as? JSON,
                      let status = profile["status_emoji"] as? String else {
                    throw NetworkError.errorParsingResponse
                }
                
                self?.logger.debug("\(reviewer.githubUsername) has status \(status) on Slack")
                
                return status
            }
    }
    
    /// - Slack Chat Post Message API: https://api.slack.com/methods/chat.postMessage & https://api.slack.com/changelog/2017-10-keeping-up-with-the-jsons
    func postMessage(_ rawBody: String) throws -> EventLoopFuture<Void> {
        logger.debug("Will post a message on Slack")
        
        guard let slackAccessToken = accessToken else {
            throw PRAssignerError.envVariableParsingError("SLACK_ACCESS_TOKEN")
        }
        
        guard let request = try? HTTPClient.Request(
                url: "https://slack.com/api/chat.postMessage",
                method: .POST,
                headers: ["Content-Type": "application/json; charset=utf-8",
                          "Authorization": "Bearer \(slackAccessToken)"],
                body: .string(rawBody)) else {
            throw NetworkError.errorInvalidRequest
        }
        
        logger.debug("Request - Post Slack message: \(request)")
        
        return try dispatcher.execute(request)
            .flatMapThrowing { [weak self] json in
                self?.logger.debug("Response body for Post Slack message:\(json)")
            }
    }
}
