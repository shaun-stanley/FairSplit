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

    func update(expense: Expense, title: String, amount: Decimal, payer: Member?, participants: [Member]) {
        expense.title = title
        expense.amount = amount
        expense.payer = payer
        expense.participants = participants
        try? context.save()
    }

    func delete(expenses: [Expense]) {
        for e in expenses { context.delete(e) }
        try? context.save()
    }

    func recordSettlements(for group: Group, transfers: [(from: Member, to: Member, amount: Decimal)]) {
        for t in transfers {
            let s = Settlement(from: t.from, to: t.to, amount: t.amount)
            group.settlements.append(s)
        }
        try? context.save()
    }
    func addMember(to group: Group, name: String) {
        let member = Member(name: name)
        group.members.append(member)
        try? context.save()
    }

    func rename(member: Member, to newName: String) {
        member.name = newName
        try? context.save()
    }

    /// Returns true if deletion succeeded; false if member is used in any expense.
    func delete(member: Member, from group: Group) -> Bool {
        let used = group.expenses.contains {
            $0.payer?.persistentModelID == member.persistentModelID ||
            $0.participants.contains(where: { $0.persistentModelID == member.persistentModelID })
        }
        guard !used else { return false }
        context.delete(member)
        try? context.save()
        return true
    }

}
