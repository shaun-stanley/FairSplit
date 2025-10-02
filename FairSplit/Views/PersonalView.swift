import SwiftUI
import SwiftData

struct PersonalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: [SortDescriptor(\PersonalExpense.date, order: .reverse)]) private var expenses: [PersonalExpense]
    @State private var showingAdd = false
    @State private var showingAccount = false
    @State private var editing: PersonalExpense?

    // Focus the screen on an elegant summary of "This Month".
    private var thisMonthRange: ClosedRange<Date>? { MonthScope.thisMonth.dateRange }
    private var thisMonthExpenses: [PersonalExpense] {
        guard let range = thisMonthRange else { return [] }
        return expenses.filter { range.contains($0.date) }
    }
    private var monthTotal: Decimal { thisMonthExpenses.reduce(0) { $0 + $1.amount } }

    var body: some View {
        NavigationStack {
            List {
                if thisMonthExpenses.isEmpty {
                    Section {
                        emptyState
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 12, trailing: 0))
                    .listRowBackground(Color.clear)
                } else {
                    Section("Recent") {
                        ForEach(thisMonthExpenses, id: \.persistentModelID) { e in
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
            // Elegant hero summary header
            .safeAreaInset(edge: .top, spacing: 0) { headerSummary }
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

// MARK: - Summary
private extension PersonalView {
    private var periodLabel: String { "This Month" }
    private var periodExpenses: [PersonalExpense] { thisMonthExpenses }
    private var periodTotal: Decimal { monthTotal }
    private var topCategories: [(ExpenseCategory, Decimal)] {
        var map: [ExpenseCategory: Decimal] = [:]
        for e in periodExpenses { if let c = e.category { map[c, default: 0] += e.amount } }
        return ExpenseCategory.allCases.compactMap { c in
            if let v = map[c], v > 0 { return (c, v) }
            return nil
        }.sorted { $0.1 > $1.1 }.prefix(3).map { $0 }
    }
    private var last7Values: [Double] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -6, to: today) ?? today
        let rangeStart = thisMonthRange?.lowerBound ?? start
        let effectiveStart = max(rangeStart, start)
        var dayTotals: [Date: Decimal] = [:]
        for e in periodExpenses {
            let d = cal.startOfDay(for: e.date)
            if d >= effectiveStart && d <= today { dayTotals[d, default: 0] += e.amount }
        }
        var vals: [Double] = []
        for i in 0..<7 {
            if let d = cal.date(byAdding: .day, value: i, to: effectiveStart) {
                let v = dayTotals[cal.startOfDay(for: d)] ?? 0
                vals.append((NSDecimalNumber(decimal: v).doubleValue))
            }
        }
        return vals
    }

    // Hero header summary shown in safe area inset.
    @ViewBuilder var headerSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(periodLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(alignment: .lastTextBaseline) {
                Text(CurrencyFormatter.string(from: periodTotal, currencyCode: Locale.current.currency?.identifier ?? "INR"))
                    .font(.largeTitle).fontWeight(.bold).monospacedDigit()
                Spacer(minLength: 12)
                MiniBarChart(values: last7Values)
                    .frame(width: 140, height: 56)
                    .accessibilityHidden(true)
            }
            if !topCategories.isEmpty {
                HStack(spacing: 8) {
                    ForEach(0..<topCategories.count, id: \.self) { i in
                        let item = topCategories[i]
                        let amount = CurrencyFormatter.string(from: item.1, currencyCode: Locale.current.currency?.identifier ?? "INR")
                        Label("\(item.0.displayName) \(amount)", systemImage: item.0.symbolName)
                            .labelStyle(.titleAndIcon)
                            .font(.footnote)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule(style: .continuous).fill(.ultraThinMaterial))
                    }
                }
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [Color.accentColor.opacity(0.18), Color.accentColor.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 8)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(Color.clear.ignoresSafeArea())
    }

    @ViewBuilder var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "creditcard")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("No spending this month")
                .font(.title3).fontWeight(.semibold)
            Text("Add an expense to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack { // keep the button compact
                Button(action: { showingAdd = true }) {
                    Label("Add Expense", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
        }
        .padding(22)
        .frame(maxWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// (Old summarySection removed; replaced with headerSummary)

// (Old category chip UI removed)

private struct MiniBarChart: View {
    var values: [Double]
    var body: some View {
        GeometryReader { geo in
            let maxV = max(values.max() ?? 0, 1)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(values.enumerated()), id: \.offset) { _, item in
                    let height = CGFloat(item / maxV) * geo.size.height
                    Capsule(style: .continuous)
                        .fill(Color.accentColor.opacity(0.35))
                        .frame(width: (geo.size.width - 6 * CGFloat(values.count - 1)) / CGFloat(values.count), height: height)
                }
            }
        }
    }
}
// (Old chip button removed)

// Keep a minimal MonthScope for internal range calculation
private enum MonthScope: String, CaseIterable {
    case thisMonth
    var dateRange: ClosedRange<Date>? {
        let cal = Calendar.current
        let date = Date()
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
