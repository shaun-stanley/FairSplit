import Foundation
import SwiftData

@Model
final class Group {
    var name: String
    var defaultCurrency: String
    @Relationship(deleteRule: .cascade) var members: [Member]
    @Relationship(deleteRule: .cascade) var expenses: [Expense]
    @Relationship(deleteRule: .cascade) var settlements: [Settlement]

    init(name: String, defaultCurrency: String, members: [Member] = [], expenses: [Expense] = [], settlements: [Settlement] = []) {
        self.name = name
        self.defaultCurrency = defaultCurrency
        self.members = members
        self.expenses = expenses
        self.settlements = settlements
    }
}

extension Group {
    /// Latest activity date from expenses or settlements.
    var lastActivity: Date {
        let expenseDate = expenses.map(\.date).max() ?? .distantPast
        let settlementDate = settlements.map(\.date).max() ?? .distantPast
        return max(expenseDate, settlementDate)
    }

    /// Net balance for a member: positive means they are owed money.
    func balance(for member: Member) -> Decimal {
        let net = SplitCalculator.netBalances(
            expenses: expenses,
            members: members,
            settlements: settlements
        )
        return net[member.persistentModelID] ?? 0
    }
}
