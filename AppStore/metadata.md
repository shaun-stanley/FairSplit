# FairSplit - App Store Submission Packet

## Metadata Summary
- **Name:** FairSplit
- **Subtitle:** Share expenses with clarity and calm
- **Promotional Text:** Keep every shared bill tidy. FairSplit suggests who pays whom, tracks personal spending, and works beautifully on iPhone and iPad.
- **Description:**
  - Welcome travelers, roommates, and teams to an Apple-first way to share costs.
  - Track groups with rich context - split uneven expenses, log receipts, attach comments, and settle up with confidence.
  - See who owes whom instantly. Suggested transfers, recurring expenses, and personal insights keep everyone aligned.
  - Works offline with SwiftData; optionally sync privately through iCloud when available. Widgets, Live Activities, and TipKit hints keep momentum going.
- **Keywords:** splitwise, expenses, shared bills, travel, roommates, groups, settle up, personal budget, receipts, iCloud
- **Primary Category:** Finance
- **Secondary Category:** Productivity
- **Age Rating:** 4+
- **Platforms:** iOS, iPadOS (universal build)
- **App Icon Asset:** `AppIcon/`
- **Support URL:** https://sviftstudios.com/support/fairsplit
- **Marketing URL:** https://sviftstudios.com/fairsplit
- **Privacy Policy URL:** https://sviftstudios.com/privacy

## Screenshots Checklist
1. iPhone 6.7" - Groups overview with balances
2. iPhone 6.1" - Settle Up suggested transfers
3. iPhone 6.1" - Personal tab hero + list
4. iPhone 6.1" - Reports chart highlights
5. iPad 12.9" - Split view with Group detail + expense list
6. Widget preview - medium widget showing top group

> Export updated assets into `AppStore/Screenshots/` before submission.

## App Privacy (App Store Connect Answers)
- **Data Collected:** None. FairSplit stores all information on device. When the optional iCloud sync toggle is enabled, data is stored in the user’s private iCloud database and is not accessible to Svift Studios.
- **Data Used for Tracking:** None
- **Data Linked to the User:** None
- **Data Not Linked to the User:** None
- **Diagnostics:** Optional in-app diagnostics toggle writes anonymized logs locally for export by the user only.

## Compliance Notes
- No third-party analytics SDKs.
- No advertising or tracking identifiers.
- Uses Apple frameworks only (SwiftUI, SwiftData, CloudKit, WidgetKit, ActivityKit, TipKit, VisionKit).
- App Groups entitlement: `group.com.sviftstudios.FairSplit`
- CloudKit container: `iCloud.com.sviftstudios.FairSplit`
- In-App Purchases: None
- Payments: Apple Pay currently not integrated; settlement workflow uses manual logging.

## Review Notes Template
> Thanks for reviewing FairSplit! Test with the seeded "Goa Trip" group for demo data. If you toggle iCloud Sync in Settings, please run on an iCloud-signed build; the app will fall back to offline mode if entitlements are missing.
