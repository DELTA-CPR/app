# AGENTS.md

<!--
Adapted for a stock `flutter create` app. HTML comments name the source of each
section and can be deleted. Wording is original; only the ideas are taken from sources.

Source keys (all read 2026-11-11):
  [F10k] flutter/flutter            docs/rules/rules_10k.md        (Flutter team's AI rules, condensed)
  [FPKG] flutter/packages           AGENTS.md                      (contributor guide for that repo)
  [EVA]  evanca/flutter-ai-rules    combined/flutter_dart__under_6K.md, combined/flutter_dart.md, rules/bloc.md
  [SPEC] agentsmd/agents.md         format guidance (README + agents.md site)
  Anything tagged "unsourced" is my own addition (standard CLI / template facts).
  Commands were NOT executed while writing this; run each once before trusting it.
-->

## Project context
<!-- src: [SPEC] "project overview" section; flutter_lints per [F10k] "Analysis Options". Layout facts: unsourced (stock template). -->
- Stock `flutter create` app: entry point `lib/main.dart`, tests in `test/`, lints from `analysis_options.yaml` (`flutter_lints`).
- Platform folders (`android/`, `ios/`, `web/`, ...) are tool-generated; edit them only for native-config tasks.

## Commands (repo root)
<!-- src: pub add/remove and format/fix tooling: [F10k]; doctor and build_runner: [FPKG].
     Unsourced: `flutter pub get`, `flutter analyze`, `flutter test`, `dart fix --apply` (standard CLI equivalents). -->
- Install deps: `flutter pub get`
- Format: `dart format .`
- Analyze: `flutter analyze`
- Apply safe lint fixes: `dart fix --apply`
- Test: `flutter test`
- Packages: prefer the CLI over hand-editing versions: `flutter pub add <pkg>`, `flutter pub add dev:<pkg>`, `dart pub remove <pkg>`
- Environment problems: `flutter doctor --verbose`
- Only if `build_runner` is in `pubspec.yaml`: `dart run build_runner build -d` after changing annotated code
- Definition of done: formatted, `flutter analyze` clean, `flutter test` green.

## Code style
<!-- src: [F10k] "Code Quality", "Dart Best Practices", "Documentation Philosophy"; naming also in [EVA] flutter_dart__under_6K.md.
     Import-style note reconciles [F10k] (package imports) with [EVA] (relative imports): a real conflict between sources. -->
- Names: `PascalCase` types, `camelCase` members, `snake_case` files; avoid abbreviations.
- Keep functions short and single-purpose (rough ceiling: 20 lines).
- Sound null safety; avoid `!` unless the value is provably non-null.
- Log with `log` from `dart:developer`, never `print`.
- `///` doc comments on public APIs; inline comments explain why, not what.
- Prefer `final`, then `const`; use records, patterns and switch expressions where they simplify code.
- Imports: use `package:` imports inside `lib/`. Effective Dart prefers relative imports instead; if you switch, change the lint to match.

## Widgets and UI
<!-- src: [F10k] "Flutter Best Practices", "Visual Design & Theming", "Accessibility", "Layout Best Practices";
     overflow/unbounded-constraint fixes: [EVA] combined/flutter_dart.md "Common Flutter Errors". -->
- Build UI from small private widget classes, not methods that return widgets.
- Use `const` constructors and `const` instances wherever possible.
- Long lists: `ListView.builder` or slivers. No network or heavy work in `build()`; move CPU-heavy work (e.g. JSON parsing) to `compute()`.
- Overflow / unbounded-constraint errors: wrap in `Expanded`/`Flexible` or give the parent bounded size.
- One central `ThemeData`, colors from `ColorScheme.fromSeed`, both light and dark themes.
- Accessibility: 4.5:1 text contrast, `Semantics` labels, stays usable at larger system font sizes.

## State, navigation, data
<!-- src: [F10k] "State Management", "Routing (GoRouter)", "Data Handling & Serialization".
     The Bloc line comes from [EVA] rules/bloc.md and only applies if you opt in; [F10k] says not to use Bloc by default. -->
- Default to built-ins: `ValueNotifier`, `ChangeNotifier`, `ListenableBuilder`. Do not add Riverpod, Bloc or GetX unless asked.
- Pass dependencies through constructors; move to MVVM when state outgrows a single widget.
- Navigation: `go_router` (add it when the app needs routing or deep links).
- JSON: `json_serializable` with `fieldRename: FieldRename.snake`.
- If the project adopts Bloc: events named in the past tense, states as sealed classes, no business logic in widgets.

## Testing
<!-- src: unit vs widget tests: [EVA] flutter_dart__under_6K.md "Testing". Mocktail-vs-Mockito choice: both exist in [EVA]; the pick is mine. -->
- Unit-test business logic; widget-test UI.
- The template's `test/widget_test.dart` must keep passing; update it when you change `lib/main.dart`.
- Mocks: Mocktail unless the project already uses Mockito.

## Don't
<!-- src: generated files: [FPKG] "Code Generators" and the .NET Blog "Instructions Hygiene" example; new-dependency rule: [F10k] "Interaction Guidelines". Secrets line: unsourced. -->
- Don't hand-edit generated files (`*.g.dart`, `*.freezed.dart`); rerun the generator.
- Don't add a dependency without stating why it is needed.
- Don't commit secrets or API keys.

## References
- Flutter's official AI rules (source of most of this file): https://docs.flutter.dev/ai/ai-rules
