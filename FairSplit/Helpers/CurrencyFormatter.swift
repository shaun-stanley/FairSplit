import Foundation

enum CurrencyFormatter {
    static func string(from decimal: Decimal, currencyCode: String? = nil) -> String {
        let number = NSDecimalNumber(decimal: decimal)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        if let code = currencyCode ?? Locale.current.currency?.identifier {
            formatter.currencyCode = code
            // Apply Indian numbering system grouping when formatting INR
            if code.uppercased() == "INR" {
                formatter.usesGroupingSeparator = true
                formatter.groupingSize = 3
                formatter.secondaryGroupingSize = 2
            }
        }
        return formatter.string(from: number) ?? "\(number)"
    }
}
