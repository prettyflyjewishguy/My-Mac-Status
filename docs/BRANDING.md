# Branding & customization

My Mac Status ships with a generic look and supports optional build-time customization.

To customize the application icon, replace `Resources/AppIcon.png` before building. To add a brand logo, provide `Resources/BrandLogo.png`.

To customize the displayed organization and support details, run:

```zsh
MYMACSTATUS_BRAND_NAME='Example IT' \
MYMACSTATUS_BRAND_SUBTITLE='Endpoint Support' \
MYMACSTATUS_SUPPORT_EMAIL='support@example.org' \
MYMACSTATUS_SUPPORT_URL='https://support.example.org' \
zsh Scripts/build_on_mac.zsh
```

The application uses the system accent color by default. Additional styling can be changed in `Sources/Components/CompanionStyle.swift`.

Custom branding is optional; the default application works without it.
