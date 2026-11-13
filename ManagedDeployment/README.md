# RC3 Managed Preferences — foundation only

Bundle / preferences domain: `com.prettyfly.mymacstatus` (matches the existing build script). Deploy the example `.mobileconfig` through MDM after replacing example URLs and identifiers. The sample hides Settings & Connections in the sidebar and toolbar; if the Settings window is opened by another route, it shows a managed notice instead of editable controls.

## Keys (MDM-forced values only)
- `HideSettingsAndConnections` (Boolean): hide settings UI; default false.
- `HideHelpAndDocumentation` (Boolean): hide Help & Documentation sidebar entry, Help menu command/shortcut, and About-window Help button; default false. Other support links remain available when configured.
- `ConnectorURL` (HTTPS string): reserved for the future self-hosted connector; no network connection is implemented in RC3.
- `JamfProURL`, `IruTenantURL` (HTTPS strings): metadata reserved for future managed integrations.
- `ABMOrganizationID` (String): metadata reserved for future managed integrations.

**Security:** Do not deploy API tokens, client secrets, ABM private keys or passwords in profiles. RC3 does **not** automatically authenticate to Jamf, Iru, or ABM, and does **not** implement the connector. Existing manual integrations remain unchanged. MDM must install these as *forced* managed preferences; ordinary defaults are ignored by this managed configuration reader. Removing the profile restores sidebar visibility. The v2.0 bundle ID is `com.prettyfly.mymacstatus`. Replace all previously deployed `org.example.mymacstatus` profiles with new-domain profiles.

**Validation on a Mac:** build with `zsh Scripts/build_on_mac.zsh`; verify unmanaged settings visible; install profile with MDM, relaunch app, verify sidebar and toolbar settings hidden, direct Settings shows notice; remove profile and relaunch, verify settings return. Test light/dark modes and navigation. Build has not been compiled in this environment.

## RC3 Fix 1 testing
Deploy `Sidebar-Hide-Settings-And-Help-Test.mobileconfig` as a forced MDM profile, relaunch the app, and verify both sidebar entries are absent. Check that Command-? does not open Help, the Help menu has no My Mac Status Help action, and the About window has no Help button. Remove the profile, relaunch, and confirm both items return. The Help window is also guarded against programmatic opening while managed.
