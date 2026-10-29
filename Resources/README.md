# App icon and optional branding

`AppIcon.png` is the default Community Edition icon: a blue rounded-square Mac with a heart. It has no Veeam logo and transparent outer corners.

To replace the default icon, supply your own 1024 × 1024 PNG at `Resources/AppIcon.png` before building. The existing build script automatically creates `AppIcon.icns` and sets `CFBundleIconFile`.

`BrandLogo.png` remains optional for organizations that want a header logo. The default release includes no organization logo.

Branding text and support links can be set through `MYMACSTATUS_BRAND_NAME`, `MYMACSTATUS_BRAND_SUBTITLE`, `MYMACSTATUS_SUPPORT_EMAIL`, and `MYMACSTATUS_SUPPORT_URL`. Never put credentials or proprietary assets in a public repository.
