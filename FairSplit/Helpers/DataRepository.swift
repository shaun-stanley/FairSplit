import Foundation
import SwiftData

final class DataRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func seedIfNeeded() {
        let fetch = FetchDescriptor<Group>(predicate: #Predicate { _ in true })
        if let count = try? context.fetchCount(fetch), count == 0 {
            let alex = Member(name: "Alex")
            let sam = Member(name: "Sam")
            let kai = Member(name: "Kai")
            let group = Group(name: "Sample Trip", defaultCurrency: "USD", members: [alex, sam, kai])
            let e1 = Expense(title: "Groceries", amount: 36.50, payer: alex, participants: [alex, sam, kai])
            group.expenses.append(e1)
            context.insert(group)
            try? context.save()
        }
    }

    func addExpense(to group: Group, title: String, amount: Decimal, payer: Member?, participants: [Member]) {
        let expense = Expense(title: title, amount: amount, payer: payer, participants: participants)
        group.expenses.append(expense)
        try? context.save()
    }

    func delete(expenses: [Expense]) {
        for e in expenses { context.delete(e) }
        try? context.save()
    }
}

