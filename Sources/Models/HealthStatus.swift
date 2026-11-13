import SwiftUI

enum HealthStatus: String {
    case healthy = "Healthy"
    case needsAttention = "Needs Attention"
    case unhealthy = "Unhealthy"
    case unableToVerify = "Information Unavailable"
    case notEvaluated = "Not Checked Yet"

    var color: Color {
        CompanionStyle.StatusTone(health: self).color
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
