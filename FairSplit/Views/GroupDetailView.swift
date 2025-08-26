import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct GroupDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    let group: Group
    @State private var showingAddExpense = false
    @State private var showingAddItemized = false
    @State private var editingExpense: Expense?
    @State private var searchText = ""
    @State private var minAmount: Double?
    @State private var maxAmount: Double?
    @State private var selectedMemberIDs: Set<PersistentIdentifier> = []
    @State private var showingAmountFilter = false
    @State private var showingImporter = false
    @State private var showingExporter = false
    @State private var exportDocument: CSVDocument?
    @State private var showingShare = false
    @State private var shareText: String = ""
    @State private var shareURL: URL?
    @State private var importError: String?
    @State private var showingAddRecurring = false
    @State private var showComposer = false
    @State private var composeBody: String = ""
    @State private var commentingExpense: Expense?
    @State private var showingCurrencyPicker = false
    @State private var newCurrencyCode: String = AppSettings.defaultCurrencyCode()
    @State private var confirmCurrencyChange = false
    @State private var selectedAnchor: Anchor? = nil

    private enum Anchor: String, Hashable {
        case balances, settle, expenses, recurring, totals, activity, members
    }

    private var anchorItems: [(title: String, anchor: Anchor)] {
        [
            ("Balances", .balances),
            ("Settle Up", .settle),
            ("Expenses", .expenses),
            ("Recurring", .recurring),
            ("Totals", .totals),
            ("Activity", .activity),
            ("Members", .members)
        ]
    }

    private var settlementProposals: [(from: Member, to: Member, amount: Decimal)] {
        SplitCalculator.balances(for: group)
    }
    private var totalsByMember: [(Member, Decimal)] {
        let totals = StatsCalculator.totalsByMember(for: group)
        return group.members.map { ($0, totals[$0.persistentModelID] ?? 0) }
    }
    private var totalsByCategory: [(ExpenseCategory, Decimal)] {
        let totals = StatsCalculator.totalsByCategory(for: group)
        return ExpenseCategory.allCases.compactMap { cat in
            if let value = totals[cat], value > 0 { return (cat, value) }
            return nil
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                archivedBanner()
                balancesSection().id(Anchor.balances)
                settleUpSection().id(Anchor.settle)
                expensesSection().id(Anchor.expenses)
                recurringSection().id(Anchor.recurring)
                totalsSections().id(Anchor.totals)
                activitySection().id(Anchor.activity)
                membersSection().id(Anchor.members)
            }
            .safeAreaInset(edge: .top) { pillBar(proxy: proxy) }
        }
        .navigationTitle(group.name)
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { showingAddExpense = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add Expense")
                    .disabled(group.isArchived)
                    #if canImport(TipKit)
                    .popoverTip(Tips.addExpense)
                    #endif
                Button { showingAddItemized = true } label: { Image(systemName: "list.bullet.rectangle.portrait") }
                    .accessibilityLabel("Add Itemized Expense")
                    .disabled(group.isArchived)
                    #if canImport(TipKit)
                    .popoverTip(Tips.addItemized)
                    #endif
                Button { showingAddRecurring = true } label: { Image(systemName: "arrow.triangle.2.circlepath") }
                    .accessibilityLabel("Add Recurring Expense")
                    .disabled(group.isArchived)
                    #if canImport(TipKit)
                    .popoverTip(Tips.addRecurring)
                    #endif
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
                    Section("CSV") {
                        Button("Import CSV…") { showingImporter = true }
                        Button("Export CSV…") {
                            let csv = DataRepository(context: modelContext, undoManager: undoManager).exportCSV(for: group)
                            exportDocument = CSVDocument(text: csv)
                            showingExporter = true
                        }
                    }
                    Section("Currency") {
                        Button("Change Group Currency…") {
                            newCurrencyCode = group.defaultCurrency
                            showingCurrencyPicker = true
                        }
                    }
                    Section("Share") {
                        Button("Share Summary…") {
                            shareText = GroupSummaryExporter.markdown(for: group)
                            showingShare = true
                        }
                        Button("Share Summary PDF…") {
                            let pdf = PDFExporter.summaryPDF(for: group)
                            if let url = try? TempFileWriter.writeTemporary(data: pdf, fileName: group.name.replacingOccurrences(of: " ", with: "-"), fileExtension: "pdf") {
                                shareURL = url
                                showingShare = true
                            }
                        }
                    }
                    #if canImport(ActivityKit)
                    Section("Live Activity") {
                        Button("Start Live Activity") {
                            LiveActivityManager.start(group: group)
                        }
                        Button("End Live Activity") {
                            LiveActivityManager.endAll()
                        }
                    }
                    #endif
                    Section("Group") {
                        if group.isArchived {
                            Button("Unarchive Group") {
                                DataRepository(context: modelContext, undoManager: undoManager).setArchived(false, for: group)
                            }
                        } else {
                            Button("Archive Group") {
                                DataRepository(context: modelContext, undoManager: undoManager).setArchived(true, for: group)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .accessibilityLabel("Filters and actions")
                }
                #if canImport(TipKit)
                .popoverTip(Tips.filters)
                #endif
            }

        }
        .searchable(text: $searchText, prompt: "Search expenses")
        .sheet(isPresented: $showingCurrencyPicker) {
            NavigationStack {
                Form {
                    Picker("Currency", selection: $newCurrencyCode) {
                        ForEach(AppSettings.currencyPresets, id: \.self) { code in
                            HStack {
                                Text(Locale.current.localizedString(forCurrencyCode: code) ?? code)
                                Spacer()
                                Text(code).foregroundStyle(.secondary)
                            }.tag(code)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    Section("About") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Changing the group currency updates how totals and balances are displayed.")
                            Text("Existing expenses are not converted automatically.")
                            Text("Expenses logged in other currencies continue to use their set conversion rates (you can edit an expense to adjust its rate).")
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("Group Currency")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingCurrencyPicker = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { confirmCurrencyChange = true }
                        .disabled(newCurrencyCode.isEmpty || newCurrencyCode == group.defaultCurrency)
                    }
                }
                .alert("Change Group Currency?", isPresented: $confirmCurrencyChange) {
                    Button("Cancel", role: .cancel) {}
                    Button("Change", role: .destructive) {
                        group.defaultCurrency = newCurrencyCode
                        try? modelContext.save()
                        Diagnostics.event("Group currency changed to \(newCurrencyCode)")
                        showingCurrencyPicker = false
                    }
                } message: {
                    Text("This updates display currency for this group to \(newCurrencyCode). Existing expenses are not converted automatically. Expenses in other currencies keep their set conversion rates.")
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            NavigationStack {
                AddExpenseView(members: group.members, groupCurrencyCode: group.defaultCurrency, lastRates: group.lastFXRates) { title, amount, currency, rate, payer, participants, category, note, receipt in
                    DataRepository(context: modelContext, undoManager: undoManager).addExpense(to: group, title: title, amount: amount, payer: payer, participants: participants, category: category, note: note, receiptImageData: receipt, currencyCode: currency, fxRateToGroupCurrency: rate)
                }
            }
        }
        .sheet(isPresented: $showingAddItemized) {
            NavigationStack {
                ItemizedExpenseView(members: group.members, groupCurrencyCode: group.defaultCurrency) { title, items, tax, tip, allocation, payer, category, note, receipt in
                    DataRepository(context: modelContext, undoManager: undoManager).addItemizedExpense(
                        to: group,
                        title: title,
                        items: items.map { ($0.0, $0.1, $0.2) },
                        tax: tax,
                        tip: tip,
                        allocation: allocation,
                        payer: payer,
                        category: category,
                        note: note,
                        receiptImageData: receipt,
                        currencyCode: group.defaultCurrency
                    )
                }
            }
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.commaSeparatedText], allowsMultipleSelection: false) { result in
            do {
                guard let url = try result.get().first else { return }
                let data = try Data(contentsOf: url)
                guard let text = String(data: data, encoding: .utf8) else { throw CocoaError(.fileReadCorruptFile) }
                DataRepository(context: modelContext, undoManager: undoManager).importExpenses(fromCSV: text, into: group)
            } catch {
                importError = "Failed to import CSV."
            }
        }
        .fileExporter(isPresented: $showingExporter, document: exportDocument, contentType: .commaSeparatedText, defaultFilename: "\(group.name)-expenses") { _ in }
        .sheet(isPresented: $showingShare) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            } else {
                ShareSheet(activityItems: [shareText])
            }
        }
        .sheet(item: $commentingExpense) { expense in
            NavigationStack {
                ExpenseCommentsView(expense: expense, isArchived: group.isArchived)
            }
        }
        .alert("Import Failed", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(importError ?? "") }
        .sheet(isPresented: $showingAddRecurring) {
            AddRecurringView(members: group.members) { title, amount, freq, start, payer, participants, category, note in
                DataRepository(context: modelContext).addRecurring(to: group, title: title, amount: amount, frequency: freq, nextDate: start, payer: payer, participants: participants, category: category, note: note)
            }
        }
        .sheet(item: $editingExpense) { expense in
            NavigationStack {
                AddExpenseView(members: group.members, groupCurrencyCode: group.defaultCurrency, expense: expense, lastRates: group.lastFXRates) { title, amount, currency, rate, payer, participants, category, note, receipt in
                    DataRepository(context: modelContext, undoManager: undoManager).update(expense: expense, in: group, title: title, amount: amount, payer: payer, participants: participants, category: category, note: note, receiptImageData: receipt, currencyCode: currency, fxRateToGroupCurrency: rate)
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
        .sheet(isPresented: $showComposer) {
            MessageComposerView(bodyText: composeBody) {
                showComposer = false
            }
        }
    }

    // MARK: - Section Builders
    @ViewBuilder private func archivedBanner() -> some View {
        if group.isArchived {
            Section {
                HStack(spacing: 8) {
                    Image(systemName: "archivebox")
                        .foregroundStyle(.secondary)
                    Text("This group is archived. Data is read-only.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder private func totalsSections() -> some View {
        if !totalsByMember.isEmpty || !totalsByCategory.isEmpty {
            Section("Totals by Member") {
                ForEach(0..<totalsByMember.count, id: \.self) { i in
                    let (member, amount) = totalsByMember[i]
                    HStack {
                        Text(member.name)
                        Spacer()
                        Text(CurrencyFormatter.string(from: amount, currencyCode: group.defaultCurrency))
                    }
                }
            }
            if !totalsByCategory.isEmpty {
                Section("Totals by Category") {
                    ForEach(0..<totalsByCategory.count, id: \.self) { i in
                        let (category, amount) = totalsByCategory[i]
                        HStack {
                            Text(category.displayName)
                            Spacer()
                            Text(CurrencyFormatter.string(from: amount, currencyCode: group.defaultCurrency))
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder private func recurringSection() -> some View {
        Section("Recurring") {
            if group.recurring.isEmpty {
                ContentUnavailableView("No recurring expenses", systemImage: "arrow.triangle.2.circlepath")
            } else {
                ForEach(group.recurring, id: \.persistentModelID) { r in
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.title).font(.headline)
                            Text("Next: \(r.nextDate, style: .date)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Menu {
                            Button(r.isPaused ? "Resume" : "Pause") { DataRepository(context: modelContext).togglePause(r) }
                            Button("Run Now") { DataRepository(context: modelContext).generateOnce(r, in: group) }
                            Button("Delete", role: .destructive) { DataRepository(context: modelContext).deleteRecurring(r, from: group) }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel("Recurring actions")
                    }
                }
            }
        }
        .headerProminence(.increased)
    }

    @ViewBuilder private func activitySection() -> some View {
        let expenseEvents = group.expenses.map { e in
            (
                date: e.date,
                icon: "list.bullet",
                text: {
                    let who = e.payer?.name ?? "Someone"
                    let amt = CurrencyFormatter.string(from: SplitCalculator.amountInGroupCurrency(for: e, defaultCurrency: group.defaultCurrency), currencyCode: group.defaultCurrency)
                    return "Expense: \(who) paid \(amt) — \(e.title)"
                }()
            )
        }
        let settlementEvents = group.settlements.map { s in
            (
                date: s.date,
                icon: "arrow.right.circle",
                text: {
                    let amt = CurrencyFormatter.string(from: s.amount, currencyCode: group.defaultCurrency)
                    return "Settlement: \(s.from.name) → \(s.to.name) \(amt)"
                }()
            )
        }
        let events = (expenseEvents + settlementEvents).sorted { $0.date > $1.date }.prefix(10)
        if !events.isEmpty {
            Section("Recent Activity") {
                ForEach(Array(events.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.text)
                            Text(item.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .headerProminence(.increased)
        }
    }

    @ViewBuilder private func expensesSection() -> some View {
        Section("Expenses") {
            ForEach(filteredExpenses, id: \.persistentModelID) { expense in
                expenseRow(expense)
            }
        }
        .headerProminence(.increased)
    }

    @ViewBuilder private func expenseRow(_ expense: Expense) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if let data = expense.receiptImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipped()
                    .cornerRadius(6)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if let category = expense.category {
                        Image(systemName: category.symbolName)
                            .foregroundStyle(.secondary)
                    }
                    Text(expense.title)
                }
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                if let category = expense.category {
                    Text(category.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                if let payer = expense.payer {
                    Text("Paid by \(payer.name)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .layoutPriority(1)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 6) {
                Text(CurrencyFormatter.string(from: SplitCalculator.amountInGroupCurrency(for: expense, defaultCurrency: group.defaultCurrency), currencyCode: group.defaultCurrency))
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Button(action: { commentingExpense = expense }) {
                    HStack(spacing: 4) {
                        Image(systemName: "text.bubble")
                        Text(expense.comments.isEmpty ? "Comments" : "\(expense.comments.count)")
                    }
                }
                .buttonStyle(.bordered)
                .font(.caption)
                .accessibilityLabel(expense.comments.isEmpty ? "Add comment" : "\(expense.comments.count) comments")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(expenseAccessibilityLabel(expense))
        .swipeActions(allowsFullSwipe: false) {
            if !group.isArchived {
                Button("Edit") { editingExpense = expense }.tint(.blue)
                Button("Delete", role: .destructive) {
                    DataRepository(context: modelContext, undoManager: undoManager).delete(expenses: [expense], from: group)
                    Haptics.success()
                }
            }
        }
        .contextMenu {
            if !group.isArchived {
                Button("Edit") { editingExpense = expense }
                Button("Delete", role: .destructive) {
                    DataRepository(context: modelContext, undoManager: undoManager).delete(expenses: [expense], from: group)
                    Haptics.success()
                }
            }
            Button("Comments") { commentingExpense = expense }
        }
    }

    @ViewBuilder private func balancesSection() -> some View {
        Section("Balances") {
            let net = SplitCalculator.netBalances(expenses: group.expenses, members: group.members, settlements: group.settlements, defaultCurrency: group.defaultCurrency)
            ForEach(group.members, id: \.persistentModelID) { member in
                let amount = net[member.persistentModelID] ?? 0
                balanceRow(member: member, amount: amount)
            }
        }
        .headerProminence(.increased)
    }

    @ViewBuilder private func balanceRow(member: Member, amount: Decimal) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: amount >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                    .foregroundStyle(amount >= 0 ? .green : .red)
                    .accessibilityHidden(true)
                Text(member.name)
            }
            Spacer()
            Text(CurrencyFormatter.string(from: amount, currencyCode: group.defaultCurrency))
                .foregroundStyle(amount >= 0 ? .green : .red)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(member.name), balance \(CurrencyFormatter.string(from: amount, currencyCode: group.defaultCurrency))")
        .contextMenu {
            Button("Copy Amount") {
                let text = CurrencyFormatter.string(from: amount, currencyCode: group.defaultCurrency)
                UIPasteboard.general.string = text
                Haptics.success()
            }
            if amount < 0 {
                Button("Message \(member.name)") {
                    composeBody = "Hi \(member.name), you owe \(CurrencyFormatter.string(from: -amount, currencyCode: group.defaultCurrency)) for \(group.name)."
                    showComposer = true
                }
            }
        }
    }

    @ViewBuilder private func settleUpSection() -> some View {
        Section {
            if settlementProposals.isEmpty {
                ContentUnavailableView("You're all settled!", systemImage: "checkmark.seal")
            } else {
                ForEach(Array(settlementProposals.enumerated()), id: \.offset) { _, item in
                    HStack {
                        Text(item.from.name)
                        Image(systemName: "arrow.right.circle")
                            .foregroundStyle(.secondary)
                        Text(item.to.name)
                        Spacer()
                        Text(CurrencyFormatter.string(from: item.amount, currencyCode: group.defaultCurrency))
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .accessibilityLabel("\(item.from.name) pays \(item.to.name) \(CurrencyFormatter.string(from: item.amount, currencyCode: group.defaultCurrency))")
                }
            }
        } header: {
            HStack {
                Text("Settle Up")
                Spacer()
                if !group.isArchived {
                    NavigationLink {
                        SettleUpView(group: group)
                    } label: {
                        HStack(spacing: 4) {
                            Text("Settle Up")
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open Settle Up")
                    #if canImport(TipKit)
                    .popoverTip(Tips.settleUp)
                    #endif
                } else {
                    Text("Unavailable in archived groups")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .headerProminence(.increased)
    }

    @ViewBuilder private func membersSection() -> some View {
        Section("Members") {
            NavigationLink(destination: MembersView(group: group)) {
                HStack {
                    Text("Members")
                    Spacer()
                    Text("\(group.members.count)").foregroundStyle(.secondary)
                }
            }
        }
        .headerProminence(.increased)
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

    private func expenseAccessibilityLabel(_ expense: Expense) -> String {
        var parts: [String] = [expense.title]
        let amount = SplitCalculator.amountInGroupCurrency(for: expense, defaultCurrency: group.defaultCurrency)
        parts.append(CurrencyFormatter.string(from: amount, currencyCode: group.defaultCurrency))
        if let category = expense.category { parts.append(category.displayName) }
        if let payer = expense.payer { parts.append("Paid by \(payer.name)") }
        if let note = expense.note, !note.isEmpty { parts.append(note) }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Pill Bar
extension GroupDetailView {
    @ViewBuilder
    private func pillBar(proxy: ScrollViewProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(anchorItems, id: \.anchor) { item in
                    Button {
                        withAnimation(.easeInOut) {
                            proxy.scrollTo(item.anchor, anchor: .top)
                            selectedAnchor = item.anchor
                        }
                    } label: {
                        Text(item.title)
                            .font(.subheadline)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(selectedAnchor == item.anchor ? Color.accentColor : Color.secondary.opacity(0.15))
                            .foregroundStyle(selectedAnchor == item.anchor ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Jump to \(item.title)")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    if let container = try? ModelContainer(
        for: Group.self, Member.self, Expense.self, Settlement.self, RecurringExpense.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) {
        let member = Member(name: "A")
        let group = Group(name: "G", defaultCurrency: "USD", members: [member])
        return GroupDetailView(group: group).modelContainer(container)
    } else {
        return Text("Preview unavailable")
    }
}
