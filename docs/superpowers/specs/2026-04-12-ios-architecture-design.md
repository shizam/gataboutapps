# gatabout iOS App — Architecture Design Spec

## Overview

Native iOS app for the gatabout (lfourg) social activity coordination platform. Users create and join local events, discover activities via a location-aware feed, coordinate with other participants, and build social trust through ratings and badges.

This spec covers the foundational architecture and first two milestones: authentication and the event feed.

## Decisions

- **MVVM** with `@Observable` ViewModels and Repositories
- **FirebaseAuth SDK** for authentication (only Firebase dependency for now)
- **Custom GraphQL networking layer** — no Apollo, no code generation
- **Repository pattern** with in-memory caches for shared state
- **Chat/notifications deferred** — Firestore SDK decision made when needed
- **iOS 26 / Swift 6.2** deployment target

## Data Flow Architecture

```
View → ViewModel → Repository → GraphQLClient → URLSession → Backend
          ↑              ↑
     @Observable    In-memory cache
                   (keyed by ID)
```

### Repositories

`@Observable` classes that own both the cache and the network calls. One per domain:

- **`UserRepository`** — current user profile, other user lookups
- **`EventRepository`** — events by ID, my events, feed results
- **`FriendRepository`** — friends list, pending requests, mutual friends

Repositories are shared across the app via SwiftUI `.environment()`. They are the single source of truth for entity data.

**Cache strategy:** `[ID: Entity]` dictionaries. No TTL, no persistence — in-memory for the session. Methods like `event(id:)` return cached data if available, fetch if not. Feed results stored as ordered arrays of IDs referencing the same cache.

### ViewModels

`@Observable` classes scoped to a single screen. They hold UI-specific state (loading, error, form fields) and call repository methods. They do NOT hold entity data — they read it from the repository.

ViewModels are created in views, receiving repositories from the environment. They are NOT shared across screens.

### Views

Standard SwiftUI views. They observe their ViewModel and read display data. No business logic in views.

## Networking Layer

### GraphQLClient

A single class handling all HTTP communication:

- Takes a query string + optional `[String: Any]` variables dictionary
- POSTs to `https://lfourg-a6fe3.web.app/graphql`
- Injects Firebase ID token via `Authorization: Bearer <token>` header
- Decodes the `{ "data": ... }` envelope
- Surfaces `{ "errors": ... }` as typed Swift errors
- Returns decoded `Codable` types via generics: `func execute<T: Decodable>(query:variables:) async throws -> T`

### Queries

Plain Swift strings organized by domain in caseless enums:

- `EventQueries.feed`, `EventQueries.event`
- `EventMutations.createEvent`, `EventMutations.requestToJoin`
- `UserQueries.me`, `UserMutations.createProfile`

No `.graphql` files, no code generation. Query strings live close to the repository that uses them.

### AuthService

Thin wrapper around FirebaseAuth:

- `signUp(email:password:displayName:) async throws`
- `signIn(email:password:) async throws`
- `signOut() throws`
- `resetPassword(email:) async throws`
- Exposes `authState: AuthState` (`.unknown`, `.signedIn`, `.signedOut`)
- Provides `getToken() async throws -> String` called by GraphQLClient before each request
- Listens to FirebaseAuth's `addStateDidChangeListener` for auth state changes
- After sign-up: calls `createProfile` mutation to create the user's GraphQL profile, then populates `UserRepository`
- After sign-in: calls `me` query to fetch the existing profile into `UserRepository`

### Error Handling

`AppError` enum: `.network(Error)`, `.unauthorized`, `.graphQL([String])`, `.decoding(Error)`. Repositories surface these to ViewModels, which map them to user-facing messages.

## Models

Shared `Codable` structs mirroring GraphQL types in `Models/`:

| Model | Key Fields |
|-------|-----------|
| `User` | id, displayName, photoURL, bio, interests, traits, badges, eventsOrganized, eventsAttended, memberSince, relationshipLevel |
| `Event` | id, organizer, title, description, category, date, time, duration, totalSlots, slotsRemaining, fillMode, visibility, status, location, venue, participants, myParticipantStatus |
| `EventLocation` | name, address, lat, lng, radius, placeId |
| `EventParticipant` | user, status, slotType, joinedAt |
| `Venue` | placeId, displayName, formattedAddress, location, rating, photos |
| `Friendship` | id, user, status, createdAt |
| `EventConnection` | edges (EventEdge array), pageInfo (hasNextPage, endCursor) |

Enums map 1:1 from the GraphQL schema: `ActivityCategory`, `EventStatus`, `ParticipantStatus`, `FillMode`, `Visibility`, `FeedSort`, etc. All `String`-backed and `Codable`. One file per enum.

## Theme & Constants

No magic numbers anywhere in layout code.

### Sizes

Caseless enum of `CGFloat` constants. Naming convention: `category + size`.

```swift
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

Constants are added as needed — not exhaustively upfront.

### AppColors

Semantic color names backed by the asset catalog: `AppColors.primary`, `AppColors.secondaryText`, `AppColors.cardBackground`, etc. Defined as we build screens.

### AppTypography

ViewModifiers for consistent text styles: `.titleLarge`, `.bodyDefault`, `.caption`, etc. Built on system dynamic type sizes for accessibility scaling.

## Navigation & App Structure

### Root Navigation

```
RootView
  ├── .unknown    → Splash/loading screen
  ├── .signedOut  → AuthFlow (NavigationStack)
  └── .signedIn   → MainTabView
```

### AuthFlow

A `NavigationStack` containing:
- **LoginView** — email + password fields, sign in button, links to sign up and forgot password
- **SignUpView** — email + password + display name, create account
- **ForgotPasswordView** — email field, send reset link

### MainTabView

`TabView` with tabs (for first milestones):
- **Feed** — events near me
- **My Events** — events I'm organizing or participating in
- **Profile** — my profile, settings

Each tab owns its own `NavigationStack`. Event detail pushes onto whichever tab's stack the user tapped from.

### Dependency Injection

Repositories and AuthService created once in `gataboutApp` and injected via `.environment()`:

```swift
@main
struct gataboutApp: App {
    let authService = AuthService()
    let graphQLClient: GraphQLClient
    let userRepository: UserRepository
    let eventRepository: EventRepository

    init() {
        graphQLClient = GraphQLClient(authService: authService)
        userRepository = UserRepository(client: graphQLClient)
        eventRepository = EventRepository(client: graphQLClient)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .environment(userRepository)
                .environment(eventRepository)
        }
    }
}
```

## Project Structure

```
gatabout/
  App/
    gataboutApp.swift
    RootView.swift
    MainTabView.swift

  Core/
    Networking/
      GraphQLClient.swift
      GraphQLError.swift
      AppError.swift
    Auth/
      AuthService.swift
    Theme/
      Sizes.swift
      AppColors.swift
      AppTypography.swift

  Models/
    User.swift
    Event.swift
    EventLocation.swift
    EventParticipant.swift
    Venue.swift
    Friendship.swift
    Enums/
      ActivityCategory.swift
      EventStatus.swift
      ParticipantStatus.swift
      FillMode.swift
      Visibility.swift
      FeedSort.swift
      SlotType.swift

  Repositories/
    UserRepository.swift
    EventRepository.swift
    FriendRepository.swift

  Features/
    Login/
      LoginView.swift
      LoginViewModel.swift
      SignUpView.swift
      SignUpViewModel.swift
      ForgotPasswordView.swift
      ForgotPasswordViewModel.swift
    Feed/
      FeedView.swift
      FeedViewModel.swift
      EventCardView.swift
    EventDetail/
      EventDetailView.swift
      EventDetailViewModel.swift
    Profile/
      ProfileView.swift
      ProfileViewModel.swift

  Extensions/
    View+Extensions.swift
    Date+Extensions.swift
```

## Milestone 1 — Login Flow

### Scope
- Sign in with email/password
- Sign up with email/password + display name
- Forgot password (send reset email)
- After sign-up: `createProfile` mutation → hydrate `UserRepository`
- After sign-in: `me` query → hydrate `UserRepository`
- Auto-login on relaunch (FirebaseAuth persists session)
- Error handling: wrong password, email taken, network errors

### Out of scope
- OAuth (Apple Sign In, Google Sign In)
- Email verification gate
- Profile editing

## Milestone 2 — Event Feed

### Scope
- Request location permission
- Fetch feed via `feed` query with user's current location
- Scrollable list of `EventCardView` items: title, category, date/time, venue name, slots remaining, distance
- Cursor-based pagination (load more on scroll)
- Tap card → push `EventDetailView` (read-only: event info, organizer, participants list)

### Out of scope
- Map view
- Event creation
- Join/leave events
- Category/date filters
- Pull-to-refresh

## Deferred Features

These are not part of the initial build:
- Chat & notifications (requires Firestore SDK decision)
- Friends system
- Ratings & reputation
- Event creation/management
- Profile editing
- Map view
- Search/filters
- Push notifications
