import Foundation
import Testing
@testable import FairSplit

struct GroupTests {
    @Test
    func lastActivity_usesMostRecentDate() {
        let m = Member(name: "A")
        let g = Group(name: "G", defaultCurrency: "USD", members: [m])
        let old = Expense(title: "Old", amount: 1, payer: m, participants: [m], date: .distantPast)
        let new = Expense(title: "New", amount: 1, payer: m, participants: [m], date: .distantFuture)
        g.expenses.append(old)
        g.expenses.append(new)
        #expect(g.lastActivity == .distantFuture)
    }
}
