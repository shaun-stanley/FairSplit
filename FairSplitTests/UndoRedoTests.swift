import SwiftData
import Testing
@testable import FairSplit

struct UndoRedoTests {
    @Test
    func addExpense_thenUndo_removesIt() throws {
        let container = try ModelContainer(for: Group.self, Member.self, Expense.self, Settlement.self, Comment.self)
        let context = ModelContext(container)
        let undo = UndoManager()
        let repo = DataRepository(context: context, undoManager: undo)
        let a = Member(name: "Alex")
        let g = Group(name: "Trip", defaultCurrency: "USD", members: [a])
        context.insert(g)
        try context.save()

        repo.addExpense(to: g, title: "Water", amount: 2, payer: a, participants: [a])
        #expect(g.expenses.count == 1)
        undo.undo()
        #expect(g.expenses.isEmpty)
    }

    @Test
    func updateExpense_thenUndo_restoresFields() throws {
        let container = try ModelContainer(for: Group.self, Member.self, Expense.self, Settlement.self, Comment.self)
        let context = ModelContext(container)
        let undo = UndoManager()
        let repo = DataRepository(context: context, undoManager: undo)
        let a = Member(name: "Alex")
        let g = Group(name: "Trip", defaultCurrency: "USD", members: [a])
        let e = Expense(title: "Coffee", amount: 3, payer: a, participants: [a])
        g.expenses.append(e)
        context.insert(g)
        try context.save()

        repo.update(expense: e, in: g, title: "Latte", amount: 4, payer: a, participants: [a], category: nil, note: "test")
        #expect(e.title == "Latte")
        undo.undo()
        #expect(e.title == "Coffee")
    }

    @Test
    func deleteExpense_thenUndo_restoresIt() throws {
        let container = try ModelContainer(for: Group.self, Member.self, Expense.self, Settlement.self, Comment.self)
        let context = ModelContext(container)
        let undo = UndoManager()
        let repo = DataRepository(context: context, undoManager: undo)
        let a = Member(name: "Alex")
        let g = Group(name: "Trip", defaultCurrency: "USD", members: [a])
        let e = Expense(title: "Lunch", amount: 12, payer: a, participants: [a])
        g.expenses.append(e)
        context.insert(g)
        try context.save()

        repo.delete(expenses: [e], from: g)
        #expect(g.expenses.isEmpty)
        undo.undo()
        #expect(g.expenses.count == 1)
        #expect(g.expenses.first?.title == "Lunch")
    }

    @Test
    func recordSettlement_thenUndo_removesIt() throws {
        let container = try ModelContainer(for: Group.self, Member.self, Expense.self, Settlement.self, Comment.self)
        let context = ModelContext(container)
        let undo = UndoManager()
        let repo = DataRepository(context: context, undoManager: undo)
        let a = Member(name: "Alex")
        let b = Member(name: "Sam")
        let g = Group(name: "Trip", defaultCurrency: "USD", members: [a, b])
        context.insert(g)
        try context.save()

        repo.recordSettlements(for: g, transfers: [(from: a, to: b, amount: 5)])
        #expect(g.settlements.count == 1)
        undo.undo()
        #expect(g.settlements.isEmpty)
    }
}
