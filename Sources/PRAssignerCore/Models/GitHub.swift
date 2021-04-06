//
//  GitHub.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation

public struct GitHub: Codable, Equatable {
    
    /// Represents the event JSON sent by the GitHub hook set on the repository.
    public struct Event: Codable, Equatable {
        /// Full list of actions at https://help.github.com/en/actions/reference/events-that-trigger-workflows#pull-request-event-pull_request
        let action: String
        let number: UInt
        let pullRequest: PullRequest
        let repository: Repository
        
        enum CodingKeys: String, CodingKey {
            case action
            case number
            case pullRequest = "pull_request"
            case repository
        }
    }
    
    struct PullRequest: Codable, Equatable {
        let url: String
        let title: String
        let isDraft: Bool
        let author: User
        let requestedReviewers: [User]
        
        enum CodingKeys: String, CodingKey {
            case url = "html_url"
            case title
            case isDraft = "draft"
            case author = "user"
            case requestedReviewers = "requested_reviewers"
        }
    }
    
    struct Repository: Codable, Equatable {
        /// ex. Codertocat/Hello-World
        let fullName: String
        
        enum CodingKeys: String, CodingKey {
            case fullName = "full_name"
        }
    }
    
    struct User: Codable, Equatable {
        let username: String
        
        enum CodingKeys: String, CodingKey {
            case username = "login"
        }
    }
}
