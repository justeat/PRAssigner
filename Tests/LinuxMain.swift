import XCTest

import PRAssignerCoreTests

var tests = [XCTestCaseEntry]()
tests += PRAssignerCoreTests.allTests()
tests += SlackMessageBuilderTests.allTests()
tests += GitHubTests.allTests()
tests += GitHubClientTests.allTests()
tests += PRAssignerHandlerTests.allTests()
tests += ServiceFacadeTests.allTests()
tests += SlackClientTests.allTests()
tests += ConfigFileTests.allTests()
tests += EngineerTests.allTests()
XCTMain(tests)
