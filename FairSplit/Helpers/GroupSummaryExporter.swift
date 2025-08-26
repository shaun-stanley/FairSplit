import Foundation

enum GroupSummaryExporter {
    static func markdown(for group: Group) -> String {
        var lines: [String] = []
        lines.append("# \(group.name)")
        lines.append("")
        lines.append("Currency: \(group.defaultCurrency)")
        lines.append("Members: \(group.members.count)")
        lines.append("")

        // Balances
        let net = SplitCalculator.netBalances(
            expenses: group.expenses,
            members: group.members,
            settlements: group.settlements,
            defaultCurrency: group.defaultCurrency
        )
        lines.append("## Balances")
        for m in group.members {
            let amount = net[m.persistentModelID] ?? 0
            let str = CurrencyFormatter.string(from: amount, currencyCode: group.defaultCurrency)
            lines.append("- \(m.name): \(str)")
        }
        lines.append("")

        // Expenses
        if !group.expenses.isEmpty {
            lines.append("## Expenses")
            let df = DateFormatter()
            df.dateStyle = .medium
            for e in group.expenses.sorted(by: { $0.date > $1.date }) {
                let amt = CurrencyFormatter.string(from: SplitCalculator.amountInGroupCurrency(for: e, defaultCurrency: group.defaultCurrency), currencyCode: group.defaultCurrency)
                let date = df.string(from: e.date)
                let payer = e.payer?.name ?? "Unknown"
                lines.append("- \(e.title) — \(amt) • Paid by \(payer) • \(date)")
                if let note = e.note, !note.isEmpty { lines.append("  \n  > \(note)") }
            }
            lines.append("")
        }

        // Settlements history (optional)
        if !group.settlements.isEmpty {
            lines.append("## Settlement History")
            let df = DateFormatter()
            df.dateStyle = .medium
            for s in group.settlements.sorted(by: { $0.date > $1.date }) {
                let amt = CurrencyFormatter.string(from: s.amount, currencyCode: group.defaultCurrency)
                lines.append("- \(s.from.name) → \(s.to.name): \(amt) on \(df.string(from: s.date))")
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }
}

