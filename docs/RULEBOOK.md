# workout_tracker — Rulebook

What a contributor must know before touching this project. Every rule here is true in the
code today. If code and this file disagree, the code wins and this file gets corrected.

## 1. Architecture rules

- **Local-first, no backend, no network calls.** Do not add one (standard 6 is out of scope
  by design). The only I/O outside the database is the share sheet and file picker for backups.
- **Layers:** widget (`view/`) → Riverpod provider (`viewmodel/`) → DAO (`lib/data/daos/`)
  → SQLite. Widgets never touch the database directly.
- **DAOs are the data layer.** Do not add repository interfaces on top: there is one storage
  engine and one user, so a repository would be a pass-through.
- **Aggregation happens in SQL**, never "load all rows, fold in Dart" (bests, PRs, history
  totals, chart series). The e1RM formula exists twice and must stay identical:
  `estimatedOneRepMax()` in `lib/utils/workout_math.dart` and `_e1rm` in
  `lib/data/daos/progress_dao.dart`.
- **Weights are stored in kg (REAL), reps as INTEGER.** Convert to lb only at the UI edge
  (`lib/utils/units.dart`).
- **Only completed sets count** toward volume, records and charts. Only finished sessions
  count as history, as "previous" values, or as records.
- **Exercises are archived, never deleted.** `exercise_id` foreign keys have no cascade on
  purpose; deleting a referenced exercise must fail.
- **One active session at a time.** `WorkoutDao.startSession` enforces it inside a
  transaction.
- **Multi-row writes run in one `transaction`** (start from routine, reorder, legacy import,
  backup restore).

## 2. File and folder placement

| What | Where |
|---|---|
| Feature screens | `lib/src/<feature>/view/<name>_screen.dart` |
| Screen-local widgets | `lib/src/<feature>/view/widget/` |
| Providers / controllers | `lib/src/<feature>/viewmodel/` |
| Feature-only value types | `lib/src/<feature>/model/` |
| Shared widgets (typed params, no app state inside) | `lib/common/widget/` |
| Tables, DAOs, DB read models | `lib/data/` (`tables.dart`, `daos/`, `models.dart`) |
| Colour tokens | `lib/utils/color_constant.dart` (the ONLY file with raw `Color(0x..)`) |
| Spacing / sizes / insets | `lib/utils/app_spacing.dart` |
| ThemeData + `AppColors` extension | `lib/utils/app_theme.dart` |
| Asset paths | `lib/utils/images.dart` (`Images`, `DataAssets`) |
| Pure maths (units, e1RM, plates) | `lib/utils/` |

Naming: files `snake_case`, classes `PascalCase`, one public widget per file.

## 3. State conventions

- Riverpod **code generation only** (`@riverpod` / `@Riverpod(keepAlive: true)` +
  `part 'x.g.dart'`). The only hand-written provider is `goRouterProvider`.
- Reads are drift `watch()` streams exposed as `Stream` providers, so the UI refreshes on any
  write without manual invalidation.
- **Command controllers (void state, only ever `ref.read`) MUST be `keepAlive: true`.** An
  auto-dispose controller that nothing watches is disposed before its method runs
  (`UnmountedRefException`). This bug happened during v2 and a test caught it.
- `TextEditingController`s and `FocusNode`s live in the `State` that shows them and are
  disposed there. Never in providers.
- Load an edit form **once** (in `initState`), never from `build`. v1's form re-filled
  itself on every build and froze typing.
- Read "now" through `clockProvider`, never `DateTime.now()` in logic, so time is testable.
- `ProviderScope(retry: (_, _) => null)`: failures surface with a Retry button instead of
  retrying silently.

## 4. Presentation standards

- Every screen that loads data shows **loading / empty / error (+ retry) / loaded**. Use
  `AsyncValueView`, `EmptyState`, `ErrorState`, `LoadingState`.
- Colours come from `Theme.of(context).colorScheme` or `AppColors.of(context)`; spacing
  from `AppSpacing` / `AppInsets` / `AppSizes`. No raw colours or magic numbers in screens.
- Accessibility while building, not later:
  - every icon-only button has a `tooltip`;
  - decorative icons and images use `ExcludeSemantics`, and meaningful images get a
    `semanticLabel`;
  - tap targets are at least 48 × 48 dp;
  - state is never shown by colour alone (done = filled icon + tooltip text, PR = trophy +
    "PR" text);
  - layouts must not overflow at 2× text on a 360 dp phone: use `Wrap` rather than `Row`
    for label + action pairs, and `isExpanded: true` on dropdowns;
  - custom-painted content (charts) carries a text summary via `Semantics`.
- User feedback goes through `showToast(message:)` only. Never call
  `ScaffoldMessenger.of(context)`.
- Destructive actions (delete, discard, restore) go through `showConfirmDialog(destructive: true)`.

## 5. Navigation

- Navigate **by name only**: `RouteNames` + `context.goNamed` / `pushNamed`. `_AppPaths`
  is private.
- Pass **ids as path parameters**, never objects in `extra:`. v1 passed the object and then
  matched it by identity, which silently broke editing.
- Full-screen flows (editors, picker, active workout) use the root navigator
  (`parentNavigatorKey: _rootNavigatorKey`) so they cover the bottom bar.
- The exercise picker returns the chosen id: `await context.pushNamed<int>(RouteNames.exercisePicker)`.

## 6. Error flow

- DAOs validate and throw typed exceptions (`DuplicateExerciseNameException`,
  `ActiveSessionExistsException`, `RangeError` for out-of-range sets).
- Screens catch at the action boundary and show a toast or inline field error. Data is
  never silently dropped.
- Corrupt v1 data → `LegacyImportException` → startup error screen with Retry and
  "Continue without importing". Nothing is written, and the import is retried next launch.
- Backups are untrusted input. `decodeBackup` checks the format marker, the version, every
  field's type and range, foreign-key integrity, unique ids and names, and the file size
  (20 MB cap) **before** any write. `replaceAllData` runs in one transaction.
- CSV export neutralises spreadsheet formulas (`=`, `+`, `-`, `@` prefixes).

## 7. Adding things, in order

**A new screen or feature:**
1. Write the design down first in `docs/ARCHITECTURE.md` if it adds a table, route or subsystem.
2. Data: table/columns in `tables.dart` (bump `schemaVersion` and add an `onUpgrade` step
   if the schema changes; existing installs must migrate, never lose data). Add DAO
   methods, then run `dart run build_runner build`.
3. DAO tests on `testDatabase()` (in-memory SQLite).
4. Providers in `viewmodel/`.
5. Screen and widgets with all four states and accessibility.
6. Route in `app_routes.dart` + a `RouteNames` constant.
7. Widget tests (empty and loaded) via `testAppWidgets`, and add the screen to
   `test/widget/accessibility_test.dart`.
8. Sabotage-check every new test (section 8).

**A new exercise in the seed:** edit `assets/data/exercises.json` (it only affects new
installs, because the seed runs on database creation only).

## 8. Review gate (before every commit)

1. `dart run build_runner build`, with generated code committed alongside its source.
2. `flutter analyze` must say **No issues found**.
3. `flutter test` must be **all green**. Record the count.
4. **Sabotage check** for every new test: break the guarded code, prove the edit landed,
   see the test fail, then revert. A test that never failed proves nothing. Log it in BOARD.md.
5. Never edit an existing test to make it pass. If a test looks wrong, stop and record it.
6. One concern per commit. Moves and behaviour changes never share a commit.
7. No AI attribution in commit messages.

## 9. Verify commands

```bash
flutter pub get
```

```bash
dart run build_runner build
```

```bash
flutter analyze
```

```bash
flutter test
```

Note: this build_runner version no longer accepts `--delete-conflicting-outputs` (it warns
and ignores it).

## 10. Workflow notes and traps

- **Widget tests and drift:** use `testAppWidgets` (`test/helpers/pump_app.dart`). It
  tears down inside the test body, because flutter_test checks for pending timers before
  `tearDown` runs, and it closes the database on real time (`runAsync`).
- **Seed multi-step test data with `testAppWidgets(setup: ...)`.** Multi-step database work
  inside `dbCall`/`runAsync` after the UI is up can **deadlock**: the UI's drift stream
  queries hold the database lock and only finish when the fake-async zone is pumped.
- **Codegen ordering:** `build.yaml` makes drift write its own `*.drift.dart` parts and run
  before riverpod_generator. With drift's default shared builder, any provider whose
  signature mentions a drift class fails with `InvalidTypeException`.
- **Linux desktop build in a restricted network:** `sqlite3_flutter_libs` downloads SQLite
  from sqlite.org at CMake time. Without network access to it the Linux build fails (Android
  and iOS are unaffected).
- `applicationId` / `namespace` are still `com.example.workout_tracker`. They must change
  before any store release (the owner decides the id).

## 11. Known-stale docs

- `BOARD.md` log entries before 2026-11-04 describe v1 (GetStorage, three screens). They
  are history and are kept as written.
- `graphify-out/` (local only, gitignored) indexes v1. Rebuild it before relying on it.
