#!/usr/bin/env python3
from pathlib import Path
r = Path(__file__).resolve().parents[1]
a = (r/'Sources/MyMacStatusApp.swift').read_text()
assert 'CommandGroup(replacing: .appInfo)' in a
assert 'openWindow(id: "about-my-mac-status")' in a
assert 'Window("About My Mac Status", id: "about-my-mac-status")' in a
assert (r/'Sources/Views/AboutMyMacStatusView.swift').is_file()
assert 'DEVELOPMENT BUILD' not in (r/'Sources/Views/CompanionRootView.swift').read_text()
assert 'kSecUseAuthenticationUIFail' in (r/'Sources/Services/ProviderConnections.swift').read_text()
assert 'UpdateIntelligenceView()' in (r/'Sources/Views/MacHealthView.swift').read_text()
assert 'Settings & Connections' in (r/'Sources/Views/CompanionRootView.swift').read_text()
print('RC1 static source checks passed; macOS compilation and runtime validation still required.')
