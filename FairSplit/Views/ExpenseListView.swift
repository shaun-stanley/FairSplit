import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    var group: Group
    @State private var showingAdd = false
    @State private var editingExpense: Expense?

    var body: some View {
        List {
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
            .onDelete(perform: delete)
        }
        .navigationTitle("Expenses")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { EditButton() }
            ToolbarItem(placement: .primaryAction) {
                Button("Add Expense") { showingAdd = true }
            }
        }
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                AddExpenseView(members: group.members, currencyCode: group.defaultCurrency) { title, amount, payer, included, category, note, receipt in
                    DataRepository(context: modelContext).addExpense(to: group, title: title, amount: amount, payer: payer, participants: included, category: category, note: note, receiptImageData: receipt)
                }
            }
        }
        .sheet(item: $editingExpense) { expense in
            NavigationStack {
                AddExpenseView(members: group.members, currencyCode: group.defaultCurrency, expense: expense) { title, amount, payer, included, category, note, receipt in
                    DataRepository(context: modelContext).update(expense: expense, title: title, amount: amount, payer: payer, participants: included, category: category, note: note, receiptImageData: receipt)
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        let toDelete = offsets.map { group.expenses[$0] }
        DataRepository(context: modelContext).delete(expenses: toDelete)
    }
}

#Preview {
    // Static preview; not persisted
    let g = Group(name: "Preview", defaultCurrency: "USD", members: [Member(name: "Alex")], expenses: [])
    return NavigationStack { ExpenseListView(group: g) }
}
