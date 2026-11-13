# Managed Deployment — My Mac Status Community Edition 2.0 GA

The app uses the managed preferences domain **`com.prettyfly.mymacstatus`**. These example configuration profiles are intended for deployment through an MDM solution such as Jamf Pro or Microsoft Intune. Replace example URLs, organization identifiers, and profile identifiers before production deployment.

## Profiles

| File | Purpose |
| --- | --- |
| `Managed-Branding-Example.mobileconfig` | **Authoritative GA branding example**. Includes all supported branding image, sizing, color, and sidebar-visibility options in one profile. |
| `Managed-Preferences-Example.mobileconfig` | Example managed metadata and visibility preferences; placeholder connector/provider URLs are informational, not credentials. |
| `Sidebar-Visibility-Example.mobileconfig` | Minimal example that hides Settings & Connections and Help & Documentation. |

## Branding options

The authoritative branding profile includes `BrandingEnabled`, `BrandingImageURL`, `BrandingImageURLLight`, `BrandingImageURLDark`, `BrandingImageWidth`, `BrandingImageHeight`, `BrandPrimaryColor`, `BrandSecondaryColor`, `BrandAccentColor`, `BrandSelectionColor`, `HideSettingsAndConnections`, and `HideHelpAndDocumentation`.

Image URLs must be accessible to the target Mac. Color values use hexadecimal RGB notation (for example, `#008F47`). Replace all sample branding values with your organization's approved assets and colors. The generic image URL is a fallback where the appearance-specific image is not used.

## Managed preferences

`HideSettingsAndConnections` and `HideHelpAndDocumentation` are Boolean values. `ConnectorURL`, `JamfProURL`, and `IruTenantURL` are example HTTPS metadata strings; `ABMOrganizationID` is an example organization identifier. These metadata fields do not themselves establish authentication or configure a working provider connection.

**Do not put passwords, API client secrets, bearer tokens, or private keys in configuration profiles.** Provider credentials, where supported, belong in the user's macOS Keychain.

## Deployment and validation

1. Choose **one** example profile as the starting point; do not install all three simultaneously, since they share the same preferences domain and overlapping keys.
2. Customize values and ensure the profile's top-level and nested `PayloadIdentifier` values are unique to your organization. Deploy as forced managed preferences using your MDM.
3. Relaunch My Mac Status and confirm branding and sidebar visibility in both light and dark appearance. Verify selection contrast and navigation on each sidebar page.
4. Remove the test profile, relaunch, and confirm that unmanaged defaults return. Validate the exact deployed profile and your signing/notarization workflow on a Mac before GA rollout.

For broader deployment guidance, see [`../ADMIN_DEPLOYMENT.md`](../ADMIN_DEPLOYMENT.md) and [`../docs/BRANDING.md`](../docs/BRANDING.md).
