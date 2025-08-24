# FairSplit
[![iOS CI](https://github.com/OWNER/FairSplit/actions/workflows/ios-ci.yml/badge.svg)](https://github.com/OWNER/FairSplit/actions/workflows/ios-ci.yml)

A lightweight SwiftUI app scaffold for splitting expenses among participants. This repository is structured for clarity and quick iteration, with Models, Views, Helpers, and tests organized per AGENTS.md.

## Requirements
- Xcode 16.4+ (iOS SDK 18.5)
- iOS 18.0+ deployment target (project is set to 18.5)

## Project Structure
- `FairSplit/Models/`: SwiftData models (`Group`, `Member`, `Expense`).
- `FairSplit/Helpers/`: Pure helpers (`SplitCalculator`, `CurrencyFormatter`).
- `FairSplit/Views/`: SwiftUI views (`ExpenseListView`, `AddExpenseView`, `SplitSummaryView`).
- `FairSplitTests/`: Unit tests using Swift Testing.
- `FairSplitUITests/`: UI tests using XCTest.

## Build & Run
- Open in Xcode: `open FairSplit.xcodeproj` and run the `FairSplit` scheme.
- CLI build (generic sim): `xcodebuild -scheme FairSplit -destination 'generic/platform=iOS Simulator' build`
- CLI test (example device): `xcodebuild test -scheme FairSplit -destination 'platform=iOS Simulator,name=iPhone 16'`

## Notes
- Upgraded to SwiftData (iOS 18+): models `Group`, `Member`, `Expense` are `@Model` types with relationships.
- The app seeds one sample group on first launch if the store is empty.
- See `AGENTS.md` for contributor guidelines, coding style, and PR conventions.
