import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(PRAssignerCoreTests.allTests),
        testCase(SlackMessageBuilderTests.allTests),
        testCase(GitHubTests.allTests),
        testCase(GitHubClientTests.allTests),
        testCase(PRAssignerHandlerTests.allTests),
        testCase(ServiceFacadeTests.allTests),
        testCase(SlackClientTests.allTests),
        testCase(ConfigFileTests.allTests),
        testCase(EngineerTests.allTests)
    ]
}
#endif
