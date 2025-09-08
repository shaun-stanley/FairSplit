import SwiftUI
import SwiftData

struct ItemizedExpenseView: View {
    var members: [Member]
    var groupCurrencyCode: String
    var onSave: (_ title: String, _ items: [(String, Decimal, [Member])], _ tax: Decimal?, _ tip: Decimal?, _ allocation: Expense.TaxTipAllocation, _ payer: Member?, _ category: ExpenseCategory?, _ note: String?, _ receipt: Data?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var payer: Member?
    @State private var category: ExpenseCategory?
    @State private var note: String = ""
    @State private var receiptImageData: Data?
    @State private var showingScanner = false
    @State private var items: [ItemRow] = [ItemRow()]
    @State private var tax: Double? = nil
    @State private var tip: Double? = nil
    @State private var allocation: Expense.TaxTipAllocation = .proportional

    struct ItemRow: Identifiable {
        let id = UUID()
        var name: String = ""
        var amount: Double? = nil
        var participantIDs: Set<PersistentIdentifier> = []
    }

    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $title)
                Picker("Paid by", selection: $payer) {
                    ForEach(members) { m in Text(m.name).tag(m as Member?) }
                }
                Picker("Category", selection: $category) {
                    Text("None").tag(nil as ExpenseCategory?)
                    ForEach(ExpenseCategory.allCases) { cat in Text(cat.displayName).tag(cat as ExpenseCategory?) }
                }
                TextField("Note", text: $note)
            }

            Section("Items") {
                ForEach(items.indices, id: \.self) { idx in
                    let binding = $items[idx]
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("Item name", text: binding.name)
                            TextField("Amount", value: binding.amount, format: .currency(code: groupCurrencyCode))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 160)
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(members) { m in
                                    let isOn = binding.wrappedValue.participantIDs.contains(m.persistentModelID)
                                    Button {
                                        if isOn { binding.wrappedValue.participantIDs.remove(m.persistentModelID) } else { binding.wrappedValue.participantIDs.insert(m.persistentModelID) }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                                            Text(m.name)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    items.remove(atOffsets: offsets)
                }
                Button { addItemRow() } label: { Label("Add Item", systemImage: "plus") }
            }

            Section("Tax & Tip") {
                TextField("Tax", value: $tax, format: .currency(code: groupCurrencyCode)).keyboardType(.decimalPad)
                TextField("Tip", value: $tip, format: .currency(code: groupCurrencyCode)).keyboardType(.decimalPad)
                Picker("Allocate", selection: $allocation) {
                    ForEach(Expense.TaxTipAllocation.allCases, id: \.rawValue) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
            }

            Section("Receipt") {
                if let data = receiptImageData, let uiImage = UIImage(data: data) {
                    HStack {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipped()
                            .cornerRadius(8)
                        Spacer()
                        Button("Remove") { receiptImageData = nil }.foregroundStyle(.red)
                    }
                } else {
                    Button { showingScanner = true } label: { Label("Scan Receipt", systemImage: "doc.viewfinder") }
                }
            }
        }
        .contentMargins(.horizontal, for: .scrollContent)
        .navigationTitle("Itemized Expense")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).disabled(!canSave) }
        }
        .sheet(isPresented: $showingScanner) {
            DocumentScannerView { data in
                self.receiptImageData = data
                self.showingScanner = false
            } onCancel: {
                self.showingScanner = false
            }
        }
        .onAppear {
            if payer == nil { payer = members.first }
            // Default all members for first item
            if items.first?.participantIDs.isEmpty == true {
                let all = Set(members.map { $0.persistentModelID })
                items[0].participantIDs = all
            }
        }
    }

    private var canSave: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard items.contains(where: { ($0.amount ?? 0) > 0 && !$0.participantIDs.isEmpty }) else { return false }
        guard payer != nil else { return false }
        return true
    }

    private func save() {
        let prepared: [(String, Decimal, [Member])] = items.compactMap { row in
            guard let amt = row.amount, amt > 0 else { return nil }
            let parts = members.filter { row.participantIDs.contains($0.persistentModelID) }
            guard !parts.isEmpty else { return nil }
            return (row.name.isEmpty ? "Item" : row.name, Decimal(amt), parts)
        }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(title, prepared, tax.map { Decimal($0) }, tip.map { Decimal($0) }, allocation, payer, category, trimmed.isEmpty ? nil : trimmed, receiptImageData)
        Haptics.success()
        dismiss()
    }

    private func addItemRow() {
        var row = ItemRow()
        // Default participants: copy from last item if present; otherwise all members
        if let last = items.last, !last.participantIDs.isEmpty {
            row.participantIDs = last.participantIDs
        } else {
            row.participantIDs = Set(members.map { $0.persistentModelID })
        }
        items.append(row)
    }
}

#Preview {
    let m = [Member(name: "Alex"), Member(name: "Sam"), Member(name: "Kai")]
    return NavigationStack {
        ItemizedExpenseView(members: m, groupCurrencyCode: "USD") { _, _, _, _, _, _, _, _, _ in }
    }
}
