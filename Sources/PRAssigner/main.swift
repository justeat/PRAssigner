import Foundation
import AWSLambdaRuntime
import AsyncHTTPClient
import NIO
import PRAssignerCore

// Set LOCAL_LAMBDA_SERVER_ENABLED env var to true in this schema to run this in your local machine.
Lambda.run { context in
    return PRAssignerHandler(eventLoop: context.eventLoop, logger: context.logger)
}
