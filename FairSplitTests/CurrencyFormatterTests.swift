import XCTest
@testable import FairSplit

final class CurrencyFormatterTests: XCTestCase {
    func test_inr_uses_indian_grouping() {
        let value: Decimal = 123456
        let s = CurrencyFormatter.string(from: value, currencyCode: "INR")
        XCTAssertTrue(s.contains("1,23,456"), "INR should use Indian grouping: got \(s)")
    }

    func test_usd_uses_western_grouping() {
        let value: Decimal = 123456
        let s = CurrencyFormatter.string(from: value, currencyCode: "USD")
        XCTAssertTrue(s.contains("123,456"), "USD should use western grouping: got \(s)")
    }
}

