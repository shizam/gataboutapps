# Bunchabout iOS — Project Status

> Last updated: 2026-04-12

## What This Is

iOS app for the bunchabout social coordination platform. Users create location-based events, discover nearby events, join/chat/rate each other. The fullstack backend (Firebase + GraphQL) lives at `../bunchabout/`. The contract/spec lives at `../bunchabout/contract/`.

## Architecture

**MVVM with repository pattern.** Repositories are `@Observable` and shared via SwiftUI `.environment()`. ViewModels are screen-scoped, created with explicit init injection.

```
Views (SwiftUI) → ViewModels (@Observable) → Repositories → GraphQLClient (URLSession)
                                                           → AuthService (Firebase Auth)
```

**Key decisions:**
- Firebase Auth SDK for token minting only. Everything else goes through our custom GraphQL networking layer (URLSession). No Apollo.
- No Firebase Firestore/Analytics/Crashlytics SDKs — minimum dependencies only.
- Chat/notifications deferred (will require Firestore SDK decision later).

**Project settings:**
- iOS 26.0+ deployment target, Xcode 26.4
- Swift 6.2 with default MainActor isolation (everything implicitly `@MainActor`)
- Approachable concurrency enabled
- Firebase via **CocoaPods** (not SPM — user preference)
- Must use `bunchabout.xcworkspace` (not .xcodeproj) due to CocoaPods

## What's Built (Milestones 1 & 2: Auth + Feed)

### File Structure

```
bunchabout/bunchabout/
├── App/
│   ├── bunchaboutApp.swift           # @main, FirebaseApp.configure(), DI setup via .environment()
│   ├── RootView.swift              # Auth-gated: unknown→ProgressView, signedOut→Login, signedIn→Tabs
│   └── MainTabView.swift           # TabView with Feed + Profile tabs
├── Core/
│   ├── Auth/
│   │   ├── AuthService.swift       # Firebase Auth wrapper, @Observable, AuthState listener
│   │   ├── AuthServiceProtocol.swift  # Protocol for testability
│   │   └── AuthState.swift         # .unknown, .signedIn, .signedOut
│   ├── Networking/
│   │   ├── GraphQLClient.swift     # URLSession POST to /graphql, Bearer token injection
│   │   └── AppError.swift          # .network, .unauthorized, .graphQL, .decoding
│   ├── Theme/
│   │   ├── Sizes.swift             # All layout constants (spacing, corner radii, icons, avatars)
│   │   ├── AppColors.swift         # Semantic colors (primary, error, cardBackground, etc.)
│   │   └── AppTypography.swift     # ViewModifier-based text styles
│   └── Location/
│       └── LocationService.swift   # CoreLocation wrapper, @Observable permission + coords
├── Models/
│   ├── User.swift                  # Most fields optional (GraphQL partial responses)
│   ├── Event.swift                 # Full event with organizer, location, participants
│   ├── EventLocation.swift         # Name, address, lat/lng, radius, placeId
│   ├── EventParticipant.swift      # User + status + slotType
│   ├── Venue.swift                 # Google Places venue + VenuePhoto
│   ├── EventConnection.swift       # Pagination wrapper: edges, pageInfo
│   ├── Trait.swift                 # Name + tier (NORMAL/PROMINENT)
│   ├── Badge.swift                 # Achievement records
│   └── Enums/
│       ├── ActivityCategory.swift  # 14 categories with displayName + systemImage
│       ├── EventStatus.swift       # OPEN, FULL, IN_PROGRESS, COMPLETED, CANCELLED
│       ├── ParticipantStatus.swift # INVITED, REQUESTED, CONFIRMED, etc.
│       ├── FillMode.swift          # FIRST_COME_FIRST_SERVED, APPROVAL_REQUIRED
│       ├── Visibility.swift        # PUBLIC, FRIENDS_ONLY
│       ├── SlotType.swift          # ORGANIZER, FRIEND, OPEN
│       ├── FeedSort.swift          # SCORE, DATE, DISTANCE
│       └── Gender.swift            # MALE, FEMALE, NON_BINARY, PREFER_NOT_TO_SAY
├── Repositories/
│   ├── UserRepository.swift        # @Observable, caches users[id], currentUser
│   ├── UserQueries.swift           # `me`, `user(id:)`, `createProfile` queries + response/variable types
│   ├── EventRepository.swift       # @Observable, feed pagination, event cache
│   └── EventQueries.swift          # `feed`, `event(id:)` queries + types
├── Features/
│   ├── Login/
│   │   ├── LoginView.swift         # Email/password form + links to SignUp/ForgotPassword
│   │   ├── LoginViewModel.swift    # signIn → fetchCurrentUser
│   │   ├── SignUpView.swift        # DisplayName + email + password form
│   │   ├── SignUpViewModel.swift   # signUp → createProfile
│   │   ├── ForgotPasswordView.swift # Email form, success confirmation
│   │   └── ForgotPasswordViewModel.swift
│   ├── Feed/
│   │   ├── FeedView.swift          # Location permission states, list, empty/denied states
│   │   ├── FeedViewModel.swift     # loadFeed, loadNextPage, location resolution
│   │   └── EventCardView.swift     # Category badge, title, venue, date, slots indicator
│   ├── EventDetail/
│   │   ├── EventDetailView.swift   # Read-only event display, status pill, participants list
│   │   └── EventDetailViewModel.swift # Reads from EventRepository cache, fetches if missing
│   └── Profile/
│       └── ProfileView.swift       # Placeholder: display name + sign out button
└── Extensions/
    └── Date+Extensions.swift       # String.toDate (ISO 8601), Date.shortDisplay, relativeDisplay
```

### Tests

20 unit tests across 6 suites, all passing:
- `GraphQLClientTests` (4) — success decoding, GraphQL errors, 401, auth header
- `ModelDecodingTests` (5) — User/Event/EventConnection JSON decoding, ISO 8601 parsing
- `UserRepositoryTests` (3) — fetch + cache, cache hit, createProfile
- `EventRepositoryTests` (3) — feed population, pagination append, event caching
- `LoginViewModelTests` (3) — signIn success, signIn failure, validation
- `FeedViewModelTests` (2) — loadFeed success, loadFeed error

Test helpers in `bunchaboutTests/Helpers/`:
- `MockURLProtocol` (and per-suite variants to avoid cross-suite state collision)
- `MockAuthService` (conforms to `AuthServiceProtocol`)
- `TestHelpers.swift` (`makeTestClient`, `mockResponse`)

### Dependency Flow

```
bunchaboutApp (init)
  ├── FirebaseApp.configure()
  └── Create services:
        ├── AuthService (Firebase Auth state listener)
        ├── GraphQLClient(getToken: authService.getToken)
        ├── UserRepository(client:)
        ├── EventRepository(client:)
        └── LocationService (CoreLocation)
             All injected via .environment()

RootView (observes authService.authState)
  ├── .signedOut → LoginView(authService:, userRepository:)
  └── .signedIn  → MainTabView
                   ├── FeedView(eventRepository:, locationService:)
                   │    └── navigationDestination → EventDetailView(eventId:, eventRepository:)
                   └── ProfileView (pulls services from @Environment)
```

## Current State: NEEDS MANUAL TESTING

The app builds successfully (`** BUILD SUCCEEDED **`) and all 20 unit tests pass. It has NOT been manually verified in the simulator yet.

### What Hasn't Been Tested Yet

- [ ] App launches → shows login screen
- [ ] Sign up with new account → creates profile → transitions to feed
- [ ] Sign in with existing credentials → transitions to feed
- [ ] Sign in with wrong password → shows error message
- [ ] Forgot password → sends reset email
- [ ] Feed requests location permission on first load
- [ ] Feed loads events from the live GraphQL API
- [ ] Tap event card → EventDetailView pushes with full event info
- [ ] Pagination (scroll to bottom loads more)
- [ ] Profile tab shows display name
- [ ] Sign out → returns to login screen
- [ ] Auto-login on relaunch (Firebase persists session)

### Known Issues / Non-Issues

1. **SourceKit IDE diagnostics show false errors** — "Cannot find type in scope", "No such module 'FirebaseAuth'", etc. These appear because SourceKit can't always resolve CocoaPods modules without workspace context. The project builds fine with `xcodebuild`. Trust the build output, not IDE diagnostics.

2. **Simulator launches on every test run** — Unavoidable when running `xcodebuild test`. Use `-disable-concurrent-destination-testing` to avoid launching multiple simulators.

3. **Per-suite mock URL protocols** — Tests use separate URLProtocol subclasses per suite (`MockURLProtocol`, `RepoMockURLProtocol`, `EventMockURLProtocol`, `LoginMockURLProtocol`, `FeedMockURLProtocol`) because Swift Testing runs suites concurrently and a shared static `requestHandler` causes flaky tests.

## What's Deferred (Future Milestones)

### Immediate next candidates
- Event creation (Create Event form + mutation)
- Join/leave events (requestToJoin, respondToRequest, leaveEvent mutations)
- Profile editing (updateProfile, avatar upload)
- Category/date/radius filters on feed
- Pull-to-refresh on feed
- Map view of feed events

### Requires Firestore SDK decision
- Chat (event group chats, 1:1 DMs, multi-person DMs) — Firestore `onSnapshot` listeners
- Notification center — Firestore real-time listener
- When we add these, decide: add Firestore SDK (simplest) vs. build custom WebSocket layer (more work, avoids another Firebase dep)

### Larger features
- Friends system (send/respond/remove friend requests, mutual friends)
- Ratings & reputation (post-event rating wizard, trait tags, badges)
- Reporting & blocking (submit reports, block users)
- Waitlist / friend-reserved slots
- Event invitations

## Backend Context

- Firebase project: `bunchabout`
- GraphQL endpoint: `https://bunchabout.web.app/graphql`
- Auth: Firebase Auth, email/password only (no OAuth in v1)
- Chat: Firestore-native (NOT GraphQL) — direct `onSnapshot` listeners when we build it
- Notifications: Firestore-native, in-app only (no FCM push in v1)
- Full contract/spec: `../bunchabout/contract/`
- Schema: `../bunchabout/contract/schema.graphql`

## Design Docs

- Spec: `docs/superpowers/specs/2026-04-12-ios-architecture-design.md`
- Plan: `docs/superpowers/plans/2026-04-12-ios-auth-and-feed.md`

## Skills to Use

When writing or reviewing Swift code, invoke:
- `swiftui-pro` — SwiftUI best practices, modern iOS 26 APIs
- `swift-concurrency-pro` — Swift 6.2 concurrency correctness
- `swift-testing-pro` — Swift Testing framework
