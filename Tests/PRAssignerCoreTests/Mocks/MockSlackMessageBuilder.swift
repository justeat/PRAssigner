//
//  MockSlackMessageBuilder.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation
@testable import PRAssignerCore

class MockSlackMessageBuilder: SlackMessageBuilderProtocol {
    
    var buildBodyCallCount = 0
    var buildBodyReviewers: [Engineer]?
    var buildBodyPr: GitHub.PullRequest?
    var buildBodyRepoName: String?
    var buildBodySlackChannel: String?
    var buildBody: String = ""
    func buildBody(reviewers: [Engineer], pr: GitHub.PullRequest, repoName: String, slackChannel: String) -> String {
        buildBodyCallCount += 1
        buildBodyReviewers = reviewers
        buildBodyPr = pr
        buildBodyRepoName = repoName
        buildBodySlackChannel = slackChannel
        return buildBody
    }
}
