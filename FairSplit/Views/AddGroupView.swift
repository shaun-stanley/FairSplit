import SwiftUI

struct AddGroupView: View {
    @State private var name = ""
    @State private var currencyCode = Locale.current.currency?.identifier ?? "USD"
    var onSave: (_ name: String, _ currencyCode: String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Currency", text: $currencyCode)
            }
            .navigationTitle("New Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, currencyCode)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddGroupView { _, _ in }
}
