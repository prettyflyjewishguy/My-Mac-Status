# Optional branding

Default: generic My Mac Status name and blue Mac-and-heart icon; no company logo or service desk destination.

Set public, nonsecret build-time settings:

```zsh
MYMACSTATUS_BRAND_NAME='Example IT' \
MYMACSTATUS_BRAND_SUBTITLE='Endpoint Support' \
MYMACSTATUS_SUPPORT_EMAIL='support@example.org' \
MYMACSTATUS_SUPPORT_URL='https://support.example.org' \
zsh Scripts/build_on_mac.zsh
```

Place optional `Resources/BrandLogo.png` to show an organization logo; replace `Resources/AppIcon.png` to change the application icon. Do not commit private corporate artwork without permission. The icon itself requires separate provenance clearance before publishing this fork.
