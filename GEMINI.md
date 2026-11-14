# Gemini Agent Operational Directive: Vitalis Clinical Ecosystem

This repository is governed by strict autonomous execution rules. When the user requests "run daily sprint", follow the standard 6-phase engineering protocol:

1. **Backlog Analysis**: Review `docs/AUTONOMOUS_BACKLOG.md` to identify the active sprint.
2. **Architecture**: Adhere strictly to Feature-First Clean Architecture (`core/`, `data/`, `domain/`, `presentation/`).
3. **Data & Domain**: Implement immutable entities, SQLite repositories, and GetIt dependency injection.
4. **Presentation & Safety**:
   - Zero hardcoded colors: Dynamic Obsidian Dark and Crisp Light modes via `Theme.of(context).colorScheme`.
   - Zero emojis anywhere: Use vector Material Symbols exclusively.
   - Unique `heroTag` on all FABs.
   - 360dp landscape viewport safety: compact `NavigationRail` and two-pane independent scroll layouts.
   - Riverpod state management with safe stream teardown (`try ... finally`).
5. **Quality Gatekeeper**: Execute `dart run tool/sprint_gate.dart` ensuring 0 analyzer issues, clean formatting, and all tests green.
6. **Git Remotes**: Push all commits to both `origin main` and `vitalis_app main`.
