import SwiftUI
import SwiftData

struct SettleUpView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    var group: Group
    @State private var saved = false

    private var proposals: [(from: Member, to: Member, amount: Decimal)] {
        SplitCalculator.balances(for: group)
    }

    var body: some View {
        VStack {
            if proposals.isEmpty {
                ContentUnavailableView("You're all settled!", systemImage: "checkmark.seal")
            } else {
                List {
                    Section("Suggested Transfers") {
                        ForEach(Array(proposals.enumerated()), id: \.offset) { _, item in
                            HStack {
                                Text(item.from.name)
                                Image(systemName: "arrow.right")
                                    .foregroundStyle(.secondary)
                                Text(item.to.name)
                                Spacer()
                                Text(CurrencyFormatter.string(from: item.amount, currencyCode: group.defaultCurrency))
                                    .fontWeight(.semibold)
                            }
                            .accessibilityLabel("\(item.from.name) pays \(item.to.name) \(CurrencyFormatter.string(from: item.amount, currencyCode: group.defaultCurrency))")
                        }
                    }

                    if !group.settlements.isEmpty {
                        Section("History") {
                            ForEach(group.settlements, id: \.persistentModelID) { s in
                                HStack {
                                    Text("\(s.from.name) → \(s.to.name)")
                                    Spacer()
                                    Text(CurrencyFormatter.string(from: s.amount, currencyCode: group.defaultCurrency))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Settle Up")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Record Settlement", action: record)
                    .disabled(proposals.isEmpty)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 16) {
                    if let undoManager, undoManager.canUndo { Button("Undo") { undoManager.undo() } }
                    if let undoManager, undoManager.canRedo { Button("Redo") { undoManager.redo() } }
                }
            }
        }
        .alert("Settlement recorded", isPresented: $saved) {
            Button("OK", role: .cancel) {}
        }
    }

    private func record() {
        DataRepository(context: modelContext, undoManager: undoManager).recordSettlements(for: group, transfers: proposals)
        saved = true
    }
}

#Preview {
    let a = Member(name: "Alex")
    let b = Member(name: "Sam")
    let c = Member(name: "Kai")
    let g = Group(name: "Preview", defaultCurrency: "USD", members: [a, b, c], expenses: [Expense(title: "Lunch", amount: 12, payer: a, participants: [a, b])])
    return NavigationStack { SettleUpView(group: g) }
}
