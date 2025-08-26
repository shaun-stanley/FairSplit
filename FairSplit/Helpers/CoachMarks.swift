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

enum Tips {
    @available(iOS 17.0, *)
    static let addExpense = AddExpenseTip()

    static func configure() {
        if #available(iOS 17.0, *) {
            try? TipKit.Tips.configure()
        }
    }
}
#endif

