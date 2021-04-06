//
//  ConfigFile.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation

/// Represents the parsed version of the config file `.pr-assigner.yml`
struct ConfigFile: Codable {
    let prActions: [String]
    let numberOfReviewers: Int
    let discardableSlackStatus: [String]
    let shouldSkipDraftPR: Bool
    let slackPRChannel: String
    private let rawReviewers: [String]
    
    var engineers: [Engineer] {
        rawReviewers.compactMap {
            Engineer(rawValue: $0)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case prActions = "pr_actions"
        case numberOfReviewers = "number_of_reviewers"
        case discardableSlackStatus = "discardable_slack_status"
        case shouldSkipDraftPR = "skip_draft"
        case slackPRChannel = "slack_pr_channel"
        case rawReviewers = "reviewers"
    }
    
    init(prActions: [String],
         numberOfReviewers: Int,
         discardableSlackStatus: [String],
         shouldSkipDraftPR: Bool,
         slackPRChannel: String,
         rawReviewers: [String]) {
        self.prActions = prActions
        self.numberOfReviewers = numberOfReviewers
        self.discardableSlackStatus = discardableSlackStatus
        self.shouldSkipDraftPR = shouldSkipDraftPR
        self.slackPRChannel = slackPRChannel
        self.rawReviewers = rawReviewers
    }
}
