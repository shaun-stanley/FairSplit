import SwiftData
import Testing
@testable import FairSplit

struct SettlementPaidTests {
    @Test
    func recordSingleSettlement_marksPaidAndSavesReceipt() throws {
        let container = try ModelContainer(for: Group.self, Member.self, Expense.self, Settlement.self, Comment.self)
        let context = ModelContext(container)
        let repo = DataRepository(context: context)

        let alex = Member(name: "Alex")
        let sam = Member(name: "Sam")
        let group = Group(name: "Trip", defaultCurrency: "USD", members: [alex, sam])
        context.insert(group)
        try context.save()

        // Record with receipt
        let receipt = Data([0xAA, 0xBB, 0xCC])
        repo.recordSettlement(for: group, from: alex, to: sam, amount: 12.34, receiptImageData: receipt)

        #expect(group.settlements.count == 1)
        let s = group.settlements.first!
        #expect(s.isPaid == true)
        #expect(s.receiptImageData == receipt)

        // Record without receipt
        repo.recordSettlement(for: group, from: sam, to: alex, amount: 5)
        #expect(group.settlements.count == 2)
        let s2 = group.settlements.last!
        #expect(s2.isPaid == true)
        #expect(s2.receiptImageData == nil)
    }
}
