<div align="center">

<img src="docs/assets/app-icon.png" alt="My Mac Status app icon" width="120" />

# My Mac Status

**Know your Mac at a glance.**

A friendly, native SwiftUI app for macOS health, battery, storage, hardware details, and read-only device-management information.

![My Mac Status social preview](docs/assets/social-preview.png)

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Apple silicon](https://img.shields.io/badge/Apple%20silicon-arm64-brightgreen) ![SwiftUI](https://img.shields.io/badge/SwiftUI-native-orange) [![MIT License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

</div>

## Screenshots

**Screenshots are being prepared.** Images in this section will be actual captures of the validated macOS application, not conceptual mockups. See [screenshot capture instructions](docs/assets/screenshots/README.md).

<!-- Once genuine screenshots are added, uncomment these lines:
![Dashboard](docs/assets/screenshots/dashboard.png)
![Mac Health](docs/assets/screenshots/mac-health.png)
![Battery Health](docs/assets/screenshots/battery-health.png)
![Storage](docs/assets/screenshots/storage.png)
-->

An **unbranded, MDM-agnostic** macOS SwiftUI application for local device health, battery information, storage inspection, hardware details and **read-only** enrollment diagnostics.

This is a **separate community fork** of the internal v1.0.0 application. The original internal release is unchanged. The public fork deliberately **does not ship** private Apple Business Manager integrations, API keys, privileged helpers, Jamf policy repair, or vendor-specific health checks. These are not silently simulated.

## Features
- Dashboard, Mac Health, Battery Health, Storage, Mac hardware details
- Local FileVault, SIP, MDM enrollment, software update and uptime checks
- Read-only enrollment diagnostics (no remote MDM API or remediation)
- Refresh throttling and existing storage scan logic
- Optional logo, icon, accent color and support contact information

## Build (macOS)

Requires Xcode Command Line Tools and macOS SDK with SwiftUI. Run:

```zsh
zsh Scripts/build_on_mac.zsh
```

Build outputs are placed in `output/`. The build uses an ad-hoc signature and creates an unsigned installer; signing/notarization are the downstream distributor's responsibility. The Alpha 2 build and restored icon were compiled and visually checked on macOS by the project author. This packaging environment has not independently built the macOS application.

## Branding

The default build contains no organization logos or support addresses. Optional assets: `Resources/BrandLogo.png` and `Resources/AppIcon.png`. To customize text and support:

```zsh
MYMACSTATUS_BRAND_NAME='Example IT' \
MYMACSTATUS_BRAND_SUBTITLE='Endpoint Support' \
MYMACSTATUS_SUPPORT_EMAIL='support@example.org' \
MYMACSTATUS_SUPPORT_URL='https://support.example.org' \
zsh Scripts/build_on_mac.zsh
```

Accent color defaults to the system accent color; change `CompanionStyle.green` to a chosen `Color` to brand the UI.

## Privacy & security

No credentials, root services, remote reporting, ABM lookups or Jamf repairs are included. The storage scanner reads the current user's home directory and can trigger macOS privacy prompts. It does not bypass TCC. Do not grant Full Disk Access without reviewing the need. The source should be audited and tested on a Mac before public distribution.

## Differences from the internal release

See [FORK_NOTES.md](FORK_NOTES.md) and [SECURITY.md](SECURITY.md). Community edition does not calculate a replacement date because it has no authoritative purchase or inventory date.

## License

Licensed under the [MIT License](LICENSE). Copyright (c) 2026 Ethan Besbris.

## Validation build kit

Run `zsh Scripts/validate_on_mac.zsh` on an Apple silicon Mac. See `Validation/TEST_PLAN.md` for manual test cases and release gates.
