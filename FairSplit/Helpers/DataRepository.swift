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
            let code = AppSettings.defaultCurrencyCode()
            let group = Group(name: "Sample Trip", defaultCurrency: code, members: [alex, sam, kai])
            let e1 = Expense(title: "Groceries", amount: 36.50, currencyCode: code, payer: alex, participants: [alex, sam, kai], category: .food, note: "Milk & eggs")
            group.expenses.append(e1)
            context.insert(group)
            try? context.save()
        }
    }

    // MARK: - Comments
    func addComment(to expense: Expense, text: String, authorName: String? = nil) {
        let comment = Comment(text: text, date: .now, author: authorName)
        expense.comments.append(comment)
        try? context.save()
        if let undo = undoManager {
            undo.registerUndo(withTarget: self) { repo in
                repo.deleteComment(comment, from: expense)
            }
            undo.setActionName("Add Comment")
        }
    }

    func deleteComment(_ comment: Comment, from expense: Expense) {
        if let index = expense.comments.firstIndex(where: { $0.persistentModelID == comment.persistentModelID }) {
            expense.comments.remove(at: index)
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

    func setArchived(_ archived: Bool, for group: Group) {
        group.isArchived = archived
        group.archivedAt = archived ? .now : nil
        try? context.save()
        if let undo = undoManager {
            undo.registerUndo(withTarget: self) { repo in
                repo.setArchived(!archived, for: group)
            }
            undo.setActionName(archived ? "Archive Group" : "Unarchive Group")
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

    func addItemizedExpense(to group: Group, title: String, items: [(title: String, amount: Decimal, participants: [Member])], tax: Decimal? = nil, tip: Decimal? = nil, allocation: Expense.TaxTipAllocation = .proportional, payer: Member?, category: ExpenseCategory? = nil, note: String? = nil, receiptImageData: Data? = nil, currencyCode: String? = nil, fxRateToGroupCurrency: Decimal? = nil) {
        let totalItems = items.reduce(0) { $0 + $1.amount }
        let total = totalItems + (tax ?? 0) + (tip ?? 0)
        let expense = Expense(title: title, amount: total, currencyCode: currencyCode ?? group.defaultCurrency, fxRateToGroupCurrency: fxRateToGroupCurrency, payer: payer, participants: Array(Set(items.flatMap { $0.participants })), category: category, note: note, receiptImageData: receiptImageData)
        expense.tax = tax
        expense.tip = tip
        expense.taxTipAllocation = allocation
        for i in items {
            let item = ItemizedItem(title: i.title, amount: i.amount, participants: i.participants)
            expense.items.append(item)
        }
        group.expenses.append(expense)
        if let rate = fxRateToGroupCurrency, expense.currencyCode != group.defaultCurrency {
            group.lastFXRates[expense.currencyCode] = rate
        }
        try? context.save()
        if let undo = undoManager {
            undo.registerUndo(withTarget: self) { repo in
                repo.delete(expenses: [expense], from: group)
            }
            undo.setActionName("Add Itemized Expense")
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

    func recordSettlement(for group: Group, from: Member, to: Member, amount: Decimal, receiptImageData: Data? = nil, isPaid: Bool = true) {
        let settlement = Settlement(from: from, to: to, amount: amount, date: .now, isPaid: isPaid, receiptImageData: receiptImageData)
        group.settlements.append(settlement)
        try? context.save()
        if let undo = undoManager {
            // Capture stable identifiers only to satisfy Swift 6 Sendable rules
            let groupID = group.persistentModelID
            let settlementID = settlement.persistentModelID
            undo.registerUndo(withTarget: self) { repo in
                // Refetch the group in this context using its persistent ID
                let fetch = FetchDescriptor<Group>(predicate: #Predicate { $0.persistentModelID == groupID })
                if let targetGroup = try? repo.context.fetch(fetch).first,
                   let idx = targetGroup.settlements.firstIndex(where: { $0.persistentModelID == settlementID }) {
                    targetGroup.settlements.remove(at: idx)
                    try? repo.context.save()
                }
            }
            undo.setActionName("Record Settlement")
        }
    }

    func recordSettlements(for group: Group, transfers: [(from: Member, to: Member, amount: Decimal)]) {
        // Append new settlements (marked paid by default)
        for t in transfers {
            recordSettlement(for: group, from: t.from, to: t.to, amount: t.amount)
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

    // MARK: - Recurring Expenses
    func addRecurring(to group: Group, title: String, amount: Decimal, frequency: RecurrenceFrequency, nextDate: Date, payer: Member?, participants: [Member], category: ExpenseCategory? = nil, note: String? = nil) {
        let r = RecurringExpense(title: title, amount: amount, frequency: frequency, nextDate: nextDate, payer: payer, participants: participants, category: category, note: note)
        group.recurring.append(r)
        try? context.save()
    }

    func togglePause(_ r: RecurringExpense) {
        r.isPaused.toggle()
        try? context.save()
    }

    func deleteRecurring(_ r: RecurringExpense, from group: Group) {
        if let idx = group.recurring.firstIndex(where: { $0.persistentModelID == r.persistentModelID }) {
            group.recurring.remove(at: idx)
            try? context.save()
        }
    }

    func generateOnce(_ r: RecurringExpense, in group: Group) {
        let expense = Expense(title: r.title, amount: r.amount, currencyCode: group.defaultCurrency, payer: r.payer, participants: r.participants, category: r.category, note: r.note)
        group.expenses.append(expense)
        if let next = nextOccurrence(after: r.nextDate, frequency: r.frequency) { r.nextDate = next }
        try? context.save()
    }

    func generateDueRecurring(now: Date = .now) {
        let fetch = FetchDescriptor<Group>(predicate: #Predicate { _ in true })
        guard let groups = try? context.fetch(fetch) else { return }
        for g in groups { generateDueRecurring(in: g, now: now) }
    }

    func generateDueRecurring(in group: Group, now: Date = .now) {
        for r in group.recurring where !r.isPaused && r.nextDate <= now {
            generateOnce(r, in: group)
        }
    }

    private func nextOccurrence(after date: Date, frequency: RecurrenceFrequency) -> Date? {
        let cal = Calendar.current
        switch frequency {
        case .daily: return cal.date(byAdding: .day, value: 1, to: date)
        case .weekly: return cal.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly: return cal.date(byAdding: .month, value: 1, to: date)
        }
    }
}

// MARK: - Member Merge
extension DataRepository {
    /// Merges `from` member into `into` within the given group.
    /// - Reassigns payers/participants/shares/recurring/settlements to `into`.
    /// - Removes duplicate participant entries and combines share weights.
    /// - Removes settlements that would become self-payments.
    /// - Finally removes `from` from the group's members and deletes the model.
    func merge(member from: Member, into target: Member, in group: Group) {
        guard from.persistentModelID != target.persistentModelID else { return }

        // Expenses
        for e in group.expenses {
            if e.payer?.persistentModelID == from.persistentModelID {
                e.payer = target
            }
            if e.participants.contains(where: { $0.persistentModelID == from.persistentModelID }) {
                // Replace from with target, ensuring uniqueness
                var ids = Set(e.participants.map { $0.persistentModelID })
                ids.remove(from.persistentModelID)
                ids.insert(target.persistentModelID)
                // Rebuild participants preserving existing order where possible
                var newParticipants: [Member] = []
                for m in e.participants where m.persistentModelID != from.persistentModelID {
                    if !newParticipants.contains(where: { $0.persistentModelID == m.persistentModelID }) {
                        newParticipants.append(m)
                    }
                }
                if !newParticipants.contains(where: { $0.persistentModelID == target.persistentModelID }) {
                    newParticipants.append(target)
                }
                e.participants = newParticipants
            }
            // Shares: retarget and combine weights
            if !e.shares.isEmpty {
                var byID: [PersistentIdentifier: Int] = [:]
                for s in e.shares {
                    let id = (s.member.persistentModelID == from.persistentModelID) ? target.persistentModelID : s.member.persistentModelID
                    byID[id, default: 0] += s.weight
                }
                // Rebuild shares list using any available member instances
                var newShares: [ExpenseShare] = []
                for (id, weight) in byID {
                    // Find corresponding member instance
                    let m: Member?
                    if id == target.persistentModelID { m = target } else { m = e.participants.first { $0.persistentModelID == id } ?? group.members.first { $0.persistentModelID == id } }
                    if let m, weight > 0 { newShares.append(ExpenseShare(member: m, weight: weight)) }
                }
                e.shares = newShares
            }
            // Itemized items participants
            if !e.items.isEmpty {
                for item in e.items {
                    if item.participants.contains(where: { $0.persistentModelID == from.persistentModelID }) {
                        var newParts: [Member] = []
                        for m in item.participants where m.persistentModelID != from.persistentModelID {
                            if !newParts.contains(where: { $0.persistentModelID == m.persistentModelID }) { newParts.append(m) }
                        }
                        if !newParts.contains(where: { $0.persistentModelID == target.persistentModelID }) { newParts.append(target) }
                        item.participants = newParts
                    }
                }
            }
        }

        // Recurring
        for r in group.recurring {
            if r.payer?.persistentModelID == from.persistentModelID { r.payer = target }
            if r.participants.contains(where: { $0.persistentModelID == from.persistentModelID }) {
                var newParts: [Member] = []
                for m in r.participants where m.persistentModelID != from.persistentModelID {
                    if !newParts.contains(where: { $0.persistentModelID == m.persistentModelID }) { newParts.append(m) }
                }
                if !newParts.contains(where: { $0.persistentModelID == target.persistentModelID }) { newParts.append(target) }
                r.participants = newParts
            }
        }

        // Settlements
        group.settlements.removeAll { s in
            if s.from.persistentModelID == from.persistentModelID { s.from = target }
            if s.to.persistentModelID == from.persistentModelID { s.to = target }
            // Remove if self-payment
            return s.from.persistentModelID == s.to.persistentModelID
        }

        // Remove the old member
        if let idx = group.members.firstIndex(where: { $0.persistentModelID == from.persistentModelID }) {
            group.members.remove(at: idx)
        }
        context.delete(from)
        try? context.save()
        if let undo = undoManager {
            undo.setActionName("Merge Members")
        }
    }
}
