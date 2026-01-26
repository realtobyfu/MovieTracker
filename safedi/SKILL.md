---
name: safedi
description: Compile-time safe dependency injection for Swift using SafeDI library (dfed/SafeDI). Use when setting up dependency injection, creating @Instantiable types, managing dependency lifecycles with @Instantiated/@Received/@Forwarded, integrating SafeDI into Xcode/SPM projects, or understanding hierarchical scoping patterns. Covers macros, project setup, multi-module configuration, and testing strategies.
---

# SafeDI

Compile-time safe dependency injection for Swift. Validates dependency trees at build time—if it compiles, it works.

## Quick Start

Add SafeDI to your project:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/dfed/SafeDI.git", from: "1.0.0"),
]
```

For Xcode: Build Phases → Run Build Tool Plug-ins → Add `SafeDIGenerator`

## Core Macros

### @Instantiable

Opts a type into the SafeDI dependency tree:

```swift
import SafeDI

@Instantiable
public final class NetworkService {
    public init(urlSession: URLSession, logger: Logger) {
        self.urlSession = urlSession
        self.logger = logger
    }
    
    @Received private let urlSession: URLSession
    @Instantiated private let logger: Logger
}
```

**Parameters:**
- `fulfilledByType:` - Specify concrete type that fulfills a protocol
- `isRoot: true` - Mark as root of dependency tree (entry point)

### @Instantiated

Dependency created by this type. SafeDI instantiates it when creating the parent:

```swift
@Instantiable
public final class CoffeeMaker {
    public init(boiler: Boiler, grinder: Grinder) {
        self.boiler = boiler
        self.grinder = grinder
    }
    
    @Instantiated private let boiler: Boiler   // CoffeeMaker creates Boiler
    @Instantiated private let grinder: Grinder // CoffeeMaker creates Grinder
}
```

### @Received

Dependency passed down from a parent in the tree:

```swift
@Instantiable
public final class Boiler {
    public init(pump: Pump, waterReservoir: WaterReservoir) {
        self.pump = pump
        self.waterReservoir = waterReservoir
    }
    
    @Instantiated private let pump: Pump
    @Received private let waterReservoir: WaterReservoir  // From parent
}
```

### @Forwarded

Passes runtime values through the dependency tree:

```swift
@Instantiable
public final class UserSession {
    public init(authToken: AuthToken, apiClient: APIClient) {
        self.authToken = authToken
        self.apiClient = apiClient
    }
    
    @Forwarded private let authToken: AuthToken  // Runtime value
    @Instantiated private let apiClient: APIClient
}
```

## Dependency Lifecycle Patterns

### Singleton (shared instance)
Use `@Received` to share one instance across the tree:

```swift
@Instantiable
public final class AppRoot {
    @Instantiated private let analytics: Analytics  // Created once
    @Instantiated private let homeScreen: HomeScreen
}

@Instantiable
public final class HomeScreen {
    @Received private let analytics: Analytics  // Same instance
}
```

### Scoped (per-subtree)
Parent instantiates, children receive:

```swift
@Instantiable
public final class UserFlow {
    @Instantiated private let userSession: UserSession
    @Instantiated private let profileScreen: ProfileScreen
}

@Instantiable
public final class ProfileScreen {
    @Received private let userSession: UserSession  // This flow's session
}
```

### Factory (new each time)
Each `@Instantiated` creates a new instance:

```swift
@Instantiable
public final class OrderList {
    @Instantiated private let orderCellA: OrderCell  // Instance A
    @Instantiated private let orderCellB: OrderCell  // Instance B (different)
}
```

## Protocol Fulfillment

Map protocols to concrete implementations:

```swift
protocol NetworkProvider {
    func fetch(url: URL) async throws -> Data
}

@Instantiable(fulfilledByType: "NetworkProvider")
public final class URLSessionNetworkProvider: NetworkProvider {
    public init() {}
    
    public func fetch(url: URL) async throws -> Data {
        // Implementation
    }
}

@Instantiable
public final class DataLoader {
    public init(network: NetworkProvider) {
        self.network = network
    }
    
    @Instantiated private let network: NetworkProvider  // Gets URLSessionNetworkProvider
}
```

## Root Entry Point

Mark the dependency tree root with `isRoot: true`:

```swift
@Instantiable(isRoot: true)
public final class AppDependencies {
    public init(/* ... */) { /* ... */ }
    
    @Instantiated public let mainCoordinator: MainCoordinator
}

// Usage in App
@main
struct MyApp: App {
    let dependencies = AppDependencies()
    
    var body: some Scene {
        WindowGroup {
            dependencies.mainCoordinator.rootView
        }
    }
}
```

## Project Configuration

### Single Module (Xcode)
Build Phases → Run Build Tool Plug-ins → `SafeDIGenerator`

### Multi-Module (Xcode)
Create `.safedi/configuration/include.csv` next to `.xcodeproj`:
```csv
../SharedModule,../NetworkModule,../FeatureModule
```

### Swift Package
```swift
targets: [
    .target(
        name: "MyApp",
        dependencies: ["SafeDI"],
        plugins: [.plugin(name: "SafeDIGenerator", package: "SafeDI")]
    )
]
```

### Additional Imports
Create `.safedi/configuration/additionalImportedModules.csv`:
```csv
Foundation,UIKit,Combine
```

## Testing

SafeDI types have memberwise initializers—inject mocks directly:

```swift
final class NetworkServiceTests: XCTestCase {
    func testFetch() async throws {
        let mockSession = MockURLSession()
        let mockLogger = MockLogger()
        
        // Direct initialization with mocks
        let service = NetworkService(
            urlSession: mockSession,
            logger: mockLogger
        )
        
        // Test...
    }
}
```

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| "Missing dependency" | Type not marked `@Instantiable` | Add `@Instantiable` macro |
| "Cycle detected" | A → B → A dependency | Refactor to break cycle |
| "Unfulfilled protocol" | No concrete type for protocol | Add `fulfilledByType:` |
| "Multiple roots" | Multiple `isRoot: true` | Only one root allowed |

## Best Practices

1. **One root** - Single `@Instantiable(isRoot: true)` entry point
2. **Prefer `@Received`** - Share instances to avoid duplication
3. **Protocols for testing** - Use `fulfilledByType:` for mockability
4. **Keep trees shallow** - Deep nesting is a code smell
5. **Value types where possible** - Structs can be `@Instantiable` too

See `references/examples.md` for complete app architecture examples.
See `references/migration.md` for migrating from other DI systems.
