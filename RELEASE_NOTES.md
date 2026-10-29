# Community Edition v1.0.0 (Icon Restoration)

Base: user-validated Alpha 1.

Change: restored the original blue Mac-and-heart app icon as the default Community Edition icon, with transparent outer corners and no Veeam branding. The existing macOS build script already supports `Resources/AppIcon.png` and automatically converts it into an `.icns` resource.

The icon remains replaceable by organizations wishing to supply their own branding. No Swift source, runtime functionality, package identifiers, MDM behavior, or build logic was modified.

Validation: ZIP and icon checked; compile, launch, and Dock/Finder icon appearance require macOS validation.

Build: `zsh Scripts/validate_on_mac.zsh`
