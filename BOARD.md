# workout_tracker — Board

The single record of what changed here, who did it, when, and from where. The boss reaches this
project from the portfolio workspace, from VS Code directly, and from a phone — all three read
this file. **A change that is not on this board is a change the next manager will not know about.**

Newest entry at the top. Do not rewrite history; append.

---

## Status: v2 built on a branch, awaiting the owner's on-phone check and merge

v1 was a three-screen GetStorage scratchpad. **v2 is a full local-first workout tracker**, built on
branch `claude/sweet-bardeen-e4aswb` (not yet merged; `main` is untouched). See
`docs/V2_PROGRESS.md` for the hand-off and the on-phone checklist.

| | |
|---|---|
| Branch | `claude/sweet-bardeen-e4aswb`, 33 commits ahead of `main` (`main` = `a3b718b`, untouched) |
| Remote | https://github.com/patelparth-2000/workout_tracker.git |
| `flutter analyze` | **No issues found** (verified 2026-11-04, Flutter 3.41.9) |
| `flutter test` | **170 tests, 170 passing, 0 failing** (verified 2026-11-04) |
| Size | 69 hand-written Dart files in `lib/` (+18 generated), 16 test files |
| Stack | Riverpod 3 + codegen, go_router 16, **drift (SQLite)**, fl_chart, share_plus, file_picker |
| Docs | `docs/ARCHITECTURE.md`, `docs/RULEBOOK.md`, `docs/V2_PROGRESS.md`, README |

---

## Open items

### Needs a decision from the boss

- **MVP line.** Proposed: Phases 1+2 (library, routines, live workout, rest timer, history,
  settings). Done, along with Phase 3. Standard 1 says the boss decides.
- **`applicationId` / `namespace` are still `com.example.workout_tracker`**
  (`android/app/build.gradle.kts`). Blocks any store release. Give a real id.
- **Merge.** Run the on-phone checklist in `docs/V2_PROGRESS.md`, then merge
  `claude/sweet-bardeen-e4aswb` into `main`. The plan named `feature/workout-v2`; the cloud
  environment assigned this branch name instead.
- **Receipt images** (`images/receipt/image_10..14.jpeg`) are unrelated to the app. Left
  untouched as instructed.

### Not done (deliberately)

- **Supersets.** `superset_group` columns are reserved in schema v1, so no migration is needed.
- **RPE / set types in the UI.** Columns are reserved and backups already carry them.
- **Health integrations, reminders, body measurements.** Excluded by the plan.
- **Persisting custom plate sets** in the plate calculator. It uses standard kg/lb sets.
- **Deleting the legacy GetStorage key.** Kept this release for rollback safety; remove in a
  later release.
- **Standard 10 (CI, signing, monitoring).** Opt-in and not requested.

### Known limits (said, not hidden)

- Backup export/import holds the whole database in memory, with a 20 MB import cap. At 1000×
  today's data it gets slower but still works.
- The plate calculator is greedy: optimal for standard plate sets, not guaranteed for unusual
  custom sets.
- Linux desktop builds need network access to sqlite.org at CMake time (Android/iOS unaffected).

### Environment

- On the owner's Windows machine the SDK is at `C:\Flutter_sdk_src\flutter\bin\flutter.bat`.
  Run `pub get` first in a fresh session.
- `pubspec.lock` is now committed **with** the deliberate v2 dependency changes.

---

## Log

### 2026-11-04 · cloud session 2026-11-04 (sessions 1–3, run as one)

**Who / where:** cloud Claude Code session, on branch `claude/sweet-bardeen-e4aswb` (the
branch the cloud environment assigned; the plan named `feature/workout-v2`). `main` was not
touched. Brief: `CLOUD_PLAN_2026-11-04.md` (all three phases).

**Baseline, measured cold:** `flutter analyze` → No issues found. `flutter test` → 2/2.
**End:** `flutter analyze` → **No issues found**. `flutter test` → **170/170**. Every commit
was gated on both.

**What changed** (33 commits, one concern each):
- Phase 1: architecture doc first; 13 characterisation tests for the v1 `WorkoutList`; cleanup
  (dev_dependencies, untracked GetStorage files, dead assets, README); Riverpod 2.6 → 3.3; drift
  schema v1 (7 tables, 4 indexes, FKs on); 65-exercise seed; atomic, idempotent v1 import;
  light and dark themes from tokens; startup screen; 5-tab shell. The v1 screens were retired.
- Phase 2: exercise library, routines, live workout with set logging and previous values, rest
  timer (end timestamp + injected clock), paged history with editing, settings.
- Phase 3: progress tab (bests, e1RM and volume charts, PR badges), JSON backup and restore
  with full validation, CSV export, an accessibility and 2× text pass enforced by tests,
  plate calculator, README, `docs/RULEBOOK.md`, `docs/V2_PROGRESS.md`.

**Bugs found by tests while building, fixed in the code:**
- An auto-dispose command controller read with `ref.read` was disposed before its method
  ran (`UnmountedRefException`). All command controllers are now `keepAlive`.
- The routine editor set its dirty flag without `setState`, so the unsaved-changes guard
  never armed.
- The rest countdown read 1:29 the moment it started; it now rounds up.
- The backup restore spinner kept running behind the confirm dialog.
- At 2× text: the section header squeezed its title to one letter per line, the routine card,
  the rest dropdown and the exercise-form dropdowns overflowed, and the exercise filter bar
  left no room for the list. The live-workout title was a sub-48 dp tap target.

**Found on the real Linux build (not by tests), fixed:** prefilled "0" values weren't selected
on focus (typing appended); completed sets were greyed out as "disabled"; the progress chart
collapsed same-day workouts into a vertical line and had cluttered axis edge labels.

**Real-build verification:** a Linux debug build, driven at phone size under Xvfb. Covered
seed + GIFs, a full workout, rest timer, previous values, live PR badge, **survival after
SIGKILL**, dark mode, and **a real v1 `GetStorage.gs` import** ("100 " trimmed, "abc" kept as a
note, key kept, no second import on relaunch). The build needed a local CMake patch in the pub
cache (sqlite.org is unreachable here). It was restored afterwards and not committed.

**Test-file edits, all deliberate:**
- `test/unit/workout_provider_test.dart` (2 v1 tests) and
  `test/unit/workout_list_provider_test.dart` (13 characterisation tests) were **deleted
  together with the v1 code they tested** (commit `fd5c5a3`). They pinned behaviour of code
  that no longer exists. v1 data compatibility is now covered by the importer tests, including
  against real GetStorage.
- `test/data/legacy_importer_test.dart`: `tearDownAll` stopped deleting the GetStorage temp
  dir. An async GetStorage flush raced the delete and made the test flaky. No assertion was
  changed (commit `42ba9e7`).
- In tests not yet committed at the time, five of my own new assertions turned out to be wrong
  and were corrected before committing: the routine-test "Previous" count, the CSV line count
  (it includes the in-progress workout), a regex anchor, two `kg` finders, and the PR semantics
  finder. Each was checked against the code's documented behaviour, not loosened to pass.

**Sabotage checks.** Every new test was broken on purpose, the edit was confirmed to have
landed (file compare), the test was seen to fail, and the change was reverted. Survivors were
reported, and a new test was added for each, except two that are equivalent mutants.

| Guarded file | Sabotage | Test(s) that failed |
|---|---|---|
| workout_list_provider.dart | `index != -1` -> `== -1` in updateWorkout | both updateWorkout characterisation tests |
| workout_list_provider.dart | catch block rethrows | corrupt JSON / write-after-corrupt / non-list JSON |
| workout_list_provider.dart | _saveToStorage skips storage.write | add, persist, delete, clear, write-after-corrupt |
| workout_list_provider.dart | deleteWorkout removes last instead of index | deleteWorkout removes by index |
| workout_list_provider.dart | clearWorkouts does not save | clearWorkouts stores "[]" |
| workout_list_provider.dart | non-list JSON decoded as a fake entry | valid JSON that is not a list |
| workout_model.dart | fromJson trims weight | round-trips every field as a String |
| app_database.dart | PRAGMA foreign_keys = OFF | FK enforced, exercise delete blocked, session cascade, routine cascade |
| workout_dao.dart | previous-values SQL drops `ended_at IS NOT NULL` | **survived at first** -> added "an unfinished session never counts as previous", which then failed |
| workout_dao.dart | keyset `ws.id < ?` -> `<=` | history paging 5 and 6 sessions |
| workout_dao.dart | volume counts incomplete sets | active excluded; volume completed only |
| workout_dao.dart | no one-active-session guard | only one active session at a time |
| exercise_dao.dart | LIKE escaping removed | LIKE wildcards are literal |
| exercise_dao.dart | duplicate-name check removed | custom create rejects duplicates |
| workout_dao.dart | exercise positions not rewritten | add/move/remove keeps positions dense |
| workout_dao.dart | prefill ignores previous sets | starting from a routine copies ... previous values |
| workout_dao.dart | updateSet skips validation | sets: ... update validates |
| exercise_seed.dart | duplicate-name check disabled | parseExerciseSeed rejects malformed input |
| assets/data/exercises.json | Squat gif_asset key removed | five v1 exercises keep names, GIFs, descriptions |
| exercise_seed.dart | type check inverted | parseExerciseSeed rejects malformed input |
| app_database.dart | loader also invoked in beforeOpen on reopen | seeds on creation only |
| legacy_importer.dart | already-imported flag ignored | second launch does not import twice |
| legacy_importer.dart | "done" flag write removed | clean data; second launch; no key / empty list |
| legacy_importer.dart | non-list JSON returned as empty | corrupt data (not a list) |
| legacy_importer.dart | unparseable reps not kept as a note | messy strings ... never dropped |
| legacy_importer.dart | sets cap (50) removed | messy strings ... (9999 sets) |
| legacy_importer.dart | writes outside the transaction | a failure mid-import rolls everything back |
| legacy_importer.dart | `.trim()` before num.tryParse removed | **survived — equivalent mutant**: Dart's num.tryParse ignores surrounding whitespace itself |
| legacy_importer.dart | exercise cache keyed case-sensitively | **survived — equivalent mutant**: the fallback findByName is case-insensitive, so only an extra query results |
| app.dart | themeMode hardcoded to light | shell test (dark) |
| app_shell.dart | Settings destination relabelled | shell tests (light, dark) |
| startup_screen.dart | "Continue without importing" hidden | corrupt v1 data: error with retry, continue |
| startup_screen.dart | startup never routes to the shell | both shell tests + valid v1 import |
| app_startup_provider.dart | importer bypassed | corrupt v1 data; valid v1 data imported |
| units.dart | lbPerKg = 2.2 | lb conversion uses 2.2046226218 (+ others) |
| units.dart | formatNumber truncates | formatting rounds to one decimal |
| units.dart | comma decimal not accepted | input parsing |
| workout_math.dart | reps 1 goes through Epley | Epley e1RM |
| workout_math.dart | reps 0 allowed | Epley e1RM |
| units.dart | no thousands separators | volume has thousands separators |
| settings_screen.dart | unit segment callback emptied | settings change unit, rest and theme |
| settings_screen.dart | rest dropdown ignores choice | settings change unit, rest and theme |
| settings_provider.dart | controller auto-dispose (original code) | settings test failed with UnmountedRefException before the keepAlive fix |
| exercise_filter_bar.dart | search onChanged not wired | library lists, searches, filters |
| exercise_edit_screen.dart | duplicate-name error swallowed | create a custom exercise; duplicates rejected |
| exercise_detail_screen.dart | archive toggle inverted | detail shows info; archive hides it |
| exercise_edit_screen.dart | edit form not prefilled | custom exercise can be edited |
| exercise_edit_screen.dart | name validator removed | create a custom exercise ... |
| rest_timer_provider.dart | remaining = total (ignores clock) | start sets end timestamp; background gap |
| rest_timer_provider.dart | adjust ignores delta | +15 / -15 adjust |
| rest_timer_provider.dart | total not grown on +15 | +15 / -15 adjust |
| rest_timer_provider.dart | adjust below zero keeps running | +15 / -15 adjust |
| rest_timer_provider.dart | adjusting an expired timer revives it | adjusting an expired timer does nothing |
| rest_timer_provider.dart | adjust below zero keeps running | **survived at first** (isRunning false anyway) -> added 'removing more time than is left resets to idle', which failed |
| set_row.dart | invalid values can be ticked done | log sets: ... validate, complete |
| set_row.dart | lb input stored without conversion | lb display: typed pounds stored as kg |
| active_workout_providers.dart | rest timer not started on completion | log sets ... rest timer |
| rest_timer_bar.dart | countdown floors (1:29 at start) | log sets ... rest timer (this was a real bug first, found by the test) |
| active_workout_screen.dart | finish skips the no-completed-sets confirm | finish moves the workout to History |
| workout_home_screen.dart | Start allowed while a workout is active | in-progress workout shows Resume and blocks |
| routine_edit_screen.dart | dirty flag set without setState (original bug) | routine editor warns before discarding |
| routine_edit_screen.dart | target sets dropped on save | routines: create with the picker, start it |
| history_providers.dart | first page reports hasMore = false | loaded list pages past the first 30 (a first attempt, `return` in loadMore, did not compile and was discarded as a sabotage) |
| history_providers.dart | no refresh on data change | edit a set in history, then delete |
| edit_set_dialog.dart | weight validation removed | edit a set in history ... |
| session_detail_screen.dart | edit not saved | edit a set in history ... |
| session_detail_screen.dart | delete not wired | edit a set in history ... |
| progress_dao.dart | Epley divisor 30 -> 40 | bests ignores incomplete...; series |
| progress_dao.dart | reps = 1 special case removed | best weight, e1RM, volume computed in SQL |
| progress_dao.dart | ties count as records | a tie is not a record |
| progress_dao.dart | every qualifying set marked, not just the best | beating the prior best marks only the best set |
| progress_dao.dart | later sessions included in "prior" | **survived at first** -> added "a record stays a record after it is beaten later", which then failed |
| progress_dao.dart | unfinished sessions counted in bests | bests ignores ... unfinished sessions |
| progress_dao.dart | zero-rep sets qualify | bests ignores ...; reps 0 never counts |
| progress_dao.dart | range filter ignored | series ... range filter |
| active_workout_screen.dart | record ids not passed to the live card | completing a set that beats your best shows the PR badge |
| session_detail_screen.dart | history PR badge hidden | a record set shows a PR badge in history |
| progress_chart.dart | chart plots kg regardless of unit | **survived at first** -> added "the chart plots in the display unit", which then failed |
| progress_screen.dart | metric toggle ignored | loaded: records, chart, unit switch, metric toggle |
| exercise_bests_grid.dart | bests always in kg | loaded: ... unit switch |
| backup_codec.dart | newer version accepted | rejects ... newer version |
| backup_codec.dart | set FK check skipped | rejects ... dangling foreign key |
| backup_codec.dart | weight range unchecked | rejects ... weight above bound |
| backup_codec.dart | replace not in a transaction | **survived at first** (the old rollback test failed on the first delete) -> added "an insert failing AFTER the deletes still rolls back", which then failed. A first sed attempt did not compile and was discarded |
| backup_codec.dart | CSV formula not neutralised | fields are quoted and formulas neutralised |
| backup_codec.dart | size cap removed | oversized file is rejected |
| backup_codec.dart | GIF path not sanitised | non-bundled GIF paths are dropped |
| backup_codec.dart | duplicate exercise names allowed | rejects ... duplicate exercise name |
| backup_codec.dart | settings row not restored | export -> import -> export is identical |
| backup_section.dart | confirmation answer ignored | **survived at first** (no test pressed Cancel; it was committed in 3390311 before this was caught) -> added "cancelling the confirmation keeps the current data", which then failed |
| backup_section.dart | rejection message replaced by "Error" | an invalid file is rejected with a message |
| backup_section.dart | CSV tile exports JSON | export CSV shares the sets |
| rest_timer_bar.dart | "+15 s" icon button without tooltip | Active workout meets ... label guidelines (light, dark) |
| set_row.dart | done button shrunk to 30 dp | Active workout meets tap-target guideline (light, dark) |
| session_detail_screen.dart | pale grey text | Session detail meets contrast guideline (light) — dark correctly passes |
| routine_edit_screen.dart | rest dropdown not expanded | Routine editor does not overflow at 2x text |
| exercise_edit_screen.dart | muscle dropdown not expanded | New exercise form does not overflow at 2x text |
| plate_math.dart | plates sorted ascending | exact kg load; fractional; lb 225/315; only selected plates |
| plate_math.dart | hundredths replaced by truncation | 5 plate tests |
| plate_calculator_screen.dart | plate chip toggle ignored | plate calculator loads each side |
| plate_calculator_screen.dart | unit ignored (always kg) | plate calculator uses lb plates |
| progress_chart.dart | chart drawn for a single point | one workout shows a hint instead of a one-point chart |
| progress_chart.dart | x axis by time again | two workouts on the same day are two separate points |
| set_row.dart | no select-all on focus | set inputs select their text on focus |
| set_row.dart | completed rows disabled (greyed) again | ... done rows are read-only |

**Deliberately not done:** supersets, RPE/set-type UI, health/reminders/body measurements,
persisted plate sets, deleting the legacy key, standard 10. No `applicationId` change and no
change to `images/receipt/` (as instructed). **Not pushed:** the push was blocked by the
session's permission policy, so the branch is committed locally in the cloud container and
waits for the owner's approval to push.

#### Facts for the local manager skill

- **Stack:** flutter_riverpod 3.3.1 / riverpod_annotation 4.0.2 / riverpod_generator 4.0.3;
  drift 2.31 + drift_flutter 0.2.8 + drift_dev; fl_chart 1.3; share_plus 13.3; file_picker
  13.3; path_provider 2.1; intl 0.20. `get_storage` stays, but only for the one-shot v1 read.
  `mocktail`, `integration_test` and `flutter_launcher_icons` are dev deps;
  `flutter_native_splash` was removed.
- **Persistence:** SQLite via drift, file `workout_tracker.sqlite` in the app documents dir.
  Schema v1 (see ARCHITECTURE §3). GetStorage key `workoutList` is read once and never written.
- **Layout:** `lib/data/` (tables, DAOs, models, seed, legacy, backup) is new.
  `lib/src/{startup,shell,workout,active_workout,history,exercises,progress,settings}`. v1
  folders `splash_screen`, `workout_list_screen`, `workout_screen` and `common_function.dart`
  were removed. Tokens live in `lib/utils/{color_constant,app_spacing,app_theme}.dart`.
- **Conventions (new):** command controllers are `keepAlive`; route args are ids in path
  params (no `extra:`); `clockProvider` for time; `testAppWidgets` + `setup:` for widget tests;
  `build.yaml` sets drift `not_shared` (`*.drift.dart`) before riverpod_generator; build
  command is `dart run build_runner build` (the `--delete-conflicting-outputs` flag is now
  ignored).
- **Traps resolved:** identity-based `updateWorkout` (ids everywhere); edit-form freeze
  (forms load once in `initState`); corrupt storage treated as empty (error screen, data
  kept); String numerics (REAL kg / INT reps); no date/id (sessions dated, ids everywhere);
  `WorkoutList` had zero tests.
- **Traps that remain:** `applicationId` placeholder; Linux build needs sqlite.org.
- **New traps:** drift streams + `runAsync` multi-step work can deadlock in widget tests (use
  `setup:`); an auto-dispose provider that is only `ref.read` dies immediately.
- **Test count:** 170 (was 2).

### 2026-08-22 — project-analyst (portfolio workspace, `E:\Flutter Projects\My Projeccts`)

First registration. The project had never been analysed and had no `.claude/` folder and no
`CLAUDE.md`, so nothing existing was overwritten.

Read all 21 Dart files, `pubspec.yaml`, `analysis_options.yaml`, the README and the git history.
Verified the build rather than trusting docs:

- `flutter pub get` — succeeded (Flutter 3.41.9, Dart 3.11.5).
- `flutter analyze` — **No issues found.**
- `flutter test` — **2 tests, all passed.**
- Secret scan across `lib/`, `android/`, `ios/`, `web/` and `pubspec.yaml` — **none found.**

Written:

- `.claude/skills/workout_tracker-manager/SKILL.md` — the project's own manager.
- `.claude/agents/workout_tracker-lead.md` — plan/review, opus, no write access.
- `.claude/agents/workout_tracker-coder.md` — implementation.
- `.claude/agents/workout_tracker-tester.md` — tests.
- `BOARD.md` — this file.

Three agents, not more; 21 files does not justify a larger team.

Left alone deliberately: all application source, the README (its inaccuracies are logged above
rather than silently fixed), `pubspec.yaml`, and the tracked `GetStorage` artifacts. `pubspec.lock`
was modified by `pub get` during verification and **restored with `git checkout`**, so the working
tree is exactly as found — clean, and in sync with `origin/main`.

Nothing was committed or pushed.

---

```
2026-08-22 · main-manager (workspace: My Projeccts)
  Levelled this project's agents against the portfolio house rules. Appended to EVERY
  agent in .claude/agents/:
    - Version control: never commit/push/branch/PR without permission for that specific
      action; no AI attribution in commit messages.
    - Board recording: every task hands up one BOARD.md line (agents don't edit the board
      themselves; the manager appends).
    - RCA: anything beyond a trivial fix reports Symptom / Root cause / Why it survived /
      Edge cases / Guard. "Why it survived" must name a gate that failed.
  Reason: an audit found these rules were carried unevenly — some agents could have
  committed without knowing the rule applied, and several projects had no agent that
  recorded anything to the board.
  Documentation only. No application code, no dependency and no test was touched.
```

> Also added an accessibility standard to every agent here: labelled controls, no
> colour-only information, `ExcludeSemantics` on decorative icons, 48x48 tap targets.
> Baseline in this project is **zero** files using `Semantics`. Forward-looking rule —
> applies to code you touch, not a mandate to sweep the codebase.

2026-08-25 · Main Manager (My Projeccts workspace)
  Standing performance order added — no code touched. Appended a `## Performance standard —
  standing order` section to CLAUDE.md (identify bottlenecks / inefficient logic / unnecessary
  rebuilds / expensive operations / memory leaks; report breakdown, strategy, production-ready
  code, scaling note), with a proportionality paragraph written for THIS project and two hard
  rules: correctness outranks speed, and no unmeasured speedup claims. Same order appended to all
  3 agent files and to the manager skill, which now owns enforcing it. Set once by the boss —
  agents are not to wait for it to be restated.

2026-08-25 · Main Manager (My Projeccts workspace)
  Standing performance order extended with the future-scale rule, per the boss. Written into
  CLAUDE.md, all agent files and the manager skill. "Used by millions of users" is a design
  constraint for the future, not a claim about today: the test on every change is "what breaks if
  this runs 1000x more often, or over 1000x the data?" — if it STOPS WORKING (crash, OOM, timeout,
  unbounded cache, O(n^2), leak, per-item call in a loop) fix it now regardless of current size; if
  it merely gets slower, leave it and say so. Kept separate from the proportionality paragraph so
  "we have no users yet" cannot be used to skip structural fixes. No code touched.

2026-08-25 · Main Manager (My Projeccts workspace)
  Engineering standards restructured — no code touched. The boss is assembling 10 standing orders
  and has given 2 so far (#4 performance, #5 clean architecture); the rest are placeholder slots.
  They are now authored ONCE in the workspace STANDARDS.md and generated into this project's
  CLAUDE.md between STANDARDS:BEGIN/END markers by `python .claude/sync-standards.py`. Do not
  hand-edit that block; it is overwritten. This project's proportionality note lives in the sync
  script and is written for this project specifically. Agent and manager blocks were rewritten to
  name no individual standard, so adding standards 6-10 will not require touching agent files.
  Standard #5 carries a gate: no behaviour-preserving refactor without a test proving behaviour was
  preserved. New workspace command `/fix-all` audits this project against the standards, reports
  ranked findings, then fixes only what is safe to fix.

2026-08-25 · Main Manager (My Projeccts workspace)
  Standards 1-3 received and synced (5 of 10 now). #1 build a production-ready MVP from the ground
  up - scoped as a STARTING GATE for new projects/platform folders/subsystems, not an audit rule, so
  it reads as not-applicable here. #2 audit the codebase like a senior engineer joining it - findings
  must outlive the session and land on the board; a graphify graph is an input, not the audit. #3
  debug like a production outage - reproduce first, cause not symptom, one suspect at a time, edge
  cases are part of the deliverable, and say plainly when something is a hypothesis. Assessment
  added to workspace COMPLIANCE.md: #1 not-applicable, #2 partial (architecture reverse-engineered
  via project-analyst + graphify, findings half missing), #3 already followed - all agent files
  carry root-cause discipline from the registration template. No code touched.

2026-08-25 · Main Manager (My Projeccts workspace)
  Standard 1 rewritten after the boss corrected it, and ownership clarified on 2/4/5. #1 is NOT
  "be an MVP" and mandates no particular pattern: for existing code the rule is a COHERENT STRUCTURE
  APPLIED CONSISTENTLY - Clean Architecture, MVVM, BLoC, feature-folders all pass equally, and size
  does not decide. Only the absence of structure fails (mixed conventions, no UI/logic/data
  separation, nothing enforced). When fixing a mess, pick the structure that fits THIS project and
  extend what it already reaches for; never import a favourite. The greenfield half (design
  architecture before writing code) now applies only to new projects, platform folders and
  subsystems. Standards 1, 2, 4 and 5 are the PROJECT MANAGER's to close, and only on /fix-all -
  everyday work just must not add new violations. Standard 3 still governs how every fix is made.
  COMPLIANCE.md re-scored for #1 against real folder structure. No code touched.

2026-08-25 · Main Manager (My Projeccts workspace)
  Standard 1 gained an MVP-SCOPE clause after the boss clarified MVP = Minimum Viable Product
  (smallest version a real person can use), not a file structure. Key points now written into every
  project: "minimum" applies to the FEATURE LIST, never to engineering quality - a good MVP still
  has clean architecture, security, tests and a real schema. It does NOT judge existing code and is
  not scored in the matrix; having built past an MVP is not a defect and features cannot be
  un-built. It binds what gets built NEXT: the manager states which side of the MVP line a proposed
  feature falls on before work starts, and the boss - never a manager - decides what the MVP is.
  Recorded in COMPLIANCE.md that no project in the portfolio is in a user's hands. No code touched.

2026-08-25 · Main Manager (My Projeccts workspace)
  Standard 6 received and synced (6 of 10): architect the backend BEFORE building it - system
  architecture, component structure, data flow, API design, database schema, caching strategy,
  production-ready code; design complete, implementation minimal. Scoped to apply only where a
  backend exists or is being started, so a deliberately local-first app is out of scope rather than
  in violation. Written in that the two items always skipped are DATABASE SCHEMA and CACHING
  STRATEGY, both expensive to retrofit; a deliberate "no cache, because X" counts as a strategy, an
  absent one does not. Assessment in COMPLIANCE.md: 7 of 8 projects have no backend; only
  Receipt-Scanning-New is assessable and it fails - no database, no cache, no Dockerfile, no auth,
  4 endpoints in a single api/main.py. No code touched.

2026-08-25 · Main Manager (My Projeccts workspace)
  Standard 7 received and synced (7 of 10): build UI as a SYSTEM, not as screens - reusable
  components, scalable component architecture, accessible production-ready interfaces; loading /
  empty / edge / responsive / accessibility / reusability / clean DX. Written in: every view that
  loads or submits owes FOUR states (loaded, loading, empty, error) and the last three are the ones
  skipped; accessibility is part of "done" because framework defaults do not cover icon-only
  buttons, custom-painted widgets or meaningful images; reusable means a real component API with
  design tokens instead of literal colours and spacing. Headless backends are out of scope, not in
  violation. Measured across the 6 Flutter apps for COMPLIANCE.md - the portfolio-wide finding is
  ACCESSIBILITY: 1 file out of 743 has any explicit semantics. No code touched.

2026-08-25 · Main Manager (My Projeccts workspace)
  Ownership model extended to standards 6 and 7 per the boss: existing violations are the project
  manager's to close ON /fix-all, not opportunistically mid-task; everyday work only has to avoid
  adding new ones. Manager-owned on the sweep is now 1 (existing-code half), 2, 4, 5, 6 (only where
  a backend already exists - never propose one to satisfy it) and 7. Standard 3 stays the exception:
  it governs how every fix is made, sweep or not. /fix-all gained a ranked category for missing UI
  states and accessibility - individually small and safe, which is why they never get done, so
  batched per screen rather than one commit per widget. New apps must carry standard 7 from the
  first screen; the 6 Flutter apps have 1 accessible file between them across 743 because nobody
  labelled as they went. No code touched.

2026-08-25 · Main Manager (My Projeccts workspace)
  Standard 8 received and synced (8 of 10): technical lead mode - before any code, ask clarifying
  questions, challenge weak decisions, identify scaling risks, suggest better approaches, prioritise
  simplicity; think 5+ years; then give decisions, tradeoffs, architecture, plan, solution. Written
  in that this standard is ENFORCED BY TOOLS not instruction - every <project>-lead agent has no
  Write and no Edit, and must not work around it via Bash. Also added the 5-year clause: a lead's
  load-bearing facts must be verified against the repo before planning on them, because a lead
  reasoning from a stale premise makes confident wrong calls. Assessment: all 8 leads exist, run on
  opus and cannot edit - no structural failures. No code touched.

2026-08-25 · Main Manager (My Projeccts workspace)
  Standard 9 received and synced (9 of 10): security as a core requirement - vulnerabilities, auth
  flaws, API weaknesses, injection, sensitive data exposure, infrastructure risk; report with
  severity, attack scenarios and secure fixes. Written in: a finding needs a concrete attack
  scenario (who the attacker is, what they control, what they get) or it is noise; severity ranks by
  what an attacker achieves, not how bad the code looks; a clean grep is NOT an audit and must never
  be recorded as one. Named the four recurring issues - unauthenticated endpoints, user-controlled
  paths/filenames, secrets in source and therefore in history (rotate first, deleting the line
  achieves nothing), and client keys misjudged in both directions (Firebase config keys are
  identifiers meant to ship; Maps/Directions keys are billable and must be platform-restricted).
  Manager owns this on /fix-all with ONE exception: a confirmed exploitable vulnerability is
  reported to the boss immediately, never held for a sweep. No code touched.

2026-08-25 · Main Manager (My Projeccts workspace)
  Standard 10 received and synced - THE SET IS NOW COMPLETE AT 10 OF 10. DevOps and deployment:
  deployment architecture, CI/CD, monitoring and logging, reliability, downtime risk, scaling.
  Written in that the checklist must be read against the ACTUAL deployment target - Docker and
  Kubernetes are the server answer, a mobile app deploys as a signed bundle to a store, and
  demanding a container for an app produces theatre. Mapped both shapes explicitly. Two clauses
  added: CI COMES FIRST because it is what makes every other standard enforceable ("tests pass"
  without CI means someone ran them once on one machine), and the FLUTTER RELEASE TRAP - flutter
  create writes a release build type signed with DEBUG KEYS under a TODO, which builds and runs and
  can never be published. Also: deployable is not deployed; whether to ship is the boss's call, but
  not having decided is no reason to have no pipeline.
  Portfolio-wide measurement: 0 CI pipelines, 0 Dockerfiles, 0 crash/error monitoring across all 8
  projects. 1 project (stop_snoozer) has real release signing. No code touched.

2026-08-25 · Main Manager (My Projeccts workspace)
  Set finalised at 10 of 10, plus three structural changes on the boss's instruction.
  1. STANDARD 10 IS NOW OPT-IN. Deployment/CI/Docker/monitoring is documented but dormant - it runs
     only when the boss asks for it by name, is excluded from /fix-all by default (include with
     "/fix-all point 10"), and no agent may raise it as a gap or call a project deficient for it.
     The only live part: never break an existing pipeline or release path. Standards 1-9 remain
     standing orders.
  2. HOUSE RULES added portfolio-wide, drawn from the MoneyKind rulebook and never swept, deferred
     or proportioned: no commit/push/branch/PR/repo action without explicit permission for THAT
     specific action (adjacent approval is not approval); no AI attribution in commits; one task at
     a time, smallest change, no drive-by refactors; never edit a test to make it pass - stop and
     report; code wins over docs; verify before finishing. Written into all 42 agent files and all
     8 manager skills.
  3. EVERY PROJECT OWES A RULEBOOK - one consolidated file covering architecture, file placement,
     state conventions, error flow, ordering rules, review gate, verify commands, workflow notes and
     stale docs. money_kind/mobile/ is the worked example: copy its SECTIONS, never its content.
     Must be assembled from what is already true in the code - an aspirational rulebook is worse
     than none because the team gets reviewed against it.
  New-project creation now asks 8 questions once, up front: what/who, stack+platforms, file
  structure and architecture pattern, state management, persistence+backend, auth, MVP scope, repo
  name and visibility. Deployment is deliberately NOT asked - that is opt-in point 10.
  No code touched.

2026-08-26 · Main Manager (My Projeccts workspace)
  ROUTING CORRECTED BY THE BOSS - structural, affects every project. The Main Manager was BECOMING
  each project's manager (loading its skill, reading its source, editing its files) instead of
  DISPATCHING to it. The /fix-all sweeps on 2026-08-25 ran entirely in the Main Manager's own
  context; all 42 project agents existed and none was used.
  Root cause: the project managers were SKILLS only, so from the workspace root there was no
  <project>-manager agent to delegate to - "become the manager" was the only available path.
  Fixed: eight dispatchable manager agents created at .claude/agents/<project>-manager.md. Each
  loads this project's own manager skill, CLAUDE.md and BOARD.md, works in its own context, and
  reports back with numbers. Routing cards, slash commands, workspace CLAUDE.md, the main-manager
  skill and /fix-all were all rewritten from "hand over / become" to "dispatch".
  The Main Manager now has exactly three jobs: CREATE a new project and its team, REPAIR a manager
  or agent file that is stale or wrong (it is their boss), and ROUTE/RELAY/SYNTHESISE across
  projects. Everything else about a project goes to that project's manager.
  project-analyst and the create-a-project flow now require the workspace-level manager agent as a
  registration deliverable, so no future project can be created without something to delegate to.
  No product code touched.


2026-08-20 · workout_tracker-manager (dispatched from the My Projeccts workspace)
  FIRST COMMIT IN THIS PROJECT SINCE 2025-08-13, and the first that is not application code.
  Committed on explicit authorisation, one commit only. Not pushed, no branch, no PR — none of
  those was authorised, and adjacent approval is not approval.
  Landed: the modified `.gitignore`, plus `BOARD.md` and `CLAUDE.md` as NEW TRACKED FILES.
  What `.gitignore` actually does here: it does **not** mention `BOARD.md` or `CLAUDE.md`, so both
  are now versioned and travel with a clone. The uncommitted change added exactly two ignores —
  `graphify-out/` (rebuildable graph output) and `.claude/` (agent tooling: the manager skill and
  the three `workout_tracker-*` agents). Nothing was tracked under either path, so the ignore took
  effect cleanly; no `git rm --cached` was needed. Consequence worth knowing: after this, a fresh
  clone gets the board and the project brief but NOT the manager skill or the agents.
  CLAUDE.md carries a GENERATED `Engineering standards` block between `STANDARDS:BEGIN/END`,
  synced from the workspace `STANDARDS.md` by `python .claude/sync-standards.py`. It is not
  hand-written and must never be hand-edited — it is overwritten on every sync. Said so in the
  commit message so a future reader does not try to fix it here.
  Two stale claims in CLAUDE.md corrected before committing (code wins over docs): it said
  `graphify-out/` was "Untracked, and not gitignored" — the `.gitignore` in the same commit
  ignores it — and the "Where the depth lives" section pointed at `.claude/skills/...` without
  noting that path is now local-only.
  Verified before committing: `flutter analyze` → **No issues found, 0 issues** (6.6s);
  `flutter test` → **2 tests, 2 passing, 0 failing**. The 12-month dormancy has cost nothing —
  the baseline is still clean. No Dart file, dependency or test was touched.
  FOR THE BOSS — the generated standards block in this project's CLAUDE.md is TRUNCATED. It jumps
  straight from the "do not hand-edit" note into a headerless table fragment: `STANDARDS.md` lines
  20-49 (the `## 1. A structure that fits the project` heading, the "design it first" half, the
  "simplest scalable" note, the whole "MVP is about scope" section and the table's header row) are
  missing, so standard 1 begins mid-sentence. That is a defect in the workspace
  `.claude/sync-standards.py`, not in this project, and it was deliberately NOT hand-patched here.
  Every other project synced by the same script is likely to have the same hole. Separately,
  `STANDARDS.md` still says "**Status: 9 of 10 received**" while the block it generates contains
  all ten.
