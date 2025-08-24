import Foundation
import SwiftData

@Model
final class Settlement {
    var from: Member
    var to: Member
    var amount: Decimal
    var date: Date

    init(from: Member, to: Member, amount: Decimal, date: Date = .now) {
        self.from = from
        self.to = to
        self.amount = amount
        self.date = date
    }
}

