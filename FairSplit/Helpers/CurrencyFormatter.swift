import Foundation

enum CurrencyFormatter {
    static func string(from decimal: Decimal, currencyCode: String? = nil) -> String {
        let number = NSDecimalNumber(decimal: decimal)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let current = Locale.current
        let code = (currencyCode ?? current.currency?.identifier)?.uppercased()
        if let code { formatter.currencyCode = code }

        // Adopt Indian numbering format when appropriate
        // Conditions:
        // - Currency is INR, or
        // - User’s region is India
        let isIndianCurrency = (code == "INR")
        let isIndianRegion = (current.region?.identifier == "IN") || current.identifier.contains("_IN")
        if isIndianCurrency || isIndianRegion {
            formatter.usesGroupingSeparator = true
            // Indian system: last 3 digits, then groups of 2
            formatter.groupingSize = 3
            formatter.secondaryGroupingSize = 2
        }
        return formatter.string(from: number) ?? "\(number)"
    }
}
