import SwiftData
import Testing
@testable import FairSplit

struct MergeMembersTests {
    @Test
    func merge_reassignsParticipantsAndPayer_andRemovesSelfSettlements() throws {
        let container = try ModelContainer(for: Group.self, Member.self, Expense.self, Settlement.self, RecurringExpense.self, ExpenseShare.self, ItemizedItem.self, Comment.self)
        let context = ModelContext(container)
        let repo = DataRepository(context: context)

        let a = Member(name: "Alex")
        let a2 = Member(name: "A. Smith")
        let b = Member(name: "Sam")
        let g = Group(name: "Trip", defaultCurrency: "USD", members: [a, a2, b])
        let e1 = Expense(title: "Lunch", amount: 10, currencyCode: "USD", payer: a, participants: [a, b])
        let e2 = Expense(title: "Taxi", amount: 20, currencyCode: "USD", payer: b, participants: [a2, b])
        e2.shares = [ExpenseShare(member: a2, weight: 1), ExpenseShare(member: b, weight: 1)]
        g.expenses.append(contentsOf: [e1, e2])
        g.settlements.append(Settlement(from: a2, to: a, amount: 5))
        context.insert(g)
        try context.save()

        repo.merge(member: a2, into: a, in: g)

        // a2 should be gone
        #expect(!g.members.contains(where: { $0.name == "A. Smith" }))
        // Participants should have no duplicates and include Alex
        #expect(e1.participants.contains(where: { $0.persistentModelID == a.persistentModelID }))
        #expect(e2.participants.contains(where: { $0.persistentModelID == a.persistentModelID }))
        // Shares for e2 should be combined under Alex and Sam
        #expect(e2.shares.count == 2)
        let alexShare = e2.shares.first { $0.member.persistentModelID == a.persistentModelID }
        #expect(alexShare?.weight == 1)
        // Settlement between the two Alex identities becomes self-payment and should be removed
        #expect(g.settlements.isEmpty)
    }
}
