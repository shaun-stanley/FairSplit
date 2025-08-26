import Foundation
import SwiftData

enum RecurrenceFrequency: String, CaseIterable, Codable, Identifiable {
    case daily, weekly, monthly
    var id: String { rawValue }
}

@Model
final class RecurringExpense {
    var title: String
    var amount: Decimal
    var frequency: RecurrenceFrequency
    var nextDate: Date
    var isPaused: Bool
    var payer: Member?
    var participants: [Member]
    var category: ExpenseCategory?
    var note: String?

    init(title: String, amount: Decimal, frequency: RecurrenceFrequency, nextDate: Date, isPaused: Bool = false, payer: Member?, participants: [Member], category: ExpenseCategory? = nil, note: String? = nil) {
        self.title = title
        self.amount = amount
        self.frequency = frequency
        self.nextDate = nextDate
        self.isPaused = isPaused
        self.payer = payer
        self.participants = participants
        self.category = category
        self.note = note
    }
}

