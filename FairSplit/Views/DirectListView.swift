import SwiftUI
import SwiftData

struct DirectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Contact.name)]) private var contacts: [Contact]
    @Query(sort: [SortDescriptor(\DirectExpense.date, order: .reverse)]) private var expenses: [DirectExpense]
    @State private var showingAddExpense = false
    @State private var showingAddContact = false
    @State private var newContactName = ""

    private var pairs: [(Contact, Contact, Decimal)] {
        var set = Set<String>()
        var results: [(Contact, Contact, Decimal)] = []
        for e in expenses {
            let a = e.payer
            let b = e.other
            let key = a.persistentModelID.uuidString < b.persistentModelID.uuidString ? "\(a.persistentModelID.uuidString)_\(b.persistentModelID.uuidString)" : "\(b.persistentModelID.uuidString)_\(a.persistentModelID.uuidString)"
            if !set.contains(key) {
                set.insert(key)
                let net = DirectCalculator.netBetween(a, b, expenses: expenses)
                results.append((a, b, net))
            }
        }
        return results.sorted { $0.0.name < $1.0.name }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Balances") {
                    if pairs.isEmpty {
                        ContentUnavailableView("No direct expenses", systemImage: "person.fill.and.arrow.right")
                    } else {
                        ForEach(0..<pairs.count, id: \.self) { i in
                            let (a, b, net) = pairs[i]
                            HStack(spacing: 6) {
                                Text("\(a.name) ↔ \(b.name)")
                                Spacer()
                                let amount = abs(net)
                                let owes = net > 0 ? b.name : a.name
                                let color: Color = net == 0 ? .secondary : (net > 0 ? .red : .green)
                                Text(net == 0 ? "Settled" : "\(owes) owes \(CurrencyFormatter.string(from: amount))")
                                    .foregroundStyle(color)
                            }
                        }
                    }
                }

                Section("Recent") {
                    ForEach(expenses, id: \.persistentModelID) { e in
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading) {
                                Text(e.title).font(.headline)
                                Text("Paid by \(e.payer.name) • \(e.date, style: .date)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(CurrencyFormatter.string(from: e.amount, currencyCode: e.currencyCode))
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .navigationTitle("Direct")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button { showingAddExpense = true } label: { Image(systemName: "plus") }
                    Button { showingAddContact = true } label: { Image(systemName: "person.badge.plus") }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddDirectExpenseView(contacts: contacts) { title, amount, payer, other, note in
                    let expense = DirectExpense(title: title, amount: amount, payer: payer, other: other, note: note)
                    modelContext.insert(expense)
                    try? modelContext.save()
                    Haptics.success()
                }
            }
            .sheet(isPresented: $showingAddContact) {
                NavigationStack {
                    Form {
                        TextField("Name", text: $newContactName)
                    }
                    .navigationTitle("New Contact")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddContact = false; newContactName = "" } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                let trimmed = newContactName.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmed.isEmpty else { return }
                                let c = Contact(name: trimmed)
                                modelContext.insert(c)
                                try? modelContext.save()
                                newContactName = ""
                                showingAddContact = false
                                Haptics.success()
                            }.disabled(newContactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
        }
    }
}

struct AddDirectExpenseView: View {
    var contacts: [Contact]
    var onSave: (_ title: String, _ amount: Decimal, _ payer: Contact, _ other: Contact, _ note: String?) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var amount: Double?
    @State private var payer: Contact?
    @State private var other: Contact?
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Amount", value: $amount, format: .currency(code: Locale.current.currency?.identifier ?? "INR"))
                        .keyboardType(.decimalPad)
                }
                Section("People") {
                    Picker("Payer", selection: $payer) {
                        ForEach(contacts) { c in Text(c.name).tag(c as Contact?) }
                    }
                    Picker("Other", selection: $other) {
                        ForEach(contacts) { c in Text(c.name).tag(c as Contact?) }
                    }
                }
                Section("Notes") {
                    TextField("Note", text: $note)
                }
            }
            .navigationTitle("New Direct Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).disabled(!canSave) }
            }
        }
    }

    private var canSave: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard let amount, amount > 0 else { return false }
        return payer != nil && other != nil && payer?.persistentModelID != other?.persistentModelID
    }

    private func save() {
        guard let amount, let payer, let other else { return }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(title, Decimal(amount), payer, other, trimmed.isEmpty ? nil : trimmed)
        dismiss()
    }
}

