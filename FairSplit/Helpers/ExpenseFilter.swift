import Foundation
import SwiftData

struct ExpenseQuery: Equatable {
    var searchText: String = ""
    var minAmount: Decimal?
    var maxAmount: Decimal?
    var memberIDs: Set<PersistentIdentifier> = []
}

enum ExpenseFilterHelper {
    static func filtered(expenses: [Expense], query: ExpenseQuery) -> [Expense] {
        let trimmed = query.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return expenses.filter { e in
            // Text match
            let matchesText: Bool = {
                guard !trimmed.isEmpty else { return true }
                if e.title.lowercased().contains(trimmed) { return true }
                if let note = e.note?.lowercased(), note.contains(trimmed) { return true }
                return false
            }()

            // Amount range
            let matchesAmount: Bool = {
                if let min = query.minAmount, e.amount < min { return false }
                if let max = query.maxAmount, e.amount > max { return false }
                return true
            }()

            // Member filter (payer or any participant matches)
            let matchesMembers: Bool = {
                guard !query.memberIDs.isEmpty else { return true }
                if let payer = e.payer, query.memberIDs.contains(payer.persistentModelID) { return true }
                return e.participants.contains { query.memberIDs.contains($0.persistentModelID) }
            }()

            return matchesText && matchesAmount && matchesMembers
        }
        .sorted { $0.date > $1.date }
    }
}

