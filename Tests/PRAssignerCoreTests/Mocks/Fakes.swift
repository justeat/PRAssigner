//
//  Fakes.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation
@testable import PRAssignerCore

extension GitHub.Event {
    static func fake() -> GitHub.Event {
        return GitHub.Event(action: "", number: 0, pullRequest: .fake(), repository: GitHub.Repository(fullName: ""))
    }
}

extension GitHub.PullRequest {
    static func fake() -> GitHub.PullRequest {
        return GitHub.PullRequest(url: "https://github.com/justeat/PRAssigner/pull/1",
                                  title: "Pull Request Title",
                                  isDraft: false,
                                  author: GitHub.User(username: "author-username"),
                                  requestedReviewers: [])
    }
}

extension Engineer {
    static func fake() -> Engineer {
        return Engineer(githubUsername: "", slackID: "")
    }
}

extension ConfigFile {
    static func fake() -> ConfigFile {
        return ConfigFile(prActions: [], numberOfReviewers: 0, discardableSlackStatus: [], shouldSkipDraftPR: false, slackPRChannel: "", rawReviewers: [])
    }
    
    init(prActions: [String] = [],
         numberOfReviewers: Int = 0,
         discardableSlackStatus: [String] = [],
         shouldSkipDraftPR: Bool = false,
         slackPRChannel: String = "",
         reviewers: [Engineer] = []) {
        
        let rawReviewers = reviewers.compactMap { "\($0.githubUsername):\($0.slackID)" }
        self.init(prActions: prActions,
                  numberOfReviewers: numberOfReviewers,
                  discardableSlackStatus: discardableSlackStatus,
                  shouldSkipDraftPR: shouldSkipDraftPR,
                  slackPRChannel: slackPRChannel,
                  rawReviewers: rawReviewers)
    }
}
