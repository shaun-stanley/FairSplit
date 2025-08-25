import Foundation
import SwiftData

final class DataRepository {
    private let context: ModelContext
    private let undoManager: UndoManager?

    init(context: ModelContext, undoManager: UndoManager? = nil) {
        self.context = context
        self.undoManager = undoManager
    }

    func seedIfNeeded() {
        let fetch = FetchDescriptor<Group>(predicate: #Predicate { _ in true })
        if let count = try? context.fetchCount(fetch), count == 0 {
            let alex = Member(name: "Alex")
            let sam = Member(name: "Sam")
            let kai = Member(name: "Kai")
            let group = Group(name: "Sample Trip", defaultCurrency: "USD", members: [alex, sam, kai])
            let e1 = Expense(title: "Groceries", amount: 36.50, payer: alex, participants: [alex, sam, kai], category: .food, note: "Milk & eggs")
            group.expenses.append(e1)
            context.insert(group)
            try? context.save()
        }
    }

    func addExpense(to group: Group, title: String, amount: Decimal, payer: Member?, participants: [Member], category: ExpenseCategory? = nil, note: String? = nil, receiptImageData: Data? = nil) {
        let expense = Expense(title: title, amount: amount, payer: payer, participants: participants, category: category, note: note, receiptImageData: receiptImageData)
        group.expenses.append(expense)
        try? context.save()
        if let undo = undoManager {
            undo.registerUndo(withTarget: self) { repo in
                repo.delete(expenses: [expense], from: group)
            }
            undo.setActionName("Add Expense")
        }
    }

    func update(expense: Expense, title: String, amount: Decimal, payer: Member?, participants: [Member], category: ExpenseCategory?, note: String?, receiptImageData: Data? = nil) {
        // Capture old state for undo
        let old = (expense.title, expense.amount, expense.payer, expense.participants, expense.category, expense.note, expense.receiptImageData)
        expense.title = title
        expense.amount = amount
        expense.payer = payer
        expense.participants = participants
        expense.category = category
        expense.note = note
        expense.receiptImageData = receiptImageData
        try? context.save()
        if let undo = undoManager {
            undo.registerUndo(withTarget: self) { repo in
                repo.update(expense: expense, title: old.0, amount: old.1, payer: old.2, participants: old.3, category: old.4, note: old.5, receiptImageData: old.6)
            }
            undo.setActionName("Edit Expense")
        }
    }

    func delete(expenses: [Expense], from group: Group) {
        // Keep references to restore on undo
        let removed = expenses
        for e in expenses { context.delete(e) }
        try? context.save()
        if let undo = undoManager {
            undo.registerUndo(withTarget: self) { repo in
                for e in removed { group.expenses.append(e) }
                try? repo.context.save()
            }
            undo.setActionName("Delete Expense")
        }
    }

    func recordSettlements(for group: Group, transfers: [(from: Member, to: Member, amount: Decimal)]) {
        var added: [Settlement] = []
        for t in transfers {
            let s = Settlement(from: t.from, to: t.to, amount: t.amount)
            group.settlements.append(s)
            added.append(s)
        }
        try? context.save()
        if let undo = undoManager {
            undo.registerUndo(withTarget: self) { repo in
                // Remove the settlements we just added
                group.settlements.removeAll { s in added.contains(where: { $0.persistentModelID == s.persistentModelID }) }
                try? repo.context.save()
            }
            undo.setActionName("Record Settlement")
        }
    }
    func addMember(to group: Group, name: String) {
        let member = Member(name: name)
        group.members.append(member)
        try? context.save()
        if let undo = undoManager {
            undo.registerUndo(withTarget: self) { repo in
                _ = repo.delete(member: member, from: group)
            }
            undo.setActionName("Add Member")
        }
    }

    func rename(member: Member, to newName: String) {
        let oldName = member.name
        member.name = newName
        try? context.save()
        if let undo = undoManager {
            undo.registerUndo(withTarget: self) { repo in
                repo.rename(member: member, to: oldName)
            }
            undo.setActionName("Rename Member")
        }
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
        if let undo = undoManager {
            undo.registerUndo(withTarget: self) { repo in
                group.members.append(member)
                try? repo.context.save()
            }
            undo.setActionName("Delete Member")
        }
        return true
    }

}
