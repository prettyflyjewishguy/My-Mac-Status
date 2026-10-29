<div align="center">

![My Mac Status](docs/assets/social-preview.png)

**Know your Mac at a glance.**

A friendly, native macOS app that makes it easy to check your Mac’s health, battery, storage, and hardware information—all in one place.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Apple silicon](https://img.shields.io/badge/Apple%20silicon-arm64-brightgreen) ![SwiftUI](https://img.shields.io/badge/SwiftUI-native-orange) [![MIT License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

</div>

## Take a look

### Dashboard
Get a quick overview of your Mac and the things that might need attention.

![My Mac Status Dashboard](docs/assets/screenshots/dashboard.png)

<table>
<tr><td width="50%"><strong>Mac Health</strong><br><img src="docs/assets/screenshots/mac-health.png" alt="Mac Health screen" /></td><td width="50%"><strong>Battery Health</strong><br><img src="docs/assets/screenshots/battery-health.png" alt="Battery Health screen" /></td></tr>
<tr><td><strong>Storage</strong><br><img src="docs/assets/screenshots/storage.png" alt="Storage screen" /></td><td><strong>Mac Details</strong><br><img src="docs/assets/screenshots/mac-details.png" alt="Mac Details screen" /></td></tr>
<tr><td><strong>Diagnostics</strong><br><img src="docs/assets/screenshots/diagnostics.png" alt="Diagnostics screen" /></td><td><strong>Made for macOS</strong><br>Native SwiftUI design with a familiar sidebar, straightforward status indicators, and read-only checks.</td></tr>
</table>

## What it does

- **Dashboard:** See device health, battery charge, available storage, and software-update status at a glance.
- **Mac Health:** Review FileVault encryption, system protection, updates, uptime, and device enrollment.
- **Battery Health:** Check charge, maximum capacity, cycle count, and charging information.
- **Storage:** See available space and scan your home folder for large files and folders. Nothing is deleted.
- **Mac Details:** View local hardware and model information.
- **Diagnostics:** Check MDM enrollment status without making changes to your Mac.

## Get started

**Requirements:** An Apple silicon Mac running macOS 14 or later, plus Xcode Command Line Tools and the macOS SDK to build from source.

This repository provides **source code and a local build script**. The build creates an ad-hoc-signed app and an unsigned installer; it is not a notarized consumer download.

1. Download or clone this repository on your Mac.
2. Open Terminal in the repository folder.
3. Run:

   ```zsh
   zsh Scripts/build_on_mac.zsh
   ```

4. Find the generated application and installer in `output/`.

For local build validation, run `zsh Scripts/validate_on_mac.zsh`.

## Make it yours

My Mac Status supports optional organization branding, including a custom icon, logo, name, and support details. See [Branding & customization](docs/BRANDING.md) for configuration examples.

## Privacy first

My Mac Status reads device information locally. It does not send reports to a remote service, install privileged helpers, or change your device-management configuration. A home-folder storage scan may request macOS privacy permissions; only grant access you are comfortable with. Learn more in [SECURITY.md](SECURITY.md).

## Contributing

Ideas, bug reports, and improvements are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a pull request.

## License

Released under the [MIT License](LICENSE). © 2026 Ethan Besbris.
