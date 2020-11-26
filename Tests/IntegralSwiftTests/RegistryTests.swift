import XCTest
@testable import IntegralSwift

extension Registry: RegistryRegistrations {

    public static func onStartup() {

        register(TestService.self) {
            print("Resolving")
            return TestService()
        }.lazy()

        register(EagerTestService.self) {
            print("Resolving")
            return EagerTestService()
        }.eager()
    }
}

class TestService {
    func testValue() -> String {
        "test"
    }
}

class EagerTestService {
    func testValue() -> String {
        "test"
    }
}

final class RegistryTests: XCTestCase {

    class TestData {

        @Inject
        var service: TestService

        func testValue() -> String {
            self.service.testValue()
        }

        var random: String = UUID().uuidString
    }

    override func setUp() {
        Registry.performStartup()
    }

    override func tearDown() {
        Registry.performShutdown()
    }

    func testExample() {

        // ARRANGE / ACT

        let testData: TestData = TestData()
        print("Before resolving")

        // ASSERT

        XCTAssertEqual(testData.testValue(), "test")
        XCTAssertEqual(testData.testValue(), "test")
    }

    func testExample2() {

        // ARRANGE / ACT

        let testData1: TestData = TestData()

        print("Before resolving")

        // ASSERT

        XCTAssertEqual(testData1.testValue(), "test")
        XCTAssertEqual(testData1.testValue(), "test")
        XCTAssertEqual(testData1.random, testData1.random)

        // ACT

        Registry.performShutdown()

        Registry.performStartup()
        let testData2: TestData = TestData()

        XCTAssertNotEqual(testData1.random, testData2.random)

    }

    static var allTests = [
        ("testExample", testExample)
    ]
}
