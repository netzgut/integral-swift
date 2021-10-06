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
        [SubModule1.self, SubModule2.self]
    }
}

class SubModule1: RegistryModule {
    public static func imports() -> [RegistryModule.Type] {
        [SubModule2.self]
    }

    public static func onStartup() {
        print("==================Submodule1!")
    }
}

class SubModule2: RegistryModule {

    public static func onStartup() {
        print("==================Submodule2!")
    }
}
