import SwiftUI

struct SplitSummaryView: View {
    var group: Group

    var body: some View {
        let balances = SplitCalculator.netBalances(expenses: group.expenses, members: group.members, settlements: group.settlements, defaultCurrency: group.defaultCurrency)
        List(group.members, id: \.persistentModelID) { m in
            let amount = balances[m.persistentModelID] ?? 0
            HStack {
                Text(m.name)
                Spacer()
                Text(CurrencyFormatter.string(from: amount, currencyCode: group.defaultCurrency))
                    .foregroundStyle(amount >= 0 ? .green : .red)
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .navigationTitle("Summary")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink("Settle Up") {
                    SettleUpView(group: group)
                }
            }
        }
    }
}

#Preview {
    let alex = Member(name: "Alex")
    let sam = Member(name: "Sam")
    let kai = Member(name: "Kai")
    let g = Group(name: "Preview", defaultCurrency: "USD", members: [alex, sam, kai], expenses: [])
    return NavigationStack { SplitSummaryView(group: g) }
}
