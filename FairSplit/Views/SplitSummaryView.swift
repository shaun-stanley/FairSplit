import SwiftUI

struct SplitSummaryView: View {
    var group: Group
    @State private var revealed: Set<PersistentIdentifier> = []

    var body: some View {
        let balances = SplitCalculator.netBalances(expenses: group.expenses, members: group.members, settlements: group.settlements, defaultCurrency: group.defaultCurrency)
        List(group.members, id: \.persistentModelID) { m in
            let amount = balances[m.persistentModelID] ?? 0
            HStack(spacing: 8) {
                Text(m.name)
                Spacer(minLength: 8)
                let positive = amount >= 0
                Image(systemName: positive ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                    .foregroundStyle(positive ? .green : .red)
                    .accessibilityHidden(true)
                Text(positive ? "Owed" : "Owes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.string(from: amount, currencyCode: group.defaultCurrency))
                    .foregroundStyle(positive ? .green : .red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .scaleEffect(revealed.contains(m.persistentModelID) ? 1 : 0.98)
            .opacity(revealed.contains(m.persistentModelID) ? 1 : 0)
            .animation(AppAnimations.spring, value: revealed)
            .onAppear { revealed.insert(m.persistentModelID) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(m.name), \(amount >= 0 ? "is owed" : "owes") \(CurrencyFormatter.string(from: amount >= 0 ? amount : -amount, currencyCode: group.defaultCurrency))")
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
