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

struct FairSplitShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: LogExpenseIntent(),
                phrases: ["Log expense in \(.applicationName)", "Add expense in \(.applicationName)"] ,
                shortTitle: "Log Expense",
                systemImageName: "plus.circle"
            ),
            AppShortcut(
                intent: ShowBalancesIntent(),
                phrases: ["Show balances in \(.applicationName)", "View balances in \(.applicationName)"],
                shortTitle: "Show Balances",
                systemImageName: "chart.bar"
            )
        ]
    }
}

