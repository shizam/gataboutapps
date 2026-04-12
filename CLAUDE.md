## First Step

Read `docs/PROJECT-STATUS.md` before doing anything. It has the full architecture, file map, known issues, and testing checklist.

## Project

- iOS app for the lfourg social coordination platform
- Contract/spec: `../lfourg/contract/`
- Must use `ios/gatabout/gatabout.xcworkspace` (CocoaPods), NOT `.xcodeproj`
- Build: `xcodebuild -workspace gatabout.xcworkspace -scheme gatabout -destination 'generic/platform=iOS Simulator' build`

## Code Style

- All spacing/padding/sizing in SwiftUI uses `Sizes.*` constants — no magic numbers
- MVVM with explicit init injection — no singletons, no DI container, no @Environment
- Use Swift skills (`swift-concurrency-pro`, `swiftui-pro`) when writing or reviewing Swift code
