//
//  SecretsManagerProtocol.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation
import SotoSecretsManager

protocol SecretsManagerProtocol {
    func getSecretValue(_ input: SecretsManager.GetSecretValueRequest, logger: Logger, on eventLoop: EventLoop?) -> EventLoopFuture<SecretsManager.GetSecretValueResponse>
}

extension SecretsManager: SecretsManagerProtocol {}
