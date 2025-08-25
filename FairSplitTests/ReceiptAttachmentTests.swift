import SwiftData
import Testing
@testable import FairSplit

struct ReceiptAttachmentTests {
    @Test
    func addExpense_savesReceiptImageData() throws {
        let container = try ModelContainer(for: Group.self, Member.self, Expense.self)
        let context = ModelContext(container)
        let repo = DataRepository(context: context)
        let alex = Member(name: "Alex")
        let group = Group(name: "Trip", defaultCurrency: "USD", members: [alex])
        context.insert(group)
        try context.save()

        let receipt = Data([0x01, 0x02, 0x03])
        repo.addExpense(to: group, title: "Taxi", amount: 15, payer: alex, participants: [alex], category: .travel, note: "Airport ride", receiptImageData: receipt)

        let expense = group.expenses.first
        #expect(expense?.receiptImageData == receipt)
    }

    @Test
    func updateExpense_updatesReceiptImageData() throws {
        let container = try ModelContainer(for: Group.self, Member.self, Expense.self)
        let context = ModelContext(container)
        let repo = DataRepository(context: context)
        let alex = Member(name: "Alex")
        let group = Group(name: "Trip", defaultCurrency: "USD", members: [alex])
        let e = Expense(title: "Lunch", amount: 10, payer: alex, participants: [alex])
        group.expenses.append(e)
        context.insert(group)
        try context.save()

        let newReceipt = Data([0x0A, 0x0B])
        repo.update(expense: e, title: "Lunch", amount: 10, payer: alex, participants: [alex], category: nil, note: nil, receiptImageData: newReceipt)

        #expect(e.receiptImageData == newReceipt)
    }
}

