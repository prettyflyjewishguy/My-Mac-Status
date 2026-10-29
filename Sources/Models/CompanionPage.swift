import Foundation

enum CompanionPage: String, CaseIterable, Identifiable, Hashable {
    case dashboard = "Dashboard"
    case macHealth = "Mac Health"
    case batteryHealth = "Battery Health"
    case storage = "Storage"
    case appleCare = "Mac Details"
    case diagnostics = "Diagnostics"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .macHealth: return "heart.text.square"
        case .batteryHealth: return "battery.75percent"
        case .storage: return "internaldrive"
        case .appleCare: return "calendar.badge.clock"
        case .diagnostics: return "stethoscope"
        }
    }
}
