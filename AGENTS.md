# Flutter App - AGENTS.md

## Context & Environment
- **Path**: `app/`
- **Framework**: Flutter with Dart (SDK `^3.13.4`), Material 3 enabled.
- **Entrypoint**: `lib/main.dart`
- **Tests**: `test/` (e.g. `test/widget_test.dart`)
- **Linter**: `analysis_options.yaml` (`package:flutter_lints`)

All commands below must be executed from the `app/` directory.

---

## Verification & Workflow Commands
```bash
# Verify code health (Mandatory before finishing any task)
flutter analyze
flutter test

# Format code according to Dart standard
dart format .

# Dependency management
flutter pub get
flutter pub add <pkg>
```

---

## High-Impact Architecture & Coding Rules

### 1. Separation of Concerns & State
- **Keep Widgets Lean**: Widgets are only responsible for UI rendering and capturing user inputs. Never embed business logic, direct HTTP requests, or raw database queries inside widget classes.
- **State Management**: Default to idiomatic Flutter built-ins (`ChangeNotifier`, `ValueNotifier`, `ListenableBuilder`). Do not introduce external state management (Bloc, Riverpod, etc.) unless already present or explicitly requested.
- **Dependency Flow**: Pass dependencies explicitly via constructor parameters.

### 2. Async Safety & Lifecycle Management (Anti-Crash Rules)
- **Context Across Async Gaps**: Never access `BuildContext` (e.g. `Navigator.of(context)`, `Theme.of(context)`, `ScaffoldMessenger.of(context)`) after an `await` without checking:
  ```dart
  if (!mounted) return; // In State classes
  // OR
  if (!context.mounted) return; // In Stateless/function contexts
  ```
- **Resource Disposal**: Every controller or subscription created (`TextEditingController`, `ScrollController`, `AnimationController`, `StreamSubscription`) must be instantiated once (typically in `initState`) and explicitly disposed in `dispose()`.
- **Pure `build()` Methods**: The `build()` method must be completely deterministic and free of side-effects. Never trigger API calls, initialize controllers, or register navigation actions directly in `build()`.

### 3. Layout, Rendering & Performance
- **Unbounded Constraint Protection**: Avoid layout crashes (`RenderFlex overflowed`) by never placing unconstrained flex children (like raw `ListView` or `Expanded`) directly into vertical `Column` or horizontal `Row` without bounded sizing (`Expanded`, `Flexible`, or `SizedBox`).
- **List Performance**: Use `ListView.builder` or `CustomScrollView` with slivers for dynamic or potentially unbounded lists; never construct `ListView(children: ...)` with arbitrary data lengths.
- **Rebuild Optimization**:
  - Maximize the use of `const` constructors on widgets and subtrees.
  - Break down large monolith widget trees into small private `StatelessWidget` classes rather than helper methods returning `Widget`.

### 4. Data Handling & Network Resilience
- **Explicit States**: Every asynchronous UI flow must cleanly handle four discrete states: **Initial**, **Loading**, **Success**, and **Error** (with a user-actionable retry).
- **Safe Serialization**: Do not trust remote API shapes blindly; parse with null-coalescing defaults and defensive type checks.
- **Logging**: Use `dart:developer`'s `log()`, never bare `print()`.

### 5. Testing Expectations
- When modifying widgets, ensure existing widget tests (e.g. `test/widget_test.dart`) are updated and pass.
- New business logic and data mappers must include corresponding unit tests in `test/`.
