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
