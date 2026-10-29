import SwiftUI

enum HealthStatus: String {
    case healthy = "Healthy"
    case needsAttention = "Needs Attention"
    case unhealthy = "Unhealthy"
    case unableToVerify = "Information Unavailable"
    case notEvaluated = "Not Checked Yet"

    var color: Color {
        switch self {
        case .healthy: return CompanionStyle.green
        case .needsAttention: return .orange
        case .unhealthy: return .red
        case .unableToVerify, .notEvaluated: return .secondary
        }
    }
    var symbol: String {
        switch self {
        case .healthy: return "checkmark.circle.fill"
        case .needsAttention: return "exclamationmark.triangle.fill"
        case .unhealthy: return "xmark.circle.fill"
        case .unableToVerify, .notEvaluated: return "questionmark.circle.fill"
        }
    }
}
