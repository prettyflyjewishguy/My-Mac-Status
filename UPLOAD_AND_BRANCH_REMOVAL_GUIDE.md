# GitHub upload and branch cleanup guide

## Before changing anything

- Confirm the separate **private development repository** contains the files you want to retain. A ZIP upload preserves files but not the original branch's commit history.
- Confirm the public repository's `main` branch still has `docs/assets/readme-banner.png` and the existing `docs/assets/screenshots/` images. This kit **references** those existing assets and does not replace them.
- Inspect the development branch for any sensitive material. Moving files into a private repo does **not** make previously published commits private.

## Upload via GitHub website

Repository: https://github.com/prettyflyjewishguy/My-Mac-Status

1. Select branch **main**.
2. Open root `README.md`, select **Edit** (pencil), replace the contents with this kit's `README.md`, then commit to `main` with message `Update community collaboration and support information`.
3. At the repository root, use **Add file → Create new file**, name it `CONTRIBUTING.md`, paste the supplied file, and commit.
4. Use **Add file → Create new file**, name it `.github/ISSUE_TEMPLATE/mdm-integration.yml`, paste the supplied YAML, and commit. GitHub creates intermediate folders automatically when you type `/`.
5. Open **Issues → New issue** and confirm the **New MDM integration** template appears. If the template does not appear, check the YAML formatting and that Issues are enabled in repository settings.
6. Verify the README banner, screenshot gallery, and Venmo link render correctly.

## Safely remove the old public development branch

1. Verify the private development repository has all desired source and documentation. Keep a local backup, too.
2. Check for open pull requests targeting or originating from `development/v1.1.1-managed-integrations`; close or retarget them as appropriate.
3. Check branch protection/rulesets and confirm `main` is the default branch.
4. Open the public repository's **Branches** page, locate `development/v1.1.1-managed-integrations`, and select **Delete branch**.
5. Confirm `main` remains the default and the README has no links to the removed branch.

**Privacy warning:** Deleting a public branch does not erase its commits from forks, clones, PRs, or cached references. If secrets were ever published, revoke/rotate them and review GitHub's sensitive-data removal guidance. Avoid assuming the old code is now confidential.

## Optional polish

- In repository settings, enable **Issues** and **Discussions** if desired; consider a Discussions category named **MDM Integrations**.
- The support button uses **Venmo** (`https://venmo.com/u/bigdaddybesbris`), not a Buy Me a Coffee account. Do not label it as a Buy Me a Coffee service link.
- No application source files are changed by this documentation kit.
