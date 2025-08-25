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
            let code = Locale.current.currency?.identifier ?? "USD"
            let group = Group(name: "Sample Trip", defaultCurrency: code, members: [alex, sam, kai])
            let e1 = Expense(title: "Groceries", amount: 36.50, currencyCode: code, payer: alex, participants: [alex, sam, kai], category: .food, note: "Milk & eggs")
            group.expenses.append(e1)
            context.insert(group)
            try? context.save()
        }
    }

    func addGroup(name: String, defaultCurrency: String) {
        let group = Group(name: name, defaultCurrency: defaultCurrency)
        context.insert(group)
        try? context.save()
        if let undo = undoManager {
            undo.registerUndo(withTarget: self) { repo in
                repo.delete(groups: [group])
            }
            undo.setActionName("Add Group")
        }
    }

    func delete(groups: [Group]) {
        let removed = groups
        for g in groups { context.delete(g) }
        try? context.save()
        if let undo = undoManager {
            undo.registerUndo(withTarget: self) { repo in
                for g in removed { repo.context.insert(g) }
                try? repo.context.save()
            }
            undo.setActionName("Delete Group")
        }
    }

    func addExpense(to group: Group, title: String, amount: Decimal, payer: Member?, participants: [Member], category: ExpenseCategory? = nil, note: String? = nil, receiptImageData: Data? = nil, currencyCode: String? = nil, fxRateToGroupCurrency: Decimal? = nil) {
        let expense = Expense(title: title, amount: amount, currencyCode: currencyCode ?? group.defaultCurrency, fxRateToGroupCurrency: fxRateToGroupCurrency, payer: payer, participants: participants, category: category, note: note, receiptImageData: receiptImageData)
        group.expenses.append(expense)
        if let rate = fxRateToGroupCurrency, expense.currencyCode != group.defaultCurrency {
            group.lastFXRates[expense.currencyCode] = rate
        }
        try? context.save()
        if let undo = undoManager {
            undo.registerUndo(withTarget: self) { repo in
                repo.delete(expenses: [expense], from: group)
            }
            undo.setActionName("Add Expense")
        }
    }

    func update(expense: Expense, in group: Group, title: String, amount: Decimal, payer: Member?, participants: [Member], category: ExpenseCategory?, note: String?, receiptImageData: Data? = nil, currencyCode: String? = nil, fxRateToGroupCurrency: Decimal? = nil) {
        // Capture old state for undo
        let old = (expense.title, expense.amount, expense.currencyCode, expense.fxRateToGroupCurrency, expense.payer, expense.participants, expense.category, expense.note, expense.receiptImageData)
        expense.title = title
        expense.amount = amount
        if let currencyCode { expense.currencyCode = currencyCode }
        expense.fxRateToGroupCurrency = fxRateToGroupCurrency
        expense.payer = payer
        expense.participants = participants
        expense.category = category
        expense.note = note
        expense.receiptImageData = receiptImageData
        if let rate = fxRateToGroupCurrency {
            let code = currencyCode ?? expense.currencyCode
            if code != group.defaultCurrency {
                group.lastFXRates[code] = rate
            }
        }
        try? context.save()
        if let undo = undoManager {
            undo.registerUndo(withTarget: self) { repo in
                repo.update(expense: expense, in: group, title: old.0, amount: old.1, payer: old.4, participants: old.5, category: old.6, note: old.7, receiptImageData: old.8, currencyCode: old.2, fxRateToGroupCurrency: old.3)
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
        // Append new settlements
        for t in transfers {
            let s = Settlement(from: t.from, to: t.to, amount: t.amount)
            group.settlements.append(s)
        }
        let addedCount = transfers.count
        try? context.save()
        if let undo = undoManager {
            undo.registerUndo(withTarget: self) { repo in
                // Remove the last N settlements we just added (avoids capturing non-Sendable model instances)
                let count = group.settlements.count
                if addedCount > 0 && count >= addedCount {
                    group.settlements.removeSubrange((count - addedCount)..<count)
                }
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
