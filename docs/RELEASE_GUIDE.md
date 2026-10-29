# Release guide — Community Edition v1.0.0

**License:** MIT, copyright (c) 2026 Ethan Besbris (`LICENSE`).
**Status:** Prepared for GitHub; not uploaded or publicly released.
**Validated baseline:** v1.0.0 icon-restoration build compiled and visually inspected by author; application functionality was validated for Alpha 1. No new Swift or build-script changes in this package.

## Before publishing

1. Confirm the author's distribution rights under applicable employer agreements and the icon's asset provenance.
2. Review staged files for secrets, confidential identifiers and third-party licensing.
3. Create a new repository (`my-mac-status`) with fresh Git history. Do not import internal commits or credential packages.
4. Enable secret scanning/push protection and a private vulnerability-reporting channel.
5. Run `.github/workflows/macos-build.yml` and check build logs.
6. Tag `v1.0.0` and create a **source-only release**. Do not attach an unsigned PKG as a production installer.

## Build locally

```zsh
zsh Scripts/validate_on_mac.zsh
```

Build outputs under `output/` and `validation-results/` are not intended for version control. The current build targets Apple silicon macOS 14+, uses an ad-hoc app signature and an unsigned PKG. The bundle identifier is still `org.example.mymacstatus` and must be selected before distributing installable binaries; changing it is outside the frozen Alpha 2 scope.

## Suggested release notes

My Mac Status Community Edition v1.0.0 includes local Dashboard, Mac Health, Battery Health, Storage, Mac Details and read-only enrollment diagnostics. The validated icon-restoration build restores the blue Mac-and-heart default icon. Optional build-time branding remains available. No organization-specific credentials, privileged helpers, Jamf remediation or ABM API integrations are shipped. macOS privacy prompts may apply to storage inspection.
