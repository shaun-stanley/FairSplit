import Foundation
import SwiftData

enum SplitCalculator {
    /// Evenly splits a given amount (in currency) among members, rounded to cents.
    /// Any leftover cents are distributed to the first `remainder` members.
    static func evenSplit(amount: Decimal, among members: [Member]) -> [PersistentIdentifier: Decimal] {
        guard !members.isEmpty else { return [:] }
        let centsTotal = (NSDecimalNumber(decimal: amount)
            .multiplying(by: 100)
            .rounding(accordingToBehavior: nil)).intValue

        let count = members.count
        let per = centsTotal / count
        var remainder = centsTotal % count

        var result: [PersistentIdentifier: Decimal] = [:]
        for m in members {
            var share = per
            if remainder > 0 {
                share += 1
                remainder -= 1
            }
            result[m.persistentModelID] = Decimal(share) / 100
        }
        return result
    }

    /// Splits a given amount among members using integer weight shares.
    /// Any leftover cents are distributed to members in the order of the shares array.
    static func weightedSplit(amount: Decimal, shares: [ExpenseShare]) -> [PersistentIdentifier: Decimal] {
        let totalWeight = shares.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return [:] }
        let centsTotal = (NSDecimalNumber(decimal: amount)
            .multiplying(by: 100)
            .rounding(accordingToBehavior: nil)).intValue

        var result: [PersistentIdentifier: Decimal] = [:]
        var allocated = 0
        for share in shares {
            let cents = centsTotal * share.weight / totalWeight
            allocated += cents
            result[share.member.persistentModelID] = Decimal(cents) / 100
        }
        var remainder = centsTotal - allocated
        for share in shares where remainder > 0 {
            let id = share.member.persistentModelID
            result[id, default: 0] += 0.01
            remainder -= 1
        }
        return result
    }

    /// Computes net balances per member: positive means they are owed, negative means they owe.
    static func netBalances(expenses: [Expense], members: [Member], settlements: [Settlement] = []) -> [PersistentIdentifier: Decimal] {
        var net: [PersistentIdentifier: Decimal] = Dictionary(uniqueKeysWithValues: members.map { ($0.persistentModelID, 0) })
        for expense in expenses {
            let split: [PersistentIdentifier: Decimal]
            if expense.shares.isEmpty {
                split = evenSplit(amount: expense.amount, among: expense.participants)
            } else {
                split = weightedSplit(amount: expense.amount, shares: expense.shares)
            }
            if let payer = expense.payer { net[payer.persistentModelID, default: 0] += expense.amount }
            for (memberID, owed) in split { net[memberID, default: 0] -= owed }
        }
        for s in settlements {
            net[s.from.persistentModelID, default: 0] += s.amount
            net[s.to.persistentModelID, default: 0] -= s.amount
        }
        return net
    }

    /// Suggests settlement transfers using a greedy algorithm on integer cents.
    /// Returns an array of (from, to, amount) tuples; amount rounded to cents.
    static func proposedTransfers(netBalances net: [PersistentIdentifier: Decimal], members: [Member]) -> [(from: Member, to: Member, amount: Decimal)] {
        var creditors: [(id: PersistentIdentifier, cents: Int)] = []
        var debtors: [(id: PersistentIdentifier, cents: Int)] = []

        for (id, value) in net {
            let cents = (NSDecimalNumber(decimal: value).multiplying(by: 100).rounding(accordingToBehavior: nil)).intValue
            if cents > 0 { creditors.append((id, cents)) }
            else if cents < 0 { debtors.append((id, -cents)) }
        }

        // Map IDs to members for quick lookup
        let map: [PersistentIdentifier: Member] = Dictionary(uniqueKeysWithValues: members.map { ($0.persistentModelID, $0) })

        // Greedy: largest creditors and debtors first
        creditors.sort { $0.cents > $1.cents }
        debtors.sort { $0.cents > $1.cents }

        var i = 0, j = 0
        var results: [(from: Member, to: Member, amount: Decimal)] = []
        while i < debtors.count && j < creditors.count {
            var debt = debtors[i].cents
            var credit = creditors[j].cents
            let pay = min(debt, credit)

            if pay > 0, let from = map[debtors[i].id], let to = map[creditors[j].id] {
                results.append((from: from, to: to, amount: Decimal(pay) / 100))
            }

            debt -= pay
            credit -= pay
            debtors[i].cents = debt
            creditors[j].cents = credit

            if debt == 0 { i += 1 }
            if credit == 0 { j += 1 }
        }
        return results
    }

    /// Convenience helper to compute greedy settlement transfers for a group.
    /// - Returns: Array of (from, to, amount) tuples; amounts rounded to cents.
    static func balances(for group: Group) -> [(from: Member, to: Member, amount: Decimal)] {
        let net = netBalances(expenses: group.expenses, members: group.members, settlements: group.settlements)
        return proposedTransfers(netBalances: net, members: group.members)
    }
}
