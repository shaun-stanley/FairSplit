import SwiftUI

struct AddGroupView: View {
    @State private var name = ""
    var onSave: (_ name: String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
            }
            .contentMargins(.horizontal, for: .scrollContent)
            .navigationTitle("New Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddGroupView { _ in }
}
