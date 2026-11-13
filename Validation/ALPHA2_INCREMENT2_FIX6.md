# Alpha 2 · Increment 2 · Fix 6 — Unified Action Alignment

Presentation-only change to `Sources/Views/AppleCareLifecycleView.swift`.

- Both AppleCare and Replacement Planning cards now use the same two-row footer geometry: primary button followed by a reserved 16-point secondary row, with 6-point spacing.
- Check Coverage and Check Date share a baseline regardless of whether Configure Connections is visible, whether a lookup has failed, or whether a record is present.
- Configure Connections remains a secondary SettingsLink below Check Date when no record exists and lookup is not running, including after a failed lookup.
- No changes to service calls, management/health calculations, AppleCare URL, provider integrations, replacement logic, or status colors.

## Mac validation required

1. Compile with `zsh Scripts/build_on_mac.zsh` and launch.
2. Compare button baselines before and after Check Date reports an error.
3. Confirm Configure Connections still opens Settings.
4. Verify AppleCare link, populated replacement record, narrow window stacking, Light and Dark Mode.
5. Confirm no functional regressions. Do not freeze before approval.
