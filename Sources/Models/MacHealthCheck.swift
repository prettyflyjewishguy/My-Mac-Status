import Foundation

enum CheckSeverity: String { case healthy, needsAttention, unhealthy, unableToVerify }

struct MacHealthCheck: Identifiable {
    let id: String
    let title: String
    let detail: String
    let value: String
    let severity: CheckSeverity
    let symbol: String
}

struct MacHealthSnapshot {
    var checks: [MacHealthCheck] = []
    var checkedAt: Date?
    var isScanning = false

    // One shared severity policy for both summaries. The Dashboard intentionally
    // excludes routine software-update maintenance from overall device health.
    private func status(excludingIDs excluded: Set<String>) -> HealthStatus {
        guard checkedAt != nil else { return .notEvaluated }
        let included = checks.filter { !excluded.contains($0.id) }
        if included.contains(where: { $0.severity == .unhealthy }) { return .unhealthy }
        if included.contains(where: { $0.severity == .needsAttention }) { return .needsAttention }
        if included.contains(where: { $0.severity == .unableToVerify }) { return .unableToVerify }
        return included.isEmpty ? .unableToVerify : .healthy
    }

    var summary: HealthStatus { status(excludingIDs: []) }
    var dashboardSummary: HealthStatus { status(excludingIDs: ["updates"]) }
}
