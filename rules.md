# Vitalis Engineering Rules & Autonomous Protocol

Whenever the user instructs "run daily sprint", execute the 6-Phase Autonomous Lifecycle defined below.

---

## Autonomous 6-Phase Engineering Lifecycle

### 1. Backlog Analysis & Identification
- Open `docs/AUTONOMOUS_BACKLOG.md` and locate the earliest `SCHEDULED` sprint.
- Extract sprint requirements, data structures, and acceptance criteria.

### 2. Sprint Branch & Architectural Planning
- Verify clean git status.
- Ensure SOLID design principles and Clean Architecture layer boundaries.

### 3. Domain & Data Layer Implementation
- Implement immutable models, repository contracts, and SQLite DAO queries.
- Register dependencies in `lib/core/di/injection_container.dart`.

### 4. Presentation Layer & UI Standards
- Dynamic colors only: resolve via `Theme.of(context).colorScheme`.
- Zero emojis anywhere in source code, UI strings, logs, or commit messages.
- Unique `heroTag` on every `FloatingActionButton`.
- 360dp landscape viewport safety: compact `NavigationRail` and dual-pane scrolling.
- Riverpod state management with immutable updates and stream cleanup in `try ... finally`.

### 5. Automated Quality Gate
- Run `dart run tool/sprint_gate.dart`.
- Verify:
  1. `flutter pub get`
  2. `dart format --output=none --set-exit-if-changed lib test`
  3. `flutter analyze --no-pub` (0 errors, 0 warnings, 0 infos)
  4. `flutter test --no-pub` (100% tests passing)
  5. ADB logcat clean check.

### 6. Git Synchronization
- Update sprint status to `COMPLETED` in `docs/AUTONOMOUS_BACKLOG.md`.
- Commit with conventional format: `feat: complete Sprint <number> - <title>` (no emojis).
- Push synchronously to both remotes: `origin main` and `vitalis_app main`.
