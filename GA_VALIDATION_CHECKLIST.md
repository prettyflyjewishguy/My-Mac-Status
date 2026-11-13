# 2.0 GA Release Gate

- [ ] Compile on supported macOS/Xcode; run included validation script.
- [ ] Confirm About version 2.0 and build 2000, bundle ID `com.prettyfly.mymacstatus`.
- [ ] Verify app signing, notarization, install/uninstall and update path.
- [ ] Test all pages, health indicators, update checks, battery, storage, diagnostics and lifecycle calculations.
- [ ] Validate provider endpoints, API authentication and existing Keychain credentials after bundle ID migration.
- [ ] Install consolidated managed branding profile and confirm logo in both appearances; native titlebar unchanged.
- [ ] Verify primary, secondary, accent and selection colors; selected icon/text contrast.
- [ ] Change managed selection color while app stays open; confirm live update.
- [ ] Remove profile while app stays open; confirm default theme and Settings/Help return.
- [ ] Verify Help menu restriction and managed Settings access.
- [ ] Test unreachable logo URLs, invalid hex values, offline use and missing preferences.
- [ ] Pilot on managed devices before marking signed release GA.

**Packaging status:** source/docs prepared. The above items require on-device validation and are not claimed complete.
