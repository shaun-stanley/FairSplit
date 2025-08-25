import SwiftData
import Testing
@testable import FairSplit

struct SeedDataTests {
    @Test
    func seedIfNeeded_createsSampleGroupWithLocaleCurrency() throws {
        let container = try ModelContainer(for: Group.self, Member.self, Expense.self, Settlement.self)
        let context = ModelContext(container)
        let repo = DataRepository(context: context)
        repo.seedIfNeeded()
        let fetch = FetchDescriptor<Group>()
        let groups = try context.fetch(fetch)
        #expect(groups.count == 1)
        #expect(groups.first?.defaultCurrency == Locale.current.currency?.identifier ?? "USD")
    }
}
