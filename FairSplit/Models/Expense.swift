import Foundation
import SwiftData
import SwiftUI

@Model
final class Expense {
    var title: String
    var amount: Decimal
    var payer: Member?
    var participants: [Member]
    @Relationship(deleteRule: .cascade) var shares: [ExpenseShare]
    var date: Date
    var category: ExpenseCategory?
    var note: String?
    @Attribute(.externalStorage) var receiptImageData: Data?

    init(title: String, amount: Decimal, payer: Member?, participants: [Member], shares: [ExpenseShare] = [], date: Date = .now, category: ExpenseCategory? = nil, note: String? = nil, receiptImageData: Data? = nil) {
        self.title = title
        self.amount = amount
        self.payer = payer
        self.participants = participants
        self.shares = shares
        self.date = date
        self.category = category
        self.note = note
        self.receiptImageData = receiptImageData
    }
}
