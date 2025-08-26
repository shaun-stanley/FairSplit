import Foundation
import SwiftData

@Model
final class Group {
    var name: String
    var defaultCurrency: String
    @Attribute var lastFXRates: [String: Decimal] = [:]
    @Relationship(deleteRule: .cascade) var members: [Member]
    @Relationship(deleteRule: .cascade) var expenses: [Expense]
    @Relationship(deleteRule: .cascade) var settlements: [Settlement]
    @Relationship(deleteRule: .cascade) var recurring: [RecurringExpense] = []
    var createdAt: Date
    var isArchived: Bool = false
    var archivedAt: Date?

    init(name: String, defaultCurrency: String, members: [Member] = [], expenses: [Expense] = [], settlements: [Settlement] = [], createdAt: Date = .now) {
        self.name = name
        self.defaultCurrency = defaultCurrency
        self.members = members
        self.expenses = expenses
        self.settlements = settlements
        self.createdAt = createdAt
    }
}

extension Group {
    /// Latest activity date from expenses or settlements.
    var lastActivity: Date {
        let expenseDate = expenses.map(\.date).max() ?? .distantPast
        let settlementDate = settlements.map(\.date).max() ?? .distantPast
        let archived = archivedAt ?? .distantPast
        return max(createdAt, max(expenseDate, max(settlementDate, archived)))
    }

    /// Net balance for a member: positive means they are owed money.
    func balance(for member: Member) -> Decimal {
        let net = SplitCalculator.netBalances(
            expenses: expenses,
            members: members,
            settlements: settlements,
            defaultCurrency: defaultCurrency
        )
        return net[member.persistentModelID] ?? 0
    }
}
