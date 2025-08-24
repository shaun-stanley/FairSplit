import Foundation
import SwiftData

@Model
final class ExpenseShare {
    var member: Member
    var weight: Int

    init(member: Member, weight: Int) {
        self.member = member
        self.weight = weight
    }
}

