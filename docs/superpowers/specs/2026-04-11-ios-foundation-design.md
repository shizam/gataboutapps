# iOS Foundation: Sign In + Events Feed

## Overview

First milestone for the Gatabout iOS app. Implements email/password sign-in via Firebase Auth SDK and a nearby events feed via a custom GraphQL networking layer. No signup, onboarding, chat, or notifications in this milestone.

## Architecture

MVVM with three layers:

```
Views (SwiftUI) → ViewModels (@Observable) → Repositories → GraphQLClient (URLSession)
                                                           → AuthService (Firebase Auth SDK)
```

### Folder Structure

```
gatabout/
├── App/
│   ├── GataboutApp.swift              # @main, auth-gated root navigation
│   └── AppConfig.swift                # GraphQL URL, environment config
├── Core/
│   ├── Auth/
│   │   └── AuthService.swift          # Firebase Auth wrapper
│   └── Network/
│       ├── GraphQLClient.swift        # URLSession + Codable GraphQL client
│       └── GraphQLError.swift         # Error types
├── Models/
│   ├── User.swift                     # User, partial user types
│   ├── Event.swift                    # Event, EventParticipant, EventLocation
│   └── Feed.swift                     # EventConnection, EventEdge, PageInfo
├── Repositories/
│   ├── UserRepository.swift           # me()
│   └── EventRepository.swift          # feed(...)
├── Features/
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   └── LoginViewModel.swift
│   └── Feed/
│       ├── FeedView.swift
│       ├── FeedViewModel.swift
│       └── EventCardView.swift
└── Shared/
    ├── Sizes.swift                    # Layout constants (spacing, padding, corner radii)
    └── LocationManager.swift          # CoreLocation wrapper
```

## Components

### AuthService

`@Observable` class wrapping Firebase Auth SDK. Responsibilities:

- `signIn(email:password:) async throws` — Firebase Auth email/password sign-in
- `signOut() throws` — sign out
- `authState: AuthState` — published enum: `.unknown`, `.loggedOut`, `.loggedIn`
- `getIDToken() async throws -> String` — returns current Firebase ID token (auto-refreshes)
- Listens to `Auth.auth().addStateDidChangeListener` to track auth state

No signup or profile creation in this milestone. Users must already have an account.

### GraphQLClient

Single class wrapping `URLSession` for GraphQL requests:

- `func query<T: Decodable>(_ query: String, variables: [String: Any]?, as type: T.Type) async throws -> T`
- `func mutation<T: Decodable>(_ query: String, variables: [String: Any]?, as type: T.Type) async throws -> T`
- Both methods build a POST request to `AppConfig.graphQLURL` with JSON body `{ "query": ..., "variables": ... }`
- Injects `Authorization: Bearer <token>` via `AuthService.getIDToken()`
- Decodes the `data` field of the response into `T`
- Surfaces GraphQL errors from the `errors` array as typed `GraphQLError`
- No caching, no retry logic, no request deduplication — just clean request/response

### Models

Codable structs matching the GraphQL schema types we need:

**User.swift:**
- `User` — id, displayName, photoURL, bio, interests, eventsOrganized, eventsAttended, traits, badges

**Event.swift:**
- `Event` — id, title, description, category, date, time, duration, status, totalSlots, slotsRemaining, fillMode, visibility, location, organizer, participants, myParticipantStatus
- `EventLocation` — name, address, lat, lng, radius, placeId
- `EventParticipant` — id, user, status, slotType
- All relevant enums: `ActivityCategory`, `EventStatus`, `ParticipantStatus`, `FillMode`, `Visibility`

**Feed.swift:**
- `EventConnection` — edges, pageInfo, totalCount
- `EventEdge` — node (Event), cursor, distance, score
- `PageInfo` — hasNextPage, endCursor
- `FeedSort` enum

### Repositories

**UserRepository:**
- `func me() async throws -> User` — queries `me { id displayName photoURL ... }`

**EventRepository:**
- `func feed(lat:lng:radius:categories:sort:cursor:limit:) async throws -> EventConnection` — queries the `feed` query with location and filters

Each repository holds its GraphQL query strings as private constants. No protocols.

### ViewModels

**LoginViewModel** (`@Observable`):
- `email: String`, `password: String` — bound to text fields
- `isLoading: Bool`, `errorMessage: String?` — view state
- `func signIn() async` — validates inputs, calls `AuthService.signIn`, clears error on success

**FeedViewModel** (`@Observable`):
- `events: [EventEdge]` — loaded events
- `isLoading: Bool`, `errorMessage: String?`
- `func loadFeed() async` — gets location from `LocationManager`, calls `EventRepository.feed`
- `func loadMore() async` — cursor-based pagination using `pageInfo.endCursor`

### LocationManager

`@Observable` class wrapping `CLLocationManager`:
- Requests when-in-use authorization
- Exposes `currentLocation: CLLocationCoordinate2D?`
- Used by `FeedViewModel` to get coordinates for the feed query

### Navigation

`GataboutApp` observes `AuthService.authState`:
- `.unknown` → splash/loading screen
- `.loggedOut` → `LoginView`
- `.loggedIn` → `FeedView` (single screen for now, no tab bar yet)

## Data Flow

### Sign In
```
User taps "Sign In"
→ LoginViewModel.signIn()
→ AuthService.signIn(email, password)          // Firebase Auth SDK
→ Firebase Auth state listener fires
→ AuthService.authState = .loggedIn
→ GataboutApp swaps root view to FeedView
```

### Load Feed
```
FeedView appears
→ FeedViewModel.loadFeed()
→ LocationManager.currentLocation              // CoreLocation
→ EventRepository.feed(lat, lng, radius: 10)
  → GraphQLClient.query(feedQuery, variables)
    → AuthService.getIDToken()                 // Firebase ID token
    → URLSession POST to /graphql
  → Decode EventConnection from response
→ FeedViewModel.events = connection.edges
→ FeedView renders EventCardView list
```

## Configuration

- Firebase project: `lfourg-a6fe3`
- GraphQL endpoint: `https://lfourg-a6fe3.web.app/graphql`
- Firebase Auth: email/password only
- GoogleService-Info.plist: copied from ~/Downloads/ into the Xcode project
- Firebase SDK added via SPM (FirebaseAuth package only)

## Event Card Display

Each card in the feed shows:
- Event title
- Category (as chip/badge)
- Date and time
- Distance from user (from `EventEdge.distance`)
- Slots remaining / total slots
- Organizer name
- Fill mode indicator (approval required vs first come first served)

## Layout Constants

All spacing, padding, corner radius, and sizing values use named constants from a `Sizes` enum — no magic numbers in SwiftUI layout code. Example: `Sizes.padding16`, `Sizes.cornerRadius8`, `Sizes.iconSize24`. This keeps layouts consistent app-wide and makes spacing adjustments trivial.

## Error Handling

- Network errors → show inline error with retry button
- Auth errors (invalid credentials) → show error message on login form
- GraphQL errors → surface error message to user
- Location denied → show prompt explaining why location is needed, with button to settings
- Token expiry → `AuthService.getIDToken()` handles refresh; if refresh fails, sign out

## What's Deferred

- Sign up / account creation
- Profile creation (createProfile onboarding)
- Chat, notifications (Firestore SDK)
- Friends, ratings, event creation, event detail
- Map view
- Image upload / avatars
- Caching / offline support
- Deep linking
- Pull-to-refresh (can add quickly later)
- Search / filter UI (categories, radius, sort)
