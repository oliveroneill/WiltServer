import XCTest

extension PlayHistoryGraphQLHandlerTests {
    static let __allTests = [
        ("testHandleQuery", testHandleQuery),
        ("testHandleQueryInvalidSchema", testHandleQueryInvalidSchema),
        ("testHandleQueryUnexpectedQuery", testHandleQueryUnexpectedQuery),
        ("testHandleRequest", testHandleRequest),
        ("testHandleRequestCallsDatabase", testHandleRequestCallsDatabase),
        ("testHandleRequestCallsDatabaseWithDate", testHandleRequestCallsDatabaseWithDate),
        ("testHandleRequestExcludingFields", testHandleRequestExcludingFields),
        ("testHandleRequestIncorrectQuery", testHandleRequestIncorrectQuery),
        ("testHandleRequestNoQuery", testHandleRequestNoQuery),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(PlayHistoryGraphQLHandlerTests.__allTests),
    ]
}
#endif
