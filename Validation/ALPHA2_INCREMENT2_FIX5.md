# Alpha 2 · Increment 2 · Fix 5 — Preserve Configure Connections Action

Scope: Mac Details presentation only.

- Preserve the secondary **Configure Connections** SettingsLink when no replacement record is available, including when the most recent lookup returns an error.
- Continue hiding the link while a lookup is in progress or when a replacement record exists.
- Preserve the existing Check Date action, AppleCare action, responsive two-column cards, styling, and underlying lifecycle/integration logic.

## Validation on macOS
1. Build using `zsh Scripts/build_on_mac.zsh`.
2. Without an inventory record, verify Configure Connections appears beneath Check Date.
3. Click Check Date and induce/observe a failed lookup; verify the error remains visible **and** Configure Connections returns beneath Check Date.
4. Verify Configure Connections opens Settings; verify Check Date and Check Coverage work as before.
5. Verify light/dark mode and narrow-window stacked layout.

Not frozen. Requires user acceptance.
