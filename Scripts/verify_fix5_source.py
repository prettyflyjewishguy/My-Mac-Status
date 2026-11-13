#!/usr/bin/env python3
from pathlib import Path
root=Path(__file__).resolve().parents[1]
s=(root/'Sources/Services/ProviderConnections.swift').read_text()
assert 'kSecUseAuthenticationUIFail' in s and 'interactionNotAllowed = true' in s
assert 'never fall back to legacy individual Keychain items' in s
assert 'ABM consolidated credentials unavailable' in s
assert 'ProviderCredentials.read("abm.clientID")' not in s
assert 'ProviderCredentials.read("jamf.clientID")' not in s
assert 'UpdateIntelligenceView()' in (root/'Sources/Views/MacHealthView.swift').read_text()
assert 'Settings & Connections' in (root/'Sources/Views/CompanionRootView.swift').read_text()
assert 'FEATURE 2.3 FIX 8' in (root/'Sources/Views/CompanionRootView.swift').read_text()
print('Fix 8 source checks passed. macOS build and Keychain runtime validation required.')

assert 'No updates available right now' in (root/'Sources/Views/MacHealthView.swift').read_text()
assert 'minHeight: 52' in (root/'Sources/Views/UpdateIntelligenceView.swift').read_text()
