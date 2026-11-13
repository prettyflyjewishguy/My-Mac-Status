import Foundation

enum CompanionPage: String, CaseIterable, Identifiable, Hashable {
    case dashboard = "Overview"
    case insights = "Device Insights"
    case macHealth = "Health & Security"
    case batteryHealth = "Battery"
    case storage = "Storage"
    case appleCare = "Mac Details"
    case diagnostics = "Diagnostics"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .insights: return "chart.bar.doc.horizontal"
        case .dashboard: return "square.grid.2x2"
        case .macHealth: return "heart.text.square"
        case .batteryHealth: return "battery.75percent"
        case .storage: return "internaldrive"
        case .appleCare: return "calendar.badge.clock"
        case .diagnostics: return "stethoscope"
        }
    }
}
