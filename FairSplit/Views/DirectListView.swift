import SwiftUI
import SwiftData

struct DirectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Contact.name)]) private var contacts: [Contact]
    @Query(sort: [SortDescriptor(\DirectExpense.date, order: .reverse)]) private var expenses: [DirectExpense]
    @State private var showingAddExpense = false
    @State private var editingExpense: DirectExpense?
    @State private var showingAddContact = false
    @State private var newContactName = ""
    @State private var renamingContact: Contact?
    @State private var renameText: String = ""
    @State private var alertMessage: String?

    private struct PairKey: Hashable { let a: PersistentIdentifier; let b: PersistentIdentifier;
        init(_ p: PersistentIdentifier, _ q: PersistentIdentifier) {
            if p.hashValue <= q.hashValue { a = p; b = q } else { a = q; b = p }
        }
    }
    private var pairs: [(Contact, Contact, Decimal)] {
        var set = Set<PairKey>()
        var results: [(Contact, Contact, Decimal)] = []
        for e in expenses {
            let a = e.payer
            let b = e.other
                        let key = PairKey(a.persistentModelID, b.persistentModelID)
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
                        .swipeActions {
                            Button("Edit") { editingExpense = e }.tint(.blue)
                            Button("Delete", role: .destructive) {
                                modelContext.delete(e)
                                try? modelContext.save()
                                Haptics.success()
                            }
                        }
                        .contextMenu {
                            Button("Edit") { editingExpense = e }
                            Button("Delete", role: .destructive) {
                                modelContext.delete(e)
                                try? modelContext.save()
                                Haptics.success()
                            }
                        }
                    }
                }

                Section("Contacts") {
                    ForEach(contacts, id: \.persistentModelID) { c in
                        Text(c.name)
                            .swipeActions {
                                Button("Rename") { renamingContact = c; renameText = c.name }.tint(.blue)
                                Button("Delete", role: .destructive) {
                                    let used = expenses.contains { $0.payer.persistentModelID == c.persistentModelID || $0.other.persistentModelID == c.persistentModelID }
                                    if used { alertMessage = "This contact has expenses and can’t be deleted." }
                                    else {
                                        modelContext.delete(c)
                                        try? modelContext.save()
                                        Haptics.success()
                                    }
                                }
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
            .sheet(item: $editingExpense) { e in
                AddDirectExpenseView(contacts: contacts, existing: e) { title, amount, payer, other, note in
                    e.title = title
                    e.amount = amount
                    e.payer = payer
                    e.other = other
                    e.note = note
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
            .sheet(item: $renamingContact) { contact in
                NavigationStack {
                    Form { TextField("Name", text: $renameText) }
                        .navigationTitle("Rename Contact")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { renamingContact = nil } }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Save") {
                                    let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !trimmed.isEmpty else { return }
                                    contact.name = trimmed
                                    try? modelContext.save()
                                    renamingContact = nil
                                    Haptics.success()
                                }.disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                }
            }
            .alert("Cannot Delete", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
                Button("OK", role: .cancel) { alertMessage = nil }
            } message: { Text(alertMessage ?? "") }
        }
    }
}

struct AddDirectExpenseView: View {
    var contacts: [Contact]
    var existing: DirectExpense?
    var onSave: (_ title: String, _ amount: Decimal, _ payer: Contact, _ other: Contact, _ note: String?) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var amount: Double?
    @State private var payer: Contact?
    @State private var other: Contact?
    @State private var note: String

    init(contacts: [Contact], existing: DirectExpense? = nil, onSave: @escaping (_ title: String, _ amount: Decimal, _ payer: Contact, _ other: Contact, _ note: String?) -> Void) {
        self.contacts = contacts
        self.existing = existing
        self.onSave = onSave
        _title = State(initialValue: existing?.title ?? "")
        _amount = State(initialValue: existing.map { Double(truncating: NSDecimalNumber(decimal: $0.amount)) })
        _payer = State(initialValue: existing?.payer)
        _other = State(initialValue: existing?.other)
        _note = State(initialValue: existing?.note ?? "")
    }

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
