import Foundation
import SwiftData

@Model
final class PersonalBudget {
    var categoryRaw: String
    var amount: Decimal
    var currencyCode: String
    var threshold: Decimal

    init(category: ExpenseCategory, amount: Decimal, currencyCode: String = Locale.current.currency?.identifier ?? "INR", threshold: Decimal? = nil) {
        self.categoryRaw = category.rawValue
        self.amount = amount
        self.currencyCode = currencyCode
        if let threshold {
            self.threshold = threshold
        } else {
            self.threshold = (amount * Decimal(85)) / Decimal(100)
        }
    }
}

extension PersonalBudget {
    var category: ExpenseCategory? {
        get { ExpenseCategory(rawValue: categoryRaw) }
        set { categoryRaw = newValue?.rawValue ?? categoryRaw }
    }
}
