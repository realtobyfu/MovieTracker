# Swift Testing Examples

## Complete Test Suite Example

```swift
import Testing
@testable import MyApp

@Suite("Video Library")
struct VideoLibraryTests {
    let library = VideoLibrary()

    @Test("Video loads with correct metadata")
    func videoMetadata() throws {
        let video = try #require(library.video(named: "Sample"))
        #expect(video.duration == .seconds(90))
        #expect(video.resolution == .hd1080)
        #expect(video.contentRating == "G")
    }

    @Test func emptyLibraryHasNoVideos() {
        let empty = VideoLibrary(videos: [])
        #expect(empty.count == 0)
        #expect(empty.isEmpty)
    }

    @Suite struct Playback {
        @Test func playsFromBeginning() async throws {
            let player = VideoPlayer()
            try await player.load(Video.sample)
            #expect(player.currentTime == .zero)
        }

        @Test(.tags(.performance))
        func buffersQuickly() async throws {
            let player = VideoPlayer()
            try await player.load(Video.sample)
            #expect(player.bufferLevel > 0.9)
        }
    }
}
```

## Parameterized Testing Patterns

### Enum Case Coverage
```swift
extension IceCream {
    enum Flavor: CaseIterable {
        case vanilla, chocolate, strawberry, mintChip, rockyRoad
        
        var containsNuts: Bool {
            switch self {
            case .rockyRoad: return true
            default: return false
            }
        }
    }
}

@Test(arguments: [IceCream.Flavor.vanilla, .chocolate, .strawberry, .mintChip])
func flavorDoesNotContainNuts(_ flavor: IceCream.Flavor) {
    #expect(!flavor.containsNuts)
}

@Test(arguments: [IceCream.Flavor.rockyRoad])
func flavorContainsNuts(_ flavor: IceCream.Flavor) {
    #expect(flavor.containsNuts)
}
```

### Test Matrix with Combinations
```swift
enum Size: CaseIterable { case small, medium, large }
enum Color: CaseIterable { case red, blue, green }

// Tests all 9 combinations
@Test(arguments: Size.allCases, Color.allCases)
func widgetRendersCorrectly(size: Size, color: Color) throws {
    let widget = Widget(size: size, color: color)
    try #require(widget.render() != nil)
}
```

### Paired Arguments
```swift
struct TestCase {
    let input: String
    let expected: Int
}

let testCases = [
    TestCase(input: "hello", expected: 5),
    TestCase(input: "", expected: 0),
    TestCase(input: "Swift", expected: 5)
]

@Test(arguments: testCases)
func stringLength(_ testCase: TestCase) {
    #expect(testCase.input.count == testCase.expected)
}
```

### Custom Test Descriptions
```swift
struct APITestCase: CustomTestStringConvertible {
    let endpoint: String
    let method: HTTPMethod
    let expectedStatus: Int

    var testDescription: String {
        "\(method.rawValue) \(endpoint) → \(expectedStatus)"
    }
}

@Test(arguments: [
    APITestCase(endpoint: "/users", method: .get, expectedStatus: 200),
    APITestCase(endpoint: "/users/999", method: .get, expectedStatus: 404),
    APITestCase(endpoint: "/users", method: .post, expectedStatus: 201)
])
func apiResponds(_ testCase: APITestCase) async throws {
    let response = try await api.request(testCase.endpoint, method: testCase.method)
    #expect(response.status == testCase.expectedStatus)
}
```

## Error Testing Patterns

### Validating Error Properties
```swift
enum NetworkError: Error, Equatable {
    case timeout(seconds: Int)
    case httpError(code: Int)
    case noConnection
}

@Test func timeoutErrorHasCorrectDuration() {
    #expect {
        try longRunningOperation(timeout: 30)
    } throws: { error in
        guard case .timeout(let seconds) = error as? NetworkError else {
            return false
        }
        return seconds == 30
    }
}
```

### Multiple Error Conditions
```swift
@Test(arguments: [
    ("", ValidationError.empty),
    ("ab", ValidationError.tooShort),
    (String(repeating: "a", count: 1000), ValidationError.tooLong)
])
func invalidInputThrows(input: String, expectedError: ValidationError) {
    #expect(throws: expectedError) {
        try validate(input)
    }
}
```

## Async and Confirmation Patterns

### Waiting for Multiple Events
```swift
@Test func notificationsAreSent() async {
    let notifier = Notifier()
    
    await confirmation("notifications sent", expectedCount: 3) { confirm in
        notifier.onNotify = { _ in confirm() }
        await notifier.sendBatch(count: 3)
    }
}
```

### Event Never Occurs
```swift
@Test func noSpuriousCallbacks() async {
    await confirmation("unexpected callback", expectedCount: 0) { shouldNotHappen in
        let handler = Handler(onUnexpected: { shouldNotHappen() })
        await handler.processValid(input)
    }
}
```

## Tag Organization

```swift
// Define tags in one place
extension Tag {
    @Tag static var networking: Self
    @Tag static var persistence: Self
    @Tag static var ui: Self
    @Tag static var slow: Self
    @Tag static var flaky: Self
}

// Apply at suite level
@Suite(.tags(.networking))
struct APITests {
    @Test func fetchUsers() async { }
    @Test func fetchPosts() async { }
    
    @Test(.tags(.slow))  // Inherits .networking, adds .slow
    func fetchLargeDataset() async { }
}

// Cross-cutting concerns
@Suite struct IntegrationTests {
    @Test(.tags(.networking, .persistence))
    func syncDataToServer() async { }
    
    @Test(.tags(.ui, .slow))
    func renderComplexView() { }
}
```

## Known Issues Pattern

```swift
@Test func featureWithKnownBug() {
    // These still run and must pass
    #expect(basicFunctionality())
    #expect(coreLogic())
    
    // This is expected to fail until bug #1234 is fixed
    withKnownIssue("Waiting for backend fix - bug #1234") {
        try advancedFeature()
    }
}
```

## Init/Deinit for Setup/Teardown

```swift
// For per-test setup, use struct with stored properties
struct DatabaseTests {
    let db: Database
    
    init() throws {
        db = try Database.createTemporary()
        try db.seed(with: TestData.standard)
    }
    
    @Test func queryReturnsResults() throws {
        let results = try db.query("SELECT * FROM users")
        #expect(!results.isEmpty)
    }
}

// For cleanup, use actor or class
actor FileSystemTests {
    let tempDir: URL
    
    init() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }
    
    deinit {
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    @Test func writesFile() throws {
        let file = tempDir.appendingPathComponent("test.txt")
        try "Hello".write(to: file, atomically: true, encoding: .utf8)
        #expect(FileManager.default.fileExists(atPath: file.path))
    }
}
```
