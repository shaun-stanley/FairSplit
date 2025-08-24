# Repository Guidelines

Use: xcodebuild -scheme FairSplit -destination 'generic/platform=iOS Simulator' build

## Planning Protocol (for Codex)
- Treat PLAN.md as the single source of truth.
- On each run:
  1) Read PLAN.md. If "In Progress" is empty, move the first item in "Next Up" to "In Progress".
  2) Implement only that item.
  3) Build with: xcodebuild -scheme FairSplit -destination 'generic/platform=iOS Simulator' build.
     If tests exist, run: xcodebuild test -scheme FairSplit -destination 'generic/platform=iOS Simulator'.
  4) If build/tests succeed: move the item to "Done" with a one-line summary and append a dated entry in "Changelog".
     If they fail: add a note under "Blocked" with diagnosis and a proposed fix.
  5) Commit with message: "<ID> short summary" (e.g., "MVP-1 add SwiftData store").
- Keep language simple and non-technical in PLAN.md. Propose up to 3 new Next Up items when the queue is low.



## Project Structure & Module Organization
- `FairSplit/`: App source (SwiftUI). Key files: `FairSplitApp.swift` (entry), `ContentView.swift` (UI), `Assets.xcassets` (assets).
- `FairSplit/Models/`: SwiftData `@Model` types: `Group`, `Member`, `Expense`.
- `FairSplit/Helpers/`: Utilities & data access (e.g., `DataRepository`, `SplitCalculator`).
- `FairSplit/Views/`: Feature views (lists, forms, summary).
- `FairSplitTests/`: Unit tests (XCTest/Swift Testing) for logic.
- `FairSplitUITests/`: UI tests (XCUITest) for flows.

## Build, Test, and Development Commands
- Open in Xcode: `open FairSplit.xcodeproj` (use the FairSplit scheme).
- Build (CLI, generic sim): `xcodebuild -scheme FairSplit -destination 'generic/platform=iOS Simulator' build`.
- Unit/UI tests (CLI): `xcodebuild test -scheme FairSplit -destination 'platform=iOS Simulator,name=iPhone 16'`.
- Xcode shortcuts: Product > Build, Product > Test, and choose a Simulator device.

## Coding Style & Naming Conventions
- Formatting: Use Xcode’s default formatting (Editor > Structure > Re-Indent). 4-space indentation, 120-col soft wrap.
- Swift naming: Types and enums in UpperCamelCase; functions, vars, and enum cases in lowerCamelCase; files named after the primary type.
- SwiftData: Use reference semantics for `@Model`. Keep relationships minimal and explicit; prefer `.cascade` for owned collections.
- SwiftUI: Keep views small and previewable; suffix view types with `View`.

## Testing Guidelines
- Frameworks: XCTest/Swift Testing for unit tests, XCUITest for UI flows.
- Naming: Test files as `<TypeName>Tests.swift`. Methods as `test_<behavior>_<expected>()`.
- Scope: Add tests for `SplitCalculator`, repository operations, and view logic where feasible.
- Running: Use the Test action or the `xcodebuild test` command above.

## Commit & Pull Request Guidelines
- Commits: Imperative mood, concise subject (≤72 chars), optional scope, e.g., `feat: add split summary view`.
- PRs: Include summary, rationale, before/after screenshots for UI, linked issue, and test coverage notes. Keep changes focused and small.

## Security & Configuration Tips
- Do not commit secrets or personal data. Keep identifiers/config in build settings where possible.
- Avoid hardcoding sample credentials; prefer mock data in tests and previews.

## Quality Gate
- Always run a build after changes:
  xcodebuild -scheme FairSplit -destination 'generic/platform=iOS Simulator' build
- If unit tests exist, run them:
  xcodebuild test -scheme FairSplit -destination 'generic/platform=iOS Simulator'
- If tests do not exist for the changed logic, create minimal tests (smoke tests) in this run, then execute them.
- On failure (build or tests): 
  - Do NOT proceed to new features.
  - Diagnose in plain English, propose the fix, apply it, and re-run the gate.
  - If still failing, move the task to "Blocked" in PLAN.md with the diagnosis and the exact commands & files to inspect.
- On success:
  - Move the item to "Done" and append a dated entry to the Changelog in PLAN.md.
  - Commit with: "<ID> short summary".
