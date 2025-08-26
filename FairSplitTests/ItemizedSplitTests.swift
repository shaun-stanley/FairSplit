import SwiftData
import Testing
@testable import FairSplit

struct ItemizedSplitTests {
    @Test
    func itemizedSplit_allocatesTaxProportionally() throws {
        let a = Member(name: "Alex")
        let b = Member(name: "Sam")
        let g = Group(name: "Trip", defaultCurrency: "USD", members: [a, b])
        let exp = Expense(title: "Dinner", amount: 0, currencyCode: "USD", payer: a, participants: [a, b])
        exp.items.append(ItemizedItem(title: "Burger", amount: 10, participants: [a]))
        exp.items.append(ItemizedItem(title: "Pasta", amount: 30, participants: [a, b]))
        exp.tax = 6
        exp.tip = 0
        exp.taxTipAllocation = .proportional
        g.expenses.append(exp)

        let net = SplitCalculator.netBalances(expenses: [exp], members: [a, b], defaultCurrency: g.defaultCurrency)
        // Pre-tax: Alex owes 25, Sam owes 15. Tax 6 => Alex 3.75, Sam 2.25
        // So totals: Alex 28.75, Sam 17.25. Payer is Alex so Alex credited total amount 46
        // Net: Alex +46 - 28.75 = 17.25 ; Sam -17.25
        #expect(net[a.persistentModelID] == Decimal(string: "17.25"))
        #expect(net[b.persistentModelID] == Decimal(string: "-17.25"))
    }

    @Test
    func itemizedSplit_allocatesEvenlyWhenChosen() throws {
        let a = Member(name: "Alex")
        let b = Member(name: "Sam")
        let g = Group(name: "Trip", defaultCurrency: "USD", members: [a, b])
        let exp = Expense(title: "Groceries", amount: 0, currencyCode: "USD", payer: a, participants: [a, b])
        exp.items.append(ItemizedItem(title: "Fruit", amount: 10, participants: [a]))
        exp.tax = 4
        exp.tip = 0
        exp.taxTipAllocation = .even
        g.expenses.append(exp)

        let net = SplitCalculator.netBalances(expenses: [exp], members: [a, b], defaultCurrency: g.defaultCurrency)
        // Pre-tax: Alex 10, Sam 0; tax even split => +2 each; totals Alex 12, Sam 2; payer Alex credited 14
        // Net: Alex +14 - 12 = 2 ; Sam -2
        #expect(net[a.persistentModelID] == Decimal(string: "2.00"))
        #expect(net[b.persistentModelID] == Decimal(string: "-2.00"))
    }
}

