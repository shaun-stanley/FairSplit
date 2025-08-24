import SwiftData
import Testing
@testable import FairSplit

@MainActor
struct DataRepositoryTests {
    @Test
    func recordSettlements_savesEntries() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: [Group.self, Member.self, Expense.self, Settlement.self], configurations: config)
        let context = container.mainContext
        let repo = DataRepository(context: context)

        let a = Member(name: "A")
        let b = Member(name: "B")
        let group = Group(name: "Trip", defaultCurrency: "USD", members: [a, b])
        context.insert(group)
        try context.save()

        repo.recordSettlements(for: group, transfers: [(from: a, to: b, amount: 10)])

        #expect(group.settlements.count == 1)
        let s = group.settlements.first
        #expect(s?.from === a)
        #expect(s?.to === b)
        #expect(s?.amount == 10)
    }
}

