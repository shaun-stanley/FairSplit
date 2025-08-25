import SwiftUI
import SwiftData

struct GroupDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    let group: Group
    @State private var showingAddExpense = false
    @State private var editingExpense: Expense?
    @State private var searchText = ""
    @State private var minAmount: Double?
    @State private var maxAmount: Double?
    @State private var selectedMemberIDs: Set<PersistentIdentifier> = []
    @State private var showingAmountFilter = false

    private var settlementProposals: [(from: Member, to: Member, amount: Decimal)] {
        SplitCalculator.balances(for: group)
    }

    var body: some View {
        List {
            Section("Expenses") {
                ForEach(filteredExpenses, id: \.persistentModelID) { expense in
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
                            DataRepository(context: modelContext, undoManager: undoManager).delete(expenses: [expense], from: group)
                        }
                    }
                    .contextMenu {
                        Button("Edit") { editingExpense = expense }
                        Button("Delete", role: .destructive) {
                            DataRepository(context: modelContext, undoManager: undoManager).delete(expenses: [expense], from: group)
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
                Menu {
                    Section("Members") {
                        ForEach(group.members, id: \.persistentModelID) { m in
                            Button {
                                toggleMember(m)
                            } label: {
                                HStack {
                                    Text(m.name)
                                    if selectedMemberIDs.contains(m.persistentModelID) { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    }
                    Section("Amount") {
                        Button("Amount Range…") { showingAmountFilter = true }
                        if minAmount != nil || maxAmount != nil || !selectedMemberIDs.isEmpty || !searchText.isEmpty {
                            Button("Clear Filters", role: .destructive) { clearFilters() }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
            
        }
        .searchable(text: $searchText, prompt: "Search expenses")
        .sheet(isPresented: $showingAddExpense) {
            NavigationStack {
                AddExpenseView(members: group.members, currencyCode: group.defaultCurrency) { title, amount, payer, participants, category, note, receipt in
                    DataRepository(context: modelContext, undoManager: undoManager).addExpense(to: group, title: title, amount: amount, payer: payer, participants: participants, category: category, note: note, receiptImageData: receipt)
                }
            }
        }
        .sheet(item: $editingExpense) { expense in
            NavigationStack {
                AddExpenseView(members: group.members, currencyCode: group.defaultCurrency, expense: expense) { title, amount, payer, participants, category, note, receipt in
                    DataRepository(context: modelContext, undoManager: undoManager).update(expense: expense, title: title, amount: amount, payer: payer, participants: participants, category: category, note: note, receiptImageData: receipt)
                }
            }
        }
        .sheet(isPresented: $showingAmountFilter) {
            NavigationStack {
                Form {
                    Section("Amount Range") {
                        TextField("Min", value: $minAmount, format: .number)
                            .keyboardType(.decimalPad)
                        TextField("Max", value: $maxAmount, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
                .navigationTitle("Amount Filter")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAmountFilter = false } }
                    ToolbarItem(placement: .confirmationAction) { Button("Apply") { showingAmountFilter = false } }
                }
            }
        }
    }

    private var filteredExpenses: [Expense] {
        let query = ExpenseQuery(
            searchText: searchText,
            minAmount: minAmount.map { Decimal($0) },
            maxAmount: maxAmount.map { Decimal($0) },
            memberIDs: selectedMemberIDs
        )
        return ExpenseFilterHelper.filtered(expenses: group.expenses, query: query)
    }

    private func toggleMember(_ m: Member) {
        if selectedMemberIDs.contains(m.persistentModelID) {
            selectedMemberIDs.remove(m.persistentModelID)
        } else {
            selectedMemberIDs.insert(m.persistentModelID)
        }
    }

    private func clearFilters() {
        searchText = ""
        minAmount = nil
        maxAmount = nil
        selectedMemberIDs.removeAll()
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
