import Testing
@testable import FairSplit

struct StatsCalculatorTests {
    @Test
    func totalsByMember_evenSplit() throws {
        let a = Member(name: "Alex")
        let b = Member(name: "Sam")
        let g = Group(name: "Trip", defaultCurrency: "INR", members: [a, b])
        g.expenses.append(Expense(title: "Taxi", amount: 100, currencyCode: "INR", payer: a, participants: [a, b]))
        let totals = StatsCalculator.totalsByMember(for: g)
        let aTotal = totals[a.persistentModelID] ?? -1
        let bTotal = totals[b.persistentModelID] ?? -1
        #expect(aTotal == 50)
        #expect(bTotal == 50)
    }

    @Test
    func totalsByCategory_sumsByCategory() throws {
        let a = Member(name: "Alex")
        let g = Group(name: "Trip", defaultCurrency: "INR", members: [a])
        let e1 = Expense(title: "Lunch", amount: 60, currencyCode: "INR", payer: a, participants: [a], category: .food)
        let e2 = Expense(title: "Bus", amount: 40, currencyCode: "INR", payer: a, participants: [a], category: .travel)
        g.expenses.append(contentsOf: [e1, e2])
        let totals = StatsCalculator.totalsByCategory(for: g)
        #expect(totals[.food] == 60)
        #expect(totals[.travel] == 40)
    }
}

