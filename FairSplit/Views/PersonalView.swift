import SwiftUI
import SwiftData

struct PersonalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: [SortDescriptor(\PersonalExpense.date, order: .reverse)]) private var expenses: [PersonalExpense]
    @State private var showingAdd = false
    @State private var showingAccount = false
    @State private var editing: PersonalExpense?
    @State private var scope: MonthScope = .thisMonth
    @State private var selectedCategory: ExpenseCategory? = nil

    private var scopeFiltered: [PersonalExpense] {
        guard let range = scope.dateRange else { return expenses }
        return expenses.filter { range.contains($0.date) }
    }
    private var filteredExpenses: [PersonalExpense] {
        scopeFiltered.filter { exp in
            guard let cat = selectedCategory else { return true }
            return exp.category == cat
        }
    }
    private var categoryCounts: [(ExpenseCategory?, Int)] {
        var map: [ExpenseCategory: Int] = [:]
        for e in scopeFiltered { if let c = e.category { map[c, default: 0] += 1 } }
        // Build chips: All first with total count, then categories with non-zero count (or all if none yet)
        let total = scopeFiltered.count
        var chips: [(ExpenseCategory?, Int)] = [(nil, total)]
        let cats = ExpenseCategory.allCases
        let anyCounts = map.values.contains { $0 > 0 }
        for c in cats {
            let count = map[c, default: 0]
            if anyCounts {
                if count > 0 { chips.append((c, count)) }
            } else {
                chips.append((c, 0))
            }
        }
        return chips
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredExpenses.isEmpty {
                    Section {
                        emptyCard
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                    .listRowBackground(Color.clear)
                } else {
                    Section("Recent") {
                        ForEach(filteredExpenses, id: \.persistentModelID) { e in
                            PersonalExpenseCard(expense: e) { editing = e } onDelete: {
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
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .listRowBackground(Color.clear)
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
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add Expense")
                    Button { showingAccount = true } label: { Image(systemName: "person.crop.circle") }
                        .accessibilityLabel("Account")
                }
            }
            // Empty state shown inline as a card row to avoid overlay sizing issues
            .safeAreaInset(edge: .top, spacing: 0) {
                filtersBar
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

// MARK: - Filters UI
private extension PersonalView {
    // Precompute simple models to help the type-checker and keep ForEach stable.
    private var chipModels: [CategoryChipModel] {
        categoryCounts.map { pair in
            let cat = pair.0
            return CategoryChipModel(
                id: cat?.id ?? "all",
                category: cat,
                title: cat?.displayName ?? "All",
                systemImage: cat?.symbolName,
                count: pair.1
            )
        }
    }
    // A compact, delightful filter bar that sits under the large title.
    // Segmented month scope + gently rounded category chips, like Apple apps.
    @ViewBuilder var filtersBar: some View {
        VStack(spacing: 10) {
            Picker("Time", selection: $scope) {
                ForEach(MonthScope.allCases, id: \.self) { s in
                    Text(s.label).tag(s)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Time Filter")

            Divider().overlay(Color.primary.opacity(0.08)).padding(.horizontal, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(chipModels) { chip in
                        let isSelected = (selectedCategory?.id ?? "all") == (chip.category?.id ?? "all")
                        CategoryChip(
                            title: chip.title,
                            systemImage: chip.systemImage,
                            count: chip.count,
                            isSelected: isSelected
                        ) {
                            withAnimation(AppAnimations.spring) {
                                selectedCategory = chip.category
                            }
                            Haptics.light()
                        }
                        .accessibilityLabel(chip.title)
                    }

                    if scope != .all || selectedCategory != nil {
                        CategoryChip(title: "Clear", systemImage: "line.3.horizontal.decrease.circle", count: nil, isSelected: false) {
                            withAnimation(AppAnimations.spring) {
                                scope = .all
                                selectedCategory = nil
                            }
                            Haptics.selection()
                        }
                        .accessibilityLabel("Clear Filters")
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(Color.clear.ignoresSafeArea())
    }

    @ViewBuilder var emptyCard: some View {
        VStack(spacing: 12) {
            ContentUnavailableView {
                Label("No Personal Expenses", systemImage: "creditcard")
            } description: {
                Text("Add your own expenses to track and review.")
            } actions: {
                HStack(spacing: 16) {
                    Button { showingAdd = true } label: { Label("Add Expense", systemImage: "plus") }
                    if scope != .all || selectedCategory != nil {
                        Button(role: .none) {
                            scope = .all
                            selectedCategory = nil
                        } label: { Label("Clear Filters", systemImage: "line.3.horizontal.decrease.circle") }
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .frame(maxWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 20)
    }
}

// MARK: - Components
private struct CategoryChipModel: Identifiable, Equatable {
    var id: String
    var category: ExpenseCategory?
    var title: String
    var systemImage: String?
    var count: Int
}
private struct CategoryChip: View {
    var title: String
    var systemImage: String?
    var count: Int?
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let name = systemImage { Image(systemName: name) }
                Text(title)
                if let count, count > 0 { Text("\(count)").foregroundStyle(.secondary) }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.18) : Color(.tertiarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

enum MonthScope: String, CaseIterable {
    case thisMonth, lastMonth, all
    var label: String {
        switch self {
        case .thisMonth: return "This Month"
        case .lastMonth: return "Last Month"
        case .all: return "All"
        }
    }
    var dateRange: ClosedRange<Date>? {
        switch self {
        case .all: return nil
        case .thisMonth:
            return Self.range(for: Date())
        case .lastMonth:
            if let d = Calendar.current.date(byAdding: .month, value: -1, to: Date()) { return Self.range(for: d) }
            return nil
        }
    }
    private static func range(for date: Date) -> ClosedRange<Date>? {
        let cal = Calendar.current
        guard let start = cal.date(from: cal.dateComponents([.year, .month], from: date)),
              let endStart = cal.date(byAdding: DateComponents(month: 1, day: 0), to: start),
              let end = cal.date(byAdding: .second, value: -1, to: endStart) else { return nil }
        return start...end
    }
}

private struct PersonalExpenseCard: View {
    var expense: PersonalExpense
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        let amountString = CurrencyFormatter.string(from: expense.amount, currencyCode: expense.currencyCode)
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: expense.category?.symbolName ?? "creditcard")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(.headline)
                HStack(spacing: 6) {
                    if let cat = expense.category {
                        Text(cat.displayName)
                            .foregroundStyle(.secondary)
                    }
                    Text("\(expense.date, style: .date)")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
            Spacer(minLength: 12)
            Text(amountString)
                .fontWeight(.semibold)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
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
