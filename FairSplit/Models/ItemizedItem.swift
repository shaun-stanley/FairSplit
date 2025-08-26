import Foundation
import SwiftData

@Model
final class ItemizedItem {
    var title: String
    var amount: Decimal
    var participants: [Member]

    init(title: String, amount: Decimal, participants: [Member]) {
        self.title = title
        self.amount = amount
        self.participants = participants
    }
}

