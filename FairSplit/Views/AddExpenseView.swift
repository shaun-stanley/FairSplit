import SwiftUI
import SwiftData

struct AddExpenseView: View {
    var members: [Member]
    var onSave: (_ title: String, _ amount: Decimal, _ payer: Member?, _ participants: [Member]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var payer: Member?
    @State private var selected: Set<PersistentIdentifier> = []

    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $title)
                TextField("Amount", text: $amountText)
                    .keyboardType(.decimalPad)
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
        .navigationTitle("New Expense")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).disabled(!canSave) }
        }
        .onAppear {
            if payer == nil { payer = members.first }
            if selected.isEmpty { selected = Set(members.map { $0.persistentModelID }) }
        }
    }

    private var canSave: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) != nil else { return false }
        guard payer != nil else { return false }
        return !selected.isEmpty
    }

    private func save() {
        guard let amount = Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) else { return }
        let included = members.filter { selected.contains($0.persistentModelID) }
        onSave(title, amount, payer, included)
        dismiss()
    }
}

#Preview {
    // SwiftData previews would require a model container; keeping a static preview of the form.
    let m = [Member(name: "Alex"), Member(name: "Sam"), Member(name: "Kai")]
    return NavigationStack {
        AddExpenseView(members: m) { _, _, _, _ in }
    }
}
