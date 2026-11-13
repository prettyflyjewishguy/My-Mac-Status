#!/usr/bin/env python3
from pathlib import Path
root=Path(__file__).resolve().parents[1]
service=(root/'Sources/Services/ProviderConnections.swift').read_text()
assert 'kSecUseAuthenticationUIFail' in service
assert 'interactionNotAllowed = true' in service
assert 'allowInteraction: Bool = false' in service
assert 'UpdateIntelligenceView()' in (root/'Sources/Views/MacHealthView.swift').read_text()
assert 'Settings & Connections' in (root/'Sources/Views/CompanionRootView.swift').read_text()
print('Source regression checks passed. macOS runtime validation still required.')

assert "DEVELOPMENT BUILD • FEATURE 2.3 FIX 4" in (root/"Sources/Views/CompanionRootView.swift").read_text()
