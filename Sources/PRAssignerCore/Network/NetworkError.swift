//
//  NetworkError.swift
//
//  Copyright (c) 2021 Just Eat Takeaway. All rights reserved.

import Foundation
import AsyncHTTPClient

enum NetworkError: Error, CustomStringConvertible {
    case errorInvalidRequest
    case errorResponseNotSuccessful(HTTPClient.Response)
    case errorBody
    case errorParsingResponse
    case errorEncodingBody([String: [String]]?)
    
    var description: String {
        switch self {
        case .errorInvalidRequest:
            return "Invalid request"
        case .errorResponseNotSuccessful(let response):
            return "Error response not successful: \(response)"
        case .errorBody:
            return "Error with response body. May be missing or cannot convert into Data"
        case .errorParsingResponse:
            return "Error parsing response"
        case .errorEncodingBody(let raw):
            return "Error encoding body in the request: \(String(describing: raw))"
        }
    }
}
