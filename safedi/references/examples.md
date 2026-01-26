# SafeDI Examples

Complete examples for common app architectures.

## MVVM App Architecture

```swift
import SafeDI
import SwiftUI

// MARK: - Root

@Instantiable(isRoot: true)
public final class AppDependencies {
    public init(
        networkService: NetworkService,
        persistenceService: PersistenceService,
        homeViewModel: HomeViewModel
    ) {
        self.networkService = networkService
        self.persistenceService = persistenceService
        self.homeViewModel = homeViewModel
    }
    
    @Instantiated public let networkService: NetworkService
    @Instantiated public let persistenceService: PersistenceService
    @Instantiated public let homeViewModel: HomeViewModel
}

// MARK: - Services

@Instantiable
public final class NetworkService {
    public init() {}
    
    public func fetch<T: Decodable>(_ url: URL) async throws -> T {
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

@Instantiable
public final class PersistenceService {
    public init() {}
    
    public func save<T: Encodable>(_ item: T, key: String) throws {
        let data = try JSONEncoder().encode(item)
        UserDefaults.standard.set(data, forKey: key)
    }
    
    public func load<T: Decodable>(key: String) throws -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - ViewModels

@Instantiable
public final class HomeViewModel: ObservableObject {
    public init(
        networkService: NetworkService,
        persistenceService: PersistenceService
    ) {
        self.networkService = networkService
        self.persistenceService = persistenceService
    }
    
    @Received private let networkService: NetworkService
    @Received private let persistenceService: PersistenceService
    
    @Published public var items: [Item] = []
    @Published public var isLoading = false
    
    @MainActor
    public func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await networkService.fetch(URL(string: "https://api.example.com/items")!)
        } catch {
            print("Failed to load: \(error)")
        }
    }
}

// MARK: - App Entry Point

@main
struct MyApp: App {
    let dependencies = AppDependencies()
    
    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: dependencies.homeViewModel)
        }
    }
}

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        List(viewModel.items) { item in
            Text(item.name)
        }
        .task { await viewModel.loadItems() }
    }
}
```

## Feature Module Pattern

```swift
// MARK: - Feature Module

@Instantiable
public final class ProfileFeature {
    public init(
        userService: UserServiceProtocol,
        profileViewModel: ProfileViewModel,
        settingsViewModel: SettingsViewModel
    ) {
        self.userService = userService
        self.profileViewModel = profileViewModel
        self.settingsViewModel = settingsViewModel
    }
    
    @Received private let userService: UserServiceProtocol
    @Instantiated public let profileViewModel: ProfileViewModel
    @Instantiated public let settingsViewModel: SettingsViewModel
}

@Instantiable
public final class ProfileViewModel: ObservableObject {
    public init(userService: UserServiceProtocol) {
        self.userService = userService
    }
    
    @Received private let userService: UserServiceProtocol
    
    @Published public var user: User?
    
    @MainActor
    public func loadUser() async {
        user = try? await userService.getCurrentUser()
    }
}

@Instantiable
public final class SettingsViewModel: ObservableObject {
    public init(userService: UserServiceProtocol) {
        self.userService = userService
    }
    
    @Received private let userService: UserServiceProtocol
    
    public func updateSettings(_ settings: Settings) async throws {
        try await userService.updateSettings(settings)
    }
}
```

## Protocol-Based Testing

```swift
// MARK: - Protocols

protocol UserServiceProtocol {
    func getCurrentUser() async throws -> User
    func updateSettings(_ settings: Settings) async throws
}

protocol AnalyticsProtocol {
    func track(_ event: String, properties: [String: Any])
}

// MARK: - Production Implementations

@Instantiable(fulfilledByType: "UserServiceProtocol")
public final class UserService: UserServiceProtocol {
    public init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    @Received private let networkService: NetworkService
    
    public func getCurrentUser() async throws -> User {
        try await networkService.fetch(URL(string: "https://api.example.com/user")!)
    }
    
    public func updateSettings(_ settings: Settings) async throws {
        // Implementation
    }
}

@Instantiable(fulfilledByType: "AnalyticsProtocol")
public final class FirebaseAnalytics: AnalyticsProtocol {
    public init() {}
    
    public func track(_ event: String, properties: [String: Any]) {
        // Firebase implementation
    }
}

// MARK: - Test Mocks

final class MockUserService: UserServiceProtocol {
    var mockUser: User?
    var updateSettingsCalled = false
    
    func getCurrentUser() async throws -> User {
        guard let user = mockUser else { throw TestError.notFound }
        return user
    }
    
    func updateSettings(_ settings: Settings) async throws {
        updateSettingsCalled = true
    }
}

final class MockAnalytics: AnalyticsProtocol {
    var trackedEvents: [(String, [String: Any])] = []
    
    func track(_ event: String, properties: [String: Any]) {
        trackedEvents.append((event, properties))
    }
}

// MARK: - Tests

import Testing

@Suite
struct ProfileViewModelTests {
    @Test
    func loadUserSuccess() async {
        let mockService = MockUserService()
        mockService.mockUser = User(id: "1", name: "Test User")
        
        let viewModel = ProfileViewModel(userService: mockService)
        await viewModel.loadUser()
        
        #expect(viewModel.user?.name == "Test User")
    }
    
    @Test
    func loadUserFailure() async {
        let mockService = MockUserService()
        mockService.mockUser = nil
        
        let viewModel = ProfileViewModel(userService: mockService)
        await viewModel.loadUser()
        
        #expect(viewModel.user == nil)
    }
}
```

## Forwarded Runtime Values

```swift
// MARK: - User Session with Auth Token

@Instantiable
public final class AuthenticatedSession {
    public init(
        authToken: AuthToken,
        authenticatedAPIClient: AuthenticatedAPIClient
    ) {
        self.authToken = authToken
        self.authenticatedAPIClient = authenticatedAPIClient
    }
    
    @Forwarded public let authToken: AuthToken  // Runtime value from login
    @Instantiated public let authenticatedAPIClient: AuthenticatedAPIClient
}

@Instantiable
public final class AuthenticatedAPIClient {
    public init(authToken: AuthToken) {
        self.authToken = authToken
    }
    
    @Received private let authToken: AuthToken
    
    public func request(_ endpoint: String) async throws -> Data {
        var request = URLRequest(url: URL(string: "https://api.example.com/\(endpoint)")!)
        request.setValue("Bearer \(authToken.value)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
}

// MARK: - Usage after Login

func handleLoginSuccess(token: String) {
    let authToken = AuthToken(value: token)
    let session = AuthenticatedSession(authToken: authToken)
    
    // Now session.authenticatedAPIClient has the token
}
```

## SwiftUI Environment Integration

```swift
// MARK: - Environment Key

struct DependenciesKey: EnvironmentKey {
    static let defaultValue: AppDependencies? = nil
}

extension EnvironmentValues {
    var dependencies: AppDependencies? {
        get { self[DependenciesKey.self] }
        set { self[DependenciesKey.self] = newValue }
    }
}

// MARK: - App Setup

@main
struct MyApp: App {
    let dependencies = AppDependencies()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.dependencies, dependencies)
        }
    }
}

// MARK: - View Usage

struct ProfileView: View {
    @Environment(\.dependencies) private var dependencies
    
    var body: some View {
        if let deps = dependencies {
            ProfileContent(viewModel: deps.profileFeature.profileViewModel)
        }
    }
}
```

## Multi-Module Setup

```
MyApp/
├── .safedi/
│   └── configuration/
│       ├── include.csv              # ../CoreModule,../NetworkModule,../FeatureModule
│       └── additionalImportedModules.csv  # Foundation,Combine
├── MyApp.xcodeproj
├── CoreModule/
│   └── Sources/
│       └── Models.swift
├── NetworkModule/
│   └── Sources/
│       └── NetworkService.swift
└── FeatureModule/
    └── Sources/
        └── ProfileFeature.swift
```

Each module can define `@Instantiable` types. SafeDI resolves cross-module dependencies automatically.
