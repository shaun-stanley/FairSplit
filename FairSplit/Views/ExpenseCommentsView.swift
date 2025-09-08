import SwiftUI
import SwiftData

struct ExpenseCommentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    let expense: Expense
    let isArchived: Bool
    @State private var newComment: String = ""

    var body: some View {
        List {
            if expense.comments.isEmpty {
                ContentUnavailableView("No comments yet", systemImage: "text.bubble")
            } else {
                ForEach(expense.comments.sorted(by: { $0.date > $1.date }), id: \.persistentModelID) { c in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline) {
                            if let author = c.author, !author.isEmpty {
                                Text(author)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(c.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                        Text(c.text)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(c.author ?? "Comment") on \(c.date.formatted(date: .abbreviated, time: .shortened)): \(c.text)")
                    .swipeActions(allowsFullSwipe: false) {
                        Button("Delete", role: .destructive) {
                            DataRepository(context: modelContext, undoManager: undoManager).deleteComment(c, from: expense)
                        }
                    }
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .navigationTitle("Comments")
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                TextField("Add a comment…", text: $newComment, axis: .vertical)
                    .disabled(isArchived)
                Button("Send") { add() }
                    .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isArchived)
            }
        }
    }

    private func add() {
        let text = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        DataRepository(context: modelContext, undoManager: undoManager).addComment(to: expense, text: text)
        newComment = ""
        Haptics.success()
    }
}

#Preview {
    let a = Member(name: "Alex")
    let g = Group(name: "Trip", defaultCurrency: "USD", members: [a])
    let e = Expense(title: "Taxi", amount: 30, payer: a, participants: [a])
    e.comments.append(Comment(text: "Keep the receipt"))
    g.expenses.append(e)
    return NavigationStack {
        ExpenseCommentsView(expense: e, isArchived: false)
    }
    .modelContainer(for: [Group.self, Member.self, Expense.self, Settlement.self, Comment.self], inMemory: true)
}
