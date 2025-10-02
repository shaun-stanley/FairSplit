import SwiftUI
import SwiftData
import Foundation

struct AddExpenseView: View {
    var members: [Member]
    /// Group's default currency
    var groupCurrencyCode: String
    var lastRates: [String: Decimal]
    var expense: Expense?
    var onSave: (_ title: String, _ amount: Decimal, _ currencyCode: String, _ fxRateToGroup: Decimal?, _ payer: Member?, _ participants: [Member], _ category: ExpenseCategory?, _ note: String?, _ receipt: Data?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    // Use numeric binding with currency formatting for polished input
    @State private var amount: Double?
    @State private var currencyCode: String
    @State private var fxRateToGroup: Double?
    @State private var payer: Member?
    @State private var selected: Set<PersistentIdentifier>
    @State private var category: ExpenseCategory?
    @State private var note: String
    @State private var receiptImageData: Data?
    @State private var showingScanner = false

    init(members: [Member], groupCurrencyCode: String, expense: Expense? = nil, lastRates: [String: Decimal] = [:], onSave: @escaping (_ title: String, _ amount: Decimal, _ currencyCode: String, _ fxRateToGroup: Decimal?, _ payer: Member?, _ participants: [Member], _ category: ExpenseCategory?, _ note: String?, _ receipt: Data?) -> Void) {
        self.members = members
        self.groupCurrencyCode = groupCurrencyCode
        self.expense = expense
        self.lastRates = lastRates
        self.onSave = onSave
        _title = State(initialValue: expense?.title ?? "")
        _amount = State(initialValue: expense.map { Double(truncating: NSDecimalNumber(decimal: $0.amount)) })
        _currencyCode = State(initialValue: expense?.currencyCode ?? groupCurrencyCode)
        if let decimalRate = expense?.fxRateToGroupCurrency {
            _fxRateToGroup = State(initialValue: NSDecimalNumber(decimal: decimalRate).doubleValue)
        } else {
            _fxRateToGroup = State(initialValue: nil)
        }
        _payer = State(initialValue: expense?.payer)
        _selected = State(initialValue: Set(expense?.participants.map { $0.persistentModelID } ?? []))
        _category = State(initialValue: expense?.category)
        _note = State(initialValue: expense?.note ?? "")
        _receiptImageData = State(initialValue: expense?.receiptImageData)
    }

    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $title)
                TextField("Amount", value: $amount, format: .currency(code: currencyCode))
                    .keyboardType(.decimalPad)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
            currencySection
            Section("Category & Notes") {
                Picker("Category", selection: $category) {
                    Text("None").tag(nil as ExpenseCategory?)
                    ForEach(ExpenseCategory.allCases) { cat in
                        Text(cat.displayName).tag(cat as ExpenseCategory?)
                    }
                }
                TextField("Note", text: $note)
            }
        Section("Receipt") {
            if let data = receiptImageData, let uiImage = UIImage(data: data) {
                HStack(alignment: .center) {
                    Image(uiImage: uiImage)
                        .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipped()
                            .cornerRadius(8)
                        Spacer()
                        Button("Remove") { receiptImageData = nil }
                            .foregroundColor(.red)
                    }
                } else {
                    Button {
                        showingScanner = true
                    } label: {
                        Label("Scan Receipt", systemImage: "doc.viewfinder")
                    }
                }
            }
            Section("Payer") {
                Picker("Paid by", selection: $payer) {
                    ForEach(members) { m in
                        Text(m.name).tag(m as Member?)
                    }
                }
            }
            Section("Split Between") {
                ForEach(members) { m in
                    Toggle(m.name, isOn: Binding(
                        get: { selected.contains(m.persistentModelID) },
                        set: { isOn in
                            if isOn { selected.insert(m.persistentModelID) } else { selected.remove(m.persistentModelID) }
                        }
                    ))
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .navigationTitle(expense == nil ? "New Expense" : "Edit Expense")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(!canSave)
                    #if canImport(TipKit)
                    .popoverTip(AppTips.addExpense)
                    #endif
            }
        }
        .sheet(isPresented: $showingScanner) {
            DocumentScannerView { imageData in
                self.receiptImageData = imageData
                self.showingScanner = false
            } onCancel: {
                self.showingScanner = false
            }
        }
        .onAppear {
            if expense == nil {
                if payer == nil { payer = members.first }
                if selected.isEmpty { selected = Set(members.map { $0.persistentModelID }) }
                if fxRateToGroup == nil, currencyCode != groupCurrencyCode, let stored = lastRates[currencyCode] {
                    fxRateToGroup = NSDecimalNumber(decimal: stored).doubleValue
                }
            }
        }
        .onChange(of: currencyCode, initial: false) { _, newValue in
            if newValue == groupCurrencyCode {
                fxRateToGroup = nil
            } else if let existing = expense, existing.currencyCode == newValue, let rate = existing.fxRateToGroupCurrency {
                fxRateToGroup = NSDecimalNumber(decimal: rate).doubleValue
            } else if let stored = lastRates[newValue] {
                fxRateToGroup = NSDecimalNumber(decimal: stored).doubleValue
            } else {
                fxRateToGroup = nil
            }
        }
    }


    private var currencyOptions: [String] {
        var codes = Set(AppSettings.currencyPresets)
        codes.insert(groupCurrencyCode)
        codes.insert(currencyCode)
        return Array(codes).sorted()
    }

    @ViewBuilder
    private var currencySection: some View {
        Section("Currency") {
            currencyPicker
            if currencyCode != groupCurrencyCode {
                exchangeRateField
                rateHelperText
            }
        }
    }

    private var currencyPicker: some View {
        Picker("Currency", selection: $currencyCode) {
            ForEach(currencyOptions, id: \.self) { code in
                currencyRow(for: code)
                    .tag(code)
            }
        }
        .pickerStyle(.navigationLink)
    }

    private func currencyRow(for code: String) -> some View {
        HStack {
            Text(Locale.current.localizedString(forCurrencyCode: code) ?? code)
            Spacer()
            Text(code).foregroundColor(.secondary)
        }
    }

    private var exchangeRateField: some View {
        TextField("Rate to \(groupCurrencyCode)", value: $fxRateToGroup, format: .number)
            .keyboardType(.decimalPad)
            .accessibilityLabel("Exchange rate to \(groupCurrencyCode)")
            .foregroundColor((fxRateToGroup ?? 0) > 0 ? Color.primary : Color.red)
    }

    private var rateHelperText: some View {
        SwiftUI.Group {
            if let rate = fxRateToGroup, rate > 0 {
                Text("\(currencyCode) × \(formattedRate(rate)) = \(groupCurrencyCode)")
            } else {
                Text("Enter how many \(groupCurrencyCode) one \(currencyCode) equals.")
            }
        }
        .font(.footnote)
        .foregroundColor(.secondary)
    }

    private func formattedRate(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    private var canSave: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard let amount, amount > 0 else { return false }
        guard payer != nil else { return false }
        if currencyCode != groupCurrencyCode {
            guard let fxRateToGroup, fxRateToGroup > 0 else { return false }
        }
        return !selected.isEmpty
    }

    private func save() {
        guard let amt = amount else { return }
        let amount = Decimal(amt)
        let included = members.filter { selected.contains($0.persistentModelID) }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let rateDecimal: Decimal?
        if currencyCode == groupCurrencyCode {
            rateDecimal = nil
        } else if let fxRateToGroup, fxRateToGroup > 0 {
            rateDecimal = Decimal(fxRateToGroup)
        } else {
            rateDecimal = nil
        }
        onSave(title, amount, currencyCode, rateDecimal, payer, included, category, trimmed.isEmpty ? nil : trimmed, receiptImageData)
        Haptics.success()
        dismiss()
    }
}

#Preview {
    // SwiftData previews would require a model container; keeping a static preview of the form.
    let m = [Member(name: "Alex"), Member(name: "Sam"), Member(name: "Kai")]
    return NavigationStack {
        AddExpenseView(members: m, groupCurrencyCode: "USD", lastRates: [:]) { _, _, _, _, _, _, _, _, _ in }
    }
}
