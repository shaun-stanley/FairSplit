//
//  FairSplitApp.swift
//  FairSplit
//
//  Created by Shaun Stanley on 8/24/25.
//

import SwiftUI
import SwiftData

@main
struct FairSplitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Group.self, Member.self, Expense.self, Settlement.self, RecurringExpense.self, Contact.self, DirectExpense.self, Comment.self, PersonalExpense.self])
    }
}
