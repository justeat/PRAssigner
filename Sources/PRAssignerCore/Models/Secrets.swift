//
//  Secrets.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation

struct Secrets: Codable, Equatable {
    let gitHubAccessToken: String
    let slackAccessToken: String
    
    enum CodingKeys: String, CodingKey {
        case gitHubAccessToken = "github-access-token"
        case slackAccessToken = "slack-access-token"
    }
}
