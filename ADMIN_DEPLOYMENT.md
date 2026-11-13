# Administrator Deployment Guide — My Mac Status CE 2.0

## 1. Prepare and deploy
Build using `Scripts/build_on_mac.zsh` on a supported Mac; run `Scripts/validate_on_mac.zsh`. Sign and notarize the application/installer using your organization's distribution workflow, then pilot before production deployment. The application bundle ID is **`com.prettyfly.mymacstatus`** and the managed preferences payload type **must match exactly**. macOS 14+; current script targets arm64.

## 2. Managed preferences
Deploy a **Custom Settings / preference domain** configuration using a forced MDM payload with `PayloadType=com.prettyfly.mymacstatus`. Only forced values are read. Deploy through Jamf Pro, Iru, or another capable MDM. Do not rely on `defaults write` for managed configuration.

| Key | Type | Meaning |
|---|---|---|
| `BrandingEnabled` | Boolean | Enable managed logo image in supported content locations; independent of brand colors. |
| `BrandingImageURL` | String (HTTPS URL) | Default hosted image fallback. |
| `BrandingImageURLLight` | String (HTTPS URL) | Light-appearance logo. |
| `BrandingImageURLDark` | String (HTTPS URL) | Dark-appearance logo. |
| `BrandingImageBase64` | String | Optional embedded Base64 image; when valid, takes precedence over URLs. |
| `BrandingImageWidth` | Integer | Requested image width, clamped 48–320; default 165. |
| `BrandingImageHeight` | Integer | Requested image height, clamped 20–100; default 48. |
| `BrandPrimaryColor` | String | Primary brand color, `#RRGGBB`. |
| `BrandSecondaryColor` | String | Secondary brand color, `#RRGGBB`. |
| `BrandAccentColor` | String | Controls and accent color, `#RRGGBB`. |
| `BrandSelectionColor` | String | Selected sidebar item background, `#RRGGBB`. |
| `HideSettingsAndConnections` | Boolean | Hide Settings sidebar entry; settings access restricted. |
| `HideHelpAndDocumentation` | Boolean | Hide Help sidebar entry and disable corresponding Help menu action. |
| `ConnectorURL` | String (HTTPS URL) | Optional organization-controlled connector service endpoint; not a credential. |
| `JamfProURL` | String (HTTPS URL) | Optional Jamf Pro server endpoint. |
| `IruTenantURL` | String (HTTPS URL) | Optional Iru tenant endpoint. |
| `ABMOrganizationID` | String | Optional Apple Business Manager organization identifier. |

**All branding options are present in the consolidated sample** except `BrandingImageBase64`, which is intentionally documented but omitted from the sample payload: a placeholder Base64 value would override working hosted logo URLs. To use embedded branding, add the key with actual encoded image bytes; remove URL keys if unnecessary.

## 3. Consolidated sample profile
`ManagedDeployment/v2.0-Consolidated-Branding-Example.mobileconfig` includes all four colors, logo URL variants, image dimensions, and both visibility controls. Replace `assets.example.com` with your HTTPS image host before installing. Adjust colors for contrast in both appearances. For user-accessible Settings/Help, change the two `Hide...` values to false. Logo branding never replaces the native window title or toolbar.

## 4. Lifecycle and reactive behavior
The theme manager checks for forced preference changes about every 15 seconds and when the app becomes active; brand colors should update without a restart. Removing the managed profile restores default colors and sidebar behavior. Verify actual image refresh separately: logo downloading/caching follows its own code path and may not hot-reload on profile changes.

## 5. Migration from earlier candidates
Remove old profiles for `org.example.mymacstatus` (and any `com.example.mymacstatus` experiments); deploy the new domain. macOS treats the changed bundle identifier as a distinct app. Verify signing, installed app replacement, launch permissions, privacy prompts, saved provider credentials and Keychain access. Do not assume existing tokens migrate automatically. The legacy Keychain service literal remains intentionally unchanged in source.

## 6. Security and rollout
Never distribute passwords, API tokens, private keys or bearer tokens in MDM preferences. Use least-privilege provider access and macOS Keychain where supported. Serve logos over HTTPS from a trusted organizational host; avoid exposing private device data in image URLs. Validate managed restrictions, light/dark contrast, no-profile fallback, network-offline behavior and update cadence on a small pilot fleet before wider rollout.
