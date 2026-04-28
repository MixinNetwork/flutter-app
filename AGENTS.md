# AGENTS.md

## Project

Mixin Messenger desktop Flutter app.

Tech stack:

- Flutter/Dart app, `environment` in `pubspec.yaml`: Dart `^3.10.0`, Flutter `^3.38.0`.
- Desktop targets: macOS, Linux, Windows. Web/iOS/Android folders exist, but README/release flow focuses on desktop.
- State/UI: Flutter Hooks, Riverpod, Provider, Bloc/Hydrated Bloc.
- Storage: Drift/Moor over SQLite, Hive, Hydrated Bloc storage.
- Networking/runtime: Dio, rhttp, WebSocket, Mixin SDK, Signal protocol implementation.
- Code generation: `build_runner`, `drift_dev`, `json_serializable`, `envied_generator`, `flutter_intl`.

Main directories:

- `lib/main.dart`, `lib/app.dart`: app bootstrap, desktop window setup, localization and root providers.
- `lib/account`: account server, notification and key-value account state.
- `lib/ai`: AI chat controller, models and tools.
- `lib/api`, `lib/blaze`: HTTP/API and Blaze message models.
- `lib/db`: main Drift database, DAOs, converters, FTS database, open helpers.
- `lib/db/moor`: Drift SQL schema and DAO `.drift` files.
- `lib/crypto/signal`: Signal protocol database, DAOs and crypto storage.
- `lib/ui`, `lib/widgets`: screens and reusable UI.
- `lib/utils`, `lib/workers`: platform utilities, background work, transfer and job queues.
- `lib/l10n`: source ARB localization files.
- `lib/generated`: generated localization output; do not edit by hand.
- `assets`, `fonts`: bundled assets and fonts.
- `test`: Flutter/unit tests.
- `third_party/system_tray`: local path dependency.
- `dist`: packaging scripts and platform distribution metadata.

## Commands

Setup:

```sh
flutter pub get
```

Generate code:

```sh
dart run build_runner build --delete-conflicting-outputs
```

Short scripts:

```sh
./generate.sh      # dart run build_runner build
./db_generate.sh   # dart run build_runner build --delete-conflicting-outputs
```

Format/lint:

```sh
dart format --set-exit-if-changed .
dart analyze --fatal-infos
```

Tests:

```sh
dart run webcrypto:setup
flutter test
flutter test test/path/to/file_test.dart
```

Run:

```sh
flutter run -d macos
flutter run -d linux
flutter run -d windows
```

Build:

```sh
flutter build macos --release
flutter build linux --release
flutter build windows --release
```

Packaging helpers:

```sh
./dist/macos.sh
./dist/win.sh
./dist/linux_deb.sh amd64
./dist/linux_deb.sh arm64
```

Linux desktop build dependencies used by CI:

```sh
sudo apt-get install -y ninja-build libgtk-3-dev libsdl2-dev \
  libwebkit2gtk-4.1-dev libopus-dev libogg-dev libcurl4-openssl-dev
```

## Environment

- `lib/constants/env.dart` uses `envied` with `.env`.
- `.env` may contain:

```env
SENTRY_DSN=...
```

- `SENTRY_DSN` is optional for local debug; release builds read it through generated env code and may also pass `--dart-define SENTRY_DSN=$SENTRY_DSN` in CI/release scripts.
- If `.env` changes or `EnviedField` changes, rerun build runner.

## Database

- Main DB: `lib/db/mixin_database.dart`, schema in `lib/db/moor/**`, current `schemaVersion` is `30`.
- FTS DB: `lib/db/fts_database.dart`, schema in `lib/db/moor/fts.drift`.
- Signal DB: `lib/crypto/signal/signal_database.dart`, schema in `lib/crypto/signal/moor/**`.
- Drift generation options are in `build.yaml`; FTS5 is enabled.
- When changing `.drift` schemas or DAOs:
  - update `schemaVersion` when persistent schema changes;
  - add an `onUpgrade` migration in `MigrationStrategy`;
  - prefer idempotent helpers like `_addColumnIfNotExists` for additive migrations;
  - keep existing data migration jobs in `lib/workers/job` in mind;
  - rerun `dart run build_runner build --delete-conflicting-outputs`;
  - add or update focused tests under `test/db` when behavior changes.

## Code Generation

- Do not hand-edit `*.g.dart`, `lib/generated/**`, or other files marked generated.
- Source annotations/models commonly use `part '*.g.dart'` with `json_serializable`, `drift_dev`, or `envied_generator`.
- Reserve `part` and `part of` for code generation only. For manual code organization, split code into separate libraries and connect them with imports.
- Localization source is `lib/l10n/*.arb`; generated class is `Localization` in `lib/generated/l10n.dart`.
- Asset constants in `lib/constants/resources.dart` are generated; update the generator flow instead of manual edits if assets change.

## Coding Conventions

- Follow `analysis_options.yaml` and `very_good_analysis` overrides.
- Prefer relative imports inside `lib`; avoid broad package imports for local files.
- Prefer `final` locals, expression-bodied members where already used, and concise null handling.
- Keep generated, third-party, and platform registrant files untouched unless the task explicitly requires them.
- Keep changes scoped to the requested behavior; do not refactor unrelated areas.
- Reuse existing UI components from `lib/widgets` and patterns from nearby screens.
- Reuse existing DB access through DAOs and providers instead of bypassing with ad hoc SQL unless Drift APIs cannot express the query.
- For user-facing text, use `Localization` and ARB files rather than hard-coded strings.
- For async work, preserve current error propagation style and do not swallow exceptions without a concrete recovery path.
- Before finalizing non-trivial changes, run the narrowest relevant tests plus `dart analyze --fatal-infos` when feasible.

## Code Style

- Follow the Dart style guide and `analysis_options.yaml` rules.
- Use consistent naming conventions for variables, functions, classes, and files.
- Keep lines within 80 characters where possible for readability.
- Prefer clear and descriptive names over abbreviations.
- Maintain consistent indentation and spacing throughout the codebase.
- Flow effective-dart guidelines, such as using `final` for variables that are not reassigned, and preferring composition over inheritance where appropriate.
- Use comments judiciously to explain complex logic, but avoid redundant comments that do not add value beyond the code itself.
