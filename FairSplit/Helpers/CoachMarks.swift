import Foundation

#if canImport(TipKit)
import TipKit
import SwiftUI

@available(iOS 17.0, *)
struct AddExpenseTip: Tip {
    var title: Text { Text("Add your first expense") }
    var message: Text? { Text("Log who paid and split it fairly.") }
    var image: Image? { Image(systemName: "plus.circle") }
}

enum AppTips {
    @available(iOS 17.0, *)
    static let addExpense = AddExpenseTip()
    @available(iOS 17.0, *)
    static let addItemized = SimpleTip(title: "Itemize a bill", message: "Break a bill into items, tax, and tip.", systemImage: "list.bullet.rectangle.portrait")
    @available(iOS 17.0, *)
    static let addRecurring = SimpleTip(title: "Make it recurring", message: "Set rent or subscriptions to auto-add.", systemImage: "arrow.triangle.2.circlepath")
    @available(iOS 17.0, *)
    static let settleUp = SimpleTip(title: "Settle up", message: "See who should pay whom to get even.", systemImage: "arrow.right.circle")
    @available(iOS 17.0, *)
    static let addMember = SimpleTip(title: "Add people", message: "Add members or import from Contacts.", systemImage: "person.crop.circle.badge.plus")
    @available(iOS 17.0, *)
    static let filters = SimpleTip(title: "Filter & share", message: "Search, export CSV, or share a summary.", systemImage: "line.3.horizontal.decrease.circle")
    @available(iOS 17.0, *)
    static let addGroup = SimpleTip(title: "Create a group", message: "Start a trip, dinner, or roommates group.", systemImage: "person.3")
    @available(iOS 17.0, *)
    static let recordSettlement = SimpleTip(title: "Record settlement", message: "Save transfers when people pay up.", systemImage: "checkmark.circle")

    static func configure() {
        if #available(iOS 17.0, *) {
            try? TipKit.Tips.configure()
        }
    }
}
#endif

// MARK: - SimpleTip helper
#if canImport(TipKit)
import TipKit
import SwiftUI

@available(iOS 17.0, *)
struct SimpleTip: Tip {
    var title: Text
    var message: Text?
    var image: Image?

    init(title: String, message: String? = nil, systemImage: String? = nil) {
        self.title = Text(LocalizedStringKey(title))
        if let message { self.message = Text(LocalizedStringKey(message)) } else { self.message = nil }
        if let systemImage { self.image = Image(systemName: systemImage) } else { self.image = nil }
    }
}
#endif
