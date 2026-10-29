# Security model

This fork is local-only, read-only for MDM state and does not use root helpers. It does not bundle credentials or upload device information. It runs macOS built-in commands for local health inspection and scans files accessible to the current user. The scan may trigger privacy consent prompts.

Do not commit private keys, environment files, installer payloads, private support links, proprietary artwork or confidential fleet details. Audit the final git diff and history before publication. No claim of external security review is made.

Report suspected vulnerabilities privately to the repository maintainer; add a responsible contact before publishing.
