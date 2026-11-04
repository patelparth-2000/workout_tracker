# workout_tracker v2 — architecture

Written before the v2 code (standard 1: design first). Every tradeoff that shaped the code is
recorded here, not only in a chat log (standard 8). If this file disagrees with the code, the code
is right and this file must be corrected.

## 1. What v2 is

A local-first strength-training logger. No backend, no account, no network calls (standard 6 is
out of scope by design). The user:

1. picks exercises from a seeded library (~60) or creates their own,
2. optionally saves routines (templates),
3. runs a live workout: logs weight × reps per set, ticks sets complete, a rest timer starts,
4. reviews history, personal records and progress charts,
5. backs the whole database up to a JSON file and restores it.

Proposed MVP line (the owner decides — standard 1): Phase 1 + Phase 2 (library, routines, active
workout, rest timer, history, settings). Progress/backup/plate calculator are post-MVP polish.

## 2. Folder layout

The existing `src/<feature>/{model,view,viewmodel}` convention is kept and extended. One new
top-level folder, `lib/data/`, owns persistence.

```
lib/
  main.dart                 binding init + ProviderScope + App
  app.dart                  MaterialApp.router, light/dark ThemeData, theme mode from settings
  routes/app_routes.dart    goRouterProvider (the one hand-written provider), _AppPaths (private), RouteNames
  common/widget/            shared, reusable widgets (state views, dialogs, number field, toast)
  utils/                    design tokens (colours, spacing, theme), asset constants, pure maths
  data/
    app_database.dart       drift database, schema version, MigrationStrategy, seeding hook
    tables.dart             table definitions
    daos/                   one DAO per aggregate; DAOs ARE the data layer (no repository on top)
    database_provider.dart  @riverpod AppDatabase (keepAlive), overridden in tests
    seed/                   exercise seed loader (assets/data/exercises.json)
    legacy/                 v1 GetStorage model + one-shot importer
    backup/                 JSON backup/restore + CSV export (pure codec + file I/O split)
  src/
    startup/                opens DB, seeds, runs legacy import; loading / error+retry
    shell/                  StatefulShellRoute bottom navigation (5 tabs)
    workout/                Workout tab: start empty / from routine, routines list + editor
    active_workout/         live session screen, set rows, rest timer
    history/                paged history list + session detail/edit
    exercises/              library: search, filter, detail, custom create/edit/archive
    progress/               PRs + charts per exercise
    settings/               unit, default rest, theme, backup/restore, plate calculator
```

Why no repository layer: a 1-user on-device app with one storage engine. A repository over a DAO
would be a pass-through with nothing to abstract (standard 5: "a layer that exists only to satisfy a
diagram is coupling"). Tests use a real in-memory SQLite instead of mocks.

## 3. Data model (drift / SQLite)

Weights are stored canonically in **kg as REAL**; reps as INTEGER. Conversion to lb happens only
for display/input (1 kg = 2.2046226218 lb, 1 decimal shown). Ids are INTEGER PRIMARY KEY
AUTOINCREMENT. Dates are drift DateTime (unix seconds — timezone-independent; rendered in local
time). `PRAGMA foreign_keys = ON` in `beforeOpen`.

| Table | Columns |
|---|---|
| exercises | id, name UNIQUE (case-insensitive via `COLLATE NOCASE`), muscle_group, equipment, description, gif_asset NULL, is_custom, archived |
| routines | id, name, notes NULL, position, created_at |
| routine_exercises | id, routine_id FK→routines CASCADE, exercise_id FK→exercises, position, target_sets, target_reps NULL, rest_seconds NULL, superset_group NULL |
| workout_sessions | id, routine_id NULL FK→routines SET NULL, name, started_at, ended_at NULL, notes NULL |
| session_exercises | id, session_id FK→workout_sessions CASCADE, exercise_id FK→exercises, position, superset_group NULL, notes NULL |
| set_entries | id, session_exercise_id FK→session_exercises CASCADE, position, weight_kg REAL, reps INT, set_type TEXT default 'normal', rpe REAL NULL, completed_at NULL |
| app_settings | id = 1 (single row), unit 'kg'\|'lb', default_rest_seconds, theme_mode 'system'\|'light'\|'dark', legacy_imported_at NULL |

Indexes: `workout_sessions(started_at)`, `session_exercises(session_id)`,
`session_exercises(exercise_id)`, `set_entries(session_exercise_id)`.

`exercises` are never hard-deleted: they are referenced by history. Built-ins and customs both
**archive** (hidden from pickers, still resolvable in history). `exercise_id` FKs therefore have
no cascade (RESTRICT by default) — deleting an exercise that history uses must fail loudly.

Reserved now so later features need no migration: `superset_group`, `set_type`, `rpe`.

**Schema version 1** with a `MigrationStrategy` (`onCreate` creates all + indexes + seeds;
`onUpgrade` is in place, empty, ready for v2). Tradeoff recorded: drift over GetStorage/Hive
because PRs/history need relational queries and aggregation in SQL, schema migrations are
first-class, and logging a set writes one row instead of rewriting the whole JSON blob (the v1
cost grows linearly with history — standard 4).

### Derived values (never stored)

- **Volume** of a set = `weight_kg × reps`; only **completed** sets (`completed_at IS NOT NULL`)
  count toward volume, records and charts.
- **e1RM** (Epley) = `w × (1 + reps/30)`; reps = 1 → `w`; reps ≤ 0 is not a lift and is excluded.
- **PR**: a completed set is a record when its e1RM is strictly greater than the best e1RM of that
  exercise in all sessions started before this one, and it is the best such set in its session.
  Ties are not records. The very first time an exercise is logged sets the baseline and shows no
  badge (avoids every imported entry lighting up as a "record").
- All aggregation (bests, per-session series, totals) is done **in SQL**, never by loading all
  rows into Dart and folding.

## 4. Data flow

```
Widget (ConsumerWidget) --ref.watch--> @riverpod provider --watch()/get()--> DAO --> SQLite
        |                                                                       ^
        +--ref.read(x.notifier).action()--> Notifier --DAO write (transaction)--+
```

- Reads are drift `watch()` streams exposed as `@riverpod Stream<T>` providers, so a write anywhere
  refreshes every screen showing that data without manual invalidation.
- Writes that touch more than one row run in one `transaction`.
- Screens map `AsyncValue` to the shared `AsyncValueView` (loading / error+retry / empty / loaded).
- User feedback: `showToast(message:)` through the global `scaffoldMessengerKey`.

## 5. Navigation

go_router, navigation **by name only** (`RouteNames` + `pushNamed`/`goNamed`).

```
/startup                         StartupScreen (loading → error+retry → goNamed(workout))
StatefulShellRoute (bottom nav)
  /workout                       WorkoutHomeScreen
     routine/new, routine/:id    RoutineEditScreen
  /history                       HistoryScreen
     :id                         SessionDetailScreen
  /exercises                     ExerciseListScreen
     :id                         ExerciseDetailScreen
     new, :id/edit               ExerciseEditScreen
  /progress                      ProgressScreen
  /settings                      SettingsScreen
     plates                      PlateCalculatorScreen
/active                          ActiveWorkoutScreen (full screen, above the shell)
```

Route arguments are ids in the path (`pathParameters`), never objects in `extra:`. That removes the
v1 identity-equality trap by construction.

## 6. Legacy migration (v1 → v2)

v1 stored `List<WorkoutModel>` as one JSON string in GetStorage key `workoutList`, with String
weight/reps/sets, no id, no date.

On startup, after the DB opens and **only if `app_settings.legacy_imported_at` is NULL** and the
key exists:

1. Decode. Failure (not JSON, not a list, wrong element shape) → **nothing is written, the key is
   not touched**, the startup screen shows the error with Retry. Data is never silently treated as
   empty (fixes v1 trap 3).
2. One transaction: create a workout session "Imported workouts" dated now (v1 had no dates);
   for each entry map `type` to an exercise by name (case-insensitive) or create a custom exercise;
   `trim()` + `num.tryParse` weight / reps / sets; `sets = N` → N set entries (completed);
   anything unparseable is kept verbatim in the session-exercise `notes` — never dropped.
   Unparseable sets → 1 set. Unparseable weight → 0 kg; reps → 0, with the raw text in notes.
3. Set `legacy_imported_at` **in the same transaction**, so the import is atomic and idempotent:
   a crash mid-import leaves nothing behind and retries next launch; a second launch never
   imports twice.
4. The legacy key is **kept** this release (rollback safety). A later release may delete it.

An empty list is a valid v1 state: the flag is set and nothing is imported.

## 7. State conventions

- Riverpod 3 code generation only (`@riverpod` / `@Riverpod(keepAlive: true)` + `part 'x.g.dart'`).
  The only hand-written provider is `goRouterProvider`.
- Screens are `ConsumerWidget` (or `ConsumerStatefulWidget` when they own controllers).
  `ref.watch` for values, `ref.read(x.notifier)` for actions.
- `TextEditingController`s live in the widget `State` that shows them and are disposed there
  (v1 kept them in a provider, which couples lifecycle to provider caching).
- Time is read through `clockProvider` so the rest timer and "now" are testable with a fake clock.
- Riverpod 3 automatic retry is disabled in `ProviderScope(retry: ...)`: a failing startup must
  surface its error and wait for the user's Retry, not loop.

## 8. Rest timer

State = `endsAt` timestamp (+ total duration for the progress ring). Remaining time is always
`endsAt - clock.now()`, so backgrounding the app cannot make it drift. A 1-second ticker only
triggers repaints; it is cancelled when no timer runs and on dispose. Auto-starts when a set is
ticked complete: routine's per-exercise rest, else settings default. ±15 s, skip. No notification
(out of scope, and it would need a new permission).

## 9. Backup

- Export: every table to `{"format":"workout_tracker_backup","version":1,"exported_at":...,
  "tables":{...}}`, shared through the OS share sheet as a `.json` file.
- Import is **untrusted input** (standard 9): format marker, version, every field's type and range,
  and referential integrity (every FK points at a row in the file) are validated **before** any
  write. Then one transaction deletes all rows and inserts the file's rows. Any failure rolls back
  and existing data is intact. The user confirms that import **replaces** all data.
- CSV export of all sets (date, workout, exercise, set, weight kg, reps, type, rpe, completed).
- Size bound: the file is read fully into memory; a hard cap (20 MB) rejects anything larger
  before decoding, so a hostile file cannot OOM the app.

## 10. Performance bounds (standard 4)

- History is paged with keyset pagination (`started_at`, `id`) at 30 rows per page in a
  builder list. Totals per page are one grouped query, not a query per row.
- Exercise search/filter runs in SQL (`LIKE` + `WHERE`), the list is a builder list (library is
  bounded at hundreds, not unbounded).
- Charts query one exercise over a chosen date range with per-session grouping in SQL.
- Seeding is one batch insert. Legacy import is one transaction with batched inserts.
- What breaks at 1000x data: nothing stops working; chart queries over years of data get slower
  per exercise (indexed join, still bounded by the range filter). Left as is and said so.

## 11. UI system (standard 7)

- Tokens: `lib/utils/color_constant.dart` (semantic colour roles for light and dark),
  `lib/utils/app_spacing.dart` (spacing / radii), `lib/utils/app_theme.dart` (ThemeData built only
  from tokens). Screens use `Theme.of(context)` / tokens, never raw `Color(0x..)` or magic
  `EdgeInsets`.
- Shared components in `lib/common/widget/` with typed params and defaults: `AsyncValueView`,
  `EmptyState`, `ErrorState`, `LoadingState`, `ConfirmDialog`, `NumberField`, `SectionHeader`.
- Accessibility: tooltips on every icon-only button, `ExcludeSemantics` on decorative images,
  `Semantics` labels on custom controls (set-complete checkbox, timer), 48×48 dp minimum targets,
  completion/PR shown with icon + text, not colour alone; layouts scroll so 2× text does not
  overflow.

## 12. Decisions not taken (and why)

- **No repository interfaces** (see §2).
- **No notifications for the rest timer** — needs a permission and background work; not requested.
- **No health integrations, reminders, body measurements** — excluded by the plan.
- **applicationId stays `com.example.workout_tracker`** — the owner has not given a real id.
- **Legacy GetStorage key not deleted** this release — rollback safety.
