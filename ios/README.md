# MATCHA iOS Scaffold

Minimal Xcode-friendly SwiftUI MVP scaffold for the MATCHA iOS app, built without third-party runtime dependencies.

## What is included

- `project.yml` for [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- App entry and tab shell with `NavigationStack`
- Feature-first folders for onboarding, match feed, offers, activity, chats, and profile
- Core dark theme tokens and reusable glass card/button styles
- Sample models plus mock repository-backed seed data
- Basic accessibility labels on interactive controls

## Folder structure

```text
ios/
├── MATCHA/
│   ├── App/
│   ├── DesignSystem/
│   ├── Features/
│   └── Shared/
├── MATCHATests/
├── Preview Content/
└── project.yml
```

## Run locally

1. Install XcodeGen if needed: `brew install xcodegen`
2. From this folder run: `xcodegen generate`
3. Open `MATCHA.xcodeproj` in Xcode
4. Select the `MATCHA` scheme and an iPhone simulator
5. Build and run

## Notes

- The app starts in onboarding and then switches into the 5-tab shell.
- All data currently comes from `MockMatchaRepository` and `MockSeedData`.
- This is intentionally a scaffold: it gives the team a clean SwiftUI starting point for real networking, persistence, auth, and backend integration later.
