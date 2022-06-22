import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    [
        testCase(IntegralSwiftTests.allTests)
    ]
}
#endif
