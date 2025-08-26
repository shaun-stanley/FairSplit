import Foundation

enum ExpenseCategory: String, CaseIterable, Codable, Identifiable {
    case food
    case travel
    case lodging
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .food: return "Food"
        case .travel: return "Travel"
        case .lodging: return "Lodging"
        case .other: return "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .food: return "fork.knife"
        case .travel: return "car"
        case .lodging: return "bed.double"
        case .other: return "tag"
        }
    }
}
