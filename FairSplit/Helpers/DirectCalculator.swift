import Foundation

enum DirectCalculator {
    /// Computes net owed between two contacts based on direct expenses.
    /// Positive means `a` is owed by `b` that amount (equal split).
    static func netBetween(_ a: Contact, _ b: Contact, expenses: [DirectExpense]) -> Decimal {
        var net: Decimal = 0
        for e in expenses {
            let involvesPair = (e.payer.persistentModelID == a.persistentModelID && e.other.persistentModelID == b.persistentModelID) ||
                               (e.payer.persistentModelID == b.persistentModelID && e.other.persistentModelID == a.persistentModelID)
            guard involvesPair else { continue }
            let half = e.amount / 2
            if e.payer.persistentModelID == a.persistentModelID { net += half } else { net -= half }
        }
        return net
    }
}

