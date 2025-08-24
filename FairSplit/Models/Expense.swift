import Foundation
import SwiftData

@Model
final class Expense {
    var title: String
    var amount: Decimal
    var payer: Member?
    var participants: [Member]
    var date: Date

    init(title: String, amount: Decimal, payer: Member?, participants: [Member], date: Date = .now) {
        self.title = title
        self.amount = amount
        self.payer = payer
        self.participants = participants
        self.date = date
    }
}

