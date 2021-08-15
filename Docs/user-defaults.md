# UserDefaults

A property wrapper to simplify accessing `UserDefaults`.

## Concept

Instead of accessing `UserDefaults` manually, just use a property wrapper instead.

## UserDefaultKey

By extending `UserDefaultKey`, you can use safer keys instead of Strings:

```swift
extension UserDefaultKey {
    static let testKey = UserDefaultKey("test-key")
}

@UserDefault(.testKey)
private var myTestKey: String
````