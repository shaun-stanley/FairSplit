import Testing
@testable import FairSplit

struct PDFExporterTests {
    @Test
    func summaryPDF_isNotEmpty() throws {
        let a = Member(name: "Alex")
        let b = Member(name: "Sam")
        let g = Group(name: "Trip", defaultCurrency: "INR", members: [a, b])
        g.expenses.append(Expense(title: "Snacks", amount: 50, currencyCode: "INR", payer: a, participants: [a, b]))
        let data = PDFExporter.summaryPDF(for: g)
        #expect(!data.isEmpty)
    }
}

