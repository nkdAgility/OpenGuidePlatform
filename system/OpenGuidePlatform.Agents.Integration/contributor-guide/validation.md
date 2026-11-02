# Check and submit your translation

Submission asks the site team to review your work. It does not publish the language. You should be able to show what changed, what people reviewed and what remains unfinished.

## Work with an agent

Continue with the installed skill used for the work: [guide.transcreate](../skills/guide.transcreate/SKILL.md) for adding a language or selected guide translation, or [guide.transreconcile](../skills/guide.transreconcile/SKILL.md) for updates. Their workflows include the required checks. If the agent cannot load the appropriate skill, use [setup](setup.md) with the maintainer; do not substitute another workflow.

> Continue our work through this site's installed **guide.transcreate** skill. Check the exact changes we reviewed using its required preview and production checks. Do not publish anything. Explain the results, including failed or missing checks. Show how we can inspect the prepared website. Prepare a submission description with the agreed scope, source used, human review, credits, actual check results and unfinished work. Follow the site's permissions for saving or sharing changes; do not claim a submission exists until you can show its link.

For an update, replace **guide.transcreate** in that request with **guide.transreconcile**. Use [guide.contributions and guide.genpdfs](credits-pdfs.md) only if credits or eligible generated PDFs are part of the agreed work.

### Inspect the result together

The agent should report preview and production check results separately. A production check checks the would-be live output; it does not publish it. Confirm that the new language remains excluded from the live website.

Ask for the prepared website's review address. If none is available, ask the maintainer to arrange one. Inspect menus, language/edition switching, guide text, links, downloads and letters on a phone and larger screen. Review any newly generated PDF separately. The person checking language decides whether wording is right; software checks cannot do that.

### Hand over the submission

A **pull request**, often shortened to PR, is a submission showing proposed file changes for the site team to review. There is no separate OGP submission or publication skill. Submission uses the site's normal GitHub process and permissions, after the skills above complete their checks.

If your agent is authorised and has the necessary access, it can help save and share the reviewed work through that site process. Otherwise, give the maintainer the reviewed work and evidence and ask them to make the submission. You do not need to learn terminal commands to make that handoff.

Check that the submission or handoff includes:

- The language, selected guide and edition, and the source used.
- What changed, including whether guide starting pages are still empty.
- Wording review and consented credits.
- Actual check results, the version checked, and unresolved work.
- A review link, or a named maintainer arranging one.

Ask for the PR link and confirm the intended files appear there. Do not create a second PR if one already exists for the task. A checked website-only stage can be shared as a draft, clearly marked as incomplete guide translation. Do not claim failed checks passed.

![Check the prepared work, submit for review, review wording in preview, then obtain separate publication approval.](diagrams/publication.svg)

The site team arranges technical review, then language review in its preview environment. Later corrections follow the same reviewed-change process. The responsible language reviewer and maintainer make the separate publication decisions. A passing check, agent report or submitted PR is not permission to publish.

**You should receive:** the submission link or an explicit maintainer handoff, the actual review arrangement, and a clear account of anything still blocking completion. If a check fails, use [troubleshooting](troubleshooting.md).

## I do not have an agent and want to do this manually

First follow [manual setup](setup.md#i-do-not-have-an-agent-and-want-to-do-this-manually) and [status](status.md#i-do-not-have-an-agent-and-want-to-do-this-manually). The status procedure defines the `$platform` value used below. A build turns the source files into a checkable website. The commands below check it, show proposed file changes, save the selected changes and share them for review. Each action is explained before you run it; follow site permissions and stop if the expected result does not appear.

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


## Save and submit the reviewed change

The technical volunteer performs these actions after the site's required checks/review and Git authorisation. A commit saves locally; push shares it; a PR requests review. Translators who only supply text do not need to run them.

First inspect the branch and changes:

```powershell
git branch --show-current
git status --short
git diff
```

Confirm the branch is the agreed task branch. Stop if it changed unexpectedly. Check every changed file against scope. `git diff` shows tracked edits; open new files listed by status separately. Do not include `.processing`, credentials or unrelated work. Reviewed generated PDFs/receipts are included only when explicitly part of this task; supplied/protected PDFs stay unchanged.

Select one intended repository-relative file at a time, then review the whole staged change:

```powershell
$reviewedPath = Read-Host 'Enter one reviewed file path to include'
git add -- $reviewedPath
git diff --cached
git status --short
```

Repeat selection only for additional intended files. If the staged diff is wrong, stop and correct the selection before committing. When it is correct and committing is authorised:

```powershell
$commitMessage = Read-Host 'Enter a short description of this reviewed change'
git commit -m $commitMessage
git status --short --branch
```

Confirm Git reports a successful commit and account for anything still uncommitted. If a hook or command fails, report it and resolve the cause; do not bypass checks. When pushing is authorised under the site's rules, verify that `origin` is the expected fork or repository and that the current branch is still the agreed task branch:

```powershell
git remote -v
git branch --show-current
$agreedBranch = Read-Host 'Enter the agreed task branch name shown above'
if ((git branch --show-current) -cne $agreedBranch) { throw 'Branch changed; stop and check with the maintainer.' }
git push -u origin $agreedBranch
```

Open the site's GitHub repository in your browser and choose the option to create a pull request from the pushed branch. Select the intended destination repository/base branch and your fork/task branch as the comparison. Review the displayed changed files, link the agreed discussion and include the validation evidence and unresolved questions. Select a draft PR while work or review is still in progress. Do not create another PR if the task already has one; subsequent pushes update it. Follow the site's contribution agreement and review requirements when GitHub requests them.

Success here is a PR that shows the intended changes and their actual status. A draft PR can make website/scaffold work visible before guide bodies are translated; say so explicitly. Maintainers then arrange canary/preview review. Creating a PR does not merge it or publish a release.

**Success:** checks and human decisions are traceable to the reviewed revision. Passing automation, preview availability and an assistant report are not publication approval. **If a check fails:** use [troubleshooting](troubleshooting.md), retain the failure and rerun affected checks after correction.
