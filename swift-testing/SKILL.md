---
name: swift-testing
description: Write unit tests for iOS/macOS/Swift projects using Swift Testing framework (Xcode 16+). Use when creating tests, writing test functions, validating code behavior, identifying test opportunities, or migrating from XCTest. Covers test strategy for MVVM (ViewModels, Managers), plus @Test, #expect, #require, parameterized tests, suites, tags, and async patterns.
---

# Swift Testing

Modern testing framework for Swift. Prefer over XCTest for new tests.

## Where to Write Tests (MVVM)

**High priority targets:**
- `*ViewModel.swift` - State transformations, validation, user action handlers, computed properties
- `*Manager.swift` / `*Service.swift` - Business coordination, stateful operations
- `*UseCase.swift` / `*Interactor.swift` - Single operation orchestration
- `*Repository.swift` - Data mapping, fetch strategies

**Medium priority:**
- `*Helper.swift` / `*Formatter.swift` / `*Validator.swift` - Pure functions

**Skip (for unit tests):**
- Views, ViewControllers, Cells - use UI/snapshot tests
- Simple data models without logic
- Constants, basic extensions

**Test signals in code:**
- `if/guard/switch` → test all branches
- `async` methods → test loading, success, failure states
- String formatting → verify output
- Validation logic → test valid/invalid inputs
- `@Published` properties → verify state transitions

See `references/strategy.md` for detailed MVVM test patterns and examples.

## Core Building Blocks

### Test Functions
```swift
import Testing

@Test func videoMetadata() {
    let video = Video(fileName: "test.mov")
    #expect(video.duration == 90)
}

@Test("Descriptive display name") func rating() async throws {
    #expect(video.contentRating == "G")
}
```

- Use `@Test` attribute (no "test" prefix needed in name)
- Can be global functions or methods in a type
- Support `async`, `throws`, actor isolation

### Expectations
```swift
// Basic - use operators directly
#expect(value == expected)
#expect(array.isEmpty)
#expect(items.count > 5)
#expect(text.contains("hello"))

// Required - stops test on failure, unwraps optionals
let item = try #require(array.first)  // Unwraps or fails
try #require(condition)                // Throws if false
```

### Error Validation
```swift
// Expect any error
#expect(throws: (any Error).self) {
    try riskyOperation()
}

// Expect error type
#expect(throws: NetworkError.self) {
    try fetchData()
}

// Expect specific error
#expect(throws: ValidationError.invalidInput) {
    try validate(input)
}

// Complex validation
#expect {
    try process()
} throws: { error in
    guard let e = error as? CustomError,
          case .timeout(let seconds) = e else { return false }
    return seconds > 30
}
```

### Suites
```swift
struct VideoTests {
    let video = Video(fileName: "test.mov")  // Fresh instance per test

    @Test func metadata() { #expect(video.metadata != nil) }
    @Test func duration() { #expect(video.duration > 0) }
}

// Nested suites
@Suite("Video Processing")
struct VideoProcessingTests {
    @Suite struct Encoding { /* tests */ }
    @Suite struct Decoding { /* tests */ }
}
```

## Parameterized Tests

Replace repetitive tests with single parameterized function:

```swift
// Single argument
@Test(arguments: ["vanilla", "chocolate", "strawberry"])
func flavorIsValid(_ flavor: String) {
    #expect(Flavor(flavor) != nil)
}

// Multiple arguments - tests ALL combinations
@Test(arguments: 1...5, ["A", "B", "C"])
func gridPosition(row: Int, column: String) { /* 15 test cases */ }

// Paired arguments with zip
@Test(arguments: zip(
    [Ingredient.rice, .potato, .lettuce],
    [Dish.onigiri, .fries, .salad]
))
func cook(_ ingredient: Ingredient, into dish: Dish) { /* 3 test cases */ }
```

## Traits

```swift
// Conditional execution
@Test(.enabled(if: FeatureFlags.isEnabled))
func newFeature() { }

@Test(.disabled("Waiting for backend fix"))
func brokenEndpoint() { }

// Bug tracking
@Test(.bug("https://issue-tracker/123", "Crashes on nil input"))
func edgeCase() { }

// Tags for organization
extension Tag {
    @Tag static var networking: Self
    @Tag static var persistence: Self
}

@Test(.tags(.networking)) func fetchUser() { }

@Suite(.tags(.persistence)) struct DatabaseTests { /* all inherit tag */ }

// Serial execution (when parallel unsafe)
@Suite(.serialized) struct OrderDependentTests { /* runs sequentially */ }
```

## Known Issues

When a test fails due to external factors:

```swift
@Test func externalService() {
    withKnownIssue {
        try callFlakyService()  // Won't count as failure
    }
}

// Partial known issue
@Test func mixedTest() {
    #expect(localComputation() == expected)  // Still validated
    withKnownIssue {
        try unreliableOperation()  // Known to fail
    }
}
```

## Async Patterns

```swift
@Test func asyncOperation() async throws {
    let result = await fetchData()
    try #require(result.isValid)
}

// For completion handlers without async overload
@Test func legacyAPI() async throws {
    try await withCheckedThrowingContinuation { continuation in
        legacyFetch { result, error in
            if let result { continuation.resume(returning: result) }
            else { continuation.resume(throwing: error!) }
        }
    }
}

// For callbacks that fire multiple times
@Test func multipleEvents() async throws {
    await confirmation("received events", expectedCount: 10) { confirm in
        await processItems { item in
            confirm()  // Called for each item
        }
    }
}
```

## XCTest Migration

| XCTest | Swift Testing |
|--------|---------------|
| `func testX()` | `@Test func x()` |
| `XCTAssert*` functions | `#expect()` / `#require()` |
| `XCTestCase` subclass | Struct with `@Test` methods |
| `setUpWithError()` | `init() throws` |
| `tearDown()` | `deinit` (actors/classes only) |
| `continueAfterFailure = false` | Use `#require` |

**Keep using XCTest for**: UI automation (XCUIApplication), performance tests (XCTMetric), Objective-C tests.

## Best Practices

1. **Prefer structs** for suites (value semantics, no shared state)
2. **Use parameterized tests** instead of for-loops or duplicate functions
3. **Use tags** to group related tests across suites/files
4. **Avoid global mutable state** - tests run in parallel by default
5. **Use `#require`** for preconditions that must pass before continuing
6. **Add display names** to clarify test intent

See `references/examples.md` for complete code examples.
