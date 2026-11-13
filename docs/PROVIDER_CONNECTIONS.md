# Optional provider connections (v1.1.0 development build)

This build preserves the standalone local health experience. Open **Connections** to configure an optional provider, then **Mac Details** to look up the local serial.

- **Jamf Pro:** HTTPS Jamf server URL and a **short-lived OAuth access token** (Read Computers). Filtered `GET /api/v2/computers-inventory` request; no full-fleet download. The app does not yet exchange API client credentials for tokens.
- **Iru / Kandji:** HTTPS API URL shown under Settings → Access and a read-only bearer API token. Uses `GET /api/v1/devices?serial_number=...`; exact serial verified client-side.
- **Apple Business Manager:** A **short-lived Apple Business API OAuth access token**. Uses paginated `GET /v1/orgDevices`, matching serial locally. The API documentation does not guarantee a server-side serial filter on this endpoint. OAuth private-key JWT token generation and renewal are **not yet implemented**, so this integration is experimental and requires externally obtained tokens.

Credentials are stored in the current user's macOS Keychain, not in configuration files or logs. Provider endpoints (not secrets) are stored in UserDefaults. Connections are read-only; no MDM commands or Apple assignments are performed.

**Limitations:** This build is untested on macOS and against real tenants. Jamf token expiration requires manual replacement. ABM token acquisition is not automated. Network requests may fail due to tenant permissions, policy, or schema differences. Do not distribute as production-ready until validated.

**Security:** The default bundle ID `com.prettyfly.mymacstatus` is a placeholder inherited from v1.0.0; choose a permanent identifier before distribution and review Keychain behavior after app updates.
