# workout_tracker — Board

The single record of what changed here, who did it, when, and from where. The boss reaches this
project from the portfolio workspace, from VS Code directly, and from a phone — all three read
this file. **A change that is not on this board is a change the next manager will not know about.**

Newest entry at the top. Do not rewrite history; append.

---

## Status: complete, dormant

Last code commit **2025-08-13**. Nothing has changed in the app since. Not broken, not
half-finished — the add / edit / delete / persist loop works end to end. It is a finished small
learning project that was parked.

| | |
|---|---|
| Branch | `main`, clean, **1 commit ahead of `origin/main`** (not pushed — not authorised) |
| Remote | https://github.com/patelparth-2000/workout_tracker.git |
| Commits | 4 — 3 app commits on 2025-08-13 (`2fa80d5`, `bb617bb`, `8383f03`) + 1 docs commit dated 2026-08-20 |
| `flutter analyze` | **No issues found** (0 issues, verified 2026-08-26) |
| `flutter test` | **2 tests, 2 passing, 0 failing** (verified 2026-08-26) |
| Size | 21 Dart files under `lib/` |
| Manager | `.claude/skills/workout_tracker-manager/SKILL.md` |

There is no TODO file, no roadmap and no planning doc in the repo, so there is **no stated next
step**. Direction has to come from the boss.

---

## Open items

Nothing here is urgent — the app works and nobody is using it in anger. Ranked by value if work
does resume.

### Would bite someone

- **`updateWorkout` matches by object identity.** `WorkoutModel` overrides neither `==` nor
  `hashCode`, so `state.indexOf(oldWorkout)` is a reference comparison. It works today only
  because the edit flow passes the exact instance from the list via `extra`. Any refactor that
  copies or round-trips the model in between turns editing into a silent no-op, and no existing
  test would catch it.
- **The edit form can freeze.** `WorkoutScreen`'s `addPostFrameCallback` is guarded by
  `selectedIndex == null`. Editing a workout whose `type` is not among the five hardcoded
  `workoutTypes` leaves `typeIndex == -1`, so the guard never closes and the controllers are
  overwritten on every rebuild — the user cannot type. Becomes reachable the moment the exercise
  list is edited or reordered while saved data exists.
- **Corrupt storage looks like empty storage.** `WorkoutList.build()` catches a JSON decode
  failure, `debugPrint`s, and returns `[]`. The next write then destroys the damaged data.
- **The logic with the risk is the logic without tests.** The 2 passing tests cover the trivial
  `WorkoutProvider`. `WorkoutList` — add, update, delete, clear, persistence, the `catch` — has
  zero coverage.

### Cheap and worth doing

- Move `mocktail` and `integration_test` from `dependencies:` to `dev_dependencies:`; they
  currently ship in the app bundle. Drop `flutter_native_splash` (declared, no config block,
  never referenced) or configure it.
- Gitignore and untrack `GetStorage.gs` / `GetStorage.bak` at the repo root and in `mock_path/` —
  runtime storage artifacts should not be in version control.
- Fix the README: it claims "GetStorage/Hive", but **Hive is not used at all**. It also says
  "Number of responsive" where it means repetitions.
- Delete the dead `Images.appIcon` constant (points at `images/icons/`, which does not exist) and
  the unused `images/logos/splash_logo.jpg` (the code loads the `.jpeg`).
- Make the `IconData` fields in `utils/images.dart` `static` so widget code stops writing
  `Images().addIcon`.

### Needs a decision, not a fix

- **`applicationId` is still `com.example.workout_tracker`.** The default placeholder. Blocks any
  store release, and is painful to change after one.
- **Entries carry no date and no id.** Any request for history, progress, charts or sync needs a
  `WorkoutModel` change first — which means migrating whatever JSON already sits on a device.
- **Riverpod is a major version behind** (2.6.1 vs 3.x), as is `riverpod_annotation` (2.6.1 vs
  4.x). Not urgent for a dormant app; scope an upgrade as a project, since it touches every
  provider plus regenerated codegen.

### Environment

- **The Flutter SDK is not on PATH.** It lives at `C:\Flutter_sdk_src\flutter\bin\flutter.bat`.
  `.dart_tool/` still references the older `C:\Flutter SDK src\...` location, so run `pub get`
  before anything else in a fresh session or you get misleading "package not found" errors.
- `pub get` under the current Flutter (3.41.9) rewrites `pubspec.lock` with ~19 transitive bumps.
  That change is expected and is **not** currently committed — the lock in git is the older one.

---

## Log

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
