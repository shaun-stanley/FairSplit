import Foundation
import SwiftData

@Model
final class Settlement {
    var from: Member
    var to: Member
    var amount: Decimal
    var date: Date
    var isPaid: Bool
    var receiptImageData: Data?

    init(from: Member, to: Member, amount: Decimal, date: Date = .now, isPaid: Bool = true, receiptImageData: Data? = nil) {
        self.from = from
        self.to = to
        self.amount = amount
        self.date = date
        self.isPaid = isPaid
        self.receiptImageData = receiptImageData
    }
}
