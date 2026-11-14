# Vitalis Autonomous Engineering Lifecycle Rules

Whenever the user instructs "run daily sprint" or requests the execution of an autonomous engineering iteration, the agent must strictly execute the following 6-Phase Engineering Lifecycle.

---

## Phase 1: Backlog Analysis & Sprint Identification
1. Inspect `docs/AUTONOMOUS_BACKLOG.md` to identify the next unfinished sprint (status `SCHEDULED`).
2. Read the defined clinical scope, user stories, technical architecture, and acceptance criteria.
3. Verify that all preceding sprint dependencies are satisfied and clean.

---

## Phase 2: Sprint Branching & Architectural Planning
1. Ensure the working directory is clean (`git status`).
2. Create or checkout the sprint branch following naming convention `sprint/<number>-<feature-slug>` or work on `main` as directed.
3. Define the Clean Architecture data contracts, entities, and Riverpod state models prior to writing implementation code.

---

## Phase 3: Domain & Data Layer Implementation
1. Domain Layer: Define immutable entities and abstract repository contracts in `lib/domain/`.
2. Data Layer: Implement repository classes in `lib/data/repositories/` and models with `fromJson` / `toJson` / `fromMap` in `lib/data/models/`.
3. Database Migration: If the sprint requires persistent storage, update `AppDatabase` schemas and `DatabaseSeeder` deterministically.
4. Dependency Injection: Register new services and repositories in `lib/core/di/injection_container.dart`.

---

## Phase 4: Presentation Layer Implementation & Hygiene Standards
1. Strict Dark and Light Parity:
   - Zero hardcoded colors (`Colors.black`, `Colors.white`, or raw hex).
   - All colors must resolve from `Theme.of(context).colorScheme`.
2. Zero Emoji Hygiene:
   - Zero emojis anywhere in source code, UI strings, logs, or commit messages. Vector Material Symbols or Cupertino icons exclusively.
3. Unique Hero Tags:
   - Explicit `heroTag` on every `FloatingActionButton` across all views.
4. 360dp Landscape Viewport Safety:
   - Adaptive layouts with compact `NavigationRail` and compressed `AppBar` (`toolbarHeight: 36`).
   - Two-pane layouts with independent vertical scroll controllers and `mainAxisExtent` on grid views.
5. Reactive Riverpod Mutations:
   - State mutations must be immutable (`state = [...]`) with instant persistence and proper stream lifecycle cleanup.

---

## Phase 5: Verification & Sprint Quality Gate
1. Author or update unit and widget tests covering all new features and edge cases.
2. Execute `dart run tool/sprint_gate.dart`:
   - Stage 1: `flutter pub get`
   - Stage 2: `dart format --output=none --set-exit-if-changed lib test`
   - Stage 3: `flutter analyze --no-pub` (Must pass with 0 errors, 0 warnings, 0 infos).
   - Stage 4: `flutter test --no-pub` (Full test suite passing).
   - Stage 5: Android ADB Logcat check if device is connected.
3. If any stage fails, halt and resolve immediately before proceeding.

---

## Phase 6: Autonomous Backlog Update, Commit & Dual Remote Push
1. Update `docs/AUTONOMOUS_BACKLOG.md`, marking the completed sprint as `COMPLETED`.
2. Stage all changes: `git add .`
3. Commit with standard conventional commit message (zero emojis):
   `feat: complete Sprint <number> - <feature-title>`
4. Push to both configured remotes:
   `git push origin main` (or sprint branch)
   `git push vitalis_app main` (or sprint branch)
5. Verify `git log origin/main..HEAD` confirms local branch is fully in sync with the remote.
