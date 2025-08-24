import Foundation

enum CurrencyFormatter {
    static func string(from decimal: Decimal, currencyCode: String? = nil) -> String {
        let number = NSDecimalNumber(decimal: decimal)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        if let code = currencyCode ?? Locale.current.currency?.identifier {
            formatter.currencyCode = code
        }
        return formatter.string(from: number) ?? "\(number)"
    }
}

