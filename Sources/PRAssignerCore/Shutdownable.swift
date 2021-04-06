//
//  Shutdownable.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation
import AsyncHTTPClient
import SotoSecretsManager

protocol Shutdownable {
    func syncShutdown() throws
}

extension HTTPClient: Shutdownable {}

extension AWSClient: Shutdownable {}
