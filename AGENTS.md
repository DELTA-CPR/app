# AGENTS.md - Repo agent instructions

Purpose
- Brief, actionable guidance for AI coding agents working in this repository.

What to run (quick)
- Frontend (app): change to `app/` and use `flutter pub get` then `flutter run` (Vite? no, Flutter).
- Backend (C#/.NET): change to `be/Be/` and use `dotnet build` and `dotnet test`.

Key locations
- Frontend app: app/
- Backend project root: be/Be/

Conventions and notes for agents
- Preserve existing documentation: prefer linking to README or other docs rather than copying large sections.
- Tests: run `flutter test` for app changes; run `dotnet test` for backend changes.
- Formatting: follow existing repository style; avoid large sweeping refactors without explicit tests and CI confirmation.

Common pitfalls
- Run `flutter pub get` after changing pubspec.yaml.

What agents should do first
1. Run `flutter test` for app changes.
2. Run `dotnet test` for backend changes.

When to ask the user
- If you need credentials, secrets, or service account tokens - stop and ask; do not attempt to fetch secrets.

Suggested follow-ups
- Create small skill files for running: `dev:backend`, `dev:frontend`, and `test:backend` automation.

History
- Created by AI agent to help future code-assist tasks.
