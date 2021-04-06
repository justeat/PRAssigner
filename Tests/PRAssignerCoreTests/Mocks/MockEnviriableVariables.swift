//
//  MockEnviriableVariables.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation
import SotoSecretsManager
@testable import PRAssignerCore

class MockEnviriableVariables: EnvironmentVariablesProvider {
    var awsRegion: Region = .uswest1
    var secretsName: String = ""
    var githubUrlAPI: URL?
    var isDebug: Bool = false
}
