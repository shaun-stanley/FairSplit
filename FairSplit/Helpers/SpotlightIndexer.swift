import Foundation
import CoreSpotlight
import UniformTypeIdentifiers
import SwiftData

enum SpotlightIndexer {
    static func reindexAll(context: ModelContext) {
        CSSearchableIndex.default().deleteAllSearchableItems { _ in
            indexAll(context: context)
        }
    }

    static func indexAll(context: ModelContext) {
        let fetch = FetchDescriptor<Group>(predicate: #Predicate { _ in true })
        guard let groups = try? context.fetch(fetch) else { return }
        var items: [CSSearchableItem] = []
        for g in groups {
            items.append(item(for: g))
            for e in g.expenses {
                items.append(item(for: e, in: g))
            }
        }
        CSSearchableIndex.default().indexSearchableItems(items)
    }

    private static func item(for group: Group) -> CSSearchableItem {
        let attrs = CSSearchableItemAttributeSet(contentType: .text)
        attrs.title = group.name
        attrs.contentDescription = "Group in FairSplit"
        let id = "group:\(String(describing: group.persistentModelID))"
        let item = CSSearchableItem(uniqueIdentifier: id, domainIdentifier: "com.sviftstudios.FairSplit.group", attributeSet: attrs)
        return item
    }

    private static func item(for expense: Expense, in group: Group) -> CSSearchableItem {
        let attrs = CSSearchableItemAttributeSet(contentType: .text)
        attrs.title = expense.title
        var parts: [String] = []
        parts.append("\(CurrencyFormatter.string(from: SplitCalculator.amountInGroupCurrency(for: expense, defaultCurrency: group.defaultCurrency), currencyCode: group.defaultCurrency)) — \(group.name)")
        if let note = expense.note, !note.isEmpty { parts.append(note) }
        attrs.contentDescription = parts.joined(separator: "\n")
        let id = "expense:\(String(describing: expense.persistentModelID))"
        let item = CSSearchableItem(uniqueIdentifier: id, domainIdentifier: "com.sviftstudios.FairSplit.expense", attributeSet: attrs)
        return item
    }
}

