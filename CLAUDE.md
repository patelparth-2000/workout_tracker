# workout_tracker

A small Flutter phone app that logs gym sets. Pick one of **five hardcoded exercises** (Barbell
row, Bench press, Shoulder press, Deadlift, Squat), type weight / repetitions / sets as free text,
save. Saved entries appear in a list you can edit, view (animated GIF + description in a bottom
sheet), delete individually, or clear wholesale. Everything lives on-device as one JSON string in
GetStorage.

No backend, no account, no sync, **no date or timestamp on an entry**. It is a scratchpad, not a
training history. Learning / portfolio project, not a product.

## Status: complete, and dormant

- All **3 commits are from 2025-08-13** (`2fa80d5`, `bb617bb`, `8383f03`). Nothing since.
- `main`, clean, in sync with `origin/main` (https://github.com/patelparth-2000/workout_tracker.git).
- Verified 2026-08-23: `flutter analyze` -> **No issues found**; `flutter test` -> **2 tests, 2 passing**.

It is not a stub and not abandoned mid-edit — the add / edit / delete / persist loop works end to
end. It is finished-and-parked. There is **no TODO, roadmap or planning doc anywhere in the repo**,
so there is no stated next step; direction has to come from the owner.

## Stack

| | |
|---|---|
| Flutter / Dart | 3.41.9 stable / Dart 3.11.5 (pubspec constraint `sdk: ^3.8.1`) |
| flutter_riverpod + riverpod_annotation | 2.6.1 — one major behind 3.x; codegen, not hand-written providers |
| go_router | 16.1.0, named routes only |
| get_storage | 2.1.1 — the entire persistence layer (no Hive, no repository layer) |
| flutter_lints | 5.0.0, stock, every custom rule left commented out |
| build_runner / riverpod_generator | 2.5.4 / 2.6.5 |

21 Dart files under `lib/`, 1 test file.

## Commands — Flutter is NOT on PATH

The SDK lives at `C:\Flutter_sdk_src\flutter\bin\flutter.bat`. Invoke it explicitly:

```powershell
& 'C:\Flutter_sdk_src\flutter\bin\flutter.bat' pub get      # run this FIRST in a fresh session
& 'C:\Flutter_sdk_src\flutter\bin\flutter.bat' analyze
& 'C:\Flutter_sdk_src\flutter\bin\flutter.bat' test
& 'C:\Flutter_sdk_src\flutter\bin\flutter.bat' run
& 'C:\Flutter_sdk_src\flutter\bin\flutter.bat' pub run build_runner build --delete-conflicting-outputs
```

The SDK folder was **renamed** from `C:\Flutter SDK src\`. Stale build stamps under
`.dart_tool/flutter_build/` still reference the old path and produce misleading "package not found"
errors — `pub get` first clears that up. Expect `pub get` to rewrite `pubspec.lock` (~19 transitive
bumps); that diff is normal, unrelated to your change, and is **not** committed today.

`.g.dart` codegen files are **tracked in git**. Change anything annotated `@riverpod` and you must
regenerate and commit the `.g.dart` alongside it. Forgetting is the easiest way to break this repo.

## Layout

```
lib/
  main.dart                     GetStorage.init + ProviderScope + MaterialApp.router
  routes/app_routes.dart        goRouterProvider, _AppPaths (private), RouteNames (public)
  common/common_function.dart   the 5 workoutTypes + the GLOBAL `storage` instance
  common/widget/                show_toast.dart (global scaffoldMessengerKey), view_exercise_bottom_sheet.dart
  src/splash_screen/            3-second Timer, then goNamed(workoutListScreen)
  src/workout_list_screen/      view/ + view/widget/ + viewmodel/workout_list_provider.dart (+.g)
  src/workout_screen/           model/workout_model.dart + view/ + viewmodel/workout_provider.dart (+.g)
  utils/                        color_constant.dart (semantic colours), images.dart (asset paths)
test/unit/workout_provider_test.dart
```

`src/<feature>/{model,view,viewmodel}` is deliberate and consistently applied (the README calls it
MVVM) — follow it for new features. **Two different files are named `list_widget.dart`**, one per
feature; the path disambiguates them. `list_text_wigdet.dart` / `ListTextWigdet` is a typo, left as-is.

Conventions (habit, not lint-enforced; full list in the manager skill): navigate by name
(`RouteNames`, never `_AppPaths`); no raw `Color(...)` or asset strings in widgets (add to
`color_constant.dart` / `images.dart`); user feedback via `showToast(message:)`, never
`ScaffoldMessenger.of(context)`.

## Traps

1. **`updateWorkout` matches by object identity, not value.** `WorkoutModel` overrides neither `==`
   nor `hashCode`, so `state.indexOf(oldWorkout)` is a *reference* comparison. It works today only
   because the edit flow passes the exact instance out of the list via `extra:`. Any refactor that
   copies, `copyWith`s or JSON-round-trips the model in between silently turns editing into a
   no-op — and **no existing test would catch it**. If you add `==`/`hashCode`, note two identical
   workouts would then collide; prefer adding an `id`, or passing the index.
2. **The edit form can freeze.** `WorkoutScreen` runs `addPostFrameCallback` on every build, guarded
   by `selectedIndex == null`. Editing a workout whose `type` is not among the five hardcoded
   `workoutTypes` leaves `typeIndex == -1`, `selectWorkout` is never called, the guard never closes,
   and the controllers are overwritten every rebuild — the user cannot type. Reachable the moment
   the exercise list is edited or reordered while saved data exists.
3. **Corrupt storage looks like empty storage.** `WorkoutList.build()` catches a JSON decode
   failure, `debugPrint`s, returns `[]`. The next write then destroys the damaged data for good.
4. **Tests cover the wrong provider.** The 2 passing tests assert `WorkoutProvider` starts `null`
   and `selectWorkout(2)` sets `2`. **`WorkoutList` — add / update / delete / clear / persistence /
   the `catch` — has zero coverage.** No widget or integration tests. That is where test value is.
5. **`weight`, `reps`, `sets` are all `String`**, with no keyboard restriction and no validation
   beyond "not empty" — `"10"` and `"10 "` differ. Sorting, totals or charts must fix this first.
6. **Entries have no date and no id**, so any history / progress / sync request needs a
   `WorkoutModel` change, which means migrating JSON already on someone's device.
7. **`applicationId` is still `com.example.workout_tracker`** (`android/app/build.gradle.kts`, both
   `namespace` and `applicationId`). Blocks any store release, and is painful to change after one.
8. **The README overstates things — trust the code.** It claims "GetStorage/Hive"; **Hive is not
   used at all** and never was. "Number of responsive" means repetitions.
9. **Stray files and deps.** `GetStorage.gs` / `GetStorage.bak` are tracked at the repo root *and*
   in `mock_path/` (runtime artifacts). `Images.appIcon` points at `images/icons/`, which does not
   exist; `images/logos/splash_logo.jpg` is unused (code loads the `.jpeg`). `mocktail`,
   `integration_test`, `flutter_native_splash`, `flutter_launcher_icons` sit under `dependencies:`.

## Where the depth lives

- `.claude/skills/workout_tracker-manager/SKILL.md` — full conventions, per-file detail, the three
  `workout_tracker-*` agents (lead / coder / tester). Read it before non-trivial work.
  **`.claude/` is gitignored** — agent tooling is local-only and is not part of a clone.
- `BOARD.md` — current state, ranked open items, and the change log. **Log every change here**:
  what changed, who, when, from where. This project is opened from the portfolio workspace, from
  VS Code directly, and from a phone; an unlogged change is invisible to the next manager.
- `graphify-out/` — a knowledge graph of the repo (363 nodes, 466 edges, 34 communities), plus
  `GRAPH_REPORT.md`. **Query it instead of grepping broadly:**
  `C:\Python\python.exe -m graphify query "<question>"` from the project root. Caveat: it indexes
  all 124 files, so the "god nodes" (`Win32Window`, `MessageHandler`, ...) are desktop-runner
  boilerplate; the Dart app is in communities 2, 4-7, 9-18, 22-25. Edges are structural (imports /
  defines / references), not semantic. Untracked **and gitignored** — a fresh clone will not
  have it; rebuild it locally.

Do not commit or push unless asked. Run `analyze` and `test` before calling anything done; both are
clean today and that baseline is worth protecting.

---

<!-- STANDARDS:BEGIN — generated from ../../STANDARDS.md, do not hand-edit -->

## Engineering standards — standing order

The boss set these once. **They apply to every change, by every agent, and are never re-stated.**
If you are reading this, they are addressed to you.

Authored in the workspace `STANDARDS.md` and generated into this file. Do not edit the block —
edit the master and re-run `python .claude/sync-standards.py`.

## 1. A structure that fits the project

Two halves, and the second is the one that applies most days.

### Starting something new — design it first

New project, new platform folder (`web/`, `api/`, `desktop/`), or a subsystem big enough to have its
own schema or endpoints: act as a senior full-stack engineer building a production-ready MVP from
the ground up. Design the complete system architecture, **then build the simplest scalable version
possible** — system architecture · file structure · database schema · API endpoints · UI
architecture · production-ready code. Nothing gets written until those exist in the project's
`CLAUDE.md` or on its board.

"Simplest scalable" is the whole instruction: **simplest** rules out the speculative layer nobody
needs yet; **scalable** rules out the shortcut that must be torn out at 10x. When they pull against
each other, standard 4 decides — would it *stop working*, or just get slower?

### MVP is about scope, not structure or quality

**Minimum Viable Product = the smallest version that a real person can actually use.** Not a demo,
not a throwaway — a real, usable first release with the core path working end to end. Everything
else waits.

It says nothing about code quality. A good MVP still has clean architecture, real security, tests
and a proper schema. **"Minimum" applies to the feature list, never to the engineering.** Cutting
quality to ship faster is not an MVP; it is debt with a nicer name.

For money_kind, the difference looks like this:

| MVP | Post-MVP |
|---|---|
| log in → create group → add expense → split it → see who owes whom | receipt scanning, AI analysis, multi-currency, analytics, notifications, offline sync, payment integration, recommendations |

The reason is not engineering, it is **information**: you cannot learn whether people want the thing
until somebody uses it. Every feature built before that is a bet placed with no data.

### How this binds existing projects

**It does not judge what already exists.** A project with more than its MVP was not "done wrong" and
does not get an ❌ — you cannot un-build features, and rewriting to a smaller scope wastes the work.

It binds **what gets built next**, and it asks each project one question:

> **What is the smallest version of this that a real person could use — and is it shipped?**

Until a project answers *yes*, new feature work needs a reason that is not "it would be nice". The
manager states which side of the line a proposed feature falls on before work starts. If it is
post-MVP and the MVP has not shipped, that is the conversation to have, not a task to accept
silently.

The boss decides what the MVP is. A manager may propose one; it is never assumed.

### Existing code — the rule is coherence, not a particular pattern

**MVP is not the target, and no specific architecture is mandated.** What is required is that the
project follows **a structure appropriate to itself, and follows it consistently.**

Clean Architecture, MVVM, BLoC, Cubit, feature-folders, a plain layered split — **all of these
pass.** A 21-file app with `model/ view/ viewmodel/` per screen is following this standard as fully
as a 458-file Clean Architecture app. Size does not decide; consistency does.

What **fails** is the absence of structure:

- folders grouped by nothing recognisable, or by three different conventions at once
- no separation between UI, logic and data — logic living wherever it first landed
- the same concern solved differently in different places, with nothing enforcing either
- a naming scheme that changes folder to folder

### When you do fix a mess, pick the structure that fits *this* project

Do not import a favourite pattern, and do not impose Clean Architecture on a 13-file app. Choose
from what the project already is: its stack, its size, the partial pattern it is already reaching
for. Extend that. A structure the project cannot maintain is a different mess, not a fix.

This half is bound by standard 5's gate — restructuring is behaviour-preserving work, so it needs a
test that proves behaviour was preserved.

## 2. Audit the codebase like a senior engineer joining it

Act as a senior engineer joining a large unfamiliar codebase. **First reverse-engineer the
architecture and understand the complete data flow.**

**Then identify** — poor architecture decisions · duplicate logic · performance bottlenecks ·
scalability risks · maintainability problems.

**Finally provide** — a clear architecture breakdown · critical problem areas · refactoring
strategies · improved production-grade code.

**Do not change existing functionality.** Only improve code quality, scalability and maintainability.

### An audit is not done until its findings are written down

Understanding a codebase in a session and then letting the session end is not an audit — it is
reading. The output is a **findings list that outlives the session**: each finding names a file, the
concrete failure it causes, and what it would cost to fix.

Findings go to the project's board, and any that map to a standard update that project's row in
`COMPLIANCE.md`. A structural graph (`graphify-out/`) is an *input* to this, not the audit itself —
it shows what reaches what, never what is wrong.

Fixing what you find is standard 5's job, under standard 5's gate. This one stops at the report.

**Who fixes this, and when.** The **project manager** owns closing this out, and does it when the
boss runs `/fix-all` — not opportunistically mid-task. Everyday changes must not *add* new
violations; clearing the ones already there is sweep work, and it is the manager's to schedule,
report and record.

## 3. Debug like a production outage

Act as a senior debugging engineer investigating a **live production issue**. Analyse the codebase
step by step as if handling a critical outage at a fast-growing startup.

**Your job** — understand what the code actually does · trace the true root cause · explain why the
failure occurs · find hidden edge cases · recommend the most robust fix possible.

**Finally provide** — a code functionality breakdown · root cause analysis · failure explanation ·
edge case analysis · fixed production-ready code.

**Do not guess. Analyse carefully before changing anything.**

### What "do not guess" costs you

- **Reproduce it first.** See the failure yourself before touching code. If you cannot reproduce it,
  say that — an unreproduced bug is a hypothesis, and a fix for a hypothesis is a guess wearing a
  diff.
- **Fix the cause, not the symptom.** A null check that hides why the value was null is not a fix.
- **One suspect at a time.** Changing three things and seeing green tells you nothing about which
  one mattered.
- **The edge cases are part of the deliverable**, not an afterthought — empty, one, many, huge;
  offline, slow, interrupted; wrong locale, wrong timezone, wrong permission.
- **Say what you are unsure of.** "This is the root cause" and "this is my best hypothesis" are
  different sentences, and reporting the second as the first is the failure this standard exists to
  prevent.

## 4. Performance engineering

Work like a senior performance engineer on a production application **used by millions of users**.

**Carefully identify** — performance bottlenecks · inefficient logic · unnecessary rendering or
rebuilds · expensive operations · memory leaks.

**Then provide** — a breakdown of what you found · the optimisation strategy you chose and why ·
improved, production-ready code · one line on how it scales.

### Build for the scale that has not arrived yet

"Millions of users" is not a claim about today. It is a design constraint: write every change so
that **if** this app one day carries that load, it does not fall over. That is not a licence to
micro-optimise now — it is a rule about the choices that are expensive to undo later.

- Anything that grows with users or data gets a bound: pagination, lazy/builder lists, streaming,
  batched writes. Never "load it all, then filter in memory".
- Prefer an O(n) shape to an O(n²) one even when n is 20 today. n is 20 *today*.
- No unbounded caches. No unclosed streams, subscriptions, controllers, file handles or sockets.
  No per-item network or disk call inside a loop.
- Nothing that assumes one user, one device, or one request at a time.

The question to ask of every change: **"what breaks if this runs 1000× more often, or over 1000×
the data?"**

- If the honest answer is *"it stops working"* — a crash, an OOM, a timeout, a lock — **fix it
  now**, however small the app is today. That is the rewrite you are avoiding.
- If it is *"it gets a bit slower"* — leave it, and say that you left it. That is a tune-up, and
  tune-ups can wait for real numbers.

### Two hard rules

1. **Never trade correctness for speed.** A fast wrong answer is a defect, not an optimisation.
2. **Never claim a speedup you have not measured.** "Faster" without a number is an opinion. If you
   did not time it, say so.

**Who fixes this, and when.** The **project manager** owns closing this out, and does it when the
boss runs `/fix-all` — not opportunistically mid-task. Everyday changes must not *add* new
violations; clearing the ones already there is sweep work, and it is the manager's to schedule,
report and record.

## 5. Clean, scalable architecture

Work like a senior software architect refactoring a messy production codebase using clean
architecture principles.

**Your mission** — separate concerns properly · improve modularity · reduce tight coupling ·
increase scalability · make the codebase easier to maintain long term.

**Do NOT change product behaviour.** Only improve architecture and code quality.

**Finally provide** — the new folder structure · a clean-architecture breakdown · refactored,
production-grade code · an explanation of the architectural improvements.

### The gate: no behaviour-preserving refactor without a way to prove it

"Do not change behaviour" is a promise you cannot keep in a project with no tests — there, a
refactor is a rewrite you cannot check. So before restructuring anything:

- **Characterisation tests first.** If the code path you are about to move has no test, write one
  that pins its *current* behaviour — bugs included — and see it pass. That test is the proof.
- **If you cannot test it, do not restructure it.** Say so and stop. Report what you would have
  done and what test is missing. That is a complete answer, not a failure.

### Refactor in steps that can be reverted

- One concern per commit. Never a big-bang rewrite of a whole layer.
- Behaviour-preserving moves and behaviour-changing fixes never share a commit. If you find a bug
  while refactoring, report it — do not quietly fix it inside the move.
- Match the architecture the project already has. A project whose notes say *"do not import a nicer
  architecture into this"* means it: raise the question, do not act on your own taste.
- Structure serves the product. A layer that exists only to satisfy a diagram is coupling wearing a
  nicer name.

**Who fixes this, and when.** The **project manager** owns closing this out, and does it when the
boss runs `/fix-all` — not opportunistically mid-task. Everyday changes must not *add* new
violations; clearing the ones already there is sweep work, and it is the manager's to schedule,
report and record.

## 6. Architect the backend before building it

Act as a senior systems architect designing infrastructure for a high-growth startup. **First design
a scalable, production-grade system architecture. Then create the minimum implementation that can
realistically scale later.**

**Include** — system architecture · component structure · data flow · API design · database schema ·
caching strategy · production-ready implementation code.

Optimise everything for scalability, maintainability and real-world production use.

### When this applies

Only where a backend **exists or is being started**. A local-first app that deliberately has no
server is not violating this — it is out of scope, and adding a backend to satisfy a checklist is
the opposite of what this standard is for.

It becomes binding the moment someone says "we need a backend now". That is the moment to design,
not the moment to start writing endpoints.

### The two items that get skipped

Every checklist item above tends to get built except these two, and they are the ones that are
expensive to add later:

- **Database schema** — designed up front: tables, relationships, indexes, and what happens when a
  row count grows 1000x. Retrofitting a schema onto working code means a migration under load.
- **Caching strategy** — what is cached, where, keyed on what, invalidated when. "We will add caching
  later" is how an expensive operation becomes an expensive operation repeated forever. If nothing
  should be cached, say that explicitly and why; a deliberate no is a strategy, an absent one is not.

### Minimum implementation, not minimum design

The design is complete. The **implementation** is minimal. Those are different sentences, and this
standard depends on the difference — an architecture designed only as far as the first sprint is how
a system acquires a shape it cannot grow out of.

Same test as standard 4: what breaks at 1000x? If the answer needs a rewrite rather than a bigger
box, the design is not finished.

**Who fixes this, and when.** Where a backend already exists, the **project manager** owns closing this out on
boss runs `/fix-all` — not opportunistically mid-task. Everyday changes must not *add* new
violations; clearing the ones already there is sweep work, and it is the manager's to schedule,
report and record.

## 7. Build UI as a system, not as screens

Act as a senior frontend engineer building **production-grade UI systems** for a modern startup.

**Create** — reusable UI components · a scalable component architecture · accessible,
production-ready interfaces.

**While building, properly handle** — loading states · empty states · edge cases · responsive design
· accessibility · component reusability · clean developer experience.

**Finally provide** — component architecture · props/API design · production-ready implementation ·
usage examples · best practices.

Build it as if it were shipping inside a real product used by millions.

### The four states, every time

A screen is not done when the happy path renders. Every view that loads or submits anything owes
four states, and the last three are the ones that get skipped:

| State | The question |
|---|---|
| **Loaded** | the happy path |
| **Loading** | what is on screen while waiting — and does it shift layout when the data lands? |
| **Empty** | first run, no results, everything deleted. Not a blank screen |
| **Error** | what failed, whether it can be retried, and how the user retries |

A local, synchronous read genuinely has no loading state — say so rather than inventing a spinner.
But "it never fails" is almost always wrong: disk fills, permissions get revoked, files vanish.

### Accessibility is part of "done", not a later pass

The framework's built-in semantics cover stock components. They do **not** cover what teams actually
ship: icon-only buttons, custom-painted widgets, images carrying meaning, colour used as the only
signal, tap targets under 48dp, text that breaks when the user scales it up.

Label them as you build. Retrofitting accessibility across a finished app is a project; doing it in
the moment is a line of code.

That asymmetry is why **every new app carries this from its first screen**. The six existing Flutter
apps have one accessible file between them across 743 — that backlog exists because nobody labelled
as they went, and it is now sweep work. Do not create the same backlog twice.

### Reusable means a real component API

A component is reusable when someone can use it without reading its source: named, typed inputs, a
sensible default for everything optional, no reaching into app state or navigation from inside it,
and no copy-paste variant living three folders away.

**Design tokens over literals.** Colours, spacing and text styles come from one place. A raw
`Color(0xFF...)` or a magic `EdgeInsets` in a screen file is the beginning of the drift this
standard exists to prevent.

### Scope

Applies wherever there is a user interface. A headless backend is out of scope, not in violation.

**Who fixes this, and when.** The **project manager** owns closing this out, and does it when the
boss runs `/fix-all` — not opportunistically mid-task. Everyday changes must not *add* new
violations; clearing the ones already there is sweep work, and it is the manager's to schedule,
report and record.

## 8. Technical lead mode

Act as a **senior technical lead responsible for a real engineering team** — not a code generator.

**Before writing any code** — ask clarifying questions · challenge weak decisions · identify scaling
risks · suggest better approaches · prioritise simplicity.

Think long term, like someone who will maintain this product for the next **5+ years**.

**Then provide** — technical decisions · tradeoff analysis · recommended architecture ·
implementation plan · production-ready solution.

### This one is enforced by tools, not by instruction

Every project has a `<project>-lead` agent, and **none of them has `Write` or `Edit`**. That is
deliberate and it is the standard's real teeth: a lead who can edit stops leading. Telling a model
to "think like a lead" while handing it a text editor loses to the editor every time.

Keep it that way. A lead must not work around it by writing files through `Bash` either.

### What the lead owes before a plan is accepted

- **Questions asked up front**, where two readings would produce materially different work — not
  discovered halfway through.
- **Weak decisions challenged.** A request that fights the architecture gets said so, with the
  in-architecture alternative. This is the main reason the role exists; a lead who only agrees is a
  code generator with extra steps.
- **Risks sized honestly for what this project actually is.** Server load is not a risk for a
  local-first app. Table growth and rebuild storms are. Inventing risks costs as much credibility as
  missing them.
- **Simplicity preferred.** The smallest change that satisfies the requirement and the architecture.

### The 5-year test, and the thing that breaks it

"Maintained for 5+ years" means the next person — possibly the boss after a year away — can read the
decision and the reason. A tradeoff recorded only in a chat log is not recorded.

**A lead's context must be true.** The 5-year horizon means these files are read long after they were
written, and a lead reasoning from a stale premise makes confident, wrong calls — blocking safe work
or waving through unsafe work. Verify the load-bearing facts against the repo before planning on
them, and correct the file when they have moved.

## 9. Security is a core requirement, not an afterthought

Act as a senior security engineer auditing a production application.

**Carefully inspect for** — security vulnerabilities · authentication flaws · API weaknesses ·
injection risks · sensitive data exposure · infrastructure risks.

**Then provide** — a vulnerability report · severity levels · attack scenarios · secure
implementation fixes · production-grade recommendations.

### A finding needs an attack scenario or it is not a finding

"This looks insecure" is noise. State who the attacker is, what they control, and what they get:
*"anyone who can reach this endpoint controls `file.filename`, so they can write to any path the
process can write to."* That sentence is what makes a fix urgent instead of a backlog item.

Severity follows the same discipline — rank by what an attacker actually achieves, not by how bad
the code looks.

### The four that keep appearing

- **Unauthenticated endpoints.** "It is only running locally" stops being true the first time it is
  deployed, and nobody adds auth at that moment.
- **User-controlled paths and names.** Any filename, id or path from a request is attacker-controlled
  until it is validated. In Python, joining an **absolute** path onto a base *replaces* the base
  entirely — a fact that turns a naive `Path(base) / name` into arbitrary file write.
- **Secrets in source, and therefore in history.** Removing a key from the working tree does not
  remove it from the repo. Rotate first, then clean history. Deleting the line achieves nothing.
- **Client keys treated as secrets, or as harmless.** Both readings are wrong. A Firebase config key
  is an identifier and is *meant* to ship in the client — it is protected by security rules, not by
  hiding. A Maps or Directions key shipped in a client is extractable and bills the owner, so it must
  be restricted by platform, package and SHA. Know which kind you are holding.

### Scope, and the honest limit

Every project, including local-first ones — an app with no network still has file permissions,
exported activities, deep links and local storage. But a small attack surface deserves a *small*
report, not an invented one.

**Never mark a project secure because a scan found nothing.** A grep that finds no hardcoded keys has
found no hardcoded keys, which is not the same as an audit. Say which it was.

**Who fixes this, and when.** The **project manager** owns closing this out on `/fix-all` — with one
exception that does not wait: a **confirmed, exploitable vulnerability is reported to the boss
immediately**, not held for the next sweep. Everyday changes must not add new exposure.

## 10. Prepare it for real deployment — **ON REQUEST ONLY**

> **This standard does not run by itself.** Unlike 1–9 it is **not** a standing order, it is **not**
> swept by `/fix-all`, and no agent acts on it unprompted. It applies only when the boss says so —
> "set up CI", "get this deployable", "fix point 10". Until then it is documented and dormant.
>
> Why: deployment work is only worth doing when there is a decision to ship behind it. Adding a
> pipeline to a dormant app is cost with no return, and the boss decides when that changes.
>
> Everyday work must still not *break* an existing pipeline or release path. That is the one part
> that is always live.

Act as a senior DevOps engineer preparing this application for **real production deployment**.

**Your job** — design the deployment architecture · configure CI/CD · set up monitoring and logging ·
improve reliability · reduce downtime risks · optimise scaling.

**Provide** — infrastructure architecture · deployment workflow · CI/CD pipeline · Docker/Kubernetes
setup · monitoring strategy · production deployment checklist.

Prepare the system as if real users and real revenue depend on it.

### Read the checklist against the actual deployment target

Docker and Kubernetes are the *server* answer. A mobile app does not deploy in a container, and
demanding one produces theatre. The items map like this:

| | Server / API | Mobile app |
|---|---|---|
| **CI** | lint · tests · build on every push and PR | `analyze` · tests · build on every push and PR |
| **Artifact** | container image, reproducible | signed release bundle, **not debug keys** |
| **Deploy** | documented, repeatable, revertible | store listing, staged rollout |
| **Monitoring** | health checks, structured logs, alerting | crash reporting, error tracking |
| **Reliability** | what happens when a dependency is down | what happens offline, or mid-upgrade |

Same standard, different shape. Neither version is optional.

### CI first — it is what makes every other standard enforceable

CI is the cheapest item here and the one that pays for the rest: without it, "tests pass" means
someone ran them once on one machine. Standard 5's refactor gate, standard 9's dependency checks and
every "all green" claim in this file rest on it. **Add it on day one; retrofitting it means fixing
whatever broke silently in the meantime.**

### The Flutter release trap

`flutter create` writes a `release` build type that signs with **debug keys**, with a `TODO` above
it. It builds, it runs, it looks finished — and it can never be published. A project is not
deployable until that TODO is gone and a real keystore is wired in.

### Deployable is not the same as deployed

This standard is satisfied by being *ready*: the pipeline exists, the artifact is real, the rollback
is known. Whether to ship is standard 1's MVP question and the boss's call — but "we have not
decided to ship" is not a reason to have no pipeline. The pipeline is what makes the decision cheap.

**Who fixes this, and when.** Only when the boss asks — see the box at the top of this standard. It
is excluded from `/fix-all` by default and included only when the sweep is explicitly told to.


---

# House rules

Not numbered standards — these govern *how work is done* in every project, all the time, and they
are not swept, deferred or proportioned. They are drawn from the MoneyKind rulebook, which proved
them, and they apply portfolio-wide.

## Permission

**Never commit, push, create a branch, open a PR, or create or delete a repo without explicit
permission for that specific action.** Write the files, then stop and ask.

Approval for one action never carries to the next, and **adjacent approval is not approval** —
"commit this" is not "push this", and "push this" is not "open a PR".

## Commits

- **No AI attribution.** No `Co-Authored-By` trailer, no "Generated with Claude Code" footer, no 🤖
  line. The message ends with the last line of its body.
- Group related files into **one** commit when told to commit. Never commit proactively.

## Scope

- **One task at a time.** Fix the cause, not the symptom, with the smallest change that satisfies the
  requirement and the architecture. No scope creep, no drive-by refactors.
- **Do not edit test files** unless the task explicitly says the test is wrong. If a test looks wrong
  and you were not told so, **stop and report it** rather than editing it. A test edited to pass is
  a deleted test with extra steps.

## Truth

- **Code wins over docs.** Where a `docs/` file, a handover note or a manager file disagrees with the
  source, the source is right and the stale file gets corrected. Say which one you trusted.
- **Verify before finishing.** Every project's rulebook names its own verify commands — analyse,
  test, and whatever else that stack needs. Run them. "It should work" is not a result.

## Every project owes a rulebook

One consolidated file per project, holding what a new contributor must know before touching it:
architecture rules · file and folder placement · state conventions · presentation standards · error
flow · ordering rules for adding things · the review gate · verify commands · workflow notes ·
known-stale docs.

`money_kind/mobile/` is the worked example and the shape to copy. Its content will not transfer —
another project's stack, patterns and traps are its own — but the **sections** do.

For a new project this is written at creation, from the boss's answers, before the first feature.
For an existing one it is assembled from what is already true.

---

### Proportion them to *this* project — workout_tracker

21 files, on-device, dormant 12mo, `get_storage` is the whole persistence layer. **Too small to
justify layering** — adding a repository here is ceremony, not architecture. Apply the checklists,
then say plainly when the honest answer is "nothing worth changing".

Proportion governs **effort**, never the hard rules. Correctness still outranks speed, an
unmeasured speed claim is still an opinion, and anything that *stops working* at 1000x is still
fixed now. "We have no users yet" is not a reason to skip a structural fix.

<!-- STANDARDS:END -->
