import Testing
@testable import FairSplit

struct ShareSummaryTests {
    @Test
    func markdown_containsGroupNameAndBalances() throws {
        let a = Member(name: "Alex")
        let b = Member(name: "Sam")
        let g = Group(name: "Trip", defaultCurrency: "INR", members: [a, b])
        let e = Expense(title: "Taxi", amount: 100, currencyCode: "INR", payer: a, participants: [a, b])
        g.expenses.append(e)
        let md = GroupSummaryExporter.markdown(for: g)
        #expect(md.contains("# Trip"))
        #expect(md.contains("Alex"))
        #expect(md.contains("Sam"))
        #expect(md.contains("Expenses"))
        #expect(md.contains("Taxi"))
    }
}

