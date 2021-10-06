#  Registry

A simple dependency injection container inspired by  [hmlongco/Resolver](https://github.com/hmlongco/Resolver).

## Concept

The general idea is to define services injected into properties with the `@Inject` annotation.
Instead of providing the service directly, you provide a _factory_ instead.

### Lifecycles

This allows the service to have different lifecycles.
The creation -- realization -- of such a service can be one of the following three: 

* Injection (default): The service is created if another class/struct gets created with an `@Inject` annotation for the service.
* Lazy: The service is created on first use of the injected service, not on injection itself.
* Eager: The service is created on Registry startup.

### Modules

The definition of services done is in `RegistryModule` types.
These allow to perform code on Registry startup and shutdown, and also to import other modules.

```swift
import IntegralSwift

class MyModule: RegistryModule {

    // Optional
    func imports() -> [RegistryModule.Type] {
        [MyOtherModule.self]
    }

    static func onStartup() {

        register {
            MyService()
        }
        
        lazy {
            MyLazyService()
        }

        eager {
            MyEagerService()
        }
    }

    // Optional
    static func onShutdown() {
        // ...
    }
}
```

There are multiple methods available to register services:

* `register`: Registers a service to be realized "on injection".
* `lazy`: Registers a service to be realized "on first use".
* `eager`: Registers a service to be realized "on startup".

All of them follow the same scheme:

```swift
@discardableResult
static func method<S>(_ type: S.Type = S.self,
                      factory: @escaping Factory<S>) -> ServiceOptions
```

As you can see, you _can_ provide a type but don't have to if it can be inferred.
That is useful if you have a protocol as service definition but want to inject an implementation.
The returned `ServiceOptions` allows changing a registration to `lazy` or `eager`, even if you used `register` for the factory.

You can also override a service definition by using `override`.
This addition is more a cosmetic one, to silence warnings about "already registered" services.

### Submodules

As mentioned before, the `static func imports()` allows you to define sub-modules to be loaded.
They will be registered first.
Importing the same module multiple times is ok, it will only be registered once.
But a warning will be printed.


## Registry Startup

The `Registry` must be started explicitly with `Registry.performStartup()`.

To specify the _root_ module, your `RegistryModule` must extend `Registry` itself:

```swift
extension Registry: RegistryModule {
     // ...
}
```

## Resolve

Instead of injecting a service, you can also call `static func resolve<S>(_ type: S.Type = S.self) -> S` to access a service.

## PostConstruct

A service can implement the protocol `PostConstruct`, so the `func postConstruct()` method is called after service realization.
For example, you can use this feature to register observers that use `self` and can't be registered in `init`. 
