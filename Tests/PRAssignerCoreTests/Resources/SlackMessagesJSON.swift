//
//  SlackMessagesJSON.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation

let twoReviewersJSON = """
        {
            "channel":"#pr-channel",
            "text": "<@slackID-a>, <@slackID-b> are assigned to this PR\n https://github.com/justeat/PRAssigner/pull/1",
            "blocks\": [
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": "There's a new Pull Request ready to be reviewed:\n*<https://github.com/justeat/PRAssigner/pull/1|Pull Request Title>*"
                    }
                },
                {
                    "type": "section",
                    "fields": [
                        {
                            "type": "mrkdwn",
                            "text": "*Assignees:*\n<@slackID-a> <@slackID-b>"
                        }
                    ]
                },
                {
                    "type": "section",
                    "fields": [
                        {
                            "type": "mrkdwn",
                            "text": "*Author*\nauthor-username"
                        },
                        {
                            "type": "mrkdwn",
                            "text": "*Repo*\nJustEat/PRAssigner"
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

let oneReviewerJSON = """
        {
            "channel":"#pr-channel",
            "text": "<@slackID-a> are assigned to this PR\n https://github.com/justeat/PRAssigner/pull/1",
            "blocks\": [
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": "There's a new Pull Request ready to be reviewed:\n*<https://github.com/justeat/PRAssigner/pull/1|Pull Request Title>*"
                    }
                },
                {
                    "type": "section",
                    "fields": [
                        {
                            "type": "mrkdwn",
                            "text": "*Assignees:*\n<@slackID-a>"
                        }
                    ]
                },
                {
                    "type": "section",
                    "fields": [
                        {
                            "type": "mrkdwn",
                            "text": "*Author*\nauthor-username"
                        },
                        {
                            "type": "mrkdwn",
                            "text": "*Repo*\nJustEat/PRAssigner"
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
