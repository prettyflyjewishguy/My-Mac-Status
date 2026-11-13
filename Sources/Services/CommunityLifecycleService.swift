import Foundation

struct CommunityLifecycleResult {
    let found: Bool
    let dateAdded: String?
    let dateLabel: String
    let projectedReplacementDate: String?
    let lifecycleStatus: String?
}

struct CommunityLifecycleState {
    var loading = false
    var data: CommunityLifecycleResult?
    var error: String?
    var lastUpdated: Date?
}

enum LifecycleSettings {
    static var years: Int { max(1, UserDefaults.standard.integer(forKey: "lifecycle.years") == 0 ? 4 : UserDefaults.standard.integer(forKey: "lifecycle.years")) }
    static var policyURL: String { UserDefaults.standard.string(forKey: "lifecycle.policyURL") ?? "" }
}

enum CommunityLifecycleService {
    // ABM is authoritative for registration date; MDM inventory is a fallback.
    // No remote API call occurs unless a provider has a saved credential.
    static func lookup(serial: String) async throws -> CommunityLifecycleResult {
        let configured = [ProviderKind.abm, .jamf, .iru].filter { ProviderAuthentication.hasCredential($0) }
        guard !configured.isEmpty else { throw ProviderError.configuration("Configure a provider in My Mac Status → Settings → Connections to check replacement information.") }
        var failures: [String] = []
        var fallback: ProviderRecord?
        for provider in configured {
            do {
                let record = try await ProviderLookup.lookup(provider, serial: serial)
                if provider == .abm, record.dateAdded.flatMap({ parseDate($0) }) != nil { return result(record, dateLabel: "Device Added (ABM)") }
                if fallback == nil || (fallback?.dateAdded.flatMap({ parseDate($0) }) == nil && record.dateAdded.flatMap({ parseDate($0) }) != nil) { fallback = record }
            } catch { failures.append("\(provider.rawValue): \(error.localizedDescription)") }
        }
        if let fallback { return result(fallback, dateLabel: fallback.dateAdded == nil ? "Device Added" : "Date Added (\(fallback.provider.rawValue))") }
        if !failures.isEmpty {
            throw ProviderError.network("Replacement information is unavailable. Check provider connections in Settings and try again. " + failures.joined(separator: " | "))
        }
        throw ProviderError.noMatch
    }
    private static func result(_ record: ProviderRecord, dateLabel: String) -> CommunityLifecycleResult {
        let raw = record.dateAdded
        var projected: String?
        var status: String?
        if let raw, let date = parseDate(raw), let replacement = Calendar(identifier: .gregorian).date(byAdding: .year, value: LifecycleSettings.years, to: date) {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd"
            projected = formatter.string(from: replacement)
            status = replacement < Date() ? "Replacement estimate reached" : "Current"
        }
        return CommunityLifecycleResult(found: true, dateAdded: raw.flatMap { parseDate($0).map { date in
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.timeZone = TimeZone(secondsFromGMT: 0); return f.string(from: date)
        } }, dateLabel: dateLabel, projectedReplacementDate: projected, lifecycleStatus: status ?? "Information unavailable")
    }
    private static func parseDate(_ raw: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: raw) { return d }
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: raw) { return d }
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.timeZone = TimeZone(secondsFromGMT: 0); f.dateFormat = "yyyy-MM-dd"
        return f.date(from: raw)
    }
}
