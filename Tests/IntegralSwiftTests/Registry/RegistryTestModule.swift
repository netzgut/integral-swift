//
//  RegistryTestModule.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2021 Ben Weidig
//
//  This work is licensed under the terms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>
//

import Foundation
@testable import IntegralSwift

extension Registry: RegistryModule {

    public static func onStartup() {

        register(InjectTestService.self) {
            TestServiceImpl()
        }

        lazy(LazyTestService.self) {
            LazyTestServiceImpl()
        }

        register(LazyAfterRegisterTestService.self) {
            LazyAfterRegisterTestServiceImpl()
        }.lazy()

        eager(EagerTestService.self) {
            EagerTestServiceImpl()
        }

        register(EagerAfterRegisterTestService.self) {
            EagerAfterRegisterTestServiceImpl()
        }.eager()

        register(PostConstructService.self) {
            PostConstructServiceImpl()
        }

        register(PostConstructEagerService.self) {
            PostConstructEagerServiceImpl()
        }.eager()

        register(CustomServiceIdServiceImpl.self) {
            CustomServiceIdServiceImpl()
        }

        register(CustomServiceIdServiceImpl.self, "custom-service-id") {
            CustomServiceIdServiceImpl()
        }
    }

    public static func onShutdown() {
        TestServiceImpl.reset()
        LazyTestServiceImpl.reset()
        LazyAfterRegisterTestServiceImpl.reset()
        EagerTestServiceImpl.reset()
        EagerAfterRegisterTestServiceImpl.reset()
        PostConstructServiceImpl.reset()
        PostConstructEagerServiceImpl.reset()
    }

    public static func imports() -> [RegistryModule.Type] {
        [SubModule1.self, SubModule2.self, OverrideModule.self]
    }
}

class SubModule1: RegistryModule {

    static var onStartupRunCount = 0
    static var afterStartupRunCount = 0

    public static func imports() -> [RegistryModule.Type] {
        [SubModule2.self]
    }

    public static func onStartup() {
        self.onStartupRunCount += 1
    }

    public static func afterStartup() {
        self.afterStartupRunCount += 1
    }

    public static func onShutdown() {
        self.onStartupRunCount = 0
        self.afterStartupRunCount = 0
    }
}

class SubModule2: RegistryModule {

    static var onStartupRunCount = 0
    static var afterStartupRunCount = 0

    public static func onStartup() {
        self.onStartupRunCount += 1
    }

    public static func afterStartup() {
        self.afterStartupRunCount += 1
    }

    public static func onShutdown() {
        self.onStartupRunCount = 0
        self.afterStartupRunCount = 0
    }
}

class OverrideModule: RegistryModule {

    public static func onStartup() {
        override(InjectTestService.self) {
            TestService2Impl()
        }
    }
}
