import Foundation
import SwiftData

@Model
final class DirectExpense {
    var title: String
    var amount: Decimal
    var currencyCode: String
    var payer: Contact
    var other: Contact
    var date: Date
    var note: String?

    init(title: String, amount: Decimal, currencyCode: String = Locale.current.currency?.identifier ?? "INR", payer: Contact, other: Contact, date: Date = .now, note: String? = nil) {
        self.title = title
        self.amount = amount
        self.currencyCode = currencyCode
        self.payer = payer
        self.other = other
        self.date = date
        self.note = note
    }
}

