import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    var group: Group
    @State private var showingAdd = false

    var body: some View {
        List {
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
                AddExpenseView(members: group.members, currencyCode: group.defaultCurrency) { title, amount, payer, included in
                    DataRepository(context: modelContext).addExpense(to: group, title: title, amount: amount, payer: payer, participants: included)
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
