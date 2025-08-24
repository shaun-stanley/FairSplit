import Foundation
import SwiftData

@Model
final class Group {
    var name: String
    var defaultCurrency: String
    @Relationship(deleteRule: .cascade) var members: [Member]
    @Relationship(deleteRule: .cascade) var expenses: [Expense]

    init(name: String, defaultCurrency: String, members: [Member] = [], expenses: [Expense] = []) {
        self.name = name
        self.defaultCurrency = defaultCurrency
        self.members = members
        self.expenses = expenses
    }
}

