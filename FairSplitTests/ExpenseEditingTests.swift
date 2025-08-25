import SwiftData
import Testing
@testable import FairSplit

struct ExpenseEditingTests {
    @Test
    func updateExpense_changesFields() throws {
        let container = try ModelContainer(for: Group.self, Member.self, Expense.self)
        let context = ModelContext(container)
        let repo = DataRepository(context: context)
        let alex = Member(name: "Alex")
        let sam = Member(name: "Sam")
        let group = Group(name: "Trip", defaultCurrency: "USD", members: [alex, sam])
        let expense = Expense(title: "Lunch", amount: 10, payer: alex, participants: [alex], category: .travel, note: "Shuttle")
        group.expenses.append(expense)
        context.insert(group)
        try context.save()

        repo.update(expense: expense, title: "Dinner", amount: 25, payer: sam, participants: [alex, sam], category: .food, note: "Tapas")

        #expect(expense.title == "Dinner")
        #expect(expense.amount == 25)
        #expect(expense.payer == sam)
        #expect(expense.participants.count == 2)
        #expect(expense.category == .food)
        #expect(expense.note == "Tapas")
    }

    @Test
    func deleteExpense_removesFromGroup() throws {
        let container = try ModelContainer(for: Group.self, Member.self, Expense.self)
        let context = ModelContext(container)
        let repo = DataRepository(context: context)
        let alex = Member(name: "Alex")
        let group = Group(name: "Trip", defaultCurrency: "USD", members: [alex])
        let expense = Expense(title: "Taxi", amount: 15, payer: alex, participants: [alex])
        group.expenses.append(expense)
        context.insert(group)
        try context.save()

        repo.delete(expenses: [expense], from: group)

        #expect(group.expenses.isEmpty)
}

    @Test
    func addExpense_savesCategoryAndNote() throws {
        let container = try ModelContainer(for: Group.self, Member.self, Expense.self)
        let context = ModelContext(container)
        let repo = DataRepository(context: context)
        let alex = Member(name: "Alex")
        let group = Group(name: "Trip", defaultCurrency: "USD", members: [alex])
        context.insert(group)
        try context.save()

        repo.addExpense(to: group, title: "Taxi", amount: 15, payer: alex, participants: [alex], category: .travel, note: "Airport ride")

        let expense = group.expenses.first
        #expect(expense?.category == .travel)
        #expect(expense?.note == "Airport ride")
    }
}
