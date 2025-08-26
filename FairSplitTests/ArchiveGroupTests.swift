import SwiftData
import Testing
@testable import FairSplit

struct ArchiveGroupTests {
    @Test
    func archive_setsFlagsAndDates() throws {
        let container = try ModelContainer(for: Group.self, Member.self, Expense.self, Settlement.self, Comment.self)
        let context = ModelContext(container)
        let repo = DataRepository(context: context)
        let g = Group(name: "Trip", defaultCurrency: "USD")
        context.insert(g)
        try context.save()

        #expect(g.isArchived == false)
        #expect(g.archivedAt == nil)
        repo.setArchived(true, for: g)
        #expect(g.isArchived == true)
        #expect(g.archivedAt != nil)
        let archivedAt = g.archivedAt
        repo.setArchived(false, for: g)
        #expect(g.isArchived == false)
        #expect(g.archivedAt == nil || g.archivedAt != archivedAt)
    }
}
