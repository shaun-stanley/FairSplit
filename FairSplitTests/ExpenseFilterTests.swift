import SwiftData
import Testing
@testable import FairSplit

struct ExpenseFilterTests {
    @Test
    func filter_byText_matchesTitleOrNote() throws {
        let a = Member(name: "Alex")
        let e1 = Expense(title: "Coffee", amount: 3, payer: a, participants: [a], note: "Latte")
        let e2 = Expense(title: "Lunch", amount: 12, payer: a, participants: [a])
        let e3 = Expense(title: "Dinner", amount: 20, payer: a, participants: [a], note: "noodles")
        let q = ExpenseQuery(searchText: "nood", minAmount: nil, maxAmount: nil, memberIDs: [])
        let result = ExpenseFilterHelper.filtered(expenses: [e1, e2, e3], query: q)
        #expect(result.count == 1)
        #expect(result.first?.title == "Dinner")
    }

    @Test
    func filter_byAmountRange_limitsResults() throws {
        let a = Member(name: "Alex")
        let e1 = Expense(title: "A", amount: 5, payer: a, participants: [a])
        let e2 = Expense(title: "B", amount: 10, payer: a, participants: [a])
        let e3 = Expense(title: "C", amount: 15, payer: a, participants: [a])
        let q = ExpenseQuery(searchText: "", minAmount: 6, maxAmount: 12, memberIDs: [])
        let result = ExpenseFilterHelper.filtered(expenses: [e1, e2, e3], query: q)
        #expect(result.map { $0.title } == ["B"])
    }

    @Test
    func filter_byMembers_matchesPayerOrParticipants() throws {
        let a = Member(name: "Alex")
        let b = Member(name: "Sam")
        let e1 = Expense(title: "A", amount: 5, payer: a, participants: [a])
        let e2 = Expense(title: "B", amount: 10, payer: a, participants: [b])
        let e3 = Expense(title: "C", amount: 15, payer: b, participants: [a])
        let q = ExpenseQuery(searchText: "", minAmount: nil, maxAmount: nil, memberIDs: [b.persistentModelID])
        let result = ExpenseFilterHelper.filtered(expenses: [e1, e2, e3], query: q)
        #expect(result.map { $0.title }.sorted() == ["B", "C"]) // B has b as participant; C has b as payer
    }
}

