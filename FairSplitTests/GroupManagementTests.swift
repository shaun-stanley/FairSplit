import SwiftData
import Testing
@testable import FairSplit

struct GroupManagementTests {
    @Test
    func addGroup_thenUndo_removesIt() throws {
        let container = try ModelContainer(for: Group.self, Member.self, Expense.self, Settlement.self)
        let context = ModelContext(container)
        let undo = UndoManager()
        let repo = DataRepository(context: context, undoManager: undo)
        repo.addGroup(name: "Trip", defaultCurrency: "USD")
        let fetch = FetchDescriptor<Group>()
        let groups = try context.fetch(fetch)
        #expect(groups.count == 1)
        undo.undo()
        let afterUndo = try context.fetch(fetch)
        #expect(afterUndo.isEmpty)
    }
}
