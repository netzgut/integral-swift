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
    }

    func testExample() {

        // ARRANGE / ACT
        Registry.performStartup()
        let testData: TestData = TestData()

        print("Before resolving")

        // ASSERT
        XCTAssertEqual(testData.testValue(), "test")
        XCTAssertEqual(testData.testValue(), "test")
    }

    static var allTests = [
        ("testExample", testExample)
    ]
}
