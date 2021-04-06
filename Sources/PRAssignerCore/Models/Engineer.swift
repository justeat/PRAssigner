//
//  Engineer.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation

struct Engineer: Hashable {
    let githubUsername: String  // es. andrea-antonioni
    let slackID: String         // es. ABCD1234
    
    init?(rawValue: String) {
        let splittedRawValue = rawValue.split(separator: ":")
        guard splittedRawValue.count == 2 else { return nil }
        
        self.init(githubUsername: String(splittedRawValue[0]),
                  slackID: String(splittedRawValue[1]))
    }
    
    init(githubUsername: String, slackID: String) {
        self.githubUsername = githubUsername
        self.slackID = slackID
    }
}
