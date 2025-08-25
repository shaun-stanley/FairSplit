import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    var group: Group
    @State private var showingAdd = false
    @State private var editingExpense: Expense?
    @State private var searchText = ""
    @State private var minAmount: Double?
    @State private var maxAmount: Double?
    @State private var selectedMemberIDs: Set<PersistentIdentifier> = []
    @State private var showingAmountFilter = false

    var body: some View {
        List {
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
                    Text(CurrencyFormatter.string(from: SplitCalculator.amountInGroupCurrency(for: expense, defaultCurrency: group.defaultCurrency), currencyCode: group.defaultCurrency))
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
            .onDelete(perform: delete)
        }
        .navigationTitle("Expenses")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { EditButton() }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Section("Members") {
                        ForEach(group.members, id: \.persistentModelID) { m in
                            Button { toggleMember(m) } label: {
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
                } label: { Image(systemName: "line.3.horizontal.decrease.circle") }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add Expense")
            }
        }
        .searchable(text: $searchText, prompt: "Search expenses")
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                AddExpenseView(members: group.members, groupCurrencyCode: group.defaultCurrency) { title, amount, currency, rate, payer, included, category, note, receipt in
                    DataRepository(context: modelContext, undoManager: undoManager).addExpense(to: group, title: title, amount: amount, payer: payer, participants: included, category: category, note: note, receiptImageData: receipt, currencyCode: currency, fxRateToGroupCurrency: rate)
                }
            }
        }
        .sheet(item: $editingExpense) { expense in
            NavigationStack {
                AddExpenseView(members: group.members, groupCurrencyCode: group.defaultCurrency, expense: expense) { title, amount, currency, rate, payer, included, category, note, receipt in
                    DataRepository(context: modelContext, undoManager: undoManager).update(expense: expense, title: title, amount: amount, payer: payer, participants: included, category: category, note: note, receiptImageData: receipt, currencyCode: currency, fxRateToGroupCurrency: rate)
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

    private func delete(at offsets: IndexSet) {
        let toDelete = offsets.map { group.expenses[$0] }
        DataRepository(context: modelContext, undoManager: undoManager).delete(expenses: toDelete, from: group)
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
    // Static preview; not persisted
    let g = Group(name: "Preview", defaultCurrency: "USD", members: [Member(name: "Alex")], expenses: [])
    return NavigationStack { ExpenseListView(group: g) }
}
