import Foundation
import SwiftData
import SwiftUI

@Model
final class Expense {
    var title: String
    var amount: Decimal
    /// The currency in which `amount` is stored.
    var currencyCode: String
    /// Manual FX rate to convert `amount` into the group's default currency.
    /// When `currencyCode` equals the group's currency, this can be nil.
    var fxRateToGroupCurrency: Decimal?
    var payer: Member?
    var participants: [Member]
    @Relationship(deleteRule: .cascade) var shares: [ExpenseShare]
    var date: Date
    var category: ExpenseCategory?
    var note: String?
    @Attribute(.externalStorage) var receiptImageData: Data?

    init(title: String, amount: Decimal, currencyCode: String = Locale.current.currency?.identifier ?? "USD", fxRateToGroupCurrency: Decimal? = nil, payer: Member?, participants: [Member], shares: [ExpenseShare] = [], date: Date = .now, category: ExpenseCategory? = nil, note: String? = nil, receiptImageData: Data? = nil) {
        self.title = title
        self.amount = amount
        self.currencyCode = currencyCode
        self.fxRateToGroupCurrency = fxRateToGroupCurrency
        self.payer = payer
        self.participants = participants
        self.shares = shares
        self.date = date
        self.category = category
        self.note = note
        self.receiptImageData = receiptImageData
    }
}
