# My Mac Status CE 2.0 — Release Notes

## Major release
Version **2.0**, build **2000**. The substantial feature and deployment changes since the earlier Community Edition warrant a major version increment.

### Highlights
- Modern native Overview, Device Insights, Health & Security, Battery, Storage, Mac Details and Diagnostics experience.
- On-demand macOS Update Intelligence, local device health and security checks, and storage exploration.
- Optional Jamf Pro, Iru/Kandji, and ABM inventory connections and replacement-date estimates.
- Managed sidebar restrictions: hide Settings & Connections and Help & Documentation; restricted Help menu action.
- Organization logos via HTTPS image URLs (including light/dark variants) or embedded Base64 image data; configurable display dimensions.
- Four managed brand colors (primary, secondary, accent and selection), accessible selected navigation icon contrast, and appearance-aware presentation.
- Reactive theme reconciliation while running; removing managed preferences restores defaults.
- Native macOS title bar and app identity remain unchanged by managed logos.

### Identity and migration
- Bundle ID and managed preferences domain: `com.prettyfly.mymacstatus`.
- Older `org.example.mymacstatus` / `com.example.mymacstatus` profiles must be replaced; do not leave conflicting payloads.
- Historical Keychain service name is intentionally retained to reduce credential migration disruption. Access across signing/bundle identities still requires testing.

### Limitations
- Managed settings require **forced** MDM preferences, not ordinary local defaults.
- Branding image URL downloads require reachable HTTPS hosting; embedded Base64 image data is an alternative. Color theme reconciliation is periodic (~15 seconds); image refresh behavior is not guaranteed to be equally reactive.
- Provider API credentials are not supplied through configuration profiles; Intune is not supported.
- Build/signing, notarization, package installation and final on-device regression tests remain release gates. This archive is a GA **source release candidate**, not a validated signed binary.
