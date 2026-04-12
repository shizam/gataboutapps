# Gatabout iOS — Project Status

> Last updated: 2026-04-12

## What This Is

iOS app for the lfourg social coordination platform. Users create location-based events, discover nearby events, join/chat/rate each other. The fullstack backend (Firebase + GraphQL) lives at `../lfourg/`. The contract/spec lives at `../lfourg/contract/`.

## Architecture

**MVVM** with explicit dependency injection. No singletons, no DI container.

```
Views (SwiftUI) → ViewModels (@Observable) → Repositories → GraphQLClient (URLSession)
                                                           → AuthService (Firebase Auth)
```

**Key decision:** Firebase Auth SDK for token minting only. Everything else goes through our custom GraphQL networking layer (URLSession). No Apollo, no Firebase Firestore SDK yet.

**Project settings:**
- iOS 26.4 deployment target
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (everything is implicitly @MainActor)
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- Firebase via **CocoaPods** (not SPM — switched due to SPM build/startup issues)
- Must use `gatabout.xcworkspace` (not .xcodeproj) due to CocoaPods

## What's Built (Milestone 1: Sign In + Feed)

### Files

```
ios/gatabout/gatabout/
├── App/
│   ├── AppConfig.swift              # GraphQL URL (https://lfourg-a6fe3.web.app/graphql)
│   ├── AppDelegate.swift            # UIApplicationDelegate, calls FirebaseApp.configure()
│   ├── GataboutApp.swift            # @main, creates AppServices lazily via .task
│   └── RootView.swift               # Auth-gated navigation: unknown→loading, loggedOut→login, loggedIn→feed
├── Core/
│   ├── Auth/
│   │   └── AuthService.swift        # Firebase Auth wrapper, publishes AuthState, provides ID tokens
│   └── Network/
│       ├── GraphQLClient.swift      # URLSession POST to /graphql, Bearer token injection, Codable decoding
│       └── GraphQLError.swift       # Typed error enum (network, http, decoding, graphQL, unauthenticated)
├── Models/
│   ├── User.swift                   # Partial user (id, displayName, photoURL)
│   ├── Event.swift                  # Event + EventLocation + all enums (ActivityCategory, EventStatus, etc.)
│   └── Feed.swift                   # EventConnection, EventEdge, PageInfo, FeedSort
├── Repositories/
│   └── EventRepository.swift        # feed() query with pagination
├── Features/
│   ├── Auth/
│   │   ├── LoginView.swift          # Email/password sign-in form
│   │   └── LoginViewModel.swift     # Sign-in logic, Firebase error mapping
│   └── Feed/
│       ├── EventCardView.swift      # Single event card (category, title, date, location, slots, organizer)
│       ├── EventListView.swift      # Scrollable list with pagination
│       ├── FeedView.swift           # Main feed screen with loading/error/empty states
│       └── FeedViewModel.swift      # Feed loading, pagination, location handling
└── Shared/
    ├── EmptyStateView.swift         # Reusable empty state (icon + title + message)
    ├── ErrorStateView.swift         # Reusable error state (icon + message + retry)
    ├── LocationManager.swift        # CoreLocation wrapper, permission handling
    └── Sizes.swift                  # Layout constants (padding, spacing, corners, icons, shadows)
```

### Dependency Flow

```
AppDelegate
  └── FirebaseApp.configure()

GataboutApp (deferred via .task)
  └── AppServices
        ├── AuthService (Firebase Auth)
        ├── GraphQLClient (needs AuthService for tokens)
        ├── EventRepository (needs GraphQLClient)
        └── LocationManager (CoreLocation)

RootView (observes AuthService.state)
  ├── .loggedOut → LoginView(authService:)
  │                 └── LoginViewModel(authService:)
  └── .loggedIn  → FeedView(eventRepository:, locationManager:)
                    └── FeedViewModel(eventRepository:, locationManager:)
```

## Current State: NEEDS TESTING

The app builds successfully (`BUILD SUCCEEDED`). It has NOT been fully tested in the simulator yet. The login flow and feed display need manual verification.

### Known Issues

1. **Simulator startup is slow (~30-60s)** — This is LLDB debugger overhead attaching to Firebase's Obj-C runtime, NOT our code. Our init completes in ~20ms, auth state resolves in ~300ms. On a real device in release mode it will be fast. No fix available — this is a known Firebase + LLDB issue.

2. **"Couldn't find the Objective-C runtime library" log** — LLDB debugger warning, harmless. Appears in simulator, not a real error.

3. **GoogleUtilities swizzler warning may still appear** — We've added `GoogleUtilitiesAppDelegateProxyEnabled = NO` and `FirebaseAppDelegateProxyEnabled = NO` to Info.plist keys, and moved `FirebaseApp.configure()` to `AppDelegate.didFinishLaunchingWithOptions`. If the warning still shows, it's a timing issue with SwiftUI's delegate registration — functionally harmless.

4. **SourceKit diagnostics show false errors** — "Cannot find type in scope", "No such module 'FirebaseAuth'" etc. These are SourceKit/LSP issues because it can't resolve CocoaPods modules. The project builds fine in Xcode. Building the project (Cmd+B) updates the index and clears most of these.

### What Hasn't Been Tested Yet

- [ ] Sign in with valid credentials → transitions to feed
- [ ] Sign in with invalid credentials → shows error message
- [ ] Feed loads events from the GraphQL API
- [ ] Location permission prompt appears
- [ ] Feed shows empty state when no events nearby
- [ ] Pull-to-refresh works
- [ ] Pagination (scroll to bottom loads more)
- [ ] Sign out (not implemented in UI yet — no button)

## What's Deferred (Future Milestones)

- Sign up / account creation
- Profile creation (createProfile onboarding)
- Event detail screen
- Event creation
- Chat (requires Firestore SDK — will add later)
- Notifications (requires Firestore SDK — will add later)
- Friends, ratings, reporting
- Map view (Apple MapKit)
- Image upload / avatars (requires Firebase Storage SDK)
- Caching / offline support
- Deep linking
- Search / filter UI (categories, radius, sort)

## Backend Context

- Firebase project: `lfourg-a6fe3`
- GraphQL endpoint: `https://lfourg-a6fe3.web.app/graphql`
- Auth: Firebase Auth, email/password only (no OAuth in v1)
- Chat: Firestore-native (NOT GraphQL) — direct `onSnapshot` listeners
- Notifications: Firestore-native, in-app only (no FCM push in v1)
- Full contract/spec: `../lfourg/contract/`
- Schema: `../lfourg/contract/schema.graphql`

## Code Quality

Reviewed against:
- **swift-concurrency-pro** — `isolated deinit`, CancellationError handling, proper @MainActor usage
- **swiftui-pro** — Modern APIs (.clipShape(.rect), foregroundStyle), extracted sub-views, accessibility (decorative images hidden from VoiceOver), Sizes constants for all layout values

## Skills Available

These skills are installed and should be used when writing/reviewing Swift code:
- `swift-concurrency-pro` (~/.claude/skills/) — Swift 6.2 concurrency correctness
- `swiftui-pro` (~/.claude/skills/) — SwiftUI best practices, modern APIs
- `swift-testing-pro` (~/.claude/skills/) — Swift Testing framework
- `swiftui-pro` (.agents/skills/) — Also in project (Paul Hudson's version)
- `axiom-swift-concurrency` (Axiom plugin) — Additional concurrency patterns
