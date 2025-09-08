import SwiftUI
import SwiftData

struct AddRecurringView: View {
    var members: [Member]
    var onSave: (_ title: String, _ amount: Decimal, _ frequency: RecurrenceFrequency, _ startDate: Date, _ payer: Member?, _ participants: [Member], _ category: ExpenseCategory?, _ note: String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var amount: Double?
    @State private var frequency: RecurrenceFrequency = .monthly
    @State private var startDate: Date = .now
    @State private var payer: Member?
    @State private var selected: Set<PersistentIdentifier> = []
    @State private var category: ExpenseCategory?
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Amount", value: $amount, format: .currency(code: Locale.current.currency?.identifier ?? "INR"))
                        .keyboardType(.decimalPad)
                    Picker("Frequency", selection: $frequency) {
                        ForEach(RecurrenceFrequency.allCases) { f in
                            Text(f.rawValue.capitalized).tag(f)
                        }
                    }
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                }
                Section("Category & Notes") {
                    Picker("Category", selection: $category) {
                        Text("None").tag(nil as ExpenseCategory?)
                        ForEach(ExpenseCategory.allCases) { c in
                            Text(c.displayName).tag(c as ExpenseCategory?)
                        }
                    }
                    TextField("Note", text: $note)
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
                            set: { on in if on { selected.insert(m.persistentModelID) } else { selected.remove(m.persistentModelID) } }
                        ))
                    }
                }
            }
            .contentMargins(.horizontal, for: .scrollContent)
            .navigationTitle("New Recurring")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).disabled(!canSave) }
            }
            .onAppear {
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
        let included = members.filter { selected.contains($0.persistentModelID) }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(title, Decimal(amt), frequency, startDate, payer, included, category, trimmed.isEmpty ? nil : trimmed)
        Haptics.success()
        dismiss()
    }
}

#Preview {
    let ms = [Member(name: "Alex"), Member(name: "Sam")]
    return AddRecurringView(members: ms) { _,_,_,_,_,_,_,_ in }
}
