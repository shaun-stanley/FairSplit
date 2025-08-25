//
//  plan.md
//  FairSplit
//
//  Created by Shaun Stanley on 8/24/25.
//

# PLAN.md — FairSplit (iOS 18+, SwiftUI)

## Status
- Build: ✅ runs on iOS Simulator
- Persistence: ✅ SwiftData store with demo seed
- Core features: Groups ☐  Expenses ☐  Balances ☐  Settle Up ✅
- Input: ✅ Currency formatter + validation for amount

## Next Up (top first — keep ≤3)
1. [CORE-8] Undo/Redo for create/edit/delete operations
2. [DATA-3] Import/Export: CSV export for a group; CSV import for expenses (document picker)
3. [SHARE-1] Share sheet: export a readable group summary (PDF/Markdown)

## In Progress
[MATH-4] Multi-currency per group with **manual FX rates** (safe, offline). Optional: remember last rate used

## Done
[MVP-1] Added SwiftData and a demo group
[MVP-2] Polished amount input with currency formatting and validation
[DOC-1] Use GitHub CI badge in README
[MVP-3] Settle Up suggests transfers and saves them
[CORE-1] Groups list shows balance summary, search, and recent activity sorting
[MATH-1] Added balances helper suggesting who pays whom
[CORE-2] Group detail shows sections for expenses, balances, settle up, and members
[MATH-2] Unequal splits allow weighted shares
[CORE-3] Members can be added, renamed, and removed; expenses prevent deletion
[CORE-4] Expenses can be added, edited, or removed
[TEST-1] Added unit tests for settlement math
[CORE-5] Expenses support categories and notes
[CORE-4] Expense list supports swipe edit and delete with context menu
[TEST-2] Added UI test for editing expenses
[CORE-6] Attach receipts: add photo/scan using VisionKit; show thumbnail in list
[TEST-4] UI tests for add/delete expense and settle up flow
[CORE-7] Search expenses: title, note, amount range, member filters
[UX-6] Polish primary actions placement (Add Expense, Settle Up)


## Blocked
(none)

---

## Backlog (move items up to “Next Up” when ready)

### Core Experience
 - [CORE-2] Group detail: sections (Expenses, Balances, Settle Up, Members) with sticky headers
- [CORE-8] Undo/Redo for create/edit/delete operations
- [CORE-9] App theming: light/dark with accent color; respect system appearance

### Money & Math
- [MATH-3] Recurring expenses (monthly rent, subscriptions) with auto-add and pause
- [MATH-4] Multi-currency per group with **manual FX rates** (safe, offline). Optional: remember last rate used
- [MATH-5] Per-member totals and per-category totals in group

### Persistence & Sync
- [DATA-1] SwiftData migration support (lightweight model versioning)
- [DATA-2] iCloud sync via **CloudKit** (private database). Simple last-write-wins, then improve conflict handling
- [DATA-3] Import/Export: CSV export for a group; CSV import for expenses (document picker)

### Delight & Design (Apple-ish touches)
- [UX-1] Dynamic Type everywhere; ensure layouts adapt up to Extra Large sizes
- [UX-2] Haptics on key actions (add expense, settle)
- [UX-3] SF Symbols for categories, payer, participants, settlement arrows
- [UX-4] TipKit/coach marks: first-run hints for Add Expense and Settle Up
- [UX-5] Pull-to-refresh (no-op placeholder until CloudKit lands)

### Accessibility & Localization
- [A11Y-1] VoiceOver labels/traits for all interactive elements; readable amounts/roles
- [A11Y-2] Color not the only signal: add icons/text for positive/negative balances
- [A11Y-3] Reduce Motion/Transparency respected
- [L10N-1] Localize strings; support RTL layout
- [L10N-2] Indian numbering format (₹1,23,456) when locale applies

### Sharing & Collaboration
- [SHARE-1] Share sheet: export a readable group summary (PDF/Markdown)
- [SHARE-2] Invite link (local only for now): prefill members from Contacts; no server required
- [SHARE-3] Deep links: open a specific group/expense via URL scheme

### Payments (non-transactional first, user-controlled)
- [PAY-1] “Mark as paid” Settlements; attach a receipt screenshot
- [PAY-2] Quick actions to copy amount / compose iMessage to the payer
- [PAY-3] Placeholder Apple Pay button (non-transactional): opens share sheet with amount & memo

### System Integrations
- [SYS-1] Widgets: small/medium — show top group totals and quick “Add expense”
- [SYS-2] Live Activity: ongoing trip summary with running balance (optional)
- [SYS-3] App Intents / Shortcuts: “Log expense”, “Show balances”, “Add member”
- [SYS-4] Spotlight (Core Spotlight): index groups/expenses for system search
- [SYS-5] Notifications: local reminders to settle or log recurring expense

### Platforms
- [PLAT-1] iPad split view & keyboard shortcuts
- [PLAT-2] macOS (Mac Catalyst) with sidebar layout
- [PLAT-3] watchOS companion: quick “Add expense” + glanceable balances

### Privacy & Safety
- [PRIV-1] App privacy lock (Face ID/Touch ID); blur sensitive data in app switcher
- [PRIV-2] On-device only mode toggle (no CloudKit)
- [PRIV-3] Clear personal data: wipe demo data / reset store

### Quality & Tooling
- [TEST-3] Snapshot tests for key screens (optional)
- [OPS-1] Diagnostics toggle: structured `os_log` (no PII), exportable log file in Debug builds
- [OPS-2] Performance audit: measure large group (1k expenses) list scrolling and compute time

---

## Changelog
- 2025-08-24: MVP-1 — Added SwiftData persistence and seeded a demo group (Alex, Sam, Kai) on first launch.
- 2025-08-24: MVP-2 — Amount field uses locale-aware currency formatting and blocks invalid/empty values; lists and summary now show group currency.
- 2025-08-24: DOC-1 — Updated README with CI badge.
- 2025-08-24: MVP-3 — Added Settle Up screen with suggested transfers and settlement history.
- 2025-08-24: CORE-1 — Groups list shows balance summary, search, and recent activity sorting.
- 2025-08-24: MATH-1 — Added balances helper that suggests who pays whom.
- 2025-08-24: CORE-2 — Group detail shows sections for expenses, balances, settle up, and members.
- 2025-08-24: MATH-2 — Added share-based uneven splits.
- 2025-08-24: CORE-3 — Members can be added, renamed, and removed; expenses prevent deletion.
- 2025-08-24: CORE-4 — Expenses can be added, edited, or removed.
- 2025-08-24: TEST-1 — Added unit tests for settlement calculations.
- 2025-08-24: CORE-5 — Added optional category and note fields to expenses.
- 2025-08-24: CORE-4 — Expense list supports swipe edit and delete actions with context menu.
- 2025-08-25: TEST-2 — Added UI test for editing expenses.
- 2025-08-25: CORE-6 — Attach receipts with VisionKit scanner and thumbnails in lists.
- 2025-08-25: TEST-4 — UI tests for add/delete expense and settle up flow.
- 2025-08-25: CORE-7 — Added expense search by text, amount range, and members.
- 2025-08-26: UX-6 — Polished primary actions placement.


## Vision
A tiny, beautiful, Apple-grade Splitwise-style app for tracking shared expenses with clarity and grace.
