# AGENTS.md — Repo agent instructions

Purpose
- Brief, actionable guidance for AI coding agents working in this repository.

What to run (quick)
- App (Flutter): from repository root run `flutter pub get`, then `flutter run` (or `flutter build apk`/`flutter build web`).
- Tests: `flutter test`.

Key locations
- App entrypoint: lib/main.dart
- Tests: test/
- Configuration: pubspec.yaml

Conventions and notes for agents
- Target latest stable Flutter (3.47.x) / Dart 3.13.x.
- Preserve existing documentation: prefer linking to README or other docs rather than copying large sections.
- Formatting: follow `dart format`; avoid large sweeping refactors without tests.

Common pitfalls
- Run `flutter pub get` after changing pubspec.yaml.
- Remove build/ and .dart_tool/ before committing (covered by .gitignore).

What agents should do first
1. Run `flutter pub get`.
2. Run `flutter test` to validate changes.

When to ask the user
- If you need credentials, secrets, or service account tokens — stop and ask; do not attempt to fetch secrets.

History
- Created by AI agent to help future code-assist tasks.
