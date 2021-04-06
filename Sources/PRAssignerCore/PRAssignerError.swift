//
//  PRAssignerError.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation
import AsyncHTTPClient

enum PRAssignerError: Error, CustomStringConvertible {
    case envVariableParsingError(String)
    case parsingError
    case secretsNotFetched
    
    var description: String {
        switch self {
        case .envVariableParsingError(let envVar):
            return "Cannot find env var \(envVar)"
        case .parsingError:
            return "Error during parsing"
        case .secretsNotFetched:
            return "Error while fetching secrets"
        }
    }
}
