import Foundation
import SwiftData

@Model
final class Comment {
    var text: String
    var date: Date
    var author: String?

    init(text: String, date: Date = .now, author: String? = nil) {
        self.text = text
        self.date = date
        self.author = author
    }
}

