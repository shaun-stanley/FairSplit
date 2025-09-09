import Foundation
import SwiftData

@Model
final class PersonalExpense {
    var title: String
    var amount: Decimal
    var currencyCode: String
    var date: Date
    var categoryRaw: String?
    var note: String?

    init(title: String,
         amount: Decimal,
         currencyCode: String = Locale.current.currency?.identifier ?? "INR",
         date: Date = .now,
         category: ExpenseCategory? = nil,
         note: String? = nil) {
        self.title = title
        self.amount = amount
        self.currencyCode = currencyCode
        self.date = date
        self.categoryRaw = category?.rawValue
        self.note = note
    }
}

extension PersonalExpense {
    var category: ExpenseCategory? {
        get { categoryRaw.flatMap { ExpenseCategory(rawValue: $0) } }
        set { categoryRaw = newValue?.rawValue }
    }
}

