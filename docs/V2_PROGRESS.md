# v2 progress — hand-off

Last updated 2026-11-04 by a cloud Claude Code session. All three phases of the v2 plan ran
in **one** cloud session. The work is on branch **`claude/sweet-bardeen-e4aswb`**, the branch
this cloud environment was assigned; the plan named `feature/workout-v2`. `main` is untouched.

## Numbers (measured, not copied)

| | Start (main, `a3b718b`) | End |
|---|---|---|
| `flutter analyze` | No issues found | **No issues found** |
| `flutter test` | 2 tests, 2 passing | **170 tests, 170 passing** |
| Dart files in `lib/` (hand-written) | 21 | 69 (+18 generated) |
| Test files | 1 | 16 |

Toolchain: Flutter 3.41.9 / Dart 3.11.5.

## Done

**Phase 1 — foundation**
- [x] `docs/ARCHITECTURE.md` written before code
- [x] Characterisation tests for the v1 `WorkoutList` (13 tests, sabotage-checked), retired together with the v1 screens
- [x] Cleanup: test-only packages to dev_dependencies, unused native splash removed, GetStorage files untracked + ignored, dead `Images.appIcon` and `splash_logo.jpg` removed, `Images` icons static, README corrected
- [x] Riverpod 2.6 → 3.3 (riverpod_generator 4), no conflict with drift
- [x] drift schema v1 (7 tables, 4 indexes, FKs on, MigrationStrategy in place)
- [x] 65-exercise seed; the original 5 keep their GIFs and descriptions
- [x] One-shot, atomic, idempotent v1 → v2 import (legacy key kept)
- [x] Light/dark themes from tokens; startup screen (no fixed 3 s splash); 5-tab shell

**Phase 2 — core (proposed MVP)**
- [x] Exercises: search, filters, detail (GIF), custom create/edit, archive/restore
- [x] Routines: create/edit, reorder, target sets/reps/rest, delete with confirm, start
- [x] Live workout: start empty/from routine, add/move/remove exercises, numeric validated set rows, previous values, add/remove sets, finish/discard with confirm, one active at a time, survives app kill
- [x] Rest timer: auto-start, ±15 s, skip, end-timestamp + injected clock
- [x] History: keyset-paged list, detail, edit/delete sets, delete workout
- [x] Settings: kg/lb, default rest, theme

**Phase 3 — polish**
- [x] Progress tab: best weight / e1RM / session volume, e1RM & volume charts with range filter, PR badges (live + history), records on exercise detail
- [x] Backup: versioned JSON export/import (full validation, one transaction), CSV export
- [x] Quality pass: four states everywhere; tap-target / label / contrast guidelines and 2× text on every screen, enforced by tests in light and dark
- [x] README rewritten, `docs/RULEBOOK.md` written
- [x] Plate calculator (kg/lb)
- [ ] Supersets — **not started** (columns reserved, no migration needed)

## Verified on a real build (not just tests)

A Linux desktop debug build was run under a virtual display at phone size and driven by
hand. Verified: the seed loads, the original GIFs render, a full workout logs with correct
volume, the rest timer runs, previous values prefill, PR badges show live and in history,
**the workout survives SIGKILL and resumes**, dark mode works, and **a real v1
`GetStorage.gs` file imported correctly** ("100 " trimmed, "abc" kept as a note, legacy key
left on disk, no second import on relaunch). The startup error screen was also seen for real
when the platform documents folder was missing.

Building Linux here needed a local, uncommitted CMake patch: this environment cannot reach
sqlite.org. It does not affect Android or iOS.

## What the owner must check on a real phone

1. **Migration from an old install:** install v1 from `main`, add a few workouts, then
   install this build over it. Expect a toast "Imported N saved workouts…" and an
   "Imported workouts" entry in History.
2. **Rest timer after backgrounding:** complete a set, lock the phone for a minute, unlock.
   The remaining time must be correct.
3. **Backup on a phone:** export to Files or Drive, then restore it, ideally on a second
   device. Also try restoring a random JSON file: you should get a clear message and no change.
4. **CSV** opens cleanly in Google Sheets or Excel.
5. **Dark mode** and **2× system font size** look right on your own device.
6. **Kill the app mid-workout** (swipe away) and reopen: Resume must be offered.
7. **Keyboard:** weight shows a decimal keypad, reps a number pad.

## Next steps (owner decides)

1. Decide the MVP line (proposed: Phases 1+2, now done) and whether to ship.
2. Give a real `applicationId` (still `com.example.workout_tracker`); a release also needs a
   signing key (standard 10, on request only).
3. Merge this branch after the on-phone checks.
4. Candidates after that: supersets (columns reserved), RPE / set types (columns reserved),
   persisting custom plate sets, deleting the legacy GetStorage key in a later release.
