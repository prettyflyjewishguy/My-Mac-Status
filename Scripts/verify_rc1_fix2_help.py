#!/usr/bin/env python3
from pathlib import Path
r=Path(__file__).resolve().parents[1]
v=(r/'Sources/Views/CommunityHelpView.swift').read_text()
s=(r/'Sources/Services/SupportService.swift').read_text()
assert 'width: 1050, height: 740' in s
assert 'width: 850, height: 540' in s
assert 'min: 250, ideal: 270, max: 310' in v
assert '.lineSpacing(3)' in v and '.primary.opacity(0.82)' in v
assert 'VStack(alignment: .leading, spacing: 17)' in v
assert 'CommunityHelpView()' in s
print('RC1 Fix 2 static Help layout checks passed; macOS compilation and visual QA remain required.')
