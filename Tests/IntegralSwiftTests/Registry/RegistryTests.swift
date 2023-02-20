//
//  RegistryTests.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2021 Ben Weidig
//
//  This work is licensed under the terms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>
//

@testable import IntegralSwift
import XCTest

final class RegistryTests: XCTestCase {

    class TestData {

        @Inject
        var service: InjectTestService

        @Inject
        var lazyService: LazyTestService

        @Inject
        var lazyAfterRegisterService: LazyAfterRegisterTestService

        @Inject
        var eagerService: EagerTestService

        @Inject
        var eagerAfterRegisterService: EagerAfterRegisterTestService

        @Inject
        var postConstructService: PostConstructService
    }

    override func setUp() {
        Registry.performStartup()
    }

    override func tearDown() {
        Registry.performShutdown()
    }

    func testInjectService() {

        // PRECONDITION

        XCTAssertFalse(TestServiceImpl.isResolved)

        // ARRANGE / ACT

        let data = TestData()

        // ACT / ASSERT

        XCTAssertTrue(TestServiceImpl.isResolved)
        XCTAssertTrue(data.service.test())
    }

    func testLazyService() {

        // PRECONDITION

        XCTAssertFalse(LazyTestServiceImpl.isResolved)
        XCTAssertFalse(LazyAfterRegisterTestServiceImpl.isResolved)

        // ARRANGE / ACT

        let data = TestData()

        // ACT / ASSERT

        XCTAssertFalse(LazyTestServiceImpl.isResolved)
        XCTAssertTrue(data.lazyService.test())
        XCTAssertTrue(LazyTestServiceImpl.isResolved)

        XCTAssertFalse(LazyAfterRegisterTestServiceImpl.isResolved)
        XCTAssertTrue(data.lazyAfterRegisterService.test())
        XCTAssertTrue(LazyAfterRegisterTestServiceImpl.isResolved)
    }

    func testEagerService() {

        // PRECONDITION

        XCTAssertTrue(EagerTestServiceImpl.isResolved)
        XCTAssertTrue(EagerAfterRegisterTestServiceImpl.isResolved)

        // ARRANGE / ACT

        let data = TestData()

        // ACT / ASSERT

        XCTAssertTrue(EagerTestServiceImpl.isResolved)
        XCTAssertTrue(data.eagerService.test())
        XCTAssertTrue(EagerAfterRegisterTestServiceImpl.isResolved)
    }

    func testPostContstructService() {

        // PRECONDITION

        XCTAssertFalse(PostConstructServiceImpl.isPostConstructed)

        // ARRANGE / ACT

        let data = TestData()
        _ = data.postConstructService.test()

        // ACT / ASSERT

        XCTAssertTrue(PostConstructServiceImpl.isPostConstructed)
    }

    func testPostContstructEagerService() {

        // PRECONDITION / ARRANGE / ACT / ASSERT

        XCTAssertTrue(PostConstructEagerServiceImpl.isPostConstructed)
    }

    func testOnStartupExactlyOnce() {

        // PRECONDITION / ARRANGE / ACT / ASSERT

        XCTAssertEqual(SubModule1.onStartupRunCount, 1)
        XCTAssertEqual(SubModule1.afterStartupRunCount, 1)

        XCTAssertEqual(SubModule2.onStartupRunCount, 1)
        XCTAssertEqual(SubModule2.afterStartupRunCount, 1)
    }

    func testOverride() {

        // ARRANGE / ACT

        let data = TestData()

        // ASSERT

        XCTAssertNotNil(data.service as? TestService2Impl)
    }

    func testCustomServiceId() {

        // ARRANGE / ACT

        let data = TestData()

        // ASSERT

        XCTAssertNotEqual(data.customServiceIdService.unique, data.customServiceIdService2.unique)
    }
}
