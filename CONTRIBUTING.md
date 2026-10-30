# Contributing to My Mac Status

Thanks for helping make My Mac Status useful to more Mac users and administrators.

## Current scope

The public `main` branch contains the stable **v1.0.0 Community Edition**. It works locally without MDM credentials or network services. External MDM integrations are not shipped in this release.

## Propose an MDM integration

1. Check existing issues to avoid duplicates.
2. Open a **New MDM integration** issue using the repository template.
3. Describe the provider, the information users would benefit from, relevant public API documentation, and any authentication or licensing constraints.
4. Discuss the design and data-minimization approach with the maintainer before starting substantial implementation work.
5. Submit a focused pull request referencing the issue once the design is agreed.

Providers of interest include Jamf Pro, Apple Business Manager, Iru/Kandji, and Microsoft Intune; suggestions for other platforms are welcome.

## Design principles

- **Optional by design:** Local app functionality must work when no MDM provider or gateway is configured.
- **Security first:** Never embed organization-wide API keys, client secrets, or privileged credentials in a distributed app. Favor least-privilege, appropriately authenticated integrations.
- **Privacy:** Avoid unnecessary personal data and device identifiers; never log secrets or authentication tokens.
- **Accurate lifecycle data:** Distinguish enrollment/registration dates from purchase dates, and label estimated replacement dates as estimates unless backed by a defined policy.
- **Provider neutrality:** Keep provider-specific code behind a clear interface, separate from SwiftUI views.
- **Read-only first:** Avoid silent management changes, remote commands, or destructive repairs.
- **Tests and documentation:** Include mock-based tests for normalized inventory data and lifecycle calculations, plus setup and limitations documentation.

## Pull requests

- Target the public `main` branch only for changes intended for public release. Prefer a personal feature branch and pull request; do not commit experimental integrations directly to `main`.
- Keep changes small and explain what changed, why, and how you tested it.
- Include screenshots for UI changes and redact identifying details.
- Confirm that local-only mode still works.
- Do not include Veeam-specific internal code, branding, confidential documentation, tenant IDs, device records, credentials, or private endpoints.
- Contributions are reviewed before merging; a proposal does not imply acceptance or a release commitment.

## Reporting security issues

Do not disclose credentials or exploitable security details in a public issue. Use GitHub's private vulnerability reporting feature if enabled, or contact the maintainer privately through an established channel.

## License

By contributing, you agree your contribution can be distributed under the repository's MIT license. Only submit work you have the right to share.
