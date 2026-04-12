# iOS Foundation: Sign In + Events Feed — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first working iOS screen flow — email/password sign-in via Firebase Auth, then a nearby events feed via custom GraphQL networking layer.

**Architecture:** MVVM with three layers. Views (SwiftUI) observe ViewModels (`@Observable`), ViewModels call Repositories for data, Repositories call a `GraphQLClient` (URLSession) for network requests. `AuthService` wraps Firebase Auth and provides ID tokens to `GraphQLClient`. Dependencies flow downward via explicit init injection — no singletons, no DI container, no environment trickery.

**Tech Stack:** Swift, SwiftUI, Firebase Auth SDK (via SPM), URLSession, CoreLocation, `@Observable` (Observation framework), structured concurrency (async/await)

---

## MVVM Layer Responsibilities

```
┌─────────────────────────────────────────────────────────┐
│  Views (SwiftUI structs)                                │
│  - Render state from ViewModel                          │
│  - Forward user actions to ViewModel methods            │
│  - Own their ViewModel via @State                       │
│  - No business logic, no network calls, no formatting   │
│  - Receive dependencies in init, pass to ViewModel      │
└──────────────────────┬──────────────────────────────────┘
                       │ observes (@Observable)
┌──────────────────────▼──────────────────────────────────┐
│  ViewModels (@Observable @MainActor classes)             │
│  - Own all view state: loading, error, data             │
│  - Expose actions: signIn(), loadFeed(), loadMore()     │
│  - Call Repositories, never see GraphQL strings          │
│  - Format data for display if needed                    │
│  - One ViewModel per screen                             │
└──────────────────────┬──────────────────────────────────┘
                       │ calls
┌──────────────────────▼──────────────────────────────────┐
│  Repositories (plain classes)                            │
│  - Own GraphQL query strings as private constants        │
│  - Call GraphQLClient.execute(), return domain Models    │
│  - One repository per domain (EventRepository, etc.)    │
│  - No protocols — concrete classes                      │
│  - Define response wrapper structs for Codable decoding │
└──────────────────────┬──────────────────────────────────┘
                       │ calls
┌──────────────────────▼──────────────────────────────────┐
│  GraphQLClient (plain class)                             │
│  - Wraps URLSession for POST requests to /graphql       │
│  - Gets Firebase ID token from AuthService               │
│  - Injects Authorization: Bearer header                  │
│  - Decodes GraphQL JSON response with Codable            │
│  - Surfaces errors as typed GraphQLError                  │
└──────────────────────┬──────────────────────────────────┘
                       │ gets token from
┌──────────────────────▼──────────────────────────────────┐
│  AuthService (@Observable @MainActor class)               │
│  - Wraps Firebase Auth SDK                                │
│  - Publishes auth state: .unknown / .loggedOut / .loggedIn│
│  - signIn(email:password:), signOut(), getIDToken()       │
│  - Drives root-level navigation                           │
└─────────────────────────────────────────────────────────┘
```

**Dependency flow at app startup:**

```
GataboutApp (creates everything once)
  ├── authService = AuthService()
  ├── graphQLClient = GraphQLClient(authService: authService)
  ├── eventRepository = EventRepository(client: graphQLClient)
  ├── locationManager = LocationManager()
  └── RootView observes authService.state:
        ├── .loggedOut → LoginView(authService:)
        │                 └── creates LoginViewModel(authService:)
        └── .loggedIn  → FeedView(eventRepository:, locationManager:)
                          └── creates FeedViewModel(eventRepository:, locationManager:)
```

---

## File Map

All paths relative to `ios/gatabout/gatabout/`.

| File | Action | Purpose |
|------|--------|---------|
| `App/GataboutApp.swift` | Rewrite | Entry point, creates services, FirebaseApp.configure() |
| `App/RootView.swift` | Create | Auth-gated navigation switch |
| `App/AppConfig.swift` | Create | GraphQL URL constant |
| `Core/Auth/AuthService.swift` | Create | Firebase Auth wrapper |
| `Core/Network/GraphQLClient.swift` | Create | URLSession GraphQL client |
| `Core/Network/GraphQLError.swift` | Create | Error types |
| `Models/User.swift` | Create | User Codable struct |
| `Models/Event.swift` | Create | Event + enums Codable structs |
| `Models/Feed.swift` | Create | EventConnection/Edge/PageInfo |
| `Repositories/EventRepository.swift` | Create | Feed query |
| `Features/Auth/LoginView.swift` | Create | Sign-in screen UI |
| `Features/Auth/LoginViewModel.swift` | Create | Sign-in logic |
| `Features/Feed/FeedView.swift` | Create | Events list screen |
| `Features/Feed/FeedViewModel.swift` | Create | Feed loading + pagination |
| `Features/Feed/EventCardView.swift` | Create | Single event card |
| `Shared/Sizes.swift` | Create | Layout constants |
| `Shared/LocationManager.swift` | Create | CoreLocation wrapper |
| `ContentView.swift` | Delete | Replaced by RootView |
| `GoogleService-Info.plist` | Copy from ~/Downloads/ | Firebase config |

---

### Task 1: Project Setup

**Files:**
- Copy: `~/Downloads/GoogleService-Info.plist` → `ios/gatabout/gatabout/GoogleService-Info.plist`
- Delete: `ios/gatabout/gatabout/ContentView.swift`
- Create directories under `ios/gatabout/gatabout/`

- [ ] **Step 1: Create directory structure**

```bash
cd ios/gatabout/gatabout
mkdir -p App Core/Auth Core/Network Models Repositories Features/Auth Features/Feed Shared
```

- [ ] **Step 2: Copy GoogleService-Info.plist**

```bash
cp ~/Downloads/GoogleService-Info.plist ios/gatabout/gatabout/GoogleService-Info.plist
```

- [ ] **Step 3: Delete ContentView.swift**

```bash
rm ios/gatabout/gatabout/ContentView.swift
```

- [ ] **Step 4: Move gataboutApp.swift to App/**

```bash
mv ios/gatabout/gatabout/gataboutApp.swift ios/gatabout/gatabout/App/GataboutApp.swift
```

- [ ] **Step 5: Add Firebase Auth SPM dependency**

Open the Xcode project. Go to File → Add Package Dependencies. Enter:
```
https://github.com/firebase/firebase-ios-sdk
```
Select version "Up to Next Major" from the latest release. Add only the **FirebaseAuth** library to the `gatabout` target.

- [ ] **Step 6: Add location permission to build settings**

In Xcode, select the `gatabout` target → Info tab → Custom iOS Target Properties. Add:
- Key: `Privacy - Location When In Use Usage Description`
- Value: `Gatabout needs your location to find events near you.`

Also ensure `GoogleService-Info.plist` is added to the target's "Copy Bundle Resources" build phase (drag it into the Xcode project navigator under the gatabout group if needed).

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "chore: project setup — directories, Firebase config, SPM dependency"
```

---

### Task 2: Sizes + AppConfig

**Files:**
- Create: `ios/gatabout/gatabout/Shared/Sizes.swift`
- Create: `ios/gatabout/gatabout/App/AppConfig.swift`

- [ ] **Step 1: Create Sizes.swift**

```swift
import SwiftUI

enum Sizes {
    // MARK: - Padding
    static let padding4: CGFloat = 4
    static let padding8: CGFloat = 8
    static let padding12: CGFloat = 12
    static let padding16: CGFloat = 16
    static let padding20: CGFloat = 20
    static let padding24: CGFloat = 24
    static let padding32: CGFloat = 32
    static let padding48: CGFloat = 48

    // MARK: - Spacing (VStack/HStack)
    static let spacing4: CGFloat = 4
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing24: CGFloat = 24

    // MARK: - Corner Radius
    static let cornerRadius4: CGFloat = 4
    static let cornerRadius8: CGFloat = 8
    static let cornerRadius12: CGFloat = 12
    static let cornerRadius16: CGFloat = 16

    // MARK: - Component Heights
    static let buttonHeight: CGFloat = 48
    static let textFieldHeight: CGFloat = 48

    // MARK: - Icon Sizes
    static let iconSize16: CGFloat = 16
    static let iconSize20: CGFloat = 20
    static let iconSize24: CGFloat = 24
    static let iconSize32: CGFloat = 32
    static let iconSize40: CGFloat = 40

    // MARK: - Avatar Sizes
    static let avatarSmall: CGFloat = 32
    static let avatarMedium: CGFloat = 40
}
```

- [ ] **Step 2: Create AppConfig.swift**

```swift
import Foundation

enum AppConfig {
    static let graphQLURL = URL(string: "https://lfourg-a6fe3.web.app/graphql")!
}
```

- [ ] **Step 3: Build to verify compilation**

```bash
xcodebuild -project ios/gatabout/gatabout.xcodeproj -scheme gatabout -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

Expect: build errors from GataboutApp.swift referencing deleted ContentView — that's fine, we'll rewrite it in Task 10.

- [ ] **Step 4: Commit**

```bash
git add ios/gatabout/gatabout/Shared/Sizes.swift ios/gatabout/gatabout/App/AppConfig.swift
git commit -m "feat: add Sizes layout constants and AppConfig"
```

---

### Task 3: AuthService

**Files:**
- Create: `ios/gatabout/gatabout/Core/Auth/AuthService.swift`

- [ ] **Step 1: Create AuthService.swift**

```swift
import FirebaseAuth
import Observation

enum AuthState: Equatable {
    case unknown
    case loggedOut
    case loggedIn
}

@Observable
@MainActor
final class AuthService {
    private(set) var state: AuthState = .unknown

    private var handle: AuthStateDidChangeListenerHandle?
    private var currentUser: FirebaseAuth.User?

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.state = user != nil ? .loggedIn : .loggedOut
            }
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

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func getIDToken() async throws -> String {
        guard let user = currentUser else {
            throw AuthServiceError.notAuthenticated
        }
        guard let token = try await user.getIDToken() as String? else {
            throw AuthServiceError.notAuthenticated
        }
        return token
    }
}

enum AuthServiceError: Error, LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not signed in"
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add ios/gatabout/gatabout/Core/Auth/AuthService.swift
git commit -m "feat: add AuthService — Firebase Auth wrapper with state publishing"
```

---

### Task 4: GraphQLClient

**Files:**
- Create: `ios/gatabout/gatabout/Core/Network/GraphQLError.swift`
- Create: `ios/gatabout/gatabout/Core/Network/GraphQLClient.swift`

- [ ] **Step 1: Create GraphQLError.swift**

```swift
import Foundation

struct GraphQLResponseError: Decodable, Sendable {
    let message: String
    let extensions: Extensions?

    struct Extensions: Decodable, Sendable {
        let code: String?
    }
}

enum GraphQLError: Error, LocalizedError {
    case networkError(Error)
    case httpError(statusCode: Int)
    case decodingError(Error)
    case graphQLErrors([GraphQLResponseError])
    case noData
    case unauthenticated

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let code):
            return "Server error (HTTP \(code))"
        case .decodingError(let error):
            return "Data error: \(error.localizedDescription)"
        case .graphQLErrors(let errors):
            return errors.first?.message ?? "Unknown error"
        case .noData:
            return "No data returned"
        case .unauthenticated:
            return "Please sign in again"
        }
    }
}
```

- [ ] **Step 2: Create GraphQLClient.swift**

```swift
import Foundation

final class GraphQLClient {
    private let url: URL
    private let authService: AuthService
    private let session: URLSession

    init(authService: AuthService, url: URL = AppConfig.graphQLURL) {
        self.authService = authService
        self.url = url
        self.session = .shared
    }

    /// Execute a GraphQL query or mutation.
    /// `T` is the shape of the `data` field in the response —
    /// e.g. `struct FeedResponse: Decodable { let feed: EventConnection }`.
    func execute<T: Decodable>(
        query: String,
        variables: [String: Any]? = nil,
        as type: T.Type
    ) async throws -> T {
        let token: String
        do {
            token = try await authService.getIDToken()
        } catch {
            throw GraphQLError.unauthenticated
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "query": query,
            "variables": variables ?? [:]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let responseData: Data
        let response: URLResponse
        do {
            (responseData, response) = try await session.data(for: request)
        } catch {
            throw GraphQLError.networkError(error)
        }

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            if httpResponse.statusCode == 401 {
                throw GraphQLError.unauthenticated
            }
            throw GraphQLError.httpError(statusCode: httpResponse.statusCode)
        }

        let graphQLResponse: GraphQLResponse<T>
        do {
            graphQLResponse = try JSONDecoder().decode(GraphQLResponse<T>.self, from: responseData)
        } catch {
            throw GraphQLError.decodingError(error)
        }

        if let errors = graphQLResponse.errors, !errors.isEmpty {
            if errors.contains(where: { $0.extensions?.code == "UNAUTHENTICATED" }) {
                throw GraphQLError.unauthenticated
            }
            throw GraphQLError.graphQLErrors(errors)
        }

        guard let data = graphQLResponse.data else {
            throw GraphQLError.noData
        }

        return data
    }
}

// MARK: - Response wrapper

private struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLResponseError]?
}
```

- [ ] **Step 3: Commit**

```bash
git add ios/gatabout/gatabout/Core/Network/
git commit -m "feat: add GraphQLClient — URLSession-based GraphQL networking layer"
```

---

### Task 5: Models

**Files:**
- Create: `ios/gatabout/gatabout/Models/User.swift`
- Create: `ios/gatabout/gatabout/Models/Event.swift`
- Create: `ios/gatabout/gatabout/Models/Feed.swift`

- [ ] **Step 1: Create User.swift**

Only the fields we need for this milestone (organizer display on event cards).

```swift
import Foundation

struct User: Decodable, Identifiable, Sendable {
    let id: String
    let displayName: String
    let photoURL: String?
}
```

- [ ] **Step 2: Create Event.swift**

```swift
import Foundation

// MARK: - Enums

enum ActivityCategory: String, Codable, CaseIterable, Sendable {
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

enum EventStatus: String, Codable, Sendable {
    case open = "OPEN"
    case full = "FULL"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"
}

enum FillMode: String, Codable, Sendable {
    case firstComeFirstServed = "FIRST_COME_FIRST_SERVED"
    case approvalRequired = "APPROVAL_REQUIRED"

    var displayName: String {
        switch self {
        case .firstComeFirstServed: "First Come First Served"
        case .approvalRequired: "Approval Required"
        }
    }

    var shortName: String {
        switch self {
        case .firstComeFirstServed: "Open"
        case .approvalRequired: "Approval"
        }
    }
}

enum Visibility: String, Codable, Sendable {
    case `public` = "PUBLIC"
    case friendsOnly = "FRIENDS_ONLY"
}

enum ParticipantStatus: String, Codable, Sendable {
    case invited = "INVITED"
    case requested = "REQUESTED"
    case confirmed = "CONFIRMED"
    case declined = "DECLINED"
    case waitlisted = "WAITLISTED"
    case left = "LEFT"
    case removed = "REMOVED"
}

// MARK: - Models

struct Event: Decodable, Identifiable, Sendable {
    let id: String
    let title: String
    let description: String?
    let category: ActivityCategory
    let date: String
    let time: String?
    let duration: Int?
    let status: EventStatus
    let totalSlots: Int
    let slotsRemaining: Int
    let fillMode: FillMode
    let visibility: Visibility
    let location: EventLocation?
    let organizer: User
    let myParticipantStatus: ParticipantStatus?
}

struct EventLocation: Decodable, Sendable {
    let name: String
    let address: String?
    let lat: Double
    let lng: Double
    let radius: Double
    let placeId: String?
}
```

- [ ] **Step 3: Create Feed.swift**

```swift
import Foundation

struct EventConnection: Decodable, Sendable {
    let edges: [EventEdge]
    let pageInfo: PageInfo
    let totalCount: Int
}

struct EventEdge: Decodable, Identifiable, Sendable {
    let node: Event
    let cursor: String
    let distance: Double?
    let score: Double?

    var id: String { node.id }
}

struct PageInfo: Decodable, Sendable {
    let hasNextPage: Bool
    let endCursor: String?
}

enum FeedSort: String, Codable, Sendable {
    case score = "SCORE"
    case date = "DATE"
    case distance = "DISTANCE"
}
```

- [ ] **Step 4: Commit**

```bash
git add ios/gatabout/gatabout/Models/
git commit -m "feat: add domain models — User, Event, Feed types matching GraphQL schema"
```

---

### Task 6: EventRepository

**Files:**
- Create: `ios/gatabout/gatabout/Repositories/EventRepository.swift`

- [ ] **Step 1: Create EventRepository.swift**

```swift
import Foundation

final class EventRepository {
    private let client: GraphQLClient

    init(client: GraphQLClient) {
        self.client = client
    }

    func feed(
        lat: Double,
        lng: Double,
        radius: Double = 10,
        cursor: String? = nil,
        limit: Int = 20
    ) async throws -> EventConnection {
        var variables: [String: Any] = [
            "location": ["lat": lat, "lng": lng],
            "radius": radius,
            "limit": limit
        ]
        if let cursor {
            variables["cursor"] = cursor
        }

        let response = try await client.execute(
            query: Self.feedQuery,
            variables: variables,
            as: FeedResponse.self
        )
        return response.feed
    }
}

// MARK: - Response wrappers

private extension EventRepository {
    struct FeedResponse: Decodable {
        let feed: EventConnection
    }
}

// MARK: - Queries

private extension EventRepository {
    static let feedQuery = """
        query Feed($location: LocationInput!, $radius: Float, $cursor: String, $limit: Int) {
          feed(location: $location, radius: $radius, cursor: $cursor, limit: $limit) {
            edges {
              node {
                id
                title
                description
                category
                date
                time
                duration
                status
                totalSlots
                slotsRemaining
                fillMode
                visibility
                location {
                  name
                  address
                  lat
                  lng
                  radius
                }
                organizer {
                  id
                  displayName
                  photoURL
                }
                myParticipantStatus
              }
              cursor
              distance
              score
            }
            pageInfo {
              hasNextPage
              endCursor
            }
            totalCount
          }
        }
        """
}
```

- [ ] **Step 2: Commit**

```bash
git add ios/gatabout/gatabout/Repositories/EventRepository.swift
git commit -m "feat: add EventRepository with feed query"
```

---

### Task 7: LocationManager

**Files:**
- Create: `ios/gatabout/gatabout/Shared/LocationManager.swift`

- [ ] **Step 1: Create LocationManager.swift**

```swift
import CoreLocation
import Observation

@Observable
@MainActor
final class LocationManager: NSObject {
    private(set) var currentLocation: CLLocationCoordinate2D?
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var error: String?

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
        error = nil
        manager.requestLocation()
    }

    var hasPermission: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var needsPermissionRequest: Bool {
        authorizationStatus == .notDetermined
    }
}

extension LocationManager: @preconcurrency CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last?.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = "Unable to determine location"
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if hasPermission {
            manager.requestLocation()
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add ios/gatabout/gatabout/Shared/LocationManager.swift
git commit -m "feat: add LocationManager — CoreLocation wrapper"
```

---

### Task 8: Login Feature

**Files:**
- Create: `ios/gatabout/gatabout/Features/Auth/LoginViewModel.swift`
- Create: `ios/gatabout/gatabout/Features/Auth/LoginView.swift`

- [ ] **Step 1: Create LoginViewModel.swift**

```swift
import FirebaseAuth
import Observation

@Observable
@MainActor
final class LoginViewModel {
    var email = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    func signIn() async {
        guard isFormValid else {
            errorMessage = "Please enter your email and password."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.signIn(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
        } catch {
            errorMessage = Self.friendlyError(error)
        }

        isLoading = false
    }

    private static func friendlyError(_ error: Error) -> String {
        let code = AuthErrorCode(_nsError: error as NSError).code
        switch code {
        case .invalidEmail:
            return "Invalid email address."
        case .wrongPassword, .invalidCredential:
            return "Incorrect email or password."
        case .userNotFound:
            return "No account found with this email."
        case .networkError:
            return "Network error. Please try again."
        case .tooManyRequests:
            return "Too many attempts. Please wait and try again."
        default:
            return error.localizedDescription
        }
    }
}
```

- [ ] **Step 2: Create LoginView.swift**

```swift
import SwiftUI

struct LoginView: View {
    @State private var viewModel: LoginViewModel

    init(authService: AuthService) {
        _viewModel = State(initialValue: LoginViewModel(authService: authService))
    }

    var body: some View {
        VStack(spacing: Sizes.spacing24) {
            Spacer()

            Text("gatabout")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: Sizes.spacing16) {
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .frame(height: Sizes.textFieldHeight)

                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
                    .frame(height: Sizes.textFieldHeight)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
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
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: Sizes.buttonHeight)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isFormValid || viewModel.isLoading)

            Spacer()
        }
        .padding(.horizontal, Sizes.padding24)
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add ios/gatabout/gatabout/Features/Auth/
git commit -m "feat: add LoginView + LoginViewModel — email/password sign-in"
```

---

### Task 9: Feed Feature

**Files:**
- Create: `ios/gatabout/gatabout/Features/Feed/EventCardView.swift`
- Create: `ios/gatabout/gatabout/Features/Feed/FeedViewModel.swift`
- Create: `ios/gatabout/gatabout/Features/Feed/FeedView.swift`

- [ ] **Step 1: Create EventCardView.swift**

```swift
import SwiftUI

struct EventCardView: View {
    let edge: EventEdge

    private var event: Event { edge.node }

    var body: some View {
        VStack(alignment: .leading, spacing: Sizes.spacing8) {
            // Category + Status
            HStack(spacing: Sizes.spacing8) {
                Label(event.category.displayName, systemImage: event.category.systemImage)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, Sizes.padding8)
                    .padding(.vertical, Sizes.padding4)
                    .background(.tint.opacity(0.1))
                    .clipShape(Capsule())

                Spacer()

                Text(event.fillMode.shortName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            // Title
            Text(event.title)
                .font(.headline)
                .lineLimit(2)

            // Date + Time
            HStack(spacing: Sizes.spacing4) {
                Image(systemName: "calendar")
                    .font(.system(size: Sizes.iconSize16))
                Text(Self.formatDate(event.date))
                if let time = event.time {
                    Text("at \(time)")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            // Location + Distance
            HStack(spacing: Sizes.spacing4) {
                Image(systemName: "mappin")
                    .font(.system(size: Sizes.iconSize16))
                if let location = event.location {
                    Text(location.name)
                        .lineLimit(1)
                }
                if let distance = edge.distance {
                    Text("·")
                    Text(Self.formatDistance(distance))
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            // Bottom row: Slots + Organizer
            HStack {
                Label("\(event.slotsRemaining)/\(event.totalSlots) spots",
                      systemImage: "person.2")
                    .font(.caption)
                    .foregroundStyle(event.slotsRemaining > 0 ? .primary : .red)

                Spacer()

                Text("by \(event.organizer.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Sizes.padding16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadius12))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }

    private static func formatDistance(_ miles: Double) -> String {
        if miles < 0.1 {
            return "Nearby"
        } else if miles < 10 {
            return String(format: "%.1f mi", miles)
        } else {
            return String(format: "%.0f mi", miles)
        }
    }

    private static func formatDate(_ isoString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = isoFormatter.date(from: isoString) else {
            // Try without fractional seconds
            isoFormatter.formatOptions = [.withInternetDateTime]
            guard let date = isoFormatter.date(from: isoString) else {
                return isoString
            }
            return Self.displayFormatter.string(from: date)
        }
        return displayFormatter.string(from: date)
    }

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
}
```

- [ ] **Step 2: Create FeedViewModel.swift**

```swift
import CoreLocation
import Observation

@Observable
@MainActor
final class FeedViewModel {
    private(set) var events: [EventEdge] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var errorMessage: String?
    private(set) var hasMorePages = false

    private let eventRepository: EventRepository
    private let locationManager: LocationManager
    private var endCursor: String?

    init(eventRepository: EventRepository, locationManager: LocationManager) {
        self.eventRepository = eventRepository
        self.locationManager = locationManager
    }

    func loadFeed() async {
        guard let location = locationManager.currentLocation else {
            if locationManager.needsPermissionRequest {
                locationManager.requestPermission()
            } else if locationManager.hasPermission {
                locationManager.requestLocation()
            } else {
                errorMessage = "Location access is required to find events near you. Please enable it in Settings."
            }
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let connection = try await eventRepository.feed(
                lat: location.latitude,
                lng: location.longitude
            )
            events = connection.edges
            endCursor = connection.pageInfo.endCursor
            hasMorePages = connection.pageInfo.hasNextPage
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadMore() async {
        guard hasMorePages, !isLoadingMore, let cursor = endCursor,
              let location = locationManager.currentLocation else { return }

        isLoadingMore = true

        do {
            let connection = try await eventRepository.feed(
                lat: location.latitude,
                lng: location.longitude,
                cursor: cursor
            )
            events.append(contentsOf: connection.edges)
            endCursor = connection.pageInfo.endCursor
            hasMorePages = connection.pageInfo.hasNextPage
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingMore = false
    }

    func retry() async {
        await loadFeed()
    }
}
```

- [ ] **Step 3: Create FeedView.swift**

```swift
import SwiftUI

struct FeedView: View {
    @State private var viewModel: FeedViewModel
    private let locationManager: LocationManager

    init(eventRepository: EventRepository, locationManager: LocationManager) {
        self.locationManager = locationManager
        _viewModel = State(initialValue: FeedViewModel(
            eventRepository: eventRepository,
            locationManager: locationManager
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.events.isEmpty {
                    ProgressView("Finding events near you...")
                } else if let error = viewModel.errorMessage, viewModel.events.isEmpty {
                    errorView(error)
                } else if viewModel.events.isEmpty {
                    emptyView
                } else {
                    eventList
                }
            }
            .navigationTitle("Events")
            .task {
                await viewModel.loadFeed()
            }
            .onChange(of: locationManager.currentLocation != nil) {
                if locationManager.currentLocation != nil && viewModel.events.isEmpty {
                    Task { await viewModel.loadFeed() }
                }
            }
        }
    }

    private var eventList: some View {
        ScrollView {
            LazyVStack(spacing: Sizes.spacing12) {
                ForEach(viewModel.events) { edge in
                    EventCardView(edge: edge)
                }

                if viewModel.hasMorePages {
                    ProgressView()
                        .padding(Sizes.padding16)
                        .task {
                            await viewModel.loadMore()
                        }
                }
            }
            .padding(.horizontal, Sizes.padding16)
            .padding(.vertical, Sizes.padding8)
        }
        .refreshable {
            await viewModel.loadFeed()
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: Sizes.spacing16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: Sizes.iconSize40))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.retry() }
            }
            .buttonStyle(.bordered)
        }
        .padding(Sizes.padding32)
    }

    private var emptyView: some View {
        VStack(spacing: Sizes.spacing16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: Sizes.iconSize40))
                .foregroundStyle(.secondary)
            Text("No events nearby")
                .font(.headline)
            Text("Check back soon or expand your search radius.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Sizes.padding32)
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add ios/gatabout/gatabout/Features/Feed/
git commit -m "feat: add FeedView + FeedViewModel + EventCardView — events feed with pagination"
```

---

### Task 10: App Wiring

**Files:**
- Rewrite: `ios/gatabout/gatabout/App/GataboutApp.swift`
- Create: `ios/gatabout/gatabout/App/RootView.swift`

- [ ] **Step 1: Create RootView.swift**

```swift
import SwiftUI

struct RootView: View {
    let authService: AuthService
    let eventRepository: EventRepository
    let locationManager: LocationManager

    var body: some View {
        Group {
            switch authService.state {
            case .unknown:
                ProgressView()
            case .loggedOut:
                LoginView(authService: authService)
            case .loggedIn:
                FeedView(
                    eventRepository: eventRepository,
                    locationManager: locationManager
                )
            }
        }
        .animation(.default, value: authService.state)
    }
}
```

- [ ] **Step 2: Rewrite GataboutApp.swift**

Replace the entire contents of `ios/gatabout/gatabout/App/GataboutApp.swift`:

```swift
import FirebaseCore
import SwiftUI

@main
struct GataboutApp: App {
    private let authService: AuthService
    private let graphQLClient: GraphQLClient
    private let eventRepository: EventRepository
    private let locationManager: LocationManager

    init() {
        FirebaseApp.configure()

        let auth = AuthService()
        let client = GraphQLClient(authService: auth)

        self.authService = auth
        self.graphQLClient = client
        self.eventRepository = EventRepository(client: client)
        self.locationManager = LocationManager()
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                authService: authService,
                eventRepository: eventRepository,
                locationManager: locationManager
            )
        }
    }
}
```

- [ ] **Step 3: Build the project**

```bash
xcodebuild -project ios/gatabout/gatabout.xcodeproj -scheme gatabout -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20
```

Expected: BUILD SUCCEEDED. If there are compilation errors, fix them before proceeding.

- [ ] **Step 4: Run in simulator and verify**

```bash
xcodebuild -project ios/gatabout/gatabout.xcodeproj -scheme gatabout -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Launch the app in the simulator manually. Verify:
1. App launches and shows the LoginView (email + password fields + Sign In button)
2. Entering invalid credentials shows an error message
3. Entering valid credentials transitions to the FeedView
4. FeedView requests location permission
5. After granting location, events load (or empty state shows if no events nearby)

- [ ] **Step 5: Commit**

```bash
git add ios/gatabout/gatabout/App/
git commit -m "feat: wire up app — RootView with auth-gated navigation, Firebase init"
```

---

## Verification Checklist

After all tasks are complete, verify the full flow:

- [ ] App builds without warnings
- [ ] Launch shows login screen
- [ ] Invalid credentials show error (test with bad password)
- [ ] Valid credentials sign in and transition to feed
- [ ] Location permission prompt appears on feed
- [ ] Feed loads events (or shows empty state)
- [ ] Pull-to-refresh works on feed
- [ ] Scroll-to-bottom loads more events (if available)
- [ ] No magic numbers in any SwiftUI layout — all use `Sizes.*` constants
