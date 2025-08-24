import SwiftData
import Testing
@testable import FairSplit

struct MemberManagementTests {
    @Test
    func deleteMember_preventRemovalWhenReferenced() throws {
        let container = try ModelContainer(for: Group.self, Member.self, Expense.self)
        let context = ModelContext(container)
        let repo = DataRepository(context: context)
        let alex = Member(name: "Alex")
        let sam = Member(name: "Sam")
        let group = Group(name: "Trip", defaultCurrency: "USD", members: [alex, sam])
        let expense = Expense(title: "Lunch", amount: 20, payer: alex, participants: [alex, sam])
        group.expenses.append(expense)
        context.insert(group)
        try context.save()
        let success = repo.delete(member: alex, from: group)
        #expect(success == false)
        #expect(group.members.contains(alex))
    }

    @Test
    func deleteMember_removesWhenUnused() throws {
        let container = try ModelContainer(for: Group.self, Member.self)
        let context = ModelContext(container)
        let repo = DataRepository(context: context)
        let alex = Member(name: "Alex")
        let group = Group(name: "Trip", defaultCurrency: "USD", members: [alex])
        context.insert(group)
        try context.save()
        let success = repo.delete(member: alex, from: group)
        #expect(success == true)
        #expect(!group.members.contains(alex))
    }
}
