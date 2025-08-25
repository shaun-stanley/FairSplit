import SwiftData
import Testing
@testable import FairSplit

struct ImportExportTests {
    @Test
    func exportGroup_hasExpenseRow() throws {
        let container = try ModelContainer(for: Group.self, Member.self, Expense.self, Settlement.self)
        let context = ModelContext(container)
        let repo = DataRepository(context: context)
        let a = Member(name: "Alex")
        let g = Group(name: "Trip", defaultCurrency: "USD", members: [a])
        context.insert(g)
        repo.addExpense(to: g, title: "Water", amount: 2, payer: a, participants: [a])
        let csv = repo.exportCSV(for: g)
        #expect(csv.contains("Water"))
    }

    @Test
    func importCSV_addsExpense() throws {
        let container = try ModelContainer(for: Group.self, Member.self, Expense.self, Settlement.self)
        let context = ModelContext(container)
        let repo = DataRepository(context: context)
        let a = Member(name: "Alex")
        let g = Group(name: "Trip", defaultCurrency: "USD", members: [a])
        context.insert(g)
        let csv = "Title,Amount,Currency,Payer,Participants,Category,Note\nWater,2,USD,Alex,Alex,,"
        repo.importExpenses(fromCSV: csv, into: g)
        #expect(g.expenses.count == 1)
        #expect(g.expenses.first?.title == "Water")
    }
}
