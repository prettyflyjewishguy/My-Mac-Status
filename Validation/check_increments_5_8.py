from pathlib import Path
root = Path(__file__).resolve().parents[1]
p = (root/'Sources/Services/ProviderConnections.swift').read_text()
l = (root/'Sources/Services/CommunityLifecycleService.swift').read_text()
assert 'private static let legacyService = "com.prettyfly.mymacstatus.community.providers"' in p
assert 'private static let service = "My Mac Status Community Edition — Provider Credentials"' in p
assert 'if write(legacy, key: key)' in p
assert 'SecItemDelete(query(key, serviceName: legacyService)' in p
assert 'let audience = "https://account.apple.com/auth/oauth2/v2/token"' in p
assert 'case .iru: records = (payload as? [[String: Any]])' in p
assert 'ProviderAuthentication.hasCredential($0)' in l
assert 'record.dateAdded.flatMap({ parseDate($0) })' in l
print('PASS: source contract checks for Increments 5–8')
