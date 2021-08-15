# ∫ Integral Swift

A collection of property wrappers to improve the iOS coding experience.

Contains simple dependency injection (Registry), value-based injectables (Symbols), and access to UserDefaults. 

This is still WIP!
It's not as tested as it should be, but is used in production in two apps on the AppStore.

## Registry

A _smaller_ version of [hmlongco/Resolver](https://github.com/hmlongco/Resolver), with less features.  
Only supports singletons as scope.

Services can loaded on injection (default), lazy or eager (on registry startup).

See [registry.md](Docs/registry.md) for more details.

## Symbols

Inject values instead of  _full-blown_ services.

See [symbols.md](Docs/symbols.md) for more details.

Insprired by [Apache Tapestry Symbols](https://tapestry.apache.org/symbols.html). 

## UserDefaults


Easier access to `UserDefaults`.

See [user-defaults.md](Docs/user-defaults.md) for more details.


## Licence

MIT.
