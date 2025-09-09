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
- Core features: Groups ✅  Expenses ✅  Balances ✅  Settle Up ✅
- Input: ✅ Currency formatter + validation for amount

## Next Up (top first — keep ≤3)
1. [UX-46] Improve balance formatting for long names
2. [UX-47] Larger tap targets for swipe actions
3. [UX-48] Add pull-to-refresh placeholders

## In Progress
[UX-45] Polish empty states for iOS 18 style




## Done
[A11Y-3] Respect Reduce Motion: disables spring animations when user prefers reduced motion.
[UX-44] Monospaced digits for amounts: applied monospaced digits to currency labels to prevent jitter in lists and summaries.
[ONB-1] Welcome sheet on first run: added 3-page tour with privacy note; uses native bottom toolbar for controls.
[UX-42] Micro-interactions: added subtle spring animations for add/edit/delete across expenses, members, groups, and direct items.
[L10N-2] Indian numbering format: format amounts with Indian digit grouping when currency is INR or the user’s region is India (e.g., ₹1,23,456.78).
[A11Y-2] Color not the only signal: added icons and text (Owed/Owes) alongside colored amounts in Summary; improved VoiceOver labels to announce "is owed/owes" instead of relying on sign/color.
[UX-30] Dynamic Type audit: refined trailing amount labels to avoid truncation; added line limits and scaling to Direct and Settle Up lists for clearer large text.
[UX-4] TipKit coach marks: first-run hints for Add Expense and Settle Up; added TipKit popover tips to Add Expense Save and Group Detail actions; ensured TipKit configured on launch.
[UX-41] Align page content with nav title margins across all screens. Applied consistent horizontal scroll content margins to any remaining screens (e.g., Expense List) and avoided double-insets.
[UX-40] Groups: aligned large titles with content margins across tabs using system-aligned scroll content margins; kept large, horizontally scrollable tiles for Groups
[DATA-5] Seed: sample group default currency set to INR for all seeded expenses; maintains FX mapping for USD/EUR examples
[UX-37] Reports: Apple-like chart polish with rounded bars, interactive scrubbing + callouts + haptics, smoother animations, and softer gridlines
[BUG-11] Reports: simplified Monthly Trend chart to avoid type-check timeout; precomputed values and extracted gradient with smoothed area+line and average rule
[UX-36] Reports: elevated charts with material plot backgrounds, sorted category bars with currency annotations, and smoothed area+line monthly trend with average rule line
[BUG-10] Reports: Average per month uses the selected currency from Settings (or current group) instead of locale $ symbol
[DATA-4] Seed: add rich demo dataset with many months of multi-category expenses, some FX, comments, settlements, and recurring
[UX-35] Title display: adopted native inlineLarge title mode across Groups, Direct, Reports, Settings
[UX-34] Groups: large title inline with trailing actions; tighter header spacing
[UX-33] Groups: large title with inline trailing Add button; matches Apple’s large-title pattern in iOS 26
[UX-32] Group Detail navigation: replaced cramped nav-bar segmented control with a title menu for section jumps; consolidated trailing items into an Add menu and a single More menu to prevent overflow on compact widths. Note: follows Apple’s HIG for Navigation Bars and uses SwiftUI toolbarTitleMenu.
[UX-29] Spacing and hierarchy: consistent secondary text and truncation across lists; Dynamic Type friendly
[UX-28] Expense row: comment count inline; removed bordered button
[UX-27] Group Detail: moved segmented tabs into nav bar control; scroll-to-section preserved
[UX-26] iOS 26 UI polish: Archived uses system badge; added swipe archive/unarchive; removed non-standard bottom-sheet button
[BUG-6] Group Detail: converted row headers to Section headers; pill bar now uses material blur with bottom divider and avoids overlap
[BUG-7] Group Detail: switched pill bar to system glass background (no custom UI); kept divider; adjusted spacing to avoid title/search overlap
[BUG-8] Group Detail: removed pill bar and any glass/material backgrounds; restored standard layout
[UX-11] Group Detail: added pinned segmented tabs (Expenses, Recurring, Categories, Activity); clicking a tab scrolls to its section; all sections remain visible on one page
[OPS-1] Diagnostics: toggle in Settings; logs via os.Logger + in-app exportable log
[SYS-2] Live Activity: start/stop a simple running summary from Group actions (guarded by ActivityKit)
[L10N-1] Localization scaffolding: added base Localizable.strings (en); code uses Text titles for future translations
[SYS-4] Spotlight: indexed groups and expenses; reindex on launch
[PRIV-1] App privacy lock: toggle in Settings; Face ID/Touch ID overlay on launch/background
[SHARE-3] Deep links: fairsplit://add-expense opens Add Expense; fairsplit://group?name=… opens that group
[SYS-3] App Intents: basic shortcuts for “Log Expense” and “Show Balances”; opens app
[SYS-1] Widgets: placeholder widget with quick Add deep link; opens Add Expense in most recent group
[PAY-3] Placeholder Apple Pay: Apple Pay-style button in Settle Up opens share sheet with amount and optional memo
[SHARE-2] Invite from Contacts: add members from the Contacts picker in Members; no server needed
[CORE-12] Comments on expenses + simple activity feed: per-expense threads and recent activity section
[DATA-2] iCloud sync toggle added in Settings; keeps local-only for now until entitlements/CI enable CloudKit
[SYS-5] Notifications: daily reminder toggle with time picker; scheduled at launch
[BUG-5] Guarded charts so CI doesn't break; archive unchanged
[UX-9] Balance row quick actions in Group Detail: copy amount, message owing member
[PAY-2] Quick actions: copy amount and compose message from Settle Up proposals/history
[UX-8] Itemized editor: delete rows and better default participants
[CORE-16] Archive/close group: archived flag, read-only UI, list sections, un/archive toggle
[CORE-15] Merge members: reassign expenses/shares/recurring/settlements; remove self-settlements; UI to merge
[REPORTS-2] Charts and monthly summaries: category bar chart, monthly trend line
[PAY-1] Marked settlements as paid with optional receipt image; swipe actions in Settle Up
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
[MATH-4] Expenses remember last used FX rate per currency
[CORE-8] Undo/Redo for create/edit/delete operations
[CORE-10] Groups can be added from list; sample group seeded on first launch
[UX-7] Removed undo/redo toolbar; new groups appear immediately
[BUG-1] Fixed new groups not appearing by including Settlement in model container
[BUG-2] Seeded sample group with locale currency to ensure new groups appear
[BUG-3] Ensure groups list refreshes when adding a new group
[BUG-4] Groups not showing in simulator after creation — stabilized list identity, added empty state, defaulted to INR, added UI test
[DATA-3] CSV export/import added in Group Detail (menu); unit tests exist
[SHARE-1] Share sheet: export a readable group summary (Markdown and PDF)
[MATH-5] Per-member totals and per-category totals in group
[CORE-9] App theming: light/dark with accent color; respect system appearance
[PLAT-1] iPad split view & keyboard shortcuts
[NAV-1] Tab bar navigation: Groups, Reports, Settings
[UX-1] Dynamic Type audit; layouts for large sizes
[A11Y-1] VoiceOver labels/traits for interactive elements
[CORE-2] Group detail: sticky section headers (Expenses, Balances, Settle Up, Members)
[UX-3] SF Symbols for categories and actions
[UX-2] Haptics on key actions (add expense, settle)


## Blocked
- [SYS-1/WID] Widget target temporarily removed to fix Xcode project parse error. Code scaffold remains; re-add target via Xcode.

---

## Backlog (move items up to “Next Up” when ready)

### Core Experience
 - [CORE-2] Group detail: sections (Expenses, Balances, Settle Up, Members) with sticky headers
- [CORE-9] App theming: light/dark with accent color; respect system appearance
- [CORE-14] Itemized bill split (per-item, tax/tip allocation)
- [CORE-15] Merge members (dedupe and reassign expenses)
- [CORE-16] Archive/close group (read-only with summary)

### Money & Math
- [MATH-3] Recurring expenses (monthly rent, subscriptions) with auto-add and pause
- [MATH-4] Multi-currency per group with **manual FX rates** (safe, offline). Optional: remember last rate used
- [MATH-5] Per-member totals and per-category totals in group
- [MATH-6] Live FX rates (daily cached, offline fallback) for multi-currency

### Persistence & Sync
- [DATA-1] SwiftData migration support (lightweight model versioning)
- [DATA-2] iCloud sync via **CloudKit** (private database). Simple last-write-wins, then improve conflict handling

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
- [CORE-12] Comments on expenses and a simple activity feed

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

### Reports
- [REPORTS-2] Charts and monthly summaries using Swift Charts (spend by person/category/time)

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
- 2025-09-09: A11Y-3 — Respect Reduce Motion and avoid spring animations.
- 2025-09-09: UX-44 — Monospaced digits for currency amounts across key screens.
- 2025-09-09: ONB-1 — Added welcome sheet with a short tour and privacy note, adopting native bottom toolbar for navigation.
- 2025-09-08: L10N-2 — Use Indian numbering format when applicable (INR or India region), e.g., ₹1,23,456.78.
- 2025-09-08: A11Y-2 — Balances no longer rely on color alone: added icons and Owed/Owes text; improved VoiceOver labels.
- 2025-09-08: UX-30 — Improved Dynamic Type handling for key rows: ensured amounts scale and truncate gracefully in Direct and Settle Up lists.
- 2025-09-08: UX-4 — Added TipKit coach marks for Add Expense (Save and Add menu) and Settle Up; configured Tips on launch.
- 2025-09-08: UX-41 — Aligned page content with navigation title margins across remaining screens (added horizontal content margins to Expense List, ensured no double-insets).
- 2025-09-08: UX-40 — Aligned large navigation titles with content margins across Groups, Direct, Reports, and Settings using dynamic system-aligned scroll content margins; preserved Groups' large, horizontally scrollable tiles.
- 2025-08-31: DATA-5 — Sample group seed now uses INR as the default currency; seeded local expenses use INR, with USD examples converted via static demo FX to INR.
- 2025-08-31: UX-37 — Polished Reports charts: rounded category bars with spacing, material plot backgrounds, interactive scrubbing with callouts and haptics, smoothed area+line trend, and softened grids/labels.
- 2025-08-31: BUG-11 — Simplified Monthly Trend chart to fix type-check timeout; precomputed values, extracted gradient, added smoothed area+line and kept average rule.
- 2025-08-31: DATA-4 — Seeded a large demo dataset: 18 months of expenses across categories, occasional foreign-currency items with manual FX, comments, a settlement, and a weekly recurring expense.
- 2025-08-31: BUG-10 — Reports Highlights now formats Average per month in the selected app/group currency (not locale $).
- 2025-08-31: UX-27 — Replaced in-content segmented bar with a navigation bar segmented control for sections; content scrolls to anchors.
- 2025-08-31: UX-28 — Lightened expense rows: show comment count inline as a small plain control; removed bordered comment button.
- 2025-08-31: UX-29 — Minor spacing and hierarchy tweaks across lists; consistent subheadline secondary text; improved single-line truncation.
- 2025-08-31: UX-26 — UI polish: system Archived badge, swipe archive/unarchive, removed non-standard bottom action in currency sheet.
- 2025-08-27: BUG-7 — Pill bar now uses system glass background (no custom UI). Keeps a thin divider and respects large title/search during scroll.
- 2025-08-27: BUG-8 — Removed pill navigation and all glass/material backgrounds from Group Detail to simplify and restore native behavior.
- 2025-08-27: UX-11 — Added pinned segmented tabs (Expenses, Recurring, Categories, Activity) in Group Detail that jump to each section while keeping all sections visible.
- 2025-08-27: BUG-6 — Polished Group Detail: real Section headers (Balances/Settle Up/Members); pill bar now uses .bar blur + divider and avoids overlap with title/search.
- 2025-08-27: OPS-1 — Added Diagnostics toggle and exportable in-app log; uses os.Logger with no PII.
- 2025-08-27: SYS-2 — Added Live Activity scaffold with start/stop controls in Group actions; safely guarded with ActivityKit checks.
- 2025-08-27: L10N-1 — Added base Localizable.strings (en); UI strings prepared for translation.
- 2025-08-26: FIX — Restored project.pbxproj to resolve parse error; will re-add Widget target via Xcode UI.
- 2025-08-26: WID-2 — Widget now displays top group total from shared defaults when App Group is enabled.
- 2025-08-26: SYS-4 — Indexed groups and expenses for Spotlight search; reindex on launch.
- 2025-08-26: PRIV-1 — Added Privacy Lock with biometric unlock and a Settings toggle.
- 2025-08-26: SHARE-3 — Added deep links for quick add (add-expense) and open group by name.
- 2025-08-26: SYS-3 — Added basic App Intents (Log Expense, Show Balances) with App Shortcuts that open the app.
- 2025-08-26: SYS-1 — Added Widget extension with static summary and a quick Add deep link that opens Add Expense in the most recent group.
- 2025-08-26: PAY-3 — Added placeholder Apple Pay button in Settle Up that opens the share sheet with amount and optional memo.
- 2025-08-26: SHARE-2 — Added Contacts picker to import members from the device address book.
- 2025-08-26: CORE-12 — Added per-expense comments and a Recent Activity section in Group Detail.
- 2025-08-26: DATA-2 — Added iCloud Sync toggle in Settings with local fallback; CloudKit wiring to follow once entitlements available.
- 2025-08-26: SYS-5 — Added local notifications: daily reminder toggle and time picker, schedules at launch.
- 2025-08-26: PAY-2 — Added "Message Payer" to settlement history; proposals already supported copy/message.
- 2025-08-26: BUG-5 — Guard charts with compile-time checks so CI doesn't fail; archive unchanged.
- 2025-08-26: UX-9 — Balance row quick actions to copy amount or compose message for members who owe.
- 2025-08-26: PAY-2 — Quick actions to copy amount and compose an iMessage from Settle Up rows.
- 2025-08-26: UX-8 — Itemized editor supports deleting rows and preselects participants for new items.
- 2025-08-26: CORE-16 — Archive groups with read-only detail, list sections, and un/archive actions.
- 2025-08-26: CORE-15 — Merge members with reassignment across expenses/shares/recurring/settlements and remove invalid self-settlements; UI from Members screen.
- 2025-08-26: REPORTS-2 — Added category bar chart and monthly trend line in Reports; monthly totals in StatsCalculator.
- 2025-08-26: PAY-1 — Mark settlements as paid with optional receipt; swipe actions and scanner from Settle Up.
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
- 2025-08-26: MATH-4 — Expenses remember last FX rate per currency.
- 2025-08-27: CORE-8 — Added undo/redo toolbar for data actions.
- 2025-08-27: CORE-10 — Added group creation screen and seeded sample group on first launch.
- 2025-08-28: UX-7 — Removed undo/redo toolbar buttons and ensured new groups appear immediately.
- 2025-08-28: BUG-1 — Fixed missing Settlement model so new groups appear after creation.
- 2025-08-29: BUG-2 — Seeded sample group using locale currency to ensure INR groups show.
- 2025-08-30: BUG-3 — Fixed groups list not updating after adding a group.
- 2025-08-26: BUG-4 — Fixed groups not showing on simulator; stable List identity, default INR, and UI test added.
- 2025-08-26: DATA-3 — CSV import/export added to Group detail menu.
- 2025-08-26: SHARE-1 — Added group summary sharing (Markdown + PDF) from Group detail.
- 2025-08-26: MATH-5 — Added totals by member and totals by category in Group detail.
- 2025-08-26: CORE-9 — Added theming settings (appearance + accent) and applied app-wide.
- 2025-08-26: PLAT-1 — Added iPad split view with sidebar and Command-N for New Group.
- 2025-08-26: NAV-1 — Added tab bar with Groups, Reports, and Settings; new Reports summary view.
- 2025-08-26: UX-1 — Improved Dynamic Type: multiline titles/notes, content-first layouts, and readable trailing amounts.
- 2025-08-26: A11Y-1 — Added VoiceOver labels and traits for rows and toolbar actions across Groups, Group Detail, Expense List, and Reports.
- 2025-08-26: CORE-2 — Sticky section headers and grouped look in Group Detail.
- 2025-08-26: UX-3 — Added SF Symbols for expense categories, balances (up/down arrows), and settle-up/report rows.
- 2025-08-26: UX-2 — Added subtle haptics for adding an expense, recording settlement, and deleting expenses.
- 2025-08-26: MATH-3 — Recurring expenses with add/pause/delete/run-now and auto-generate on launch.
- 2025-08-26: CORE-11 — Direct expenses: contacts, balances per pair, recent list, add/edit/delete flows.

## Vision
A tiny, beautiful, Apple-grade Splitwise-style app for tracking shared expenses with clarity and grace.
