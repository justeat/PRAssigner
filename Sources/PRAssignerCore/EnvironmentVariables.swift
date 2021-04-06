//
//  EnvironmentVariables.swift
//  
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation
import AWSLambdaRuntime
import SotoSecretsManager

protocol EnvironmentVariablesProvider {
    var githubUrlAPI: URL? { get }
    var awsRegion: Region { get }
    var secretsName: String { get }
    var isDebug: Bool { get }
}

/// Environment Variables to bet set in the AWS Lambda.
/// Those are already set in the schema to run the lambda locally.
struct EnvironmentVariables: EnvironmentVariablesProvider {
    
    /// `GITHUB_API_URL` is the API URL used for all GitHub requests.
    var githubUrlAPI: URL? {
        URL(string: Lambda.env("GITHUB_API_URL") ?? "")
    }
    
    /// `REGION` is the AWS Region where all resources are stored.
    var awsRegion: Region {
        Region(rawValue: Lambda.env("REGION") ?? "")
    }
    
    /// `SECRETS_NAME` is the name of secrets saved in AWS Secrets Manager.
    /// They need to be in the region specified in `awsRegion`.
    var secretsName: String {
        Lambda.env("SECRETS_NAME") ?? ""
    }
    
    /// `DEBUG` is a bool used to avoid disturbing other engineers tagging them on test PRs.
    ///
    /// Default value is false.
    var isDebug: Bool {
        Bool(Lambda.env("DEBUG") ?? "") ?? false
    }
}
