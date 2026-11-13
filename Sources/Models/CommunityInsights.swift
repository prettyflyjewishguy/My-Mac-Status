import Foundation

enum ManagementExpectation: String, CaseIterable, Identifiable {
    case automatic = "Automatic"
    case personal = "Personal Mac"
    case organization = "Organization-managed Mac"
    var id: String { rawValue }
}

struct CommunityRecommendation: Identifiable {
    let id: String
    let title: String
    let guidance: String
}

enum CommunityHealthPolicy {
    // Device health and security never inherit a penalty from MDM enrollment.
    static func managementMessage(checks: [MacHealthCheck], expectation: ManagementExpectation) -> String {
        guard let mdm = checks.first(where: { $0.id == "mdm" }) else { return "Not checked" }
        if mdm.value == "Not Managed" && expectation == .organization { return "Management expected — not enrolled" }
        return mdm.value
    }
    static func recommendations(checks: [MacHealthCheck], expectation: ManagementExpectation) -> [CommunityRecommendation] {
        var results: [CommunityRecommendation] = []
        for check in checks where check.severity == .needsAttention || check.severity == .unhealthy {
            guard check.id != "mdm" else { continue }
            let guidance: String
            switch check.id {
            case "filevault": guidance = "Review FileVault in System Settings → Privacy & Security."
            case "sip": guidance = "Review System Integrity Protection with an administrator before changing it."
            case "updates": guidance = "Open System Settings → General → Software Update."
            case "uptime": guidance = "Restart your Mac when convenient."
            default: guidance = check.detail
            }
            results.append(CommunityRecommendation(id: check.id, title: check.title, guidance: guidance))
        }
        if expectation == .organization && checks.contains(where: { $0.id == "mdm" && $0.value == "Not Managed" }) {
            results.append(CommunityRecommendation(id: "expected-mdm", title: "Management enrollment", guidance: "Your organization expects this Mac to be managed. Contact your IT administrator."))
        }
        return results
    }
}
