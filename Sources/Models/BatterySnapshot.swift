import Foundation

struct BatterySnapshot {
    var charge: Int?
    var maxCapacity: Int?
    var cycles: Int?
    var condition = "Unavailable"
    var connected: Bool?
    var charging: Bool?
    var watts: Int?
    var captured = Date()
    var error: String?

    var headline: String {
        if let charge { return "\(charge)%" }
        return "—"
    }
    var advice: String {
        let state = condition.lowercased()
        if state.contains("service") || state.contains("replace") || state.contains("poor") {
            return "Your Mac reports a battery that may need service. Contact the support team for help."
        }
        return "Experiencing battery or charging issues? Contact the support team."
    }
}

