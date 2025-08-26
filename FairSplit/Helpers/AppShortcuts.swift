import Foundation
import AppIntents

struct LogExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Expense"
    static var description = IntentDescription("Quickly open FairSplit to add a new expense.")
    @MainActor static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct ShowBalancesIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Balances"
    static var description = IntentDescription("Open FairSplit to view current balances.")
    @MainActor static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

// App Shortcuts provider omitted for SDK compatibility; intents are still available.
