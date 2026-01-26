# iOS Test Strategy for MVVM

## What to Test (Priority Order)

### 1. ViewModels (High Priority)
The core of business logic. Test everything here.

**Test these behaviors:**
- State transformations (input → output)
- Data formatting/mapping for display
- Validation logic
- User action handlers
- Error state handling
- Loading/empty/error states
- Computed properties

```swift
// ViewModel with testable logic
class UserProfileViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userService: UserServiceProtocol
    
    // ✅ Test: initialization with dependency
    init(userService: UserServiceProtocol) {
        self.userService = userService
    }
    
    // ✅ Test: state changes, success/failure paths
    func loadUser(id: String) async {
        isLoading = true
        do {
            let user = try await userService.fetchUser(id: id)
            displayName = formatDisplayName(user)
            errorMessage = nil
        } catch {
            errorMessage = mapError(error)
        }
        isLoading = false
    }
    
    // ✅ Test: business rule
    func formatDisplayName(_ user: User) -> String {
        user.nickname ?? "\(user.firstName) \(user.lastName)"
    }
    
    // ✅ Test: validation
    func validateEmail(_ email: String) -> ValidationResult {
        // Business rule
    }
}
```

**Test identification signals in ViewModels:**
- `if/else`, `switch`, `guard` → branching logic needs coverage
- String formatting → verify output format
- Array/collection transformations → test mapping, filtering, sorting
- `@Published` properties → verify state transitions
- `async` methods → test success, failure, loading states

### 2. Manager/Service Classes (High Priority)
Coordinate business operations, often stateful.

**Common Manager types to test:**
- `AuthManager` - login flows, token refresh, session state
- `NetworkManager` - request building, response parsing, error handling
- `CacheManager` - storage, retrieval, expiration, invalidation
- `SyncManager` - conflict resolution, retry logic
- `FeatureFlagManager` - flag evaluation, default values
- `AnalyticsManager` - event formatting, batching logic

```swift
// Manager with testable coordination logic
class CartManager {
    private let productService: ProductServiceProtocol
    private let pricingEngine: PricingEngineProtocol
    private(set) var items: [CartItem] = []
    
    // ✅ Test: add/remove/update operations
    func addItem(_ product: Product, quantity: Int) { }
    func removeItem(id: String) { }
    func updateQuantity(id: String, quantity: Int) { }
    
    // ✅ Test: business rules with edge cases
    var subtotal: Decimal { }
    var discount: Decimal { }
    var total: Decimal { }
    
    // ✅ Test: validation rules
    func canCheckout() -> Bool { }
    
    // ✅ Test: complex coordination
    func applyCoupon(_ code: String) async throws { }
}
```

### 3. Use Cases / Interactors (High Priority)
If using Clean Architecture, these encapsulate single operations.

```swift
// Use case with testable business logic
class PlaceOrderUseCase {
    // ✅ Test: orchestration logic, validation, error handling
    func execute(cart: Cart, payment: PaymentMethod) async throws -> Order {
        guard cart.isValid else { throw OrderError.invalidCart }
        let inventory = try await inventoryService.check(cart.items)
        guard inventory.allAvailable else { throw OrderError.outOfStock(inventory.unavailable) }
        // ... more testable steps
    }
}
```

### 4. Repositories / Data Mappers (Medium Priority)
Data transformation between layers.

```swift
class UserRepository {
    // ✅ Test: mapping from DTO to domain model
    func mapToDomain(_ dto: UserDTO) -> User { }
    
    // ✅ Test: caching logic, fetch strategies
    func getUser(id: String, forceRefresh: Bool) async throws -> User { }
}
```

### 5. Utilities / Helpers (Medium Priority)
Pure functions, formatters, validators.

```swift
// ✅ Test: pure functions are easy to test
struct DateFormatter {
    func relativeDate(_ date: Date) -> String { }
}

struct CurrencyFormatter {
    func format(_ amount: Decimal, currency: Currency) -> String { }
}

struct Validator {
    func isValidPhoneNumber(_ input: String) -> Bool { }
}
```

---

## What NOT to Test

### Views / SwiftUI Views
- UI layout is better covered by snapshot tests or UI tests
- Don't test that `Text("Hello")` renders "Hello"
- Exception: complex view logic extracted to helper methods

### Simple Data Models
```swift
// ❌ Don't test simple structs
struct User {
    let id: String
    let name: String
}

// ✅ DO test if model has logic
struct User {
    let firstName: String
    let lastName: String
    
    var fullName: String { "\(firstName) \(lastName)" }  // ← Test this
    var initials: String { /* logic */ }                  // ← Test this
}
```

### Apple Framework Code
- Don't test that `URLSession` makes requests
- Don't test that `UserDefaults` stores values
- DO test YOUR code that uses these frameworks

### Trivial Getters/Setters
- Don't test basic property access
- DO test computed properties with logic

---

## Identifying Test Opportunities

### Code Smell → Test Signal

| You See | Test Opportunity |
|---------|------------------|
| `if condition` | Test both branches |
| `guard else` | Test the failure path |
| `switch` | Test each case |
| `try/catch` | Test success + error paths |
| `async` | Test loading, success, failure states |
| `.map`, `.filter`, `.reduce` | Test transformation logic |
| String interpolation | Test formatted output |
| Math/calculations | Test edge cases (0, negative, overflow) |
| Date comparisons | Test boundary conditions |
| Optional handling | Test nil and non-nil paths |

### Questions to Find Tests

For each ViewModel/Manager, ask:
1. "What happens when this succeeds?"
2. "What happens when this fails?"
3. "What are the edge cases?" (empty, nil, max values)
4. "What state changes occur?"
5. "Are there validation rules?"
6. "Is there conditional logic?"

### File Naming Patterns to Target

```
✅ Test these patterns:
- *ViewModel.swift
- *Manager.swift
- *Service.swift
- *Repository.swift
- *UseCase.swift
- *Interactor.swift
- *Helper.swift
- *Formatter.swift
- *Validator.swift
- *Calculator.swift
- *Parser.swift
- *Mapper.swift

❌ Skip these (usually):
- *View.swift
- *Cell.swift
- *ViewController.swift (unless has business logic)
- *Coordinator.swift (navigation only)
- *Constants.swift
- *Extensions.swift (unless complex logic)
```

---

## Test Structure for ViewModels

```swift
@Suite("UserProfileViewModel")
struct UserProfileViewModelTests {
    
    // MARK: - Setup
    let mockService = MockUserService()
    var sut: UserProfileViewModel { UserProfileViewModel(userService: mockService) }
    
    // MARK: - Initial State
    @Test func initialState_isNotLoading() {
        #expect(!sut.isLoading)
        #expect(sut.displayName.isEmpty)
        #expect(sut.errorMessage == nil)
    }
    
    // MARK: - Load User
    @Suite struct LoadUser {
        @Test func setsLoadingState() async {
            // Verify isLoading becomes true during fetch
        }
        
        @Test func success_updatesDisplayName() async {
            mockService.stubUser = User(firstName: "John", lastName: "Doe")
            await sut.loadUser(id: "123")
            #expect(sut.displayName == "John Doe")
        }
        
        @Test func failure_setsErrorMessage() async {
            mockService.stubError = NetworkError.offline
            await sut.loadUser(id: "123")
            #expect(sut.errorMessage == "No internet connection")
        }
    }
    
    // MARK: - Business Rules
    @Suite struct DisplayNameFormatting {
        @Test func usesNickname_whenAvailable() {
            let user = User(firstName: "John", lastName: "Doe", nickname: "JD")
            #expect(sut.formatDisplayName(user) == "JD")
        }
        
        @Test func usesFullName_whenNoNickname() {
            let user = User(firstName: "John", lastName: "Doe", nickname: nil)
            #expect(sut.formatDisplayName(user) == "John Doe")
        }
    }
}
```

---

## Dependency Injection for Testability

ViewModels should accept protocols, not concrete types:

```swift
// ✅ Testable - accepts protocol
class OrderViewModel {
    private let orderService: OrderServiceProtocol
    private let analytics: AnalyticsProtocol
    
    init(orderService: OrderServiceProtocol, analytics: AnalyticsProtocol) {
        self.orderService = orderService
        self.analytics = analytics
    }
}

// In tests:
let mockService = MockOrderService()
let mockAnalytics = MockAnalytics()
let sut = OrderViewModel(orderService: mockService, analytics: mockAnalytics)
```

```swift
// ❌ Not testable - creates own dependencies
class OrderViewModel {
    private let orderService = OrderService()
    private let analytics = FirebaseAnalytics.shared
}
```
