# Validate, review and publish

Validation checks that the site builds and behaves as intended. People approve wording and publication. Start with the reviewed candidate applied and its actual diff inspected. Use the same installed package as [Prepare](status.md).

## Check locally

From the site root in the same PowerShell session:

```powershell
./build.ps1 -Target preview -PlatformSource Path -PlatformPath $platform
./build.ps1 -Target production -PlatformSource Path -PlatformPath $platform
```

Require successful exit codes and inspect reports; explain warnings and resolve errors. A production build checks the production output without publishing. Confirm the new language is excluded there. Use the output paths printed by the build to find reports and rendered files; do not assume an old artifact belongs to this change.

For interactive local inspection, the site development server is:

```powershell
./build.ps1 -Stage Serve -Target local
```

Open its printed address and stop it with Ctrl+C when done. A development server does not replace the two full builds. Inspect homepage/navigation, language and version switching, history, fallback, links, downloads, narrow/wide layouts and representative script rendering. Check any generated PDF separately. Record the revision or exact candidate, package version, target and artifact inspected.

## Share reviewed work

![Local checks lead to a pull-request canary for technical review, preview for language review, and production only after separate approval.](diagrams/publication.svg)

In words: local checks precede a PR. A maintainer arranges the canary for technical/design review. After technical review, merge to preview for native-speaker validation. Resolve later corrections through PRs, then obtain guardian approval and a separate production-promotion decision. Actual deployment depends on the site's configured workflow and access.

Review `git status` and `git diff`; stage only intended source files and approved artifacts. Follow the site's commit/push permissions and PR instructions. Include scope, source/candidate revisions, build results, review findings, consented credits and remaining issues. Never commit `.processing` output. Ask maintainers for the review link if fork PRs cannot deploy; approval alone cannot override a disabled deployment caller.

With an assistant: “Run the required local checks on this exact change. Report evidence, failures and unreviewed wording separately. Prepare a PR description; follow the site's permissions for commits, pushes and publication.”

**Success:** checks and human decisions are traceable to the reviewed revision. Passing automation, preview availability and an assistant report are not publication approval. **If a check fails:** use [troubleshooting](troubleshooting.md), retain the failure and rerun affected checks after correction.
