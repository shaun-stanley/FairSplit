import SwiftUI
import SwiftData

struct GroupDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let group: Group
    @State private var showingAddExpense = false
    @State private var editingExpense: Expense?

    private var settlementProposals: [(from: Member, to: Member, amount: Decimal)] {
        SplitCalculator.balances(for: group)
    }

    var body: some View {
        List {
            Section("Expenses") {
                ForEach(group.expenses, id: \.persistentModelID) { expense in
                    HStack {
                        if let data = expense.receiptImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipped()
                                .cornerRadius(6)
                        }
                        VStack(alignment: .leading) {
                            Text(expense.title).font(.headline)
                            if let category = expense.category {
                                Text(category.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            if let note = expense.note, !note.isEmpty {
                                Text(note)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
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
                    .swipeActions {
                        Button("Edit") { editingExpense = expense }.tint(.blue)
                        Button("Delete", role: .destructive) {
                            DataRepository(context: modelContext).delete(expenses: [expense])
                        }
                    }
                    .contextMenu {
                        Button("Edit") { editingExpense = expense }
                        Button("Delete", role: .destructive) {
                            DataRepository(context: modelContext).delete(expenses: [expense])
                        }
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
                NavigationLink(destination: MembersView(group: group)) {
                    HStack {
                        Text("Members")
                        Spacer()
                        Text("\(group.members.count)").foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(group.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { showingAddExpense = true } label: { Image(systemName: "plus") }
                NavigationLink("Settle Up") { SettleUpView(group: group) }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            NavigationStack {
                AddExpenseView(members: group.members, currencyCode: group.defaultCurrency) { title, amount, payer, participants, category, note, receipt in
                    DataRepository(context: modelContext).addExpense(to: group, title: title, amount: amount, payer: payer, participants: participants, category: category, note: note, receiptImageData: receipt)
                }
            }
        }
        .sheet(item: $editingExpense) { expense in
            NavigationStack {
                AddExpenseView(members: group.members, currencyCode: group.defaultCurrency, expense: expense) { title, amount, payer, participants, category, note, receipt in
                    DataRepository(context: modelContext).update(expense: expense, title: title, amount: amount, payer: payer, participants: participants, category: category, note: note, receiptImageData: receipt)
                }
            }
        }
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
