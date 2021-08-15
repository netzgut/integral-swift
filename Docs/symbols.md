#  Symbols

Inject values instead of services.

Insprired by [Apache Tapestry Symbols](https://tapestry.apache.org/symbols.html). 

## Concept


The general idea is that you define can define values that are injected by a `SymbolKey` into properties with the `@Symbol` annotation.
This allows to separate the values from their usage.
For example, we use it to have all API-related code in a shared dependency, but the correct host is defined as a symbol.

Like `Registry`, you provide a factory for the symbol creation.

## Types of Symbols

There are three methods available:

* `Symbols.constant`: The symbol is a constant. Instead of a factory, the value can be provided directly.
* `Symbols.lazy`: The symbol is evaluated on first use.
* `Symbols.dynamic`: The symbol factory is evaluated on every access.

## SymbolKeys

Strings can be used to identify a `Symbol`.
But to easier access all available Symbols, you should use a `SymbolKey` instead, by extending it:

```swift
import IntegralSwift

public extension SymbolKey {
    static let apiHost = SymbolKey("api-host")
}

@Symbol(.apiHost)
var host: String
```

