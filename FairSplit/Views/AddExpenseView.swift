import SwiftUI
import SwiftData

struct AddExpenseView: View {
    var members: [Member]
    /// Group's default currency
    var currencyCode: String
    var expense: Expense?
    var onSave: (_ title: String, _ amount: Decimal, _ payer: Member?, _ participants: [Member], _ category: ExpenseCategory?, _ note: String?, _ receipt: Data?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    // Use numeric binding with currency formatting for polished input
    @State private var amount: Double?
    @State private var payer: Member?
    @State private var selected: Set<PersistentIdentifier>
    @State private var category: ExpenseCategory?
    @State private var note: String
    @State private var expenseCurrency: String
    @State private var fxRate: Double?
    @State private var receiptImageData: Data?
    @State private var showingScanner = false

    init(members: [Member], currencyCode: String, expense: Expense? = nil, onSave: @escaping (_ title: String, _ amount: Decimal, _ payer: Member?, _ participants: [Member], _ category: ExpenseCategory?, _ note: String?, _ receipt: Data?) -> Void) {
        self.members = members
        self.currencyCode = currencyCode
        self.expense = expense
        self.onSave = onSave
        _title = State(initialValue: expense?.title ?? "")
        _amount = State(initialValue: expense.map { Double(truncating: NSDecimalNumber(decimal: $0.amount)) })
        _payer = State(initialValue: expense?.payer)
        _selected = State(initialValue: Set(expense?.participants.map { $0.persistentModelID } ?? []))
        _category = State(initialValue: expense?.category)
        _note = State(initialValue: expense?.note ?? "")
        _expenseCurrency = State(initialValue: expense?.currencyCode ?? currencyCode)
        _fxRate = State(initialValue: expense?.fxRateToGroupCurrency.map { Double(truncating: NSDecimalNumber(decimal: $0)) })
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
            Section("Category & Notes") {
                Picker("Category", selection: $category) {
                    Text("None").tag(nil as ExpenseCategory?)
                    ForEach(ExpenseCategory.allCases) { cat in
                        Text(cat.displayName).tag(cat as ExpenseCategory?)
                    }
                }
                TextField("Note", text: $note)
            }
            Section("Currency") {
                Picker("Currency", selection: $expenseCurrency) {
                    ForEach(Locale.commonISOCurrencyCodes, id: \.self) { code in
                        Text(code).tag(code)
                    }
                }
                if expenseCurrency != currencyCode {
                    TextField("Rate to \(currencyCode)", value: $fxRate, format: .number)
                        .keyboardType(.decimalPad)
                }
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
                            .foregroundStyle(.red)
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
        .navigationTitle(expense == nil ? "New Expense" : "Edit Expense")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).disabled(!canSave) }
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
            }
        }
    }

    private var canSave: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard let amount, amount > 0 else { return false }
        guard payer != nil else { return false }
        return !selected.isEmpty
    }

    private func save() {
        guard let amt = amount else { return }
        let amount = Decimal(amt)
        let included = members.filter { selected.contains($0.persistentModelID) }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(title, amount, payer, included, category, trimmed.isEmpty ? nil : trimmed, receiptImageData)
        dismiss()
    }
}

#Preview {
    // SwiftData previews would require a model container; keeping a static preview of the form.
    let m = [Member(name: "Alex"), Member(name: "Sam"), Member(name: "Kai")]
    return NavigationStack {
        AddExpenseView(members: m, currencyCode: "USD") { _, _, _, _, _, _, _ in }
    }
}
