import Foundation
import Security
import LocalAuthentication
import CryptoKit

// Credentials are stored in the current user's Keychain, never in UserDefaults or the application bundle.
enum ProviderKind: String, CaseIterable, Identifiable {
    case jamf = "Jamf Pro"
    case iru = "Iru / Kandji"
    case abm = "Apple Business Manager"
    var id: String { rawValue }
    var key: String { switch self { case .jamf: return "jamf"; case .iru: return "iru"; case .abm: return "abm" } }
}

struct ProviderRecord: Identifiable {
    let id = UUID()
    let provider: ProviderKind
    let serial: String
    let model: String?
    let deviceName: String?
    let user: String?
    let lastSeen: String?
    let dateAdded: String?
    let status: String?
}

enum ProviderError: LocalizedError {
    case configuration(String), network(String), invalidResponse, noMatch
    var errorDescription: String? {
        switch self {
        case .configuration(let message), .network(let message): return message
        case .invalidResponse: return "The provider returned an unexpected response."
        case .noMatch: return "No matching device was found."
        }
    }
}

enum ProviderCredentials {
    // Preserve the established Keychain service; add versioned per-provider accounts.
    private static let service = "My Mac Status Community Edition — Provider Credentials"
    private static let legacyService = "org.example.mymacstatus.community.providers" // Keep old Keychain service for backward compatibility; do not rename.
    private static let lock = NSLock()
    private static var sessionCache: [String: String] = [:]

    // Every background read uses an LAContext that cannot present authentication UI.
    // This is defense in depth in addition to kSecUseAuthenticationUIFail.
    private static func noninteractiveContext() -> LAContext {
        let context = LAContext()
        context.interactionNotAllowed = true
        return context
    }

    private static func logReadFailure(_ status: OSStatus, providerKey: String) {
        // Never log credential values, payloads, tokens, or signing keys.
        if status != errSecItemNotFound {
            NSLog("My Mac Status: noninteractive credential access unavailable (key=%@, OSStatus=%d)", providerKey, status)
        }
    }

    private static func query(_ key: String, serviceName: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: serviceName,
         kSecAttrAccount as String: key]
    }

    private static func fetch(_ key: String, serviceName: String, allowInteraction: Bool = false) -> String? {
        var request = query(key, serviceName: serviceName)
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        // Runtime reads must never display macOS Keychain authorization dialogs.
        request[kSecUseAuthenticationUI as String] = allowInteraction ? kSecUseAuthenticationUIAllow : kSecUseAuthenticationUIFail
        if !allowInteraction {
            request[kSecUseAuthenticationContext as String] = noninteractiveContext()
        }
        var result: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            if !allowInteraction { logReadFailure(status, providerKey: key) }
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    // Fix 2: one credential item per provider. Existing individual items remain
    // readable, but are never migrated or deleted during a device lookup.
    private static func bundleKey(_ kind: ProviderKind) -> String { "\(kind.key).credentials.v2" }

    static func bundled(_ kind: ProviderKind, allowInteraction: Bool = false) -> [String: String]? {
        guard let raw = read(bundleKey(kind), allowInteraction: allowInteraction),
              let data = raw.data(using: .utf8),
              let fields = try? JSONDecoder().decode([String: String].self, from: data) else { return nil }
        return fields
    }

    static func saveBundle(_ kind: ProviderKind, fields: [String: String]) -> Bool {
        guard let data = try? JSONEncoder().encode(fields),
              let value = String(data: data, encoding: .utf8) else { return false }
        return write(value, key: bundleKey(kind))
    }

    // Existence checks never request secret data and therefore do not need to
    // unlock each credential. A real lookup reads only its selected provider.
    private static func exists(_ key: String) -> Bool {
        lock.lock(); let cached = sessionCache[key]; lock.unlock()
        if cached != nil { return true }
        var request = query(key, serviceName: service)
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        request[kSecReturnAttributes as String] = true
        request[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIFail
        request[kSecUseAuthenticationContext as String] = noninteractiveContext()
        var result: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &result)
        return status == errSecSuccess || status == errSecInteractionNotAllowed
    }

    static func hasSavedCredential(_ kind: ProviderKind) -> Bool {
        if exists(bundleKey(kind)) { return true }
        switch kind {
        case .jamf: return (exists("jamf.clientID") && exists("jamf.clientSecret")) || exists("jamf.token")
        case .iru: return exists("iru.token")
        case .abm: return (exists("abm.clientID") && exists("abm.keyID") && exists("abm.privateKey")) || exists("abm.token")
        }
    }

    // Explicit, non-destructive consolidation of existing individual items.
    // May require one-time authorization; never runs during Check Date.
    static func consolidateExisting(for kind: ProviderKind) -> String {
        if bundled(kind, allowInteraction: true) != nil { return "Provider credentials are already consolidated." }
        let keys: [String]
        switch kind {
        case .jamf: keys = ["jamf.clientID", "jamf.clientSecret"]
        case .iru: keys = ["iru.token"]
        case .abm: keys = ["abm.clientID", "abm.keyID", "abm.privateKey"]
        }
        var fields: [String: String] = [:]
        for key in keys {
            guard let value = read(key, allowInteraction: true), !value.isEmpty else {
                return "Not all required credentials are available. Existing credentials were not changed."
            }
            fields[key] = value
        }
        return saveBundle(kind, fields: fields)
            ? "Credentials consolidated successfully. Original Keychain entries were preserved."
            : "Could not save consolidated credentials. Original Keychain entries were preserved."
    }

    // Explicitly user-triggered in Settings > Connections only. Force fresh reads
    // so session cache cannot hide a pending macOS authorization requirement.
    static func authorizeSavedCredentials(for kind: ProviderKind) -> String {
        let bundle = bundleKey(kind)
        if let value = fetch(bundle, serviceName: service, allowInteraction: true), !value.isEmpty {
            lock.lock(); sessionCache[bundle] = value; lock.unlock()
            return "Saved credentials authorized. You can now test the connection."
        }
        let keys: [String]
        switch kind {
        case .jamf: keys = ["jamf.clientID", "jamf.clientSecret"]
        case .iru: keys = ["iru.token"]
        case .abm: keys = ["abm.clientID", "abm.keyID", "abm.privateKey"]
        }
        for key in keys {
            guard let value = fetch(key, serviceName: service, allowInteraction: true), !value.isEmpty else {
                return "Some saved credentials need attention. Re-enter them or import existing credentials here in Connections."
            }
            lock.lock(); sessionCache[key] = value; lock.unlock()
        }
        return "Saved credentials authorized. Consider consolidating them to reduce future authorization requests."
    }

    static func read(_ key: String, allowInteraction: Bool = false) -> String? {
        lock.lock()
        let cached = sessionCache[key]
        lock.unlock()
        if let cached, !allowInteraction { return cached }
        if let current = fetch(key, serviceName: service, allowInteraction: allowInteraction) {
            lock.lock(); sessionCache[key] = current; lock.unlock()
            return current
        }
        // Never access legacy Keychain items during a lookup. A migration is
        // explicitly initiated by the user in Connections settings.
        return nil
    }

    // Explicit, non-destructive migration. Only missing current entries are copied.
    // No legacy items are deleted, even after successful verification.
    static func migrateLegacy(for provider: ProviderKind) -> String {
        let keys: [String]
        switch provider {
        case .jamf: keys = ["jamf.clientID", "jamf.clientSecret", "jamf.token"]
        case .iru: keys = ["iru.token"]
        case .abm: keys = ["abm.clientID", "abm.keyID", "abm.privateKey", "abm.token"]
        }
        var copied = 0
        var failed = 0
        for key in keys {
            if fetch(key, serviceName: service, allowInteraction: true) != nil { continue }
            guard let legacy = fetch(key, serviceName: legacyService, allowInteraction: true), !legacy.isEmpty else { continue }
            if write(legacy, key: key) { copied += 1 } else { failed += 1 }
        }
        if failed > 0 { return "Some credentials could not be imported. Existing credentials were preserved. You can retry or save new credentials." }
        if copied == 0 { return "No additional credentials were imported. Existing credentials were left unchanged." }
        return "Imported \(copied) credential(s). Original credentials were preserved."
    }

    static func write(_ value: String, key: String) -> Bool {
        let item = query(key, serviceName: service)
        let status: OSStatus
        if value.isEmpty {
            let current = SecItemDelete(item as CFDictionary)
            status = (current == errSecSuccess || current == errSecItemNotFound) ? errSecSuccess : errSecAuthFailed
        } else {
            let update: [String: Any] = [kSecValueData as String: Data(value.utf8),
                                         kSecAttrLabel as String: "My Mac Status — Provider Credentials"]
            let existing = SecItemUpdate(item as CFDictionary, update as CFDictionary)
            if existing == errSecItemNotFound {
                var attrs = item
                attrs[kSecValueData as String] = Data(value.utf8)
                attrs[kSecAttrLabel as String] = "My Mac Status — Provider Credentials"
                attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
                status = SecItemAdd(attrs as CFDictionary, nil)
            } else { status = existing }
        }
        guard status == errSecSuccess else { return false }
        lock.lock()
        if value.isEmpty { sessionCache.removeValue(forKey: key) }
        else { sessionCache[key] = value }
        lock.unlock()
        return true
    }
}

struct ProviderSettings {
    static func endpoint(_ kind: ProviderKind) -> String {
        UserDefaults.standard.string(forKey: "provider.\(kind.key).endpoint") ?? ""
    }
    static func setEndpoint(_ value: String, for kind: ProviderKind) {
        UserDefaults.standard.set(value.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "provider.\(kind.key).endpoint")
    }
    static func credential(_ kind: ProviderKind) -> String? {
        ProviderCredentials.bundled(kind)?["\(kind.key).token"]
    }
    static func setCredential(_ value: String, for kind: ProviderKind) -> Bool {
        ProviderCredentials.saveBundle(kind, fields: ["\(kind.key).token": value.trimmingCharacters(in: .whitespacesAndNewlines)])
    }
}

// Increment 4: provider-specific credential models. Legacy bearer tokens remain readable
// for compatibility until each provider's new authentication flow is validated.
struct JamfClientCredentials { let clientID: String; let clientSecret: String }
struct IruAPICredentials { let apiToken: String }
struct AppleBusinessCredentials { let clientID: String; let keyID: String; let privateKeyPEM: String }

// Successful authentication is distinct from saving credentials. A verification stamp is
// written only after a provider has accepted an authenticated API request.
enum ProviderVerification {
    static func verifiedAt(_ kind: ProviderKind) -> Date? {
        UserDefaults.standard.object(forKey: "provider.\(kind.key).verifiedAt") as? Date
    }
    static func markVerified(_ kind: ProviderKind) {
        UserDefaults.standard.set(Date(), forKey: "provider.\(kind.key).verifiedAt")
    }
    static func clear(_ kind: ProviderKind) {
        UserDefaults.standard.removeObject(forKey: "provider.\(kind.key).verifiedAt")
    }
}

private actor OAuthTokenCache {
    static let shared = OAuthTokenCache()
    private struct Entry { let token: String; let expiry: Date }
    private var entries: [String: Entry] = [:]
    func valid(_ key: String) -> String? {
        guard let item = entries[key], item.expiry.timeIntervalSinceNow > 90 else { return nil }
        return item.token
    }
    func store(_ token: String, lifetime: TimeInterval, key: String) {
        entries[key] = Entry(token: token, expiry: Date().addingTimeInterval(max(0, lifetime)))
    }
    func invalidate(_ key: String) { entries.removeValue(forKey: key) }
}

enum ProviderAuthentication {
    static func jamfCredentials() -> JamfClientCredentials? {
        if let fields = ProviderCredentials.bundled(.jamf),
           let id = fields["jamf.clientID"], !id.isEmpty,
           let secret = fields["jamf.clientSecret"], !secret.isEmpty {
            return .init(clientID: id, clientSecret: secret)
        }
        // Fix 5: never fall back to legacy individual Keychain items during
        // background authentication. Explicit consolidation belongs in Connections.
        NSLog("My Mac Status: Jamf consolidated credentials unavailable; open Settings > Connections")
        return nil
    }
    static func appleCredentials() -> AppleBusinessCredentials? {
        if let fields = ProviderCredentials.bundled(.abm),
           let id = fields["abm.clientID"], !id.isEmpty,
           let key = fields["abm.keyID"], !key.isEmpty,
           let pem = fields["abm.privateKey"], !pem.isEmpty {
            return .init(clientID: id, keyID: key, privateKeyPEM: pem)
        }
        // Fix 5: ABM's three legacy items must not be fetched by Check Date.
        // Users can authorize and consolidate them explicitly in Connections.
        NSLog("My Mac Status: ABM consolidated credentials unavailable; open Settings > Connections")
        return nil
    }
    static func saveJamf(clientID: String, secret: String) -> Bool {
        guard !clientID.isEmpty, !secret.isEmpty else { return false }
        ProviderVerification.clear(.jamf)
        return ProviderCredentials.saveBundle(.jamf, fields: ["jamf.clientID": clientID, "jamf.clientSecret": secret])
    }
    static func saveApple(clientID: String, keyID: String, privateKeyPEM: String) -> Bool {
        guard !clientID.isEmpty, !keyID.isEmpty, !privateKeyPEM.isEmpty,
              (try? P256.Signing.PrivateKey(pemRepresentation: privateKeyPEM)) != nil else { return false }
        ProviderVerification.clear(.abm)
        return ProviderCredentials.saveBundle(.abm, fields: ["abm.clientID": clientID, "abm.keyID": keyID, "abm.privateKey": privateKeyPEM])
    }
    static func remove(_ kind: ProviderKind) -> Bool {
        ProviderVerification.clear(kind)
        let keys: [String]
        switch kind {
        case .jamf: keys = ["jamf.clientID", "jamf.clientSecret", "jamf.token"]
        case .iru: keys = ["iru.token"]
        case .abm: keys = ["abm.clientID", "abm.keyID", "abm.privateKey", "abm.token"]
        }
        // Removing a connection is explicitly user initiated. Remove the bundled
        // entry as well as older per-field entries for this provider only.
        return (keys + ["\(kind.key).credentials.v2"]).map { ProviderCredentials.write("", key: $0) }.allSatisfy { $0 }
    }
    static func hasCredential(_ kind: ProviderKind) -> Bool {
        return ProviderCredentials.hasSavedCredential(kind)
    }
    private static func encoded(_ value: String) -> String {
        let safe = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return value.addingPercentEncoding(withAllowedCharacters: safe) ?? ""
    }
    private static func requestToken(_ url: URL, fields: [(String, String)], provider: String) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 25
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = Data(fields.map { "\(encoded($0.0))=\(encoded($0.1))" }.joined(separator: "&").utf8)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ProviderError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            // Only expose documented OAuth error codes/descriptions. Never echo raw
            // response bodies, JWT assertions, access tokens, or credentials.
            var detail = ""
            if let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-. "))
                let code = (payload["error"] as? String ?? "")
                    .unicodeScalars.filter { allowed.contains($0) }.map(String.init).joined()
                if !code.isEmpty { detail = " OAuth error: \(String(code.prefix(80)))." }
            }
            throw ProviderError.network("\(provider) authentication failed (HTTP \(http.statusCode)).\(detail) Verify client ID, key ID, signing key, JWT configuration, and API access.")
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["access_token"] as? String, !token.isEmpty else { throw ProviderError.invalidResponse }
        let seconds = (json["expires_in"] as? NSNumber)?.doubleValue ?? 900
        await OAuthTokenCache.shared.store(token, lifetime: seconds, key: provider)
        return token
    }
    private static func base64URL(_ data: Data) -> String {
        data.base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
    private static func appleAssertion(_ credentials: AppleBusinessCredentials) throws -> String {
        let audience = "https://account.apple.com/auth/oauth2/v2/token"
        let now = Int(Date().timeIntervalSince1970)
        let header: [String: Any] = ["alg": "ES256", "kid": credentials.keyID, "typ": "JWT"]
        let claims: [String: Any] = ["iss": credentials.clientID, "sub": credentials.clientID,
                                     "aud": audience, "iat": now, "exp": now + 300, "jti": UUID().uuidString]
        let headerData = try JSONSerialization.data(withJSONObject: header, options: [.sortedKeys])
        let claimData = try JSONSerialization.data(withJSONObject: claims, options: [.sortedKeys])
        let unsigned = "\(base64URL(headerData)).\(base64URL(claimData))"
        let key: P256.Signing.PrivateKey
        do { key = try P256.Signing.PrivateKey(pemRepresentation: credentials.privateKeyPEM) }
        catch { throw ProviderError.configuration("Apple Business signing key is not a valid P-256 PEM private key.") }
        let signature = try key.signature(for: Data(unsigned.utf8))
        return "\(unsigned).\(base64URL(signature.rawRepresentation))"
    }
    static func invalidateToken(for kind: ProviderKind) async {
        await OAuthTokenCache.shared.invalidate(kind.key)
    }
    static func accessToken(for kind: ProviderKind, endpoint: String) async throws -> String {
        if kind == .jamf, let credentials = jamfCredentials() {
            guard let base = URL(string: endpoint), base.scheme == "https", base.host != nil,
                  base.user == nil, base.password == nil, base.query == nil, base.fragment == nil,
                  var components = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
                throw ProviderError.configuration("Enter a valid HTTPS Jamf Pro server URL.")
            }
            if let cached = await OAuthTokenCache.shared.valid(kind.key) { return cached }
            components.path = "/api/oauth/token"
            guard let url = components.url else { throw ProviderError.invalidResponse }
            return try await requestToken(url, fields: [
                ("grant_type", "client_credentials"), ("client_id", credentials.clientID),
                ("client_secret", credentials.clientSecret)], provider: kind.key)
        }
        if kind == .abm, let credentials = appleCredentials() {
            if let cached = await OAuthTokenCache.shared.valid(kind.key) { return cached }
            let assertion = try appleAssertion(credentials)
            guard let url = URL(string: "https://account.apple.com/auth/oauth2/token") else { throw ProviderError.invalidResponse }
            return try await requestToken(url, fields: [
                ("grant_type", "client_credentials"), ("client_id", credentials.clientID),
                ("client_assertion_type", "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"),
                ("client_assertion", assertion), ("scope", "business.api")], provider: kind.key)
        }
        let token = ProviderCredentials.bundled(kind)?["\(kind.key).token"] ?? ProviderSettings.credential(kind)
        guard let token, !token.isEmpty else {
            throw ProviderError.configuration("Connection needs attention. Open Settings → Connections to review your saved credentials.")
        }
        return token
    }
}

enum ProviderLookup {
    static func lookup(_ kind: ProviderKind, serial: String) async throws -> ProviderRecord {
        let rawEndpoint = ProviderSettings.endpoint(kind)
        let token = try await ProviderAuthentication.accessToken(for: kind, endpoint: rawEndpoint)
        guard !serial.isEmpty else { throw ProviderError.configuration("The local serial number is unavailable.") }
        let base: String
        if kind == .abm { base = "https://api-business.apple.com" }
        else {
            guard let url = URL(string: rawEndpoint), url.scheme == "https", url.host != nil,
                  url.user == nil, url.password == nil, url.query == nil, url.fragment == nil else {
                throw ProviderError.configuration("Enter a valid HTTPS provider API URL without a path or query.")
            }
            base = url.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        var parts = URLComponents(string: base)!
        switch kind {
        case .jamf:
            parts.path = "/api/v2/computers-inventory"
            let safeSerial = serial.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            parts.queryItems = [URLQueryItem(name: "filter", value: "hardware.serialNumber==\"\(safeSerial)\""),
                                URLQueryItem(name: "section", value: "GENERAL,HARDWARE,USER_AND_LOCATION"),
                                URLQueryItem(name: "page-size", value: "10")]
        case .iru:
            parts.path = "/api/v1/devices"
            parts.queryItems = [URLQueryItem(name: "serial_number", value: serial), URLQueryItem(name: "limit", value: "20")]
        case .abm:
            parts.path = "/v1/orgDevices"
            parts.queryItems = [URLQueryItem(name: "limit", value: "1000")]
        }
        guard let url = parts.url else { throw ProviderError.invalidResponse }
        var nextURL: URL? = url
        var pages = 0
        while let current = nextURL {
            pages += 1
            guard pages <= (kind == .abm ? 100 : 1) else { throw ProviderError.network("Pagination safety limit reached.") }
            var request = URLRequest(url: current)
            request.timeoutInterval = 25
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw ProviderError.invalidResponse }
            guard (200...299).contains(http.statusCode) else {
                if http.statusCode == 401 {
                    await ProviderAuthentication.invalidateToken(for: kind)
                    ProviderVerification.clear(kind)
                }
                throw ProviderError.network("\(kind.rawValue) returned HTTP \(http.statusCode). Check credentials, permissions, and endpoint.")
            }
            let payload = try JSONSerialization.jsonObject(with: data)
            let object = payload as? [String: Any] ?? [:]
            guard kind == .iru ? (payload is [[String: Any]] || payload is [String: Any]) : (payload is [String: Any]) else {
                throw ProviderError.invalidResponse
            }
            ProviderVerification.markVerified(kind)
            let records: [[String: Any]]
            switch kind {
            case .jamf: records = object["results"] as? [[String: Any]] ?? []
            case .iru: records = (payload as? [[String: Any]]) ?? (object["results"] as? [[String: Any]]) ?? (object["devices"] as? [[String: Any]]) ?? []
            case .abm: records = object["data"] as? [[String: Any]] ?? []
            }
            for record in records {
                let hardware = record["hardware"] as? [String: Any] ?? [:]
                let general = record["general"] as? [String: Any] ?? [:]
                let attributes = record["attributes"] as? [String: Any] ?? [:]
                let user = record["userAndLocation"] as? [String: Any] ?? [:]
                let found = (hardware["serialNumber"] as? String) ?? (record["serial_number"] as? String) ?? (attributes["serialNumber"] as? String) ?? ""
                guard found.caseInsensitiveCompare(serial) == .orderedSame else { continue }
                return ProviderRecord(provider: kind, serial: found,
                    model: (hardware["model"] as? String) ?? (record["model"] as? String) ?? (attributes["deviceModel"] as? String),
                    deviceName: (general["name"] as? String) ?? (record["device_name"] as? String),
                    user: (user["username"] as? String) ?? (record["user"] as? String),
                    lastSeen: (general["lastContactTime"] as? String) ?? (record["last_check_in"] as? String),
                    dateAdded: attributes["addedToOrgDateTime"] as? String,
                    status: (attributes["status"] as? String) ?? (record["device_status"] as? String))
            }
            nextURL = nil
            if kind == .abm {
                let links = object["links"] as? [String: Any] ?? [:]
                if let next = links["next"] as? String, let candidate = URL(string: next, relativeTo: current)?.absoluteURL,
                   candidate.scheme == "https", candidate.host == "api-business.apple.com" { nextURL = candidate }
            }
        }
        throw ProviderError.noMatch
    }
}


// Fix 5: read-only provider connectivity checks, independent of device lookup.
// A successful OAuth exchange alone is not considered a verified connection.
enum ProviderConnectionTest {
    static func run(_ kind: ProviderKind) async throws -> Date {
        guard ProviderAuthentication.hasCredential(kind) else {
            throw ProviderError.configuration("Save credentials before testing this connection.")
        }
        let raw = ProviderSettings.endpoint(kind)
        let token = try await ProviderAuthentication.accessToken(for: kind, endpoint: raw)
        let base: URL
        if kind == .abm {
            base = URL(string: "https://api-business.apple.com")!
        } else {
            guard let url = URL(string: raw), url.scheme == "https", url.host != nil,
                  url.user == nil, url.password == nil, url.query == nil, url.fragment == nil else {
                throw ProviderError.configuration("Enter a valid HTTPS provider API URL.")
            }
            base = url
        }
        guard var components = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
            throw ProviderError.invalidResponse
        }
        switch kind {
        case .jamf:
            components.path = "/api/v2/computers-inventory"
            components.queryItems = [URLQueryItem(name: "page-size", value: "1")]
        case .iru:
            // Fix 5.1: Match the independently verified Kandji API request exactly.
            // The user's successful curl check uses GET /api/v1/devices without
            // query parameters. Keep device lookup's filtered request unchanged.
            components.path = "/api/v1/devices"
            components.queryItems = nil
        case .abm:
            components.path = "/v1/orgDevices"
            components.queryItems = [URLQueryItem(name: "limit", value: "1")]
        }
        guard let url = components.url else { throw ProviderError.invalidResponse }
        var request = URLRequest(url: url)
        request.timeoutInterval = 25
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ProviderError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 401 { await ProviderAuthentication.invalidateToken(for: kind) }
            let guidance: String
            switch http.statusCode {
            case 401: guidance = "Authentication rejected. Check or renew credentials."
            case 403: guidance = "Authenticated, but read-only inventory permission is missing."
            case 404: guidance = "Inventory endpoint not found. Check the provider URL."
            case 429: guidance = "Provider rate limit reached. Try again later."
            case 500...599: guidance = "Provider service is unavailable. Try again later."
            default: guidance = "Check the provider endpoint and permissions."
            }
            throw ProviderError.network("HTTP \(http.statusCode). \(guidance)")
        }
        // Fix 5.2: Kandji's /api/v1/devices returns a top-level JSON array.
        // Preserve the existing object contract for Jamf Pro and ABM.
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            throw ProviderError.invalidResponse
        }
        switch kind {
        case .iru:
            guard json is [[String: Any]] else { throw ProviderError.invalidResponse }
        case .jamf, .abm:
            guard json is [String: Any] else { throw ProviderError.invalidResponse }
        }
        ProviderVerification.markVerified(kind)
        return Date()
    }
}
