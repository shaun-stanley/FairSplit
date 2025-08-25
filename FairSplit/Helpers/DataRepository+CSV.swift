import Foundation

extension DataRepository {
    func exportCSV(for group: Group) -> String {
        var lines = ["Title,Amount,Currency,Payer,Participants,Category,Note"]
        for e in group.expenses {
            let title = e.title.replacingOccurrences(of: "\"", with: "\"\"")
            let amount = NSDecimalNumber(decimal: e.amount).stringValue
            let payer = e.payer?.name ?? ""
            let participants = e.participants.map { $0.name }.joined(separator: ";")
            let category = e.category?.rawValue ?? ""
            let note = (e.note ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            lines.append("\"\(title)\",\(amount),\(e.currencyCode),\"\(payer)\",\"\(participants)\",\"\(category)\",\"\(note)\"")
        }
        return lines.joined(separator: "\n")
    }

    func importExpenses(fromCSV csv: String, into group: Group) {
        let rows = csv.split(separator: "\n")
        guard rows.count > 1 else { return }
        for row in rows.dropFirst() {
            let cols = row.split(separator: ",", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
            guard cols.count >= 7 else { continue }
            let title = cols[0]
            let amount = Decimal(string: cols[1]) ?? 0
            let currency = cols[2]
            let payerName = cols[3]
            let participantNames = cols[4].split(separator: ";").map { String($0) }
            let category = ExpenseCategory(rawValue: cols[5])
            let note = cols[6].isEmpty ? nil : cols[6]
            let payer = group.members.first { $0.name == payerName }
            let participants = group.members.filter { participantNames.contains($0.name) }
            addExpense(to: group, title: title, amount: amount, payer: payer, participants: participants, category: category, note: note, currencyCode: currency)
        }
    }
}

