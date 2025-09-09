import SwiftUI
import SwiftData

struct PersonalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: [SortDescriptor(\PersonalExpense.date, order: .reverse)]) private var expenses: [PersonalExpense]
    @State private var showingAdd = false
    @State private var showingAccount = false
    @State private var editing: PersonalExpense?

    var body: some View {
        NavigationStack {
            List {
                if expenses.isEmpty == false {
                    Section("Recent") {
                        ForEach(expenses, id: \.persistentModelID) { e in
                            PersonalExpenseRow(expense: e) { editing = e } onDelete: {
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
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .contentMargins(.top, 4, for: .scrollContent)
            .navigationTitle("Personal")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingAccount = true } label: { Image(systemName: "person.crop.circle") }
                        .accessibilityLabel("Account")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add Expense")
                }
            }
            // Minimal, Apple-like empty state as an overlay (no big card)
            .overlay(alignment: .top) {
                VStack {
                    if expenses.isEmpty {
                        ContentUnavailableView {
                        Label("No Personal Expenses", systemImage: "creditcard")
                        } description: {
                            Text("Add your own expenses to track and review.")
                        } actions: {
                            Button { showingAdd = true } label: { Label("Add Expense", systemImage: "plus") }
                        }
                    }
                    .padding(.top, 24)
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showingAccount) { AccountView() }
        .sheet(isPresented: $showingAdd) {
            AddPersonalExpenseView { title, amount, date, category, note in
                let e = PersonalExpense(title: title, amount: amount, date: date, category: category, note: note)
                if reduceMotion {
                    modelContext.insert(e)
                    try? modelContext.save()
                } else {
                    withAnimation(AppAnimations.spring) {
                        modelContext.insert(e)
                        try? modelContext.save()
                    }
                }
                Haptics.success()
            }
        }
        .sheet(item: $editing) { e in
            AddPersonalExpenseView(existing: e) { title, amount, date, category, note in
                if reduceMotion {
                    e.title = title
                    e.amount = amount
                    e.date = date
                    e.category = category
                    e.note = note
                    try? modelContext.save()
                } else {
                    withAnimation(AppAnimations.spring) {
                        e.title = title
                        e.amount = amount
                        e.date = date
                        e.category = category
                        e.note = note
                        try? modelContext.save()
                    }
                }
                Haptics.success()
            }
        }
    }
}

#Preview {
    PersonalView()
        .modelContainer(for: [Group.self, Member.self, Expense.self, Settlement.self, Comment.self, PersonalExpense.self], inMemory: true)
}

private struct PersonalExpenseRow: View {
    var expense: PersonalExpense
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        let amountString = CurrencyFormatter.string(from: expense.amount, currencyCode: expense.currencyCode)
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading) {
                Text(expense.title).font(.headline)
                Text("\(expense.date, style: .date)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(amountString)
                .fontWeight(.semibold)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .swipeActions {
            Button("Edit") { onEdit() }.tint(.blue)
            Button("Delete", role: .destructive) { onDelete() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onEdit() }
        .accessibilityAction(named: Text("Delete")) { onDelete() }
        .accessibilityLabel(Text("\(expense.title), \(amountString) on \(expense.date.formatted(date: .abbreviated, time: .omitted))."))
        .accessibilityHint(Text("Double-tap to edit. Use Actions to delete."))
    }
}

private struct AddPersonalExpenseView: View {
    var existing: PersonalExpense?
    var onSave: (_ title: String, _ amount: Decimal, _ date: Date, _ category: ExpenseCategory?, _ note: String?) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var amount: Double?
    @State private var date: Date
    @State private var category: ExpenseCategory?
    @State private var note: String

    init(existing: PersonalExpense? = nil, onSave: @escaping (_ title: String, _ amount: Decimal, _ date: Date, _ category: ExpenseCategory?, _ note: String?) -> Void) {
        self.existing = existing
        self.onSave = onSave
        _title = State(initialValue: existing?.title ?? "")
        _amount = State(initialValue: existing.map { Double(truncating: NSDecimalNumber(decimal: $0.amount)) })
        _date = State(initialValue: existing?.date ?? .now)
        _category = State(initialValue: existing?.category)
        _note = State(initialValue: existing?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Amount", value: $amount, format: .currency(code: Locale.current.currency?.identifier ?? "INR"))
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section("Category") {
                    Picker("Category", selection: Binding(get: {
                        category
                    }, set: { category = $0 })) {
                        Text("None").tag(nil as ExpenseCategory?)
                        ForEach(ExpenseCategory.allCases, id: \.self) { c in
                            Text(c.displayName).tag(c as ExpenseCategory?)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                Section("Notes") {
                    TextField("Note", text: $note)
                }
            }
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .navigationTitle(existing == nil ? "New Personal Expense" : "Edit Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).disabled(!canSave) }
            }
        }
    }

    private var canSave: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard let amount, amount > 0 else { return false }
        return true
    }

    private func save() {
        guard let amount else { return }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(title, Decimal(amount), date, category, trimmed.isEmpty ? nil : trimmed)
        dismiss()
    }
}
