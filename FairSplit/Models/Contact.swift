import Foundation
import SwiftData

@Model
final class Contact {
    var name: String

    init(name: String) {
        self.name = name
    }
}

