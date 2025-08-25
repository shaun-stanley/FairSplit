import SwiftData
import Testing
@testable import FairSplit

struct FxRateMemoryTests {
    @Test
    func addExpense_updatesLastRate() throws {
        let container = try ModelContainer(for: Group.self, Member.self, Expense.self, Settlement.self)
        let context = ModelContext(container)
        let repo = DataRepository(context: context)
        let alex = Member(name: "Alex")
        let group = Group(name: "Trip", defaultCurrency: "USD", members: [alex])
        context.insert(group)
        try context.save()

        repo.addExpense(to: group, title: "Coffee", amount: 3, payer: alex, participants: [alex], currencyCode: "EUR", fxRateToGroupCurrency: 1.1)

        #expect(group.lastFXRates["EUR"] == 1.1)
    }

    @Test
    func updateExpense_updatesLastRate() throws {
        let container = try ModelContainer(for: Group.self, Member.self, Expense.self, Settlement.self)
        let context = ModelContext(container)
        let repo = DataRepository(context: context)
        let alex = Member(name: "Alex")
        let group = Group(name: "Trip", defaultCurrency: "USD", members: [alex])
        let expense = Expense(title: "Coffee", amount: 3, currencyCode: "EUR", fxRateToGroupCurrency: 1.1, payer: alex, participants: [alex])
        group.expenses.append(expense)
        context.insert(group)
        try context.save()

        repo.update(expense: expense, in: group, title: "Coffee", amount: 3, payer: alex, participants: [alex], category: nil, note: nil, currencyCode: "EUR", fxRateToGroupCurrency: 1.2)

        #expect(group.lastFXRates["EUR"] == 1.2)
    }
}
