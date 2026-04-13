# bunchabout iOS — Auth & Feed Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the foundational iOS app with email/password authentication and a location-aware event feed, establishing the MVVM + Repository architecture.

**Architecture:** MVVM with repository pattern. GraphQLClient sends queries via URLSession. Repositories own in-memory caches. ViewModels are screen-scoped `@Observable` classes. Dependencies injected via SwiftUI `.environment()`. Module uses default MainActor isolation (Swift 6.2).

**Tech Stack:** iOS 26, Swift 6.2, SwiftUI, FirebaseAuth, CoreLocation, URLSession

---

## File Map

```
bunchabout/bunchabout/
  App/
    bunchaboutApp.swift              ← modify (DI setup, FirebaseApp.configure)
    RootView.swift                 ← create
    MainTabView.swift              ← create
  Core/
    Auth/
      AuthService.swift            ← create
      AuthServiceProtocol.swift    ← create (protocol for testability)
      AuthState.swift              ← create
    Networking/
      GraphQLClient.swift          ← create
      AppError.swift               ← create
    Theme/
      Sizes.swift                  ← create
      AppColors.swift              ← create
      AppTypography.swift          ← create
    Location/
      LocationService.swift        ← create
  Models/
    User.swift                     ← create
    Event.swift                    ← create
    EventLocation.swift            ← create
    EventParticipant.swift         ← create
    Venue.swift                    ← create
    EventConnection.swift          ← create
    Trait.swift                    ← create
    Badge.swift                    ← create
    Enums/
      ActivityCategory.swift       ← create
      EventStatus.swift            ← create
      ParticipantStatus.swift      ← create
      FillMode.swift               ← create
      Visibility.swift             ← create
      SlotType.swift               ← create
      FeedSort.swift               ← create
      Gender.swift                 ← create
  Repositories/
    UserRepository.swift           ← create
    UserQueries.swift              ← create
    EventRepository.swift          ← create
    EventQueries.swift             ← create
  Features/
    Login/
      LoginView.swift              ← create
      LoginViewModel.swift         ← create
      SignUpView.swift             ← create
      SignUpViewModel.swift        ← create
      ForgotPasswordView.swift     ← create
      ForgotPasswordViewModel.swift ← create
    Feed/
      FeedView.swift               ← create
      FeedViewModel.swift          ← create
      EventCardView.swift          ← create
    EventDetail/
      EventDetailView.swift        ← create
      EventDetailViewModel.swift   ← create
    Profile/
      ProfileView.swift            ← create (placeholder with sign-out)
  Extensions/
    Date+Extensions.swift          ← create

  ContentView.swift                ← delete

bunchabout/bunchaboutTests/
  Helpers/
    MockURLProtocol.swift          ← create
    MockAuthService.swift          ← create
    TestHelpers.swift              ← create
  GraphQLClientTests.swift         ← create
  ModelDecodingTests.swift         ← create
  UserRepositoryTests.swift        ← create
  EventRepositoryTests.swift       ← create
  LoginViewModelTests.swift        ← create
  FeedViewModelTests.swift         ← create
  bunchaboutTests.swift              ← delete (old XCTest template)
```

---

### Task 1: Project Setup & Firebase Configuration

**Files:**
- Copy: `~/Downloads/GoogleService-Info.plist` → `bunchabout/bunchabout/GoogleService-Info.plist`
- Create: folder structure under `bunchabout/bunchabout/`
- Delete: `bunchabout/bunchabout/ContentView.swift`
- Delete: `bunchabout/bunchaboutTests/bunchaboutTests.swift`

- [ ] **Step 1: Add Firebase Auth via CocoaPods (minimal dependencies)**

Create `bunchabout/Podfile`:
```ruby
platform :ios, '26.0'

target 'bunchabout' do
  use_frameworks!

  pod 'FirebaseAuth', '~> 11.0'

  # Disable unused Firebase components
  $FirebaseAnalyticsWithoutAdIdSupport = true
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '26.0'
    end
  end
end
```

Then install:
```bash
cd bunchabout && pod install
```

**IMPORTANT:** After `pod install`, always open `bunchabout.xcworkspace` (NOT `.xcodeproj`).

Also set `FirebaseAnalyticsWithoutAdIdSupport` to avoid pulling in the full Analytics SDK. We only need `FirebaseAuth` — no Analytics, no Crashlytics, no Cloud Messaging.

- [ ] **Step 2: Copy GoogleService-Info.plist and create folder structure**

```bash
cp ~/Downloads/GoogleService-Info.plist bunchabout/bunchabout/GoogleService-Info.plist
mkdir -p bunchabout/bunchabout/{App,Core/{Networking,Auth,Theme,Location},Models/Enums,Repositories,Features/{Login,Feed,EventDetail,Profile},Extensions}
mkdir -p bunchabout/bunchaboutTests/Helpers
```

- [ ] **Step 3: Delete starter files**

```bash
rm bunchabout/bunchabout/ContentView.swift
rm bunchabout/bunchaboutTests/bunchaboutTests.swift
```

- [ ] **Step 4: Add location permission description**

In Xcode: select **bunchabout** target → **Info** tab → click **+** → add key:
- Key: `NSLocationWhenInUseUsageDescription`
- Value: `bunchabout needs your location to find events near you`

- [ ] **Step 5: Add .gitignore for Pods**

Create `.gitignore` in `bunchabout/` (or repo root):
```
# CocoaPods
Pods/
*.xcworkspace
!bunchabout.xcworkspace
```

Note: Some teams check in Pods/, some don't. We'll ignore them to keep the repo small.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore: project setup with Firebase Auth (CocoaPods), folder structure, and location permission"
```

---

### Task 2: Theme Constants

**Files:**
- Create: `bunchabout/bunchabout/Core/Theme/Sizes.swift`
- Create: `bunchabout/bunchabout/Core/Theme/AppColors.swift`
- Create: `bunchabout/bunchabout/Core/Theme/AppTypography.swift`

- [ ] **Step 1: Create Sizes.swift**

```swift
// bunchabout/bunchabout/Core/Theme/Sizes.swift
import SwiftUI

enum Sizes {
    // Spacing
    static let spacing4: CGFloat = 4
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32
    static let spacing48: CGFloat = 48

    // Corner radii
    static let cornerRadius8: CGFloat = 8
    static let cornerRadius12: CGFloat = 12
    static let cornerRadius16: CGFloat = 16

    // Icons
    static let iconSmall: CGFloat = 16
    static let iconMedium: CGFloat = 24
    static let iconLarge: CGFloat = 32

    // Avatars
    static let avatarSmall: CGFloat = 32
    static let avatarMedium: CGFloat = 48
    static let avatarLarge: CGFloat = 80

    // Components
    static let buttonHeight: CGFloat = 48
    static let inputHeight: CGFloat = 48
}
```

- [ ] **Step 2: Create AppColors.swift**

```swift
// bunchabout/bunchabout/Core/Theme/AppColors.swift
import SwiftUI

enum AppColors {
    static let primary = Color.accentColor
    static let error = Color.red
    static let secondaryText = Color.secondary
    static let cardBackground = Color(.secondarySystemBackground)
    static let inputBackground = Color(.tertiarySystemFill)
}
```

- [ ] **Step 3: Create AppTypography.swift**

```swift
// bunchabout/bunchabout/Core/Theme/AppTypography.swift
import SwiftUI

struct TitleLargeStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.largeTitle.bold())
    }
}

struct HeadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.headline)
    }
}

struct BodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.body)
    }
}

struct CaptionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

extension View {
    func titleLargeStyle() -> some View { modifier(TitleLargeStyle()) }
    func headlineStyle() -> some View { modifier(HeadlineStyle()) }
    func bodyStyle() -> some View { modifier(BodyStyle()) }
    func captionStyle() -> some View { modifier(CaptionStyle()) }
}
```

- [ ] **Step 4: Commit**

```bash
git add bunchabout/bunchabout/Core/Theme/
git commit -m "feat: add theme constants — Sizes, AppColors, AppTypography"
```

---

### Task 3: Error Types & GraphQL Client

**Files:**
- Create: `bunchabout/bunchabout/Core/Networking/AppError.swift`
- Create: `bunchabout/bunchabout/Core/Networking/GraphQLClient.swift`
- Create: `bunchabout/bunchaboutTests/Helpers/MockURLProtocol.swift`
- Create: `bunchabout/bunchaboutTests/Helpers/TestHelpers.swift`
- Create: `bunchabout/bunchaboutTests/GraphQLClientTests.swift`

- [ ] **Step 1: Create AppError.swift**

```swift
// bunchabout/bunchabout/Core/Networking/AppError.swift
import Foundation

enum AppError: Error, LocalizedError {
    case network(Error)
    case unauthorized
    case graphQL([String])
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .network(let error):
            return error.localizedDescription
        case .unauthorized:
            return "Please sign in again."
        case .graphQL(let messages):
            return messages.first ?? "Something went wrong."
        case .decoding(let error):
            return "Failed to read server response: \(error.localizedDescription)"
        }
    }
}
```

- [ ] **Step 2: Create MockURLProtocol and test helpers**

```swift
// bunchabout/bunchaboutTests/Helpers/MockURLProtocol.swift
import Foundation

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            fatalError("MockURLProtocol.requestHandler not set")
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
```

```swift
// bunchabout/bunchaboutTests/Helpers/TestHelpers.swift
import Foundation
@testable import bunchabout

func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

func makeTestClient() -> GraphQLClient {
    GraphQLClient(
        url: URL(string: "https://test.example.com/graphql")!,
        session: makeMockSession(),
        getToken: { "mock-token" }
    )
}

func mockResponse(json: String, statusCode: Int = 200) -> (HTTPURLResponse, Data) {
    let response = HTTPURLResponse(
        url: URL(string: "https://test.example.com/graphql")!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
    )!
    return (response, json.data(using: .utf8)!)
}
```

- [ ] **Step 3: Write GraphQLClient tests**

```swift
// bunchabout/bunchaboutTests/GraphQLClientTests.swift
import Testing
import Foundation
@testable import bunchabout

@Suite(.serialized)
@MainActor
struct GraphQLClientTests {
    let client = makeTestClient()

    @Test func decodesSuccessResponse() async throws {
        MockURLProtocol.requestHandler = { _ in
            mockResponse(json: """
            {"data": {"me": {"id": "u1", "displayName": "Sam"}}}
            """)
        }

        struct MeResponse: Decodable {
            let me: User
        }

        let response: MeResponse = try await client.execute(query: "query { me { id displayName } }")
        #expect(response.me.id == "u1")
        #expect(response.me.displayName == "Sam")
    }

    @Test func throwsOnGraphQLErrors() async {
        MockURLProtocol.requestHandler = { _ in
            mockResponse(json: """
            {"data": null, "errors": [{"message": "Not found"}]}
            """)
        }

        struct DummyResponse: Decodable { let me: User? }

        await #expect(throws: AppError.self) {
            let _: DummyResponse = try await client.execute(query: "query { me { id } }")
        }
    }

    @Test func throwsUnauthorizedOn401() async {
        MockURLProtocol.requestHandler = { _ in
            mockResponse(json: "{}", statusCode: 401)
        }

        struct DummyResponse: Decodable { let me: User? }

        await #expect(throws: AppError.self) {
            let _: DummyResponse = try await client.execute(query: "query { me { id } }")
        }
    }

    @Test func sendsAuthorizationHeader() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return mockResponse(json: """
            {"data": {"me": {"id": "u1", "displayName": "Sam"}}}
            """)
        }

        struct MeResponse: Decodable { let me: User }
        let _: MeResponse = try await client.execute(query: "query { me { id displayName } }")

        #expect(capturedRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer mock-token")
        #expect(capturedRequest?.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test func sendsVariablesInRequestBody() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.requestHandler = { request in
            if let data = request.httpBody ?? request.httpBodyStream.flatMap({ stream in
                stream.open()
                let data = Data(reading: stream)
                stream.close()
                return data
            }) {
                capturedBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            }
            return mockResponse(json: """
            {"data": {"user": {"id": "u2", "displayName": "Alex"}}}
            """)
        }

        struct Vars: Encodable { let id: String }
        struct UserResponse: Decodable { let user: User? }

        let _: UserResponse = try await client.execute(
            query: "query User($id: ID!) { user(id: $id) { id displayName } }",
            variables: Vars(id: "u2")
        )

        let variables = capturedBody?["variables"] as? [String: Any]
        #expect(variables?["id"] as? String == "u2")
    }
}

private extension Data {
    init(reading stream: InputStream) {
        self.init()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let count = stream.read(buffer, maxLength: 1024)
            if count > 0 { append(buffer, count: count) }
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they fail**

```bash
cd bunchabout && xcodebuild test -workspace bunchabout.xcworkspace -scheme bunchabout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:bunchaboutTests/GraphQLClientTests 2>&1 | tail -20
```

Expected: Build failure — `GraphQLClient` and `User` types do not exist yet.

- [ ] **Step 5: Create GraphQLClient.swift**

```swift
// bunchabout/bunchabout/Core/Networking/GraphQLClient.swift
import Foundation

final class GraphQLClient {
    private let url: URL
    private let session: URLSession
    private let getToken: () async throws -> String

    init(
        url: URL = URL(string: "https://bunchabout.web.app/graphql")!,
        session: URLSession = .shared,
        getToken: @escaping () async throws -> String
    ) {
        self.url = url
        self.session = session
        self.getToken = getToken
    }

    func execute<T: Decodable>(query: String) async throws -> T {
        try await execute(query: query, variables: nil as EmptyVariables?)
    }

    func execute<T: Decodable, V: Encodable>(query: String, variables: V) async throws -> T {
        try await execute(query: query, variables: Optional.some(variables))
    }

    private func execute<T: Decodable, V: Encodable>(query: String, variables: V?) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let token = try await getToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body = RequestBody(query: query, variables: variables)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.network(URLError(.badServerResponse))
        }

        if httpResponse.statusCode == 401 {
            throw AppError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.network(URLError(.badServerResponse))
        }

        let graphQLResponse: GraphQLResponse<T>
        do {
            graphQLResponse = try JSONDecoder().decode(GraphQLResponse<T>.self, from: data)
        } catch {
            throw AppError.decoding(error)
        }

        if let errors = graphQLResponse.errors, !errors.isEmpty {
            throw AppError.graphQL(errors.map(\.message))
        }

        guard let responseData = graphQLResponse.data else {
            throw AppError.graphQL(["No data returned"])
        }

        return responseData
    }
}

private struct EmptyVariables: Encodable {}

private struct RequestBody<V: Encodable>: Encodable {
    let query: String
    let variables: V?
}

struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLError]?
}

struct GraphQLError: Decodable {
    let message: String
}
```

- [ ] **Step 6: Create minimal User model so tests compile**

Create a temporary minimal `User` struct (will be expanded in Task 5):

```swift
// bunchabout/bunchabout/Models/User.swift
import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: String
    let displayName: String
    var photoURL: String?
    var bio: String?
    var interests: [String]?
    var eventsOrganized: Int?
    var eventsAttended: Int?
    var memberSince: String?
    var noShowCount: Int?
}
```

- [ ] **Step 7: Run tests to verify they pass**

```bash
cd bunchabout && xcodebuild test -workspace bunchabout.xcworkspace -scheme bunchabout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:bunchaboutTests/GraphQLClientTests 2>&1 | tail -30
```

Expected: All 4 tests PASS.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: add GraphQLClient with URLSession, AppError, and tests"
```

---

### Task 4: Auth Service

**Files:**
- Create: `bunchabout/bunchabout/Core/Auth/AuthState.swift`
- Create: `bunchabout/bunchabout/Core/Auth/AuthServiceProtocol.swift`
- Create: `bunchabout/bunchabout/Core/Auth/AuthService.swift`
- Create: `bunchabout/bunchaboutTests/Helpers/MockAuthService.swift`

- [ ] **Step 1: Create AuthState.swift**

```swift
// bunchabout/bunchabout/Core/Auth/AuthState.swift

enum AuthState {
    case unknown
    case signedIn
    case signedOut
}
```

- [ ] **Step 2: Create AuthServiceProtocol.swift**

```swift
// bunchabout/bunchabout/Core/Auth/AuthServiceProtocol.swift

protocol AuthServiceProtocol: AnyObject {
    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String) async throws
    func signOut() throws
    func resetPassword(email: String) async throws
}
```

- [ ] **Step 3: Create AuthService.swift**

```swift
// bunchabout/bunchabout/Core/Auth/AuthService.swift
import FirebaseAuth

@Observable
final class AuthService: AuthServiceProtocol {
    private(set) var authState: AuthState = .unknown
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.authState = user != nil ? .signedIn : .signedOut
        }
    }

    deinit {
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signUp(email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func getToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw AppError.unauthorized
        }
        return try await user.getIDToken()
    }
}
```

- [ ] **Step 4: Create MockAuthService for tests**

```swift
// bunchabout/bunchaboutTests/Helpers/MockAuthService.swift
import Foundation
@testable import bunchabout

final class MockAuthService: AuthServiceProtocol {
    var shouldFail = false
    var failureError: Error = AppError.unauthorized
    var signInCallCount = 0
    var signUpCallCount = 0
    var resetPasswordCallCount = 0
    var lastEmail: String?
    var lastPassword: String?

    func signIn(email: String, password: String) async throws {
        signInCallCount += 1
        lastEmail = email
        lastPassword = password
        if shouldFail { throw failureError }
    }

    func signUp(email: String, password: String) async throws {
        signUpCallCount += 1
        lastEmail = email
        lastPassword = password
        if shouldFail { throw failureError }
    }

    func signOut() throws {}

    func resetPassword(email: String) async throws {
        resetPasswordCallCount += 1
        lastEmail = email
        if shouldFail { throw failureError }
    }
}
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add AuthService with FirebaseAuth, protocol, and test mock"
```

---

### Task 5: Models & Enums

**Files:**
- Create: all files in `bunchabout/bunchabout/Models/Enums/`
- Modify: `bunchabout/bunchabout/Models/User.swift` (expand from minimal version)
- Create: remaining model files in `bunchabout/bunchabout/Models/`
- Create: `bunchabout/bunchabout/Extensions/Date+Extensions.swift`
- Create: `bunchabout/bunchaboutTests/ModelDecodingTests.swift`

- [ ] **Step 1: Create all enum files**

```swift
// bunchabout/bunchabout/Models/Enums/ActivityCategory.swift
enum ActivityCategory: String, Codable, CaseIterable {
    case dinner = "DINNER"
    case coffee = "COFFEE"
    case drinks = "DRINKS"
    case boardGames = "BOARD_GAMES"
    case videoGames = "VIDEO_GAMES"
    case outdoors = "OUTDOORS"
    case sports = "SPORTS"
    case fitness = "FITNESS"
    case music = "MUSIC"
    case arts = "ARTS"
    case movies = "MOVIES"
    case networking = "NETWORKING"
    case study = "STUDY"
    case other = "OTHER"

    var displayName: String {
        switch self {
        case .dinner: "Dinner"
        case .coffee: "Coffee"
        case .drinks: "Drinks"
        case .boardGames: "Board Games"
        case .videoGames: "Video Games"
        case .outdoors: "Outdoors"
        case .sports: "Sports"
        case .fitness: "Fitness"
        case .music: "Music"
        case .arts: "Arts"
        case .movies: "Movies"
        case .networking: "Networking"
        case .study: "Study"
        case .other: "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .dinner: "fork.knife"
        case .coffee: "cup.and.saucer"
        case .drinks: "wineglass"
        case .boardGames: "dice"
        case .videoGames: "gamecontroller"
        case .outdoors: "leaf"
        case .sports: "sportscourt"
        case .fitness: "figure.run"
        case .music: "music.note"
        case .arts: "paintbrush"
        case .movies: "film"
        case .networking: "person.2"
        case .study: "book"
        case .other: "star"
        }
    }
}
```

```swift
// bunchabout/bunchabout/Models/Enums/EventStatus.swift
enum EventStatus: String, Codable {
    case open = "OPEN"
    case full = "FULL"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"
}
```

```swift
// bunchabout/bunchabout/Models/Enums/ParticipantStatus.swift
enum ParticipantStatus: String, Codable {
    case invited = "INVITED"
    case requested = "REQUESTED"
    case confirmed = "CONFIRMED"
    case declined = "DECLINED"
    case waitlisted = "WAITLISTED"
    case left = "LEFT"
    case removed = "REMOVED"
}
```

```swift
// bunchabout/bunchabout/Models/Enums/FillMode.swift
enum FillMode: String, Codable {
    case firstComeFirstServed = "FIRST_COME_FIRST_SERVED"
    case approvalRequired = "APPROVAL_REQUIRED"
}
```

```swift
// bunchabout/bunchabout/Models/Enums/Visibility.swift
enum Visibility: String, Codable {
    case `public` = "PUBLIC"
    case friendsOnly = "FRIENDS_ONLY"
}
```

```swift
// bunchabout/bunchabout/Models/Enums/SlotType.swift
enum SlotType: String, Codable {
    case organizer = "ORGANIZER"
    case friend = "FRIEND"
    case open = "OPEN"
}
```

```swift
// bunchabout/bunchabout/Models/Enums/FeedSort.swift
enum FeedSort: String, Codable {
    case score = "SCORE"
    case date = "DATE"
    case distance = "DISTANCE"
}
```

```swift
// bunchabout/bunchabout/Models/Enums/Gender.swift
enum Gender: String, Codable {
    case male = "MALE"
    case female = "FEMALE"
    case nonBinary = "NON_BINARY"
    case preferNotToSay = "PREFER_NOT_TO_SAY"
}
```

- [ ] **Step 2: Create supporting model types**

```swift
// bunchabout/bunchabout/Models/Trait.swift
struct Trait: Codable, Hashable {
    let name: String
    let tier: TraitTier

    enum TraitTier: String, Codable {
        case normal = "NORMAL"
        case prominent = "PROMINENT"
    }
}
```

```swift
// bunchabout/bunchabout/Models/Badge.swift
struct Badge: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    var awardedAt: String?
}
```

```swift
// bunchabout/bunchabout/Models/EventLocation.swift
struct EventLocation: Codable, Hashable {
    let name: String
    var address: String?
    let lat: Double
    let lng: Double
    var radius: Double?
    var placeId: String?
}
```

```swift
// bunchabout/bunchabout/Models/EventParticipant.swift
struct EventParticipant: Codable, Identifiable {
    let user: User
    let status: ParticipantStatus
    var slotType: SlotType?
    var joinedAt: String?

    var id: String { user.id }
}
```

```swift
// bunchabout/bunchabout/Models/Venue.swift
struct Venue: Codable, Identifiable, Hashable {
    let placeId: String
    let displayName: String
    let formattedAddress: String
    var rating: Double?
    var photos: [VenuePhoto]?

    var id: String { placeId }
}

struct VenuePhoto: Codable, Hashable {
    let url: String
}
```

```swift
// bunchabout/bunchabout/Models/EventConnection.swift
struct EventConnection: Codable {
    let edges: [EventEdge]
    let pageInfo: PageInfo
}

struct EventEdge: Codable {
    let node: Event
    let cursor: String
}

struct PageInfo: Codable {
    let hasNextPage: Bool
    var endCursor: String?
}
```

- [ ] **Step 3: Expand User.swift with full fields**

Replace the minimal User model:

```swift
// bunchabout/bunchabout/Models/User.swift
import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: String
    let displayName: String
    var photoURL: String?
    var bio: String?
    var interests: [ActivityCategory]?
    var traits: [Trait]?
    var badges: [Badge]?
    var eventsOrganized: Int?
    var eventsAttended: Int?
    var memberSince: String?
    var gender: Gender?
    var dateOfBirth: String?
    var noShowCount: Int?
}
```

- [ ] **Step 4: Create Event.swift**

```swift
// bunchabout/bunchabout/Models/Event.swift
import Foundation

struct Event: Codable, Identifiable, Hashable {
    let id: String
    var organizer: User?
    let title: String
    var description: String?
    let category: ActivityCategory
    let date: String
    var time: String?
    var duration: Int?
    var totalSlots: Int?
    var friendReservedSlots: Int?
    var openSlots: Int?
    var slotsRemaining: Int?
    var fillMode: FillMode?
    var visibility: Visibility?
    var status: EventStatus?
    var location: EventLocation?
    var venue: Venue?
    var participants: [EventParticipant]?
    var myParticipantStatus: ParticipantStatus?
    var chatRoomId: String?
    var createdAt: String?
}
```

- [ ] **Step 5: Create Date+Extensions.swift**

```swift
// bunchabout/bunchabout/Extensions/Date+Extensions.swift
import Foundation

extension String {
    var toDate: Date? {
        Self.iso8601Formatter.date(from: self)
    }

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

extension Date {
    var relativeDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: .now)
    }

    var shortDisplay: String {
        formatted(date: .abbreviated, time: .shortened)
    }
}
```

- [ ] **Step 6: Write model decoding tests**

```swift
// bunchabout/bunchaboutTests/ModelDecodingTests.swift
import Testing
import Foundation
@testable import bunchabout

@Suite
struct ModelDecodingTests {
    @Test func decodesUserWithAllFields() throws {
        let json = """
        {
            "id": "u1",
            "displayName": "Sam",
            "photoURL": "https://example.com/photo.jpg",
            "bio": "Hello",
            "interests": ["DINNER", "BOARD_GAMES"],
            "traits": [{"name": "funny", "tier": "NORMAL"}],
            "badges": [{"id": "b1", "name": "First Steps", "description": "Welcome!"}],
            "eventsOrganized": 5,
            "eventsAttended": 10,
            "memberSince": "2026-01-01T00:00:00.000Z",
            "noShowCount": 0
        }
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(User.self, from: json)
        #expect(user.id == "u1")
        #expect(user.displayName == "Sam")
        #expect(user.interests == [.dinner, .boardGames])
        #expect(user.traits?.first?.name == "funny")
        #expect(user.badges?.count == 1)
    }

    @Test func decodesUserWithMinimalFields() throws {
        let json = """
        {"id": "u2", "displayName": "Alex"}
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(User.self, from: json)
        #expect(user.id == "u2")
        #expect(user.photoURL == nil)
        #expect(user.interests == nil)
    }

    @Test func decodesEvent() throws {
        let json = """
        {
            "id": "e1",
            "title": "Board Game Night",
            "category": "BOARD_GAMES",
            "date": "2026-04-15T19:00:00.000Z",
            "time": "7:00 PM",
            "totalSlots": 6,
            "slotsRemaining": 3,
            "fillMode": "FIRST_COME_FIRST_SERVED",
            "visibility": "PUBLIC",
            "status": "OPEN",
            "location": {
                "name": "The Game Parlour",
                "lat": 38.9072,
                "lng": -77.0369
            },
            "organizer": {
                "id": "u1",
                "displayName": "Sam"
            }
        }
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(Event.self, from: json)
        #expect(event.id == "e1")
        #expect(event.category == .boardGames)
        #expect(event.fillMode == .firstComeFirstServed)
        #expect(event.status == .open)
        #expect(event.location?.name == "The Game Parlour")
        #expect(event.organizer?.displayName == "Sam")
        #expect(event.slotsRemaining == 3)
    }

    @Test func decodesEventConnection() throws {
        let json = """
        {
            "edges": [
                {
                    "node": {
                        "id": "e1",
                        "title": "Dinner",
                        "category": "DINNER",
                        "date": "2026-04-15T19:00:00.000Z"
                    },
                    "cursor": "abc123"
                }
            ],
            "pageInfo": {
                "hasNextPage": true,
                "endCursor": "abc123"
            }
        }
        """.data(using: .utf8)!

        let connection = try JSONDecoder().decode(EventConnection.self, from: json)
        #expect(connection.edges.count == 1)
        #expect(connection.edges[0].node.title == "Dinner")
        #expect(connection.pageInfo.hasNextPage == true)
        #expect(connection.pageInfo.endCursor == "abc123")
    }

    @Test func decodesActivityCategoryFromRawValue() throws {
        let json = "\"BOARD_GAMES\"".data(using: .utf8)!
        let category = try JSONDecoder().decode(ActivityCategory.self, from: json)
        #expect(category == .boardGames)
    }

    @Test func parsesISO8601DateString() {
        let dateString = "2026-04-15T19:00:00.000Z"
        let date = dateString.toDate
        #expect(date != nil)
    }
}
```

- [ ] **Step 7: Run tests**

```bash
cd bunchabout && xcodebuild test -workspace bunchabout.xcworkspace -scheme bunchabout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:bunchaboutTests/ModelDecodingTests 2>&1 | tail -20
```

Expected: All tests PASS.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: add all model types, enums, and decoding tests"
```

---

### Task 6: User Repository & Queries

**Files:**
- Create: `bunchabout/bunchabout/Repositories/UserQueries.swift`
- Create: `bunchabout/bunchabout/Repositories/UserRepository.swift`
- Create: `bunchabout/bunchaboutTests/UserRepositoryTests.swift`

- [ ] **Step 1: Write UserRepository tests**

```swift
// bunchabout/bunchaboutTests/UserRepositoryTests.swift
import Testing
import Foundation
@testable import bunchabout

@Suite(.serialized)
@MainActor
struct UserRepositoryTests {
    @Test func fetchCurrentUserPopulatesCache() async throws {
        MockURLProtocol.requestHandler = { _ in
            mockResponse(json: """
            {"data": {"me": {"id": "u1", "displayName": "Sam", "bio": "Hello"}}}
            """)
        }

        let repo = UserRepository(client: makeTestClient())
        #expect(repo.currentUser == nil)

        try await repo.fetchCurrentUser()

        #expect(repo.currentUser?.id == "u1")
        #expect(repo.currentUser?.displayName == "Sam")
        #expect(repo.users["u1"]?.displayName == "Sam")
    }

    @Test func fetchUserReturnsCachedUser() async throws {
        var networkCallCount = 0
        MockURLProtocol.requestHandler = { _ in
            networkCallCount += 1
            return mockResponse(json: """
            {"data": {"user": {"id": "u2", "displayName": "Alex"}}}
            """)
        }

        let repo = UserRepository(client: makeTestClient())

        let user1 = try await repo.fetchUser(id: "u2")
        #expect(user1.displayName == "Alex")
        #expect(networkCallCount == 1)

        let user2 = try await repo.fetchUser(id: "u2")
        #expect(user2.displayName == "Alex")
        #expect(networkCallCount == 1) // cache hit, no second network call
    }

    @Test func createProfilePopulatesCurrentUser() async throws {
        MockURLProtocol.requestHandler = { _ in
            mockResponse(json: """
            {"data": {"createProfile": {"id": "u3", "displayName": "New User"}}}
            """)
        }

        let repo = UserRepository(client: makeTestClient())
        try await repo.createProfile(displayName: "New User")

        #expect(repo.currentUser?.id == "u3")
        #expect(repo.currentUser?.displayName == "New User")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd bunchabout && xcodebuild test -workspace bunchabout.xcworkspace -scheme bunchabout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:bunchaboutTests/UserRepositoryTests 2>&1 | tail -20
```

Expected: Build failure — `UserRepository` does not exist yet.

- [ ] **Step 3: Create UserQueries.swift**

```swift
// bunchabout/bunchabout/Repositories/UserQueries.swift

enum UserQueries {
    static let me = """
    query {
        me {
            id
            displayName
            photoURL
            bio
            interests
            traits { name tier }
            badges { id name description awardedAt }
            eventsOrganized
            eventsAttended
            memberSince
            gender
            dateOfBirth
            noShowCount
        }
    }
    """

    static let user = """
    query User($id: ID!) {
        user(id: $id) {
            id
            displayName
            photoURL
            bio
            interests
            traits { name tier }
            badges { id name description awardedAt }
            eventsOrganized
            eventsAttended
            memberSince
        }
    }
    """

    struct MeResponse: Decodable {
        let me: User
    }

    struct UserResponse: Decodable {
        let user: User?
    }

    struct UserVariables: Encodable {
        let id: String
    }
}

enum UserMutations {
    static let createProfile = """
    mutation CreateProfile($input: CreateProfileInput!) {
        createProfile(input: $input) {
            id
            displayName
            photoURL
            bio
            interests
        }
    }
    """

    struct CreateProfileVariables: Encodable {
        let input: CreateProfileInput
    }

    struct CreateProfileInput: Encodable {
        let displayName: String
    }

    struct CreateProfileResponse: Decodable {
        let createProfile: User
    }
}
```

- [ ] **Step 4: Create UserRepository.swift**

```swift
// bunchabout/bunchabout/Repositories/UserRepository.swift
import Foundation

@Observable
final class UserRepository {
    private(set) var currentUser: User?
    private(set) var users: [String: User] = [:]

    private let client: GraphQLClient

    init(client: GraphQLClient) {
        self.client = client
    }

    func fetchCurrentUser() async throws {
        let response: UserQueries.MeResponse = try await client.execute(query: UserQueries.me)
        currentUser = response.me
        users[response.me.id] = response.me
    }

    func fetchUser(id: String) async throws -> User {
        if let cached = users[id] { return cached }
        let response: UserQueries.UserResponse = try await client.execute(
            query: UserQueries.user,
            variables: UserQueries.UserVariables(id: id)
        )
        guard let user = response.user else {
            throw AppError.graphQL(["User not found"])
        }
        users[id] = user
        return user
    }

    func createProfile(displayName: String) async throws {
        let variables = UserMutations.CreateProfileVariables(
            input: UserMutations.CreateProfileInput(displayName: displayName)
        )
        let response: UserMutations.CreateProfileResponse = try await client.execute(
            query: UserMutations.createProfile,
            variables: variables
        )
        currentUser = response.createProfile
        users[response.createProfile.id] = response.createProfile
    }
}
```

- [ ] **Step 5: Run tests**

```bash
cd bunchabout && xcodebuild test -workspace bunchabout.xcworkspace -scheme bunchabout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:bunchaboutTests/UserRepositoryTests 2>&1 | tail -20
```

Expected: All 3 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: add UserRepository with caching, queries, and tests"
```

---

### Task 7: Event Repository & Queries

**Files:**
- Create: `bunchabout/bunchabout/Repositories/EventQueries.swift`
- Create: `bunchabout/bunchabout/Repositories/EventRepository.swift`
- Create: `bunchabout/bunchaboutTests/EventRepositoryTests.swift`

- [ ] **Step 1: Write EventRepository tests**

```swift
// bunchabout/bunchaboutTests/EventRepositoryTests.swift
import Testing
import Foundation
@testable import bunchabout

@Suite(.serialized)
@MainActor
struct EventRepositoryTests {
    @Test func fetchFeedPopulatesCacheAndIds() async throws {
        MockURLProtocol.requestHandler = { _ in
            mockResponse(json: """
            {
                "data": {
                    "feed": {
                        "edges": [
                            {"node": {"id": "e1", "title": "Dinner", "category": "DINNER", "date": "2026-04-15T19:00:00.000Z"}, "cursor": "c1"},
                            {"node": {"id": "e2", "title": "Games", "category": "BOARD_GAMES", "date": "2026-04-16T19:00:00.000Z"}, "cursor": "c2"}
                        ],
                        "pageInfo": {"hasNextPage": true, "endCursor": "c2"}
                    }
                }
            }
            """)
        }

        let repo = EventRepository(client: makeTestClient())
        try await repo.fetchFeed(lat: 37.77, lng: -122.42)

        #expect(repo.feedEventIds.count == 2)
        #expect(repo.feedEventIds == ["e1", "e2"])
        #expect(repo.events["e1"]?.title == "Dinner")
        #expect(repo.events["e2"]?.title == "Games")
        #expect(repo.feedPageInfo?.hasNextPage == true)
    }

    @Test func fetchFeedNextPageAppendsResults() async throws {
        let repo = EventRepository(client: makeTestClient())

        // First page
        MockURLProtocol.requestHandler = { _ in
            mockResponse(json: """
            {"data": {"feed": {"edges": [{"node": {"id": "e1", "title": "A", "category": "DINNER", "date": "2026-04-15T00:00:00.000Z"}, "cursor": "c1"}], "pageInfo": {"hasNextPage": true, "endCursor": "c1"}}}}
            """)
        }
        try await repo.fetchFeed(lat: 37.77, lng: -122.42)
        #expect(repo.feedEventIds == ["e1"])

        // Second page
        MockURLProtocol.requestHandler = { _ in
            mockResponse(json: """
            {"data": {"feed": {"edges": [{"node": {"id": "e2", "title": "B", "category": "COFFEE", "date": "2026-04-16T00:00:00.000Z"}, "cursor": "c2"}], "pageInfo": {"hasNextPage": false, "endCursor": "c2"}}}}
            """)
        }
        try await repo.fetchFeed(lat: 37.77, lng: -122.42, cursor: "c1")
        #expect(repo.feedEventIds == ["e1", "e2"])
    }

    @Test func fetchEventCachesResult() async throws {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            return mockResponse(json: """
            {"data": {"event": {"id": "e1", "title": "Dinner", "category": "DINNER", "date": "2026-04-15T00:00:00.000Z", "totalSlots": 6, "slotsRemaining": 3}}}
            """)
        }

        let repo = EventRepository(client: makeTestClient())

        let event1 = try await repo.fetchEvent(id: "e1")
        #expect(event1.title == "Dinner")
        #expect(callCount == 1)

        let event2 = try await repo.fetchEvent(id: "e1")
        #expect(event2.title == "Dinner")
        #expect(callCount == 1) // cache hit
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd bunchabout && xcodebuild test -workspace bunchabout.xcworkspace -scheme bunchabout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:bunchaboutTests/EventRepositoryTests 2>&1 | tail -20
```

Expected: Build failure — `EventRepository` does not exist yet.

- [ ] **Step 3: Create EventQueries.swift**

```swift
// bunchabout/bunchabout/Repositories/EventQueries.swift

enum EventQueries {
    static let feed = """
    query Feed($location: LocationInput!, $cursor: String, $limit: Int) {
        feed(location: $location, cursor: $cursor, limit: $limit) {
            edges {
                node {
                    id
                    title
                    category
                    date
                    time
                    totalSlots
                    slotsRemaining
                    status
                    fillMode
                    visibility
                    location { name lat lng }
                    organizer { id displayName photoURL }
                }
                cursor
            }
            pageInfo {
                hasNextPage
                endCursor
            }
        }
    }
    """

    static let event = """
    query Event($id: ID!) {
        event(id: $id) {
            id
            title
            description
            category
            date
            time
            duration
            totalSlots
            friendReservedSlots
            openSlots
            slotsRemaining
            fillMode
            visibility
            status
            location { name address lat lng radius placeId }
            venue { placeId displayName formattedAddress rating photos { url } }
            organizer { id displayName photoURL }
            participants {
                user { id displayName photoURL }
                status
                slotType
                joinedAt
            }
            myParticipantStatus
            createdAt
        }
    }
    """

    struct FeedResponse: Decodable {
        let feed: EventConnection
    }

    struct FeedVariables: Encodable {
        let location: LocationInput
        var cursor: String?
        var limit: Int?
    }

    struct LocationInput: Encodable {
        let lat: Double
        let lng: Double
    }

    struct EventDetailResponse: Decodable {
        let event: Event?
    }

    struct EventVariables: Encodable {
        let id: String
    }
}
```

- [ ] **Step 4: Create EventRepository.swift**

```swift
// bunchabout/bunchabout/Repositories/EventRepository.swift
import Foundation

@Observable
final class EventRepository {
    private(set) var events: [String: Event] = [:]
    private(set) var feedEventIds: [String] = []
    private(set) var feedPageInfo: PageInfo?
    private(set) var isLoadingFeed = false

    private let client: GraphQLClient

    init(client: GraphQLClient) {
        self.client = client
    }

    func fetchFeed(lat: Double, lng: Double, cursor: String? = nil) async throws {
        isLoadingFeed = true
        defer { isLoadingFeed = false }

        let variables = EventQueries.FeedVariables(
            location: EventQueries.LocationInput(lat: lat, lng: lng),
            cursor: cursor,
            limit: 20
        )
        let response: EventQueries.FeedResponse = try await client.execute(
            query: EventQueries.feed,
            variables: variables
        )

        for edge in response.feed.edges {
            events[edge.node.id] = edge.node
        }

        let newIds = response.feed.edges.map(\.node.id)
        if cursor == nil {
            feedEventIds = newIds
        } else {
            feedEventIds.append(contentsOf: newIds)
        }

        feedPageInfo = response.feed.pageInfo
    }

    func fetchEvent(id: String) async throws -> Event {
        if let cached = events[id] { return cached }

        let response: EventQueries.EventDetailResponse = try await client.execute(
            query: EventQueries.event,
            variables: EventQueries.EventVariables(id: id)
        )
        guard let event = response.event else {
            throw AppError.graphQL(["Event not found"])
        }
        events[id] = event
        return event
    }

    func event(for id: String) -> Event? {
        events[id]
    }
}
```

- [ ] **Step 5: Run tests**

```bash
cd bunchabout && xcodebuild test -workspace bunchabout.xcworkspace -scheme bunchabout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:bunchaboutTests/EventRepositoryTests 2>&1 | tail -20
```

Expected: All 3 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: add EventRepository with feed pagination, caching, and tests"
```

---

### Task 8: App Shell & Root Navigation

**Files:**
- Modify: `bunchabout/bunchabout/App/bunchaboutApp.swift`
- Create: `bunchabout/bunchabout/App/RootView.swift`
- Create: `bunchabout/bunchabout/App/MainTabView.swift`
- Create: `bunchabout/bunchabout/Features/Profile/ProfileView.swift`

- [ ] **Step 1: Update bunchaboutApp.swift**

```swift
// bunchabout/bunchabout/App/bunchaboutApp.swift
import SwiftUI
import FirebaseCore

@main
struct bunchaboutApp: App {
    let authService: AuthService
    let graphQLClient: GraphQLClient
    let userRepository: UserRepository
    let eventRepository: EventRepository
    let locationService: LocationService

    init() {
        FirebaseApp.configure()

        let auth = AuthService()
        let client = GraphQLClient(getToken: { try await auth.getToken() })

        authService = auth
        graphQLClient = client
        userRepository = UserRepository(client: client)
        eventRepository = EventRepository(client: client)
        locationService = LocationService()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .environment(userRepository)
                .environment(eventRepository)
                .environment(locationService)
        }
    }
}
```

- [ ] **Step 2: Create RootView.swift**

```swift
// bunchabout/bunchabout/App/RootView.swift
import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var authService
    @Environment(UserRepository.self) private var userRepository

    var body: some View {
        switch authService.authState {
        case .unknown:
            ProgressView("Loading...")
        case .signedOut:
            NavigationStack {
                LoginView(
                    authService: authService,
                    userRepository: userRepository
                )
            }
        case .signedIn:
            MainTabView()
                .task {
                    if userRepository.currentUser == nil {
                        try? await userRepository.fetchCurrentUser()
                    }
                }
        }
    }
}
```

- [ ] **Step 3: Create MainTabView.swift**

```swift
// bunchabout/bunchabout/App/MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @Environment(EventRepository.self) private var eventRepository
    @Environment(LocationService.self) private var locationService

    var body: some View {
        TabView {
            Tab("Feed", systemImage: "magnifyingglass") {
                NavigationStack {
                    FeedView(
                        eventRepository: eventRepository,
                        locationService: locationService
                    )
                }
            }

            Tab("Profile", systemImage: "person") {
                NavigationStack {
                    ProfileView()
                }
            }
        }
    }
}
```

- [ ] **Step 4: Create placeholder ProfileView.swift**

```swift
// bunchabout/bunchabout/Features/Profile/ProfileView.swift
import SwiftUI

struct ProfileView: View {
    @Environment(AuthService.self) private var authService
    @Environment(UserRepository.self) private var userRepository

    var body: some View {
        VStack(spacing: Sizes.spacing24) {
            if let user = userRepository.currentUser {
                Text(user.displayName)
                    .font(.title)

                if let bio = user.bio {
                    Text(bio)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button("Sign Out", role: .destructive) {
                try? authService.signOut()
            }
            .buttonStyle(.bordered)
        }
        .padding(Sizes.spacing24)
        .navigationTitle("Profile")
    }
}
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add app shell with RootView, MainTabView, and auth-gated navigation"
```

---

### Task 9: Login Feature

**Files:**
- Create: `bunchabout/bunchabout/Features/Login/LoginViewModel.swift`
- Create: `bunchabout/bunchabout/Features/Login/LoginView.swift`
- Create: `bunchabout/bunchabout/Features/Login/SignUpViewModel.swift`
- Create: `bunchabout/bunchabout/Features/Login/SignUpView.swift`
- Create: `bunchabout/bunchabout/Features/Login/ForgotPasswordViewModel.swift`
- Create: `bunchabout/bunchabout/Features/Login/ForgotPasswordView.swift`
- Create: `bunchabout/bunchaboutTests/LoginViewModelTests.swift`

- [ ] **Step 1: Write LoginViewModel tests**

```swift
// bunchabout/bunchaboutTests/LoginViewModelTests.swift
import Testing
import Foundation
@testable import bunchabout

@Suite(.serialized)
@MainActor
struct LoginViewModelTests {
    @Test func signInSuccessPopulatesUser() async {
        MockURLProtocol.requestHandler = { _ in
            mockResponse(json: """
            {"data": {"me": {"id": "u1", "displayName": "Sam"}}}
            """)
        }

        let mockAuth = MockAuthService()
        let userRepo = UserRepository(client: makeTestClient())
        let vm = LoginViewModel(authService: mockAuth, userRepository: userRepo)

        vm.email = "test@example.com"
        vm.password = "password123"
        await vm.signIn()

        #expect(mockAuth.signInCallCount == 1)
        #expect(mockAuth.lastEmail == "test@example.com")
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)
        #expect(userRepo.currentUser?.id == "u1")
    }

    @Test func signInFailureSetsErrorMessage() async {
        let mockAuth = MockAuthService()
        mockAuth.shouldFail = true
        mockAuth.failureError = AppError.graphQL(["Invalid credentials"])

        let userRepo = UserRepository(client: makeTestClient())
        let vm = LoginViewModel(authService: mockAuth, userRepository: userRepo)

        vm.email = "test@example.com"
        vm.password = "wrong"
        await vm.signIn()

        #expect(vm.errorMessage != nil)
        #expect(vm.isLoading == false)
        #expect(userRepo.currentUser == nil)
    }

    @Test func isValidRequiresEmailAndPassword() {
        let mockAuth = MockAuthService()
        let userRepo = UserRepository(client: makeTestClient())
        let vm = LoginViewModel(authService: mockAuth, userRepository: userRepo)

        #expect(!vm.isValid)

        vm.email = "test@example.com"
        #expect(!vm.isValid)

        vm.password = "password"
        #expect(vm.isValid)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd bunchabout && xcodebuild test -workspace bunchabout.xcworkspace -scheme bunchabout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:bunchaboutTests/LoginViewModelTests 2>&1 | tail -20
```

Expected: Build failure — `LoginViewModel` does not exist yet.

- [ ] **Step 3: Create LoginViewModel.swift**

```swift
// bunchabout/bunchabout/Features/Login/LoginViewModel.swift
import Foundation

@Observable
final class LoginViewModel {
    var email = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?

    private let authService: any AuthServiceProtocol
    private let userRepository: UserRepository

    var isValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    init(authService: any AuthServiceProtocol, userRepository: UserRepository) {
        self.authService = authService
        self.userRepository = userRepository
    }

    func signIn() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            try await authService.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
            try await userRepository.fetchCurrentUser()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd bunchabout && xcodebuild test -workspace bunchabout.xcworkspace -scheme bunchabout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:bunchaboutTests/LoginViewModelTests 2>&1 | tail -20
```

Expected: All 3 tests PASS.

- [ ] **Step 5: Create LoginView.swift**

```swift
// bunchabout/bunchabout/Features/Login/LoginView.swift
import SwiftUI

struct LoginView: View {
    let authService: any AuthServiceProtocol
    let userRepository: UserRepository
    @State private var viewModel: LoginViewModel

    init(authService: any AuthServiceProtocol, userRepository: UserRepository) {
        self.authService = authService
        self.userRepository = userRepository
        _viewModel = State(initialValue: LoginViewModel(
            authService: authService,
            userRepository: userRepository
        ))
    }

    var body: some View {
        VStack(spacing: Sizes.spacing24) {
            Spacer()

            Text("bunchabout")
                .font(.largeTitle.bold())

            Text("Find your people, find your plans")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            VStack(spacing: Sizes.spacing16) {
                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(Sizes.spacing12)
                    .background(AppColors.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadius8))

                SecureField("Password", text: $viewModel.password)
                    .textContentType(.password)
                    .padding(Sizes.spacing12)
                    .background(AppColors.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadius8))
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(AppColors.error)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await viewModel.signIn() }
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Sign In")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: Sizes.buttonHeight)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading || !viewModel.isValid)

            NavigationLink("Forgot Password?") {
                ForgotPasswordView(authService: authService)
            }
            .font(.footnote)

            Spacer()

            NavigationLink {
                SignUpView(authService: authService, userRepository: userRepository)
            } label: {
                Text("Don't have an account? ")
                    .foregroundStyle(.secondary)
                + Text("Sign Up")
                    .bold()
            }
            .font(.subheadline)
        }
        .padding(Sizes.spacing24)
        .navigationBarBackButtonHidden()
    }
}
```

- [ ] **Step 6: Create SignUpViewModel.swift**

```swift
// bunchabout/bunchabout/Features/Login/SignUpViewModel.swift
import Foundation

@Observable
final class SignUpViewModel {
    var displayName = ""
    var email = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?

    private let authService: any AuthServiceProtocol
    private let userRepository: UserRepository

    var isValid: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
        && !email.trimmingCharacters(in: .whitespaces).isEmpty
        && password.count >= 6
    }

    init(authService: any AuthServiceProtocol, userRepository: UserRepository) {
        self.authService = authService
        self.userRepository = userRepository
    }

    func signUp() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            try await authService.signUp(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
            try await userRepository.createProfile(
                displayName: displayName.trimmingCharacters(in: .whitespaces)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

- [ ] **Step 7: Create SignUpView.swift**

```swift
// bunchabout/bunchabout/Features/Login/SignUpView.swift
import SwiftUI

struct SignUpView: View {
    let authService: any AuthServiceProtocol
    let userRepository: UserRepository
    @State private var viewModel: SignUpViewModel

    init(authService: any AuthServiceProtocol, userRepository: UserRepository) {
        self.authService = authService
        self.userRepository = userRepository
        _viewModel = State(initialValue: SignUpViewModel(
            authService: authService,
            userRepository: userRepository
        ))
    }

    var body: some View {
        VStack(spacing: Sizes.spacing24) {
            Text("Create Account")
                .font(.title.bold())

            VStack(spacing: Sizes.spacing16) {
                TextField("Display Name", text: $viewModel.displayName)
                    .textContentType(.name)
                    .padding(Sizes.spacing12)
                    .background(AppColors.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadius8))

                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(Sizes.spacing12)
                    .background(AppColors.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadius8))

                SecureField("Password (6+ characters)", text: $viewModel.password)
                    .textContentType(.newPassword)
                    .padding(Sizes.spacing12)
                    .background(AppColors.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadius8))
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(AppColors.error)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await viewModel.signUp() }
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Create Account")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: Sizes.buttonHeight)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading || !viewModel.isValid)

            Spacer()
        }
        .padding(Sizes.spacing24)
        .navigationTitle("Sign Up")
    }
}
```

- [ ] **Step 8: Create ForgotPasswordViewModel.swift**

```swift
// bunchabout/bunchabout/Features/Login/ForgotPasswordViewModel.swift
import Foundation

@Observable
final class ForgotPasswordViewModel {
    var email = ""
    var isLoading = false
    var errorMessage: String?
    var didSendReset = false

    private let authService: any AuthServiceProtocol

    var isValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(authService: any AuthServiceProtocol) {
        self.authService = authService
    }

    func resetPassword() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            try await authService.resetPassword(email: email.trimmingCharacters(in: .whitespaces))
            didSendReset = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

- [ ] **Step 9: Create ForgotPasswordView.swift**

```swift
// bunchabout/bunchabout/Features/Login/ForgotPasswordView.swift
import SwiftUI

struct ForgotPasswordView: View {
    @State private var viewModel: ForgotPasswordViewModel

    init(authService: any AuthServiceProtocol) {
        _viewModel = State(initialValue: ForgotPasswordViewModel(authService: authService))
    }

    var body: some View {
        VStack(spacing: Sizes.spacing24) {
            if viewModel.didSendReset {
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: Sizes.spacing48))
                    .foregroundStyle(AppColors.primary)

                Text("Check Your Email")
                    .font(.title2.bold())

                Text("We sent a password reset link to \(viewModel.email)")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Reset Password")
                    .font(.title2.bold())

                Text("Enter your email and we'll send you a reset link")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(Sizes.spacing12)
                    .background(AppColors.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadius8))

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(AppColors.error)
                }

                Button {
                    Task { await viewModel.resetPassword() }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Send Reset Link")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: Sizes.buttonHeight)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading || !viewModel.isValid)
            }

            Spacer()
        }
        .padding(Sizes.spacing24)
        .navigationTitle("Forgot Password")
    }
}
```

- [ ] **Step 10: Run all tests**

```bash
cd bunchabout && xcodebuild test -workspace bunchabout.xcworkspace -scheme bunchabout -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -30
```

Expected: All tests PASS (GraphQLClient, ModelDecoding, UserRepository, LoginViewModel).

- [ ] **Step 11: Commit**

```bash
git add -A
git commit -m "feat: add login, sign up, and forgot password flows with tests"
```

---

### Task 10: Location Service

**Files:**
- Create: `bunchabout/bunchabout/Core/Location/LocationService.swift`

- [ ] **Step 1: Create LocationService.swift**

```swift
// bunchabout/bunchabout/Core/Location/LocationService.swift
import CoreLocation

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    private(set) var currentLocation: CLLocationCoordinate2D?
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var locationError: Error?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        locationError = nil
        manager.requestLocation()
    }

    var hasPermission: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: true
        default: false
        }
    }

    var needsPermissionRequest: Bool {
        authorizationStatus == .notDetermined
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last?.coordinate
        Task { @MainActor in
            self.currentLocation = location
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if self.hasPermission && self.currentLocation == nil {
                self.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationError = error
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add bunchabout/bunchabout/Core/Location/LocationService.swift
git commit -m "feat: add LocationService with CoreLocation permission handling"
```

---

### Task 11: Feed Feature

**Files:**
- Create: `bunchabout/bunchabout/Features/Feed/FeedViewModel.swift`
- Create: `bunchabout/bunchabout/Features/Feed/EventCardView.swift`
- Create: `bunchabout/bunchabout/Features/Feed/FeedView.swift`
- Create: `bunchabout/bunchaboutTests/FeedViewModelTests.swift`

- [ ] **Step 1: Write FeedViewModel tests**

```swift
// bunchabout/bunchaboutTests/FeedViewModelTests.swift
import Testing
import Foundation
@testable import bunchabout

private let feedJSON = """
{
    "data": {
        "feed": {
            "edges": [
                {
                    "node": {
                        "id": "e1", "title": "Dinner Club", "category": "DINNER",
                        "date": "2026-04-15T19:00:00.000Z", "totalSlots": 6, "slotsRemaining": 3,
                        "status": "OPEN",
                        "location": {"name": "Bistro", "lat": 37.77, "lng": -122.42},
                        "organizer": {"id": "u1", "displayName": "Sam"}
                    },
                    "cursor": "c1"
                }
            ],
            "pageInfo": {"hasNextPage": false, "endCursor": "c1"}
        }
    }
}
"""

@Suite(.serialized)
@MainActor
struct FeedViewModelTests {
    @Test func loadFeedPopulatesEvents() async {
        MockURLProtocol.requestHandler = { _ in
            mockResponse(json: feedJSON)
        }

        let repo = EventRepository(client: makeTestClient())
        let vm = FeedViewModel(eventRepository: repo, locationService: LocationService())
        vm.testLocation = (lat: 37.77, lng: -122.42)

        await vm.loadFeed()

        #expect(vm.feedEvents.count == 1)
        #expect(vm.feedEvents.first?.title == "Dinner Club")
        #expect(vm.errorMessage == nil)
    }

    @Test func loadFeedSetsErrorOnFailure() async {
        MockURLProtocol.requestHandler = { _ in
            mockResponse(json: """
            {"data": null, "errors": [{"message": "Server error"}]}
            """)
        }

        let repo = EventRepository(client: makeTestClient())
        let vm = FeedViewModel(eventRepository: repo, locationService: LocationService())
        vm.testLocation = (lat: 37.77, lng: -122.42)

        await vm.loadFeed()

        #expect(vm.errorMessage != nil)
        #expect(vm.feedEvents.isEmpty)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd bunchabout && xcodebuild test -workspace bunchabout.xcworkspace -scheme bunchabout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:bunchaboutTests/FeedViewModelTests 2>&1 | tail -20
```

Expected: Build failure — `FeedViewModel` does not exist yet.

- [ ] **Step 3: Create FeedViewModel.swift**

```swift
// bunchabout/bunchabout/Features/Feed/FeedViewModel.swift
import Foundation
import CoreLocation

@Observable
final class FeedViewModel {
    var errorMessage: String?
    var testLocation: (lat: Double, lng: Double)?

    private let eventRepository: EventRepository
    private let locationService: LocationService

    var feedEvents: [Event] {
        eventRepository.feedEventIds.compactMap { eventRepository.event(for: $0) }
    }

    var isLoading: Bool {
        eventRepository.isLoadingFeed
    }

    var hasNextPage: Bool {
        eventRepository.feedPageInfo?.hasNextPage ?? false
    }

    var needsLocationPermission: Bool {
        locationService.needsPermissionRequest
    }

    var locationDenied: Bool {
        locationService.authorizationStatus == .denied
    }

    init(eventRepository: EventRepository, locationService: LocationService) {
        self.eventRepository = eventRepository
        self.locationService = locationService
    }

    func requestLocationPermission() {
        locationService.requestPermission()
    }

    func loadFeed() async {
        errorMessage = nil
        guard let location = resolveLocation() else {
            if !locationService.needsPermissionRequest {
                locationService.requestLocation()
            }
            return
        }

        do {
            try await eventRepository.fetchFeed(lat: location.lat, lng: location.lng)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadNextPage() async {
        guard let cursor = eventRepository.feedPageInfo?.endCursor,
              let location = resolveLocation() else { return }

        do {
            try await eventRepository.fetchFeed(lat: location.lat, lng: location.lng, cursor: cursor)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resolveLocation() -> (lat: Double, lng: Double)? {
        if let test = testLocation { return test }
        guard let coord = locationService.currentLocation else { return nil }
        return (coord.latitude, coord.longitude)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd bunchabout && xcodebuild test -workspace bunchabout.xcworkspace -scheme bunchabout -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:bunchaboutTests/FeedViewModelTests 2>&1 | tail -20
```

Expected: All 2 tests PASS.

- [ ] **Step 5: Create EventCardView.swift**

```swift
// bunchabout/bunchabout/Features/Feed/EventCardView.swift
import SwiftUI

struct EventCardView: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: Sizes.spacing8) {
            HStack {
                Label(event.category.displayName, systemImage: event.category.systemImage)
                    .font(.caption)
                    .foregroundStyle(AppColors.primary)

                Spacer()

                if let date = event.date.toDate {
                    Text(date.shortDisplay)
                        .captionStyle()
                }
            }

            Text(event.title)
                .headlineStyle()
                .lineLimit(2)

            if let locationName = event.location?.name {
                Label(locationName, systemImage: "mappin")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack {
                if let organizer = event.organizer {
                    Label(organizer.displayName, systemImage: "person")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let remaining = event.slotsRemaining, let total = event.totalSlots {
                    Text("\(remaining)/\(total) spots")
                        .font(.caption.bold())
                        .foregroundStyle(remaining > 0 ? AppColors.primary : AppColors.error)
                }
            }
        }
        .padding(Sizes.spacing16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadius12))
    }
}
```

- [ ] **Step 6: Create FeedView.swift**

```swift
// bunchabout/bunchabout/Features/Feed/FeedView.swift
import SwiftUI

struct FeedView: View {
    let eventRepository: EventRepository
    @State private var viewModel: FeedViewModel

    init(eventRepository: EventRepository, locationService: LocationService) {
        self.eventRepository = eventRepository
        _viewModel = State(initialValue: FeedViewModel(
            eventRepository: eventRepository,
            locationService: locationService
        ))
    }

    var body: some View {
        Group {
            if viewModel.needsLocationPermission {
                locationPermissionView
            } else if viewModel.locationDenied {
                locationDeniedView
            } else if viewModel.feedEvents.isEmpty && !viewModel.isLoading {
                emptyFeedView
            } else {
                feedList
            }
        }
        .navigationTitle("Events Near You")
        .task {
            if viewModel.needsLocationPermission {
                viewModel.requestLocationPermission()
            } else {
                await viewModel.loadFeed()
            }
        }
    }

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: Sizes.spacing12) {
                ForEach(viewModel.feedEvents) { event in
                    NavigationLink(value: event.id) {
                        EventCardView(event: event)
                    }
                    .buttonStyle(.plain)
                }

                if viewModel.isLoading {
                    ProgressView()
                        .padding(Sizes.spacing16)
                }

                if viewModel.hasNextPage && !viewModel.isLoading {
                    Color.clear
                        .frame(height: 1)
                        .task {
                            await viewModel.loadNextPage()
                        }
                }
            }
            .padding(.horizontal, Sizes.spacing16)
            .padding(.top, Sizes.spacing8)
        }
        .navigationDestination(for: String.self) { eventId in
            EventDetailView(eventId: eventId, eventRepository: eventRepository)
        }
    }

    private var locationPermissionView: some View {
        ContentUnavailableView {
            Label("Location Required", systemImage: "location")
        } description: {
            Text("bunchabout needs your location to find events near you.")
        } actions: {
            Button("Allow Location Access") {
                viewModel.requestLocationPermission()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var locationDeniedView: some View {
        ContentUnavailableView {
            Label("Location Denied", systemImage: "location.slash")
        } description: {
            Text("Enable location access in Settings to find events near you.")
        }
    }

    private var emptyFeedView: some View {
        ContentUnavailableView {
            Label("No Events", systemImage: "calendar.badge.exclamationmark")
        } description: {
            Text("No events found near you. Check back later!")
        }
    }
}
```

- [ ] **Step 7: Run all tests**

```bash
cd bunchabout && xcodebuild test -workspace bunchabout.xcworkspace -scheme bunchabout -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -30
```

Expected: All tests PASS.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: add event feed with location, pagination, and event cards"
```

---

### Task 12: Event Detail Feature

**Files:**
- Create: `bunchabout/bunchabout/Features/EventDetail/EventDetailViewModel.swift`
- Create: `bunchabout/bunchabout/Features/EventDetail/EventDetailView.swift`

- [ ] **Step 1: Create EventDetailViewModel.swift**

```swift
// bunchabout/bunchabout/Features/EventDetail/EventDetailViewModel.swift
import Foundation

@Observable
final class EventDetailViewModel {
    var event: Event?
    var isLoading = false
    var errorMessage: String?

    private let eventId: String
    private let eventRepository: EventRepository

    var confirmedParticipants: [EventParticipant] {
        event?.participants?.filter { $0.status == .confirmed } ?? []
    }

    init(eventId: String, eventRepository: EventRepository) {
        self.eventId = eventId
        self.eventRepository = eventRepository
        // Start with cached version if available
        self.event = eventRepository.event(for: eventId)
    }

    func loadEvent() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            event = try await eventRepository.fetchEvent(id: eventId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

- [ ] **Step 2: Create EventDetailView.swift**

```swift
// bunchabout/bunchabout/Features/EventDetail/EventDetailView.swift
import SwiftUI

struct EventDetailView: View {
    @State private var viewModel: EventDetailViewModel

    init(eventId: String, eventRepository: EventRepository) {
        _viewModel = State(initialValue: EventDetailViewModel(
            eventId: eventId,
            eventRepository: eventRepository
        ))
    }

    var body: some View {
        Group {
            if let event = viewModel.event {
                eventContent(event)
            } else if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                }
            }
        }
        .navigationTitle(viewModel.event?.title ?? "Event")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadEvent()
        }
    }

    private func eventContent(_ event: Event) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Sizes.spacing16) {
                // Category & Status
                HStack {
                    Label(event.category.displayName, systemImage: event.category.systemImage)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.primary)

                    Spacer()

                    if let status = event.status {
                        Text(statusText(status))
                            .font(.caption.bold())
                            .padding(.horizontal, Sizes.spacing8)
                            .padding(.vertical, Sizes.spacing4)
                            .background(statusColor(status).opacity(0.15))
                            .foregroundStyle(statusColor(status))
                            .clipShape(Capsule())
                    }
                }

                // Title
                Text(event.title)
                    .font(.title2.bold())

                // Date & Time
                if let date = event.date.toDate {
                    Label(date.shortDisplay, systemImage: "calendar")
                        .foregroundStyle(.secondary)
                }

                if let duration = event.duration {
                    Label("\(duration) min", systemImage: "clock")
                        .foregroundStyle(.secondary)
                }

                // Location
                if let location = event.location {
                    Label(location.name, systemImage: "mappin")
                    if let address = location.address {
                        Text(address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, Sizes.spacing32)
                    }
                }

                // Description
                if let description = event.description {
                    Text(description)
                        .padding(.top, Sizes.spacing8)
                }

                Divider()

                // Slots
                if let remaining = event.slotsRemaining, let total = event.totalSlots {
                    HStack {
                        Text("Spots")
                            .font(.headline)
                        Spacer()
                        Text("\(remaining) of \(total) available")
                            .foregroundStyle(remaining > 0 ? .primary : AppColors.error)
                    }
                }

                // Organizer
                if let organizer = event.organizer {
                    VStack(alignment: .leading, spacing: Sizes.spacing8) {
                        Text("Organizer")
                            .font(.headline)

                        HStack(spacing: Sizes.spacing12) {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundStyle(.secondary)

                            Text(organizer.displayName)
                        }
                    }
                }

                // Participants
                if !viewModel.confirmedParticipants.isEmpty {
                    VStack(alignment: .leading, spacing: Sizes.spacing8) {
                        Text("Participants (\(viewModel.confirmedParticipants.count))")
                            .font(.headline)

                        ForEach(viewModel.confirmedParticipants) { participant in
                            HStack(spacing: Sizes.spacing12) {
                                Image(systemName: "person.circle")
                                    .foregroundStyle(.secondary)

                                Text(participant.user.displayName)

                                if participant.slotType == .organizer {
                                    Text("Organizer")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(Sizes.spacing16)
        }
    }

    private func statusText(_ status: EventStatus) -> String {
        switch status {
        case .open: "Open"
        case .full: "Full"
        case .inProgress: "In Progress"
        case .completed: "Completed"
        case .cancelled: "Cancelled"
        }
    }

    private func statusColor(_ status: EventStatus) -> Color {
        switch status {
        case .open: .green
        case .full: .orange
        case .inProgress: .blue
        case .completed: .secondary
        case .cancelled: .red
        }
    }
}
```

- [ ] **Step 3: Build the project**

```bash
cd bunchabout && xcodebuild build -workspace bunchabout.xcworkspace -scheme bunchabout -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Run all tests**

```bash
cd bunchabout && xcodebuild test -workspace bunchabout.xcworkspace -scheme bunchabout -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -30
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add event detail view with read-only event info and participant list"
```

---

### Task 13: Build, Run & Verify

- [ ] **Step 1: Build and launch on simulator**

```bash
cd bunchabout && xcodebuild build -workspace bunchabout.xcworkspace -scheme bunchabout -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -10
```

- [ ] **Step 2: Manual verification checklist**

Open the app in Simulator and verify:

1. App launches → shows login screen (or loading spinner briefly then login)
2. "Sign In" button is disabled when fields are empty
3. Tap "Sign Up" → navigates to sign up screen with 3 fields
4. Tap back → returns to login
5. Tap "Forgot Password?" → navigates to forgot password screen
6. Sign up with a new account → app transitions to feed tab
7. Feed shows location permission prompt (or loads events if already granted)
8. Profile tab shows display name and Sign Out button
9. Sign out → returns to login screen
10. Sign in with the account just created → feed loads

- [ ] **Step 3: Run full test suite**

```bash
cd bunchabout && xcodebuild test -workspace bunchabout.xcworkspace -scheme bunchabout -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E 'Test (Suite|Case|Passed|Failed|session)'
```

Expected: All test suites pass.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: milestone 1 and 2 complete — auth flow and event feed"
```
