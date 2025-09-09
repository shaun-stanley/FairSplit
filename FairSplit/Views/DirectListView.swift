import SwiftUI
import SwiftData

struct DirectListView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                balancesSection
                recentSection
                contactsSection
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .navigationTitle("Direct")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showingAddExpense = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add Direct Expense")
                    Button { showingAddContact = true } label: { Image(systemName: "person.badge.plus") }
                        .accessibilityLabel("Add Contact")
                }
            }
            .toolbarTitleMenu {
                Button { showingAddExpense = true } label: { Label("Add Direct Expense", systemImage: "plus") }
                Button { showingAddContact = true } label: { Label("Add Contact", systemImage: "person.badge.plus") }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddDirectExpenseView(contacts: contacts) { title, amount, payer, other, note in
                let expense = DirectExpense(title: title, amount: amount, payer: payer, other: other, note: note)
                if reduceMotion {
                    modelContext.insert(expense)
                    try? modelContext.save()
                } else {
                    withAnimation(AppAnimations.spring) {
                        modelContext.insert(expense)
                        try? modelContext.save()
                    }
                }
                Haptics.success()
            }
        }
        .sheet(item: $editingExpense) { e in
            AddDirectExpenseView(contacts: contacts, existing: e) { title, amount, payer, other, note in
                if reduceMotion {
                    e.title = title
                    e.amount = amount
                    e.payer = payer
                    e.other = other
                    e.note = note
                    try? modelContext.save()
                } else {
                    withAnimation(AppAnimations.spring) {
                        e.title = title
                        e.amount = amount
                        e.payer = payer
                        e.other = other
                        e.note = note
                        try? modelContext.save()
                    }
                }
                Haptics.success()
            }
        }
        .sheet(isPresented: $showingAddContact) {
            NavigationStack {
                Form {
                    TextField("Name", text: $newContactName)
                }
                .contentMargins(.horizontal, 20, for: .scrollContent)
                .navigationTitle("New Contact")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddContact = false; newContactName = "" } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let trimmed = newContactName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            let c = Contact(name: trimmed)
                            if reduceMotion {
                                modelContext.insert(c)
                                try? modelContext.save()
                            } else {
                                withAnimation(AppAnimations.spring) {
                                    modelContext.insert(c)
                                    try? modelContext.save()
                                }
                            }
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
                    .contentMargins(.horizontal, 20, for: .scrollContent)
                    .navigationTitle("Rename Contact")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { renamingContact = nil } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmed.isEmpty else { return }
                                if reduceMotion {
                                    contact.name = trimmed
                                    try? modelContext.save()
                                } else {
                                    withAnimation(AppAnimations.spring) {
                                        contact.name = trimmed
                                        try? modelContext.save()
                                    }
                                }
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

// MARK: - Sections (extracted to keep type-checking fast)
extension DirectListView {
    @ViewBuilder private var balancesSection: some View {
        Section("Balances") {
            if pairs.isEmpty {
                // Keep in-section empty state minimal to avoid oversized cards.
                ContentUnavailableView("No direct expenses", systemImage: "arrow.left.arrow.right")
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
                            .font(.subheadline)
                            .foregroundStyle(color)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
            }
        }
    }

    @ViewBuilder private var recentSection: some View {
        // Avoid large empty card merging with Contacts
        if !expenses.isEmpty {
            Section("Recent") {
                ForEach(expenses, id: \.persistentModelID) { e in
                    DirectExpenseRow(expense: e) {
                        editingExpense = e
                    } onDelete: {
                        if reduceMotion {
                            modelContext.delete(e)
                            try? modelContext.save()
                        } else {
                            withAnimation(AppAnimations.spring) {
                                modelContext.delete(e)
                                try? modelContext.save()
                            }
                        }
                        Haptics.success()
                    }
                }
            }
        }
    }

    @ViewBuilder private var contactsSection: some View {
        Section("Contacts") {
            if contacts.isEmpty {
                // Minimal variant keeps the card compact per HIG
                ContentUnavailableView("No Contacts Yet", systemImage: "person.badge.plus")
            } else {
                ForEach(contacts, id: \.persistentModelID) { c in
                    ContactRow(name: c.name) {
                        renamingContact = c
                        renameText = c.name
                    } onDelete: {
                        let used = expenses.contains { $0.payer.persistentModelID == c.persistentModelID || $0.other.persistentModelID == c.persistentModelID }
                        if used {
                            alertMessage = "This contact has expenses and can’t be deleted."
                        } else {
                            withAnimation(AppAnimations.spring) {
                                modelContext.delete(c)
                                try? modelContext.save()
                            }
                            Haptics.success()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Rows
private struct DirectExpenseRow: View {
    var expense: DirectExpense
    var onEdit: () -> Void
    var onDelete: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading) {
                Text(expense.title).font(.headline)
                Text("Paid by \(expense.payer.name) • \(expense.date, style: .date)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(CurrencyFormatter.string(from: expense.amount, currencyCode: expense.currencyCode))
                .fontWeight(.semibold)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .swipeActions {
            Button("Edit") { onEdit() }.tint(.blue)
            Button("Delete", role: .destructive) { onDelete() }
        }
        .contextMenu {
            Button("Edit") { onEdit() }
            Button("Delete", role: .destructive) { onDelete() }
        }
    }
}

private struct ContactRow: View {
    var name: String
    var onRename: () -> Void
    var onDelete: () -> Void

    var body: some View {
        Text(name)
            .swipeActions {
                Button("Rename") { onRename() }.tint(.blue)
                Button("Delete", role: .destructive) { onDelete() }
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
            .contentMargins(.horizontal, 20, for: .scrollContent)
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
