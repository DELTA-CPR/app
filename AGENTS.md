# AGENTS.md — Repo agent instructions

Purpose
- Brief, actionable guidance for AI coding agents working in this repository.
- App is a Flutter application (Dart). Backend lives in the sibling `be/` repository (ASP.NET Core / .NET).

What to run (quick)
- Install dependencies: `flutter pub get`
- Run on a device/emulator: `flutter run`
- Run all tests: `flutter test`
- Analyze code: `flutter analyze`
- Format code: `dart format .`
- Build release APK: `flutter build apk`
- Build web: `flutter build web`

Key locations
- App entrypoint: `lib/main.dart`
- Tests: `test/`
- Configuration: `pubspec.yaml` (dependencies, SDK constraints)
- Platform projects: `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`
- Lint rules: `analysis_options.yaml`

Conventions and notes for agents
- Target latest stable Flutter (3.47.x) and Dart 3.13.x; keep `environment.sdk` up to date.
- Prefer `const` constructors and `super.key` for widgets.
- Follow `flutter_lints` rules; resolve `flutter analyze` warnings before committing.
- Keep widget tests in `test/` and run them after changes.
- Prefer small, focused commits; avoid large refactors without tests.
- Do not commit generated/build artifacts (covered by `.gitignore`).

Common pitfalls
- Run `flutter pub get` after editing `pubspec.yaml`.
- Generated platform registrant files are gitignored; do not hand-edit them.
- Hot reload may not pick up asset/config changes; restart the app.
- On Windows, ensure Android SDK / emulator are configured before `flutter run`.

What agents should do first
1. Run `flutter pub get`.
2. Run `flutter analyze`.
3. Run `flutter test`.

When to ask the user
- If you need credentials, signing keys, API keys, or service account tokens — stop and ask; do not fetch secrets.
- If a change touches platform-specific native code or permissions, confirm scope.

Suggested follow-ups
- Add integration tests under `integration_test/`.
- Add CI workflow for `flutter analyze` and `flutter test`.

History
- Created by AI agent to help future code-assist tasks.
