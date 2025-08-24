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
1. [CORE-2] Group detail: sections (Expenses, Balances, Settle Up, Members) with sticky headers
2. [MATH-2] Unequal splits: shares / percentages / exact amounts (choose one simple mode first)
3. [CORE-3] Members management: add/rename/remove members; prevent deleting a member referenced by expenses

## In Progress
(none)

## Done
[MVP-1] Added SwiftData and a demo group
[MVP-2] Polished amount input with currency formatting and validation
[DOC-1] Use GitHub CI badge in README
[MVP-3] Settle Up suggests transfers and saves them
[CORE-1] Groups list shows balance summary, search, and recent activity sorting
[MATH-1] Added balances helper suggesting who pays whom

## Blocked
(none)

---

## Backlog (move items up to “Next Up” when ready)

### Core Experience
- [CORE-2] Group detail: sections (Expenses, Balances, Settle Up, Members) with sticky headers
- [CORE-3] Members management: add/rename/remove members; prevent deleting a member referenced by expenses
- [CORE-4] Expense editing: edit/delete, swipe actions, context menu
- [CORE-5] Categories & notes: optional category (Food/Travel/etc.) + free-text notes
- [CORE-6] Attach receipts: add photo/scan using **VisionKit** document scanner; show thumbnail in expense row
- [CORE-7] Search expenses: title, note, amount range, member filters
- [CORE-8] Undo/Redo for create/edit/delete operations
- [CORE-9] App theming: light/dark with accent color; respect system appearance

### Money & Math
- [MATH-2] Unequal splits: shares / percentages / exact amounts (choose one simple mode first)
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
- [TEST-1] Unit tests for settlement math (edge cases, rounding, settlements)
- [TEST-2] UI tests for add/edit/delete expense and settle flow
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

## Vision
A tiny, beautiful, Apple-grade Splitwise-style app for tracking shared expenses with clarity and grace.
