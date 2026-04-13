## First Step

Read `docs/PROJECT-STATUS.md` before doing anything. It has the full architecture, file map, known issues, and testing checklist.

## Project

- iOS app for the bunchabout social coordination platform
- Contract/spec: `../bunchabout/contract/`
- Must use `ios/bunchabout.xcworkspace` (CocoaPods), NOT `.xcodeproj`
- Build: `cd ios && xcodebuild build -workspace bunchabout.xcworkspace -scheme bunchabout -destination 'platform=iOS Simulator,name=iPhone 17'`
- Tests: `cd ios && xcodebuild test -workspace bunchabout.xcworkspace -scheme bunchabout -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:bunchaboutTests -disable-concurrent-destination-testing`

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
