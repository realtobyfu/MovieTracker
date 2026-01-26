# Migration Guide

Migrate from other DI patterns to SafeDI.

## From Manual DI

### Before (Manual)
```swift
class AppContainer {
    lazy var networkService = NetworkService()
    lazy var userService = UserService(network: networkService)
    lazy var homeViewModel = HomeViewModel(userService: userService)
}

// Usage
let container = AppContainer()
let viewModel = container.homeViewModel
```

### After (SafeDI)
```swift
@Instantiable(isRoot: true)
public final class AppDependencies {
    public init(
        networkService: NetworkService,
        userService: UserService,
        homeViewModel: HomeViewModel
    ) {
        self.networkService = networkService
        self.userService = userService
        self.homeViewModel = homeViewModel
    }
    
    @Instantiated private let networkService: NetworkService
    @Instantiated private let userService: UserService
    @Instantiated public let homeViewModel: HomeViewModel
}

@Instantiable
public final class NetworkService {
    public init() {}
}

@Instantiable
public final class UserService {
    public init(network: NetworkService) {
        self.network = network
    }
    @Received private let network: NetworkService
}

@Instantiable
public final class HomeViewModel {
    public init(userService: UserService) {
        self.userService = userService
    }
    @Received private let userService: UserService
}

// Usage - same simplicity
let dependencies = AppDependencies()
let viewModel = dependencies.homeViewModel
```

## From Swinject

### Before (Swinject)
```swift
let container = Container()

container.register(NetworkService.self) { _ in NetworkService() }
container.register(UserService.self) { r in
    UserService(network: r.resolve(NetworkService.self)!)
}
container.register(HomeViewModel.self) { r in
    HomeViewModel(userService: r.resolve(UserService.self)!)
}

// Usage - runtime resolution, can crash
let viewModel = container.resolve(HomeViewModel.self)!
```

### After (SafeDI)
```swift
@Instantiable
public final class NetworkService {
    public init() {}
}

@Instantiable
public final class UserService {
    public init(network: NetworkService) {
        self.network = network
    }
    @Received private let network: NetworkService
}

@Instantiable(isRoot: true)
public final class AppDependencies {
    public init(homeViewModel: HomeViewModel) {
        self.homeViewModel = homeViewModel
    }
    @Instantiated public let homeViewModel: HomeViewModel
}

// Usage - compile-time safe, no force unwraps
let dependencies = AppDependencies()
let viewModel = dependencies.homeViewModel
```

**Key differences:**
- No container registration code
- No `resolve()!` force unwraps
- Compile-time validation instead of runtime crashes

## From Factory

### Before (Factory)
```swift
extension Container {
    var networkService: Factory<NetworkService> {
        Factory(self) { NetworkService() }
    }
    
    var userService: Factory<UserService> {
        Factory(self) { UserService(network: self.networkService()) }
    }
}

class HomeViewModel {
    @Injected(\.userService) var userService
}
```

### After (SafeDI)
```swift
@Instantiable
public final class NetworkService {
    public init() {}
}

@Instantiable
public final class UserService {
    public init(network: NetworkService) {
        self.network = network
    }
    @Received private let network: NetworkService
}

@Instantiable
public final class HomeViewModel {
    public init(userService: UserService) {
        self.userService = userService
    }
    @Received private let userService: UserService
}
```

**Key differences:**
- No property wrapper injection
- Explicit constructor injection
- Hierarchical scoping (not global)

## From swift-dependencies

### Before (swift-dependencies)
```swift
struct UserClient {
    var fetch: @Sendable () async throws -> User
}

extension DependencyValues {
    var userClient: UserClient {
        get { self[UserClientKey.self] }
        set { self[UserClientKey.self] = newValue }
    }
}

class HomeViewModel {
    @Dependency(\.userClient) var userClient
    
    func load() async {
        let user = try? await userClient.fetch()
    }
}
```

### After (SafeDI)
```swift
protocol UserClientProtocol {
    func fetch() async throws -> User
}

@Instantiable(fulfilledByType: "UserClientProtocol")
public final class UserClient: UserClientProtocol {
    public init() {}
    
    public func fetch() async throws -> User {
        // Implementation
    }
}

@Instantiable
public final class HomeViewModel {
    public init(userClient: UserClientProtocol) {
        self.userClient = userClient
    }
    @Received private let userClient: UserClientProtocol
    
    public func load() async {
        let user = try? await userClient.fetch()
    }
}
```

**Key differences:**
- Use protocols instead of structs with closures
- Constructor injection instead of property wrapper
- Hierarchical scoping

## From Needle

### Before (Needle)
```swift
protocol HomeDependency: Dependency {
    var userService: UserService { get }
}

class HomeComponent: Component<HomeDependency> {
    var viewModel: HomeViewModel {
        HomeViewModel(userService: dependency.userService)
    }
}
```

### After (SafeDI)
```swift
@Instantiable
public final class HomeViewModel {
    public init(userService: UserService) {
        self.userService = userService
    }
    @Received private let userService: UserService
}
```

**Key differences:**
- No dependency protocols needed
- No Component classes
- Macros replace code generation templates

## Migration Checklist

1. **Add SafeDI dependency**
   ```swift
   .package(url: "https://github.com/dfed/SafeDI.git", from: "1.0.0")
   ```

2. **Add SafeDIGenerator to Build Phases**

3. **Convert types one at a time**
   - Add `@Instantiable` macro
   - Add `@Instantiated`/`@Received` to properties
   - Ensure memberwise `init` exists

4. **Create root dependency**
   - Mark one type with `isRoot: true`
   - Wire up from your `@main` App

5. **Remove old DI code**
   - Delete container registrations
   - Remove property wrapper injections
   - Delete dependency protocols (Needle)

6. **Update tests**
   - Use direct initialization with mocks
   - No container or context setup needed

## Incremental Migration

SafeDI can coexist with existing DI during migration:

```swift
// Old code - still using Swinject
let oldService = container.resolve(LegacyService.self)!

// New code - SafeDI
@Instantiable
public final class NewFeature {
    public init(legacyService: LegacyService) {
        self.legacyService = legacyService
    }
    @Forwarded private let legacyService: LegacyService
}

// Bridge: pass legacy service to SafeDI
let newFeature = NewFeature(legacyService: oldService)
```

Use `@Forwarded` to accept externally-created dependencies during migration.
