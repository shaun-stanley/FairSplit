import SwiftUI
import SwiftData

struct SettleUpView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    var group: Group
    @State private var saved = false
    @State private var showScanner = false
    @State private var pendingTransfer: (from: Member, to: Member, amount: Decimal)?
    @State private var showComposer = false
    @State private var composeBody: String = ""
    @State private var showShare = false
    @State private var shareTarget: (from: Member, to: Member, amount: Decimal)?

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
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .accessibilityLabel("\(item.from.name) pays \(item.to.name) \(CurrencyFormatter.string(from: item.amount, currencyCode: group.defaultCurrency))")
                            .swipeActions(edge: .trailing) {
                                Button("Mark Paid") {
                                    let repo = DataRepository(context: modelContext, undoManager: undoManager)
                                    repo.recordSettlement(for: group, from: item.from, to: item.to, amount: item.amount)
                                    Haptics.success()
                                    saved = true
                                }.tint(.green)

                                Button("Scan Receipt") {
                                    pendingTransfer = item
                                    showScanner = true
                                }.tint(.blue)

                                Button("Share Request") {
                                    shareTarget = item
                                    showShare = true
                                }.tint(.indigo)

                            }
                            .contextMenu {
                                Button("Copy Amount") {
                                    let text = CurrencyFormatter.string(from: item.amount, currencyCode: group.defaultCurrency)
                                    UIPasteboard.general.string = text
                                    Haptics.success()
                                }
                                Button("Message Payer") {
                                    composeBody = "Hi \(item.from.name), please pay \(CurrencyFormatter.string(from: item.amount, currencyCode: group.defaultCurrency)) for \(group.name)."
                                    showComposer = true
                                }
                                Button("Share Payment Request") {
                                    shareTarget = item
                                    showShare = true
                                }
                            }
                        }
                    }

                    if !group.settlements.isEmpty {
                        Section("History") {
                            ForEach(group.settlements, id: \.persistentModelID) { s in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("\(s.from.name) → \(s.to.name)")
                                        Text(s.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if s.receiptImageData != nil {
                                        Image(systemName: "doc.viewfinder")
                                            .foregroundStyle(.secondary)
                                    }
                                    Text(CurrencyFormatter.string(from: s.amount, currencyCode: group.defaultCurrency))
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                }
                                .accessibilityLabel("Settlement: \(s.from.name) paid \(s.to.name) \(CurrencyFormatter.string(from: s.amount, currencyCode: group.defaultCurrency)) on \(s.date.formatted(date: .abbreviated, time: .omitted))")
                                .contextMenu {
                                    Button("Copy Amount") {
                                        let text = CurrencyFormatter.string(from: s.amount, currencyCode: group.defaultCurrency)
                                        UIPasteboard.general.string = text
                                        Haptics.success()
                                    }
                                    Button("Message Payer") {
                                        composeBody = "Hi \(s.from.name), please pay \(CurrencyFormatter.string(from: s.amount, currencyCode: group.defaultCurrency)) for \(group.name)."
                                        showComposer = true
                                    }
                                }
                            }
                        }
                    }
                }
                .contentMargins(.horizontal, 20, for: .scrollContent)
            }
        }
        .navigationTitle("Settle Up")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Record Settlement", action: record)
                    .disabled(proposals.isEmpty)
                    #if canImport(TipKit)
                    .popoverTip(AppTips.recordSettlement)
                    #endif
            }

        }
        .alert("Settlement recorded", isPresented: $saved) {
            Button("OK", role: .cancel) {}
        }
        .sheet(isPresented: $showScanner) {
            if let item = pendingTransfer {
                DocumentScannerView { data in
                    let repo = DataRepository(context: modelContext, undoManager: undoManager)
                    repo.recordSettlement(for: group, from: item.from, to: item.to, amount: item.amount, receiptImageData: data)
                    Haptics.success()
                    saved = true
                    pendingTransfer = nil
                    showScanner = false
                } onCancel: {
                    pendingTransfer = nil
                    showScanner = false
                }
            }
        }
        .sheet(isPresented: $showComposer) {
            MessageComposerView(bodyText: composeBody) {
                showComposer = false
            }
        }
        .sheet(isPresented: $showShare, onDismiss: { shareTarget = nil }) {
            if let target = shareTarget {
                ShareSheet(activityItems: [shareMessage(for: target)])
            }
        }
    }

    private func record() {
        DataRepository(context: modelContext, undoManager: undoManager).recordSettlements(for: group, transfers: proposals)
        Haptics.success()
        saved = true
    }

    private func shareMessage(for target: (from: Member, to: Member, amount: Decimal)) -> String {
        "Pay \(CurrencyFormatter.string(from: target.amount, currencyCode: group.defaultCurrency)) to \(target.to.name) for \(group.name)."
    }
}

#Preview {
    let a = Member(name: "Alex")
    let b = Member(name: "Sam")
    let c = Member(name: "Kai")
    let g = Group(name: "Preview", defaultCurrency: "USD", members: [a, b, c], expenses: [Expense(title: "Lunch", amount: 12, payer: a, participants: [a, b])])
    return NavigationStack { SettleUpView(group: g) }
}
