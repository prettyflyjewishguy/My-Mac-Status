# Community fork change log

- Started from the split-package My Mac Status v1.0.0 source; original baseline untouched.
- Removed ABM backend, credential packaging/provisioning, helper scripts and launchd services.
- Removed Jamf-specific diagnostics, Jamf self-heal and Microsoft Defender-specific health requirements.
- Replaced vendor-specific checks with macOS MDM enrollment only.
- Replaced ABM replacement lookup with honest local hardware details and unavailable lifecycle notice.
- Removed proprietary organization logo, support portal, email and historical internal documentation.
- Added opt-in build-time branding and unbranded default.
- Replaced privileged PKG with app-only PKG.

**Functional difference:** The community fork is not feature-equivalent to the internal app. MDM repair and replacement projections are intentionally not present. No provider plugin system is implemented in this first fork.
