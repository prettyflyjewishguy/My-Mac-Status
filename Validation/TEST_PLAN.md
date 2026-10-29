# Community Edition v1.0.0 — Validation Test Plan

**Status:** Not yet tested on macOS. This kit provides source, a build wrapper, and a test record; it does **not** contain a compiled PKG.

## Build
1. On an Apple silicon Mac with Xcode Command Line Tools, extract the kit and open Terminal in `My-Mac-Status-Community`.
2. Run `zsh Scripts/validate_on_mac.zsh`.
3. Review `validation-results/<timestamp>/build.log`, `sha256.txt`, and `output/My-Mac-Status-v1.0.0-community-unsigned.pkg`.
4. If compilation fails, preserve the log and do not claim validation passed.

## Functional checks (mark PASS / FAIL / NOT TESTED)
| Test | Expected behavior | Result / notes |
|---|---|---|
| Launch app | Opens without crash; name My Mac Status | |
| Dashboard | Local device health displayed | |
| Mac Health | FileVault, SIP, enrollment, updates and uptime show meaningful states | |
| Battery Health | Shows battery details or clear unsupported/unavailable state | |
| Battery refresh | Reopening after 60 seconds updates readings; no overlapping refreshes | |
| Health refresh | Reopening after five minutes refreshes; repeated navigation does not overlap | |
| Storage | Manual scan completes; protected folders may prompt or be skipped | |
| Mac Details | Local hardware details shown; no ABM lookup/replacement estimate | |
| Diagnostics | Read-only MDM status; no Jamf repair option | |
| Help | Local help opens | |
| Unmanaged Mac | MDM status accurately says unmanaged, not unhealthy by default | |
| Failure behavior | No crash; helpful errors if commands fail | |
| No secrets | No private key, credentials.env, tokens or org-only endpoints in PKG | |
| No privileged service | No root LaunchDaemon installed | |
| Optional branding | BrandLogo.png and build-time settings work when provided | |
| Installation | PKG installs; app launches from /Applications | |
| Uninstall | App removal behavior documented; no daemon leftovers | |

## Security and release gates
- Verify compiled bundle identifier `org.example.mymacstatus` is replaced with an identifier controlled by the publisher **before public release**.
- Confirm authorization to publish Veeam-derived source and assets; choose a license.
- Run repository and package secret scans; review all hits manually.
- Review PPPC prompts from storage scanning; do not automatically grant Full Disk Access.
- Signing and notarization are intentionally not part of this validation build; assess Gatekeeper behavior separately for distribution.
- Confirm compatibility on each supported macOS version and CPU architecture. Current script targets **arm64 macOS 14+** only.

## Important limitations
The included fork is not guaranteed to compile. `validate_on_mac.zsh` runs the existing build and captures failures; it does not silently modify application logic. Any fixes must be made on a separate branch and revalidated.
