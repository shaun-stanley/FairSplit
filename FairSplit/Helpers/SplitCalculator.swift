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

    /// Computes net balances per member: positive means they are owed, negative means they owe.
    static func netBalances(expenses: [Expense], members: [Member]) -> [PersistentIdentifier: Decimal] {
        var net: [PersistentIdentifier: Decimal] = Dictionary(uniqueKeysWithValues: members.map { ($0.persistentModelID, 0) })
        for expense in expenses {
            let shares = evenSplit(amount: expense.amount, among: expense.participants)
            if let payer = expense.payer { net[payer.persistentModelID, default: 0] += expense.amount }
            for (memberID, owed) in shares { net[memberID, default: 0] -= owed }
        }
        return net
    }
}
