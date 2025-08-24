import SwiftUI
import SwiftData

struct GroupDetailView: View {
    let group: Group

    private var settlementProposals: [(from: Member, to: Member, amount: Decimal)] {
        SplitCalculator.balances(for: group)
    }

    var body: some View {
        List {
            Section("Expenses") {
                ForEach(group.expenses, id: \.persistentModelID) { expense in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(expense.title).font(.headline)
                            if let payer = expense.payer {
                                Text("Paid by \(payer.name)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(CurrencyFormatter.string(from: expense.amount, currencyCode: group.defaultCurrency))
                            .fontWeight(.semibold)
                    }
                }
            }

            Section("Balances") {
                let net = SplitCalculator.netBalances(expenses: group.expenses, members: group.members, settlements: group.settlements)
                ForEach(group.members, id: \.persistentModelID) { member in
                    let amount = net[member.persistentModelID] ?? 0
                    HStack {
                        Text(member.name)
                        Spacer()
                        Text(CurrencyFormatter.string(from: amount, currencyCode: group.defaultCurrency))
                            .foregroundStyle(amount >= 0 ? .green : .red)
                    }
                }
            }

            Section("Settle Up") {
                if settlementProposals.isEmpty {
                    ContentUnavailableView("You're all settled!", systemImage: "checkmark.seal")
                } else {
                    ForEach(Array(settlementProposals.enumerated()), id: \.offset) { _, item in
                        HStack {
                            Text(item.from.name)
                            Image(systemName: "arrow.right")
                                .foregroundStyle(.secondary)
                            Text(item.to.name)
                            Spacer()
                            Text(CurrencyFormatter.string(from: item.amount, currencyCode: group.defaultCurrency))
                                .fontWeight(.semibold)
                        }
                        .accessibilityLabel("\(item.from.name) pays \(item.to.name) \(CurrencyFormatter.string(from: item.amount, currencyCode: group.defaultCurrency))")
                    }
                }
            }

            Section("Members") {
                ForEach(group.members, id: \.persistentModelID) { member in
                    Text(member.name)
                }
            }
        }
        .navigationTitle(group.name)
    }
}

#Preview {
    if let container = try? ModelContainer(
        for: Group.self, Member.self, Expense.self, Settlement.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) {
        let member = Member(name: "A")
        let group = Group(name: "G", defaultCurrency: "USD", members: [member])
        return GroupDetailView(group: group).modelContainer(container)
    } else {
        return Text("Preview unavailable")
    }
}
