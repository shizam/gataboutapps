## First Step

Read `docs/PROJECT-STATUS.md` before doing anything. It has the full architecture, file map, known issues, and testing checklist.

## Project

- iOS app for the lfourg (gatabout) social coordination platform
- Contract/spec: `../lfourg/contract/`
- Must use `gatabout/gatabout.xcworkspace` (CocoaPods), NOT `.xcodeproj`
- Build: `cd gatabout && xcodebuild build -workspace gatabout.xcworkspace -scheme gatabout -destination 'platform=iOS Simulator,name=iPhone 17'`
- Tests: `cd gatabout && xcodebuild test -workspace gatabout.xcworkspace -scheme gatabout -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:gataboutTests -disable-concurrent-destination-testing`

## Code Style

- All spacing/padding/sizing in SwiftUI uses `Sizes.*` constants — no magic numbers
- Semantic colors via `AppColors.*` — no raw Color literals
- MVVM with @Observable ViewModels and Repositories
- Repositories shared via SwiftUI `.environment()`, ViewModels via explicit init injection
- Use Swift skills (`swift-concurrency-pro`, `swiftui-pro`, `swift-testing-pro`) when writing or reviewing Swift code

## Dependencies

- **CocoaPods** only, not SPM (user preference)
- **Minimum Firebase deps** — only `FirebaseAuth`, no Analytics/Crashlytics/etc
- Everything else through custom GraphQL networking over URLSession
