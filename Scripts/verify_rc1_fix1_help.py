#!/usr/bin/env python3
from pathlib import Path
r=Path(__file__).resolve().parents[1]
help_view=(r/'Sources/Views/CommunityHelpView.swift').read_text()
support=(r/'Sources/Services/SupportService.swift').read_text()
root=(r/'Sources/Views/CompanionRootView.swift').read_text()
app=(r/'Sources/MyMacStatusApp.swift').read_text()
assert 'CommunityHelpView()' in support
assert 'SupportService.openHelp()' in root and 'SupportService.openHelp()' in app
assert 'NSHostingController' in support
assert all(x in help_view for x in ['Getting Started','Optional Connections','Replacement Planning','macOS Update Intelligence','Troubleshooting','Jamf Pro','Iru / Kandji','Apple Business Manager'])
assert 'CommunityHelp.html' not in (r/'Scripts/build_on_mac.zsh').read_text()
print('RC1 Fix 1 native Help source checks passed; compile and runtime checks require macOS.')
