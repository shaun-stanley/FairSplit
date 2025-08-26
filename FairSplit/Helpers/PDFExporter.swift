import UIKit

enum PDFExporter {
    static func summaryPDF(for group: Group) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 @72dpi
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let data = renderer.pdfData { ctx in
            ctx.beginPage()

            let titleFont = UIFont.boldSystemFont(ofSize: 20)
            let bodyFont = UIFont.systemFont(ofSize: 12)

            var y: CGFloat = 32

            func draw(_ text: String, font: UIFont, indent: CGFloat = 0, spacing: CGFloat = 6) {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byWordWrapping
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .paragraphStyle: paragraph
                ]
                let maxWidth = pageRect.width - 32 - indent
                let rect = CGRect(x: 16 + indent, y: y, width: maxWidth, height: .greatestFiniteMagnitude)
                let height = (text as NSString).boundingRect(with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], attributes: attrs, context: nil).height
                (text as NSString).draw(in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: height), withAttributes: attrs)
                y += height + spacing
            }

            // Header
            draw(group.name, font: titleFont, spacing: 12)
            draw("Currency: \(group.defaultCurrency)", font: bodyFont)
            draw("Members: \(group.members.count)", font: bodyFont, spacing: 12)

            // Balances
            draw("Balances", font: UIFont.boldSystemFont(ofSize: 16), spacing: 8)
            let net = SplitCalculator.netBalances(expenses: group.expenses, members: group.members, settlements: group.settlements, defaultCurrency: group.defaultCurrency)
            for m in group.members {
                let amount = net[m.persistentModelID] ?? 0
                let str = CurrencyFormatter.string(from: amount, currencyCode: group.defaultCurrency)
                draw("• \(m.name): \(str)", font: bodyFont, indent: 8)
            }
            y += 8

            // Expenses
            if !group.expenses.isEmpty {
                draw("Expenses", font: UIFont.boldSystemFont(ofSize: 16), spacing: 8)
                let df = DateFormatter(); df.dateStyle = .medium
                for e in group.expenses.sorted(by: { $0.date > $1.date }) {
                    let amt = CurrencyFormatter.string(from: SplitCalculator.amountInGroupCurrency(for: e, defaultCurrency: group.defaultCurrency), currencyCode: group.defaultCurrency)
                    let payer = e.payer?.name ?? "Unknown"
                    draw("• \(e.title) — \(amt) • Paid by \(payer) • \(df.string(from: e.date))", font: bodyFont, indent: 8)
                    if let note = e.note, !note.isEmpty {
                        draw(note, font: bodyFont, indent: 20)
                    }
                }
                y += 8
            }

            // Settlements
            if !group.settlements.isEmpty {
                draw("Settlement History", font: UIFont.boldSystemFont(ofSize: 16), spacing: 8)
                let df = DateFormatter(); df.dateStyle = .medium
                for s in group.settlements.sorted(by: { $0.date > $1.date }) {
                    let amt = CurrencyFormatter.string(from: s.amount, currencyCode: group.defaultCurrency)
                    draw("• \(s.from.name) → \(s.to.name): \(amt) on \(df.string(from: s.date))", font: bodyFont, indent: 8)
                }
            }
        }
        return data
    }
}

