import Foundation
import Testing
@testable import FairSplit

struct SplitCalculatorTests {
    @Test
    func evenSplit_distributesRemainderCents() {
        let a = Member(name: "A")
        let b = Member(name: "B")
        let c = Member(name: "C")
        let shares = SplitCalculator.evenSplit(amount: 10.00, among: [a, b, c])
        // 1000 cents / 3 = 333 cents each, with remainder 1 cent -> first person gets 3.34
        #expect(shares[a.persistentModelID] == Decimal(string: "3.34"))
        #expect(shares[b.persistentModelID] == Decimal(string: "3.33"))
        #expect(shares[c.persistentModelID] == Decimal(string: "3.33"))
    }

    @Test
    func netBalances_creditsPayer_and_debitsParticipants() {
        let a = Member(name: "A")
        let b = Member(name: "B")
        let exp = Expense(title: "Lunch", amount: 12.00, payer: a, participants: [a, b])
        let net = SplitCalculator.netBalances(expenses: [exp], members: [a, b])
        // A paid 12, owes 6 => +6; B owes 6 => -6
        #expect(net[a.persistentModelID] == Decimal(string: "6.00"))
        #expect(net[b.persistentModelID] == Decimal(string: "-6.00"))
    }

    @Test
    func proposedTransfers_matchesDebtsToCredits() {
        let a = Member(name: "A")
        let b = Member(name: "B")
        let c = Member(name: "C")
        let net: [PersistentIdentifier: Decimal] = [
            a.persistentModelID: 5,
            b.persistentModelID: -3,
            c.persistentModelID: -2
        ]
        let transfers = SplitCalculator.proposedTransfers(netBalances: net, members: [a, b, c])
        #expect(transfers.count == 2)
        #expect(transfers[0].from == b)
        #expect(transfers[0].to == a)
        #expect(transfers[0].amount == 3)
        #expect(transfers[1].from == c)
        #expect(transfers[1].to == a)
        #expect(transfers[1].amount == 2)
    }
}
