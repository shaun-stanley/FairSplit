import Foundation
import SwiftData

@Model
final class Member {
    var name: String

    init(name: String) {
        self.name = name
    }
}

