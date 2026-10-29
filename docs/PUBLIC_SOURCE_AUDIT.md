# Public-source audit — Community Edition v1.0.0

**Date:** 2026-10-29  
**Basis:** Static inspection of the validated icon-restoration ZIP; no independent macOS compilation in this environment. User confirmed successful compilation and visual inspection.  
**Status:** MIT selected by author; publication remains contingent on verifying employer-related distribution rights and artwork provenance.

## Inspected

- 35 archive entries; Swift source, shell build scripts, icon, documentation, and validation files.
- Searched text for employer/product identifiers, secrets-related terms, URLs, and vendor dependencies.
- No `.env`, `.pem`, `.p12`, credential package, ABM backend, or privileged helper was present in the supplied archive.
- No live private key or API token was identified by the limited pattern inspection. **This is not proof that no secrets exist.**
- Swift code uses built-in local macOS commands; MDM diagnostics are read-only.
- Default icon has no visible Veeam wordmark, but **rights to reuse the Mac-and-heart artwork are not established**.

## Findings and gates

| ID | Severity | Finding | Required action |
|---|---|---|---|
| PUB-01 | BLOCKER | Source derives from an internal employer project; publication authorization is not established. | Obtain written approval from the appropriate rights holder before making public. |
| PUB-02 | BLOCKER | No verified redistribution rights for app icon or other derived artwork. | Confirm rights or replace with independently licensed artwork. |
| PUB-03 | BLOCKER | MIT license selected by author; employer/third-party rights not independently verified. | MIT LICENSE added at author’s direction; verify all rights before publication. |
| PUB-04 | MEDIUM | Source includes legacy `Companion*` Swift type/file names and references to the internal edition in docs. | Review public-facing narrative and decide whether to rename internal symbols in a **future** functional branch; not required for compilation. |
| PUB-05 | MEDIUM | Bundle identifier `org.example.mymacstatus` is a placeholder. | Select a unique reverse-DNS ID before publishing distributable binaries; this changes install identity. |
| PUB-06 | MEDIUM | No tested CI run on hosted macOS runner. | Enable and test the included workflow after repository creation. |
| PUB-07 | MEDIUM | App is ad-hoc signed; PKG unsigned and unnotarized. | Document distribution limitations; decide whether to offer source-only initially. |
| PUB-08 | LOW | Support contact and security reporting destination not set. | Configure private vulnerability reporting and maintainer contact before public release. |
| PUB-09 | MEDIUM | Storage scanner may prompt for protected folder/photo library access. | Document consent behavior; do not imply unrestricted access. |

## Publication hygiene

Start a **new repository with a fresh Git history**. Do not import internal commits, internal packages, credentials, or developer machine build output. Review the entire staged diff and use repository secret scanning/push protection. Manually inspect icon metadata and all documentation for confidential information. No binary release is included in this kit.

## Scope preservation

Application Swift source, app icon, and build/validation scripts are copied unchanged from the validated icon-restoration archive. Changes in this kit are limited to repository documentation, community templates, and CI workflow.

## MIT licensing update — 2026-10-29

The author selected MIT and the repository now contains `LICENSE` with copyright (c) 2026 Ethan Besbris. This resolves the missing-license issue, **not** the separate employer-contract and artwork-provenance questions. No public upload was performed.
