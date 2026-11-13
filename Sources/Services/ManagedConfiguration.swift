import Foundation

/// Non-secret preferences delivered through the app's existing bundle identifier.
/// MDM forced preferences take precedence over local defaults. No credentials belong here.
enum ManagedConfiguration {
    static let domain = "com.prettyfly.mymacstatus"

    private static func managedValue(_ key: String) -> Any? {
        // Only forced MDM preferences qualify as managed; ordinary user defaults do not.
        guard let preferences = CFPreferencesCopyAppValue(key as CFString, domain as CFString) else { return nil }
        guard CFPreferencesAppValueIsForced(key as CFString, domain as CFString) else { return nil }
        return preferences
    }

    static var hideSettingsAndConnections: Bool {
        managedValue("HideSettingsAndConnections") as? Bool ?? false
    }

    static var hideHelpAndDocumentation: Bool {
        managedValue("HideHelpAndDocumentation") as? Bool ?? false
    }

    static var brandingEnabled: Bool { managedValue("BrandingEnabled") as? Bool ?? false }
    static var brandingImageURL: URL? { managedHTTPSURL("BrandingImageURL") }
    static var brandingImageURLLight: URL? { managedHTTPSURL("BrandingImageURLLight") }
    static var brandingImageURLDark: URL? { managedHTTPSURL("BrandingImageURLDark") }
    static var brandingImageBase64: String? { managedValue("BrandingImageBase64") as? String }
    static var brandingImageWidth: Int { max(48, min(320, managedValue("BrandingImageWidth") as? Int ?? 165)) }
    static var brandingImageHeight: Int { max(20, min(100, managedValue("BrandingImageHeight") as? Int ?? 48)) }

    // Branding colors are deliberately independent of BrandingEnabled/logo configuration.
    static func managedBrandColor(_ key: String) -> String? {
        managedValue(key) as? String
    }

    static var connectorURL: URL? {
        guard let value = managedValue("ConnectorURL") as? String,
              let url = URL(string: value),
              url.scheme?.lowercased() == "https",
              url.host != nil, url.user == nil, url.password == nil else { return nil }
        return url
    }

    static var jamfProURL: URL? { managedHTTPSURL("JamfProURL") }
    static var iruTenantURL: URL? { managedHTTPSURL("IruTenantURL") }
    static var abmOrganizationID: String? { managedValue("ABMOrganizationID") as? String }

    static func managedHTTPSURL(_ key: String) -> URL? {
        guard let raw = managedValue(key) as? String,
              let url = URL(string: raw), url.scheme?.lowercased() == "https",
              url.host != nil, url.user == nil, url.password == nil else { return nil }
        return url
    }
}
