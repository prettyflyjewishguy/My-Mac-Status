# Community Edition v1.1.0 Alpha 1 — Build Fix 1

Fixes the macOS Swift standard library resolution error by explicitly passing the active macOS SDK to `swiftc` using `xcrun --sdk macosx`. The deployment target remains macOS 14.0.

No Swift application source or app functionality was changed. This is an Alpha build candidate and has not been compiled in a macOS environment by the packager.

From the extracted project root run:

```zsh
zsh Scripts/build_on_mac.zsh
```

Expected output: `output/My Mac Status.app` and `output/My-Mac-Status-v1.1.0-community-unsigned.pkg`. Confirm compilation, app launch, and unmanaged-Mac health behavior before accepting Alpha 1.
