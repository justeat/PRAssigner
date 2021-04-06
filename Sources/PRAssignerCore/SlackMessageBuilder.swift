//
//  SlackMessageBuilder.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation

protocol SlackMessageBuilderProtocol {
    func buildBody(reviewers: [Engineer], pr: GitHub.PullRequest, repoName: String, slackChannel: String) -> String
}

struct SlackMessageBuilder: SlackMessageBuilderProtocol {
    
    /// Returns a string that will be used as body for the chat.postMessage request to Slack
    ///
    /// - Note: The message is build using Block Kit https://api.slack.com/block-kit
    func buildBody(reviewers: [Engineer], pr: GitHub.PullRequest, repoName: String, slackChannel: String) -> String {
        let text = reviewers
            .compactMap { "\(tag($0.slackID))" }
            .joined(separator: ", ") + " are assigned to this PR\n \(pr.url)"
        
        return """
        {
            "channel":"\(slackChannel)",
            "text": "\(text)",
            "blocks\": [
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": "There's a new Pull Request ready to be reviewed:\n*<\(pr.url)|\(pr.title)>*"
                    }
                },
                {
                    "type": "section",
                    "fields": [
                        {
                            "type": "mrkdwn",
                            "text": "*Assignees:*\n\(reviewers.compactMap { "\(tag($0.slackID))" }.joined(separator: " "))"
                        }
                    ]
                },
                {
                    "type": "section",
                    "fields": [
                        {
                            "type": "mrkdwn",
                            "text": "*Author*\n\(pr.author.username)"
                        },
                        {
                            "type": "mrkdwn",
                            "text": "*Repo*\n\(repoName)"
                        }
                    ]
                },
                {
                    "type": "context",
                    "elements": [
                        {
                            "type": "plain_text",
                            "text": "Proudly assigned by PR Assigner 1.0",
                            "emoji": true
                        }
                    ]
                }
            ]
        }
        """
    }
    
    private func tag(_ slackID: String) -> String {
        return "<@\(slackID)>"
    }
}
