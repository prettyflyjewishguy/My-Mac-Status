from pathlib import Path
root = Path(__file__).resolve().parents[1]
health = (root/'Sources/Models/MacHealthCheck.swift').read_text()
policy = (root/'Sources/Models/CommunityInsights.swift').read_text()
service = (root/'Sources/Services/MacHealthService.swift').read_text()
assert '&& $0.id != "mdm"' in health
assert 'expectation == .organization' in policy
assert 'check.id != "mdm"' in policy
assert '"Not Managed", .healthy' in service
assert 'diagnosticHistory' in (root/'Sources/Models/CompanionModel.swift').read_text()
print('Alpha 1 source policy checks passed (not a macOS runtime test)')
