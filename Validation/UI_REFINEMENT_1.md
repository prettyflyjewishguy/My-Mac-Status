# v1.1.0 Alpha 1 — UI Refinement 1

Presentation and user-facing language changes only. No changes to CommunityHealthPolicy, enrollment detection, severity calculations, recommendations, or diagnostics.

- Device Management card: informational label and correct enrolled/not-managed explanation.
- Health & Security: clarify management status is separate from health.
- Mac Details: replace enterprise-specific replacement-policy card with conditional estimate explanation; remove organization-policy link. Existing lifecycle service and its data sources are unchanged.
- Battery: personal-user guidance to macOS Battery settings and Apple Support.

## Validation required on macOS

1. Compile and launch using `zsh Scripts/build_on_mac.zsh`.
2. Confirm unmanaged Mac is Healthy and Device Management reads Not Managed / Informational.
3. Confirm management expectation Automatic, Personal and Organization-managed retain previous recommendation behavior.
4. Confirm update available can show Needs Attention in Health & Security without changing overall device health.
5. Inspect all screens in light and dark mode.
6. Test Battery, Mac Details, Storage scan, diagnostics and history behavior.

Not compiled on macOS in this environment; do not freeze until user validation.
