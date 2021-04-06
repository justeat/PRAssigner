//
//  MockSecretsManager.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation
import SotoSecretsManager
@testable import PRAssignerCore

class MockSecretsManager: SecretsManagerProtocol {
    private let eventLoop: EventLoop
    
    init(eventLoop: EventLoop) {
        self.eventLoop = eventLoop
        getSecretValueFuture = eventLoop.makeSucceededFuture(SecretsManager.GetSecretValueResponse(arn: nil, createdDate: nil, name: nil, secretBinary: nil, secretString: "{ \"github-access-token\": \"gitHubAccessToken\", \"slack-access-token\": \"slackAccessToken\" }", versionId: nil, versionStages: nil))
    }
    
    var request: SecretsManager.GetSecretValueRequest?
    var getSecretValueCallCount = 0
    var getSecretValueFuture: EventLoopFuture<SecretsManager.GetSecretValueResponse>
    func getSecretValue(_ input: SecretsManager.GetSecretValueRequest, logger: Logger, on eventLoop: EventLoop?) -> EventLoopFuture<SecretsManager.GetSecretValueResponse> {
        getSecretValueCallCount += 1
        self.request = input
        return getSecretValueFuture
    }
}
