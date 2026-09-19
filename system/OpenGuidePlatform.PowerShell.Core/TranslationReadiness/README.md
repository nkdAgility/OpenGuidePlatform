# Create and reconcile guide translations

These workflows work in PowerShell without an agent. A person supplies translated Markdown through their editor; an agent may propose the same candidate. Both use the same discovery, checks, hash protections and builds.

## Load and select

Follow [Core setup](../README.md#load-the-installed-commands-and-discover-content) to resolve `$platform`, import Core, run Prepare into a fresh `$output`, and load `$policy` from its `discovered-site.json`. Use the repository root as `$workspace`. Keep Prepare and subsequent builds on that same package with `-PlatformSource Path -PlatformPath $platform`.

List available guides and editions with `Get-GuideContent`, then select their actual identifiers and the requested target language:

```powershell
$selection = @{
    WorkspaceRoot = $workspace; Policy = $policy
    GuideId = 'your-guide'; EditionId = 'your-edition'; Language = 'fr'
}
$work = Get-GuideTranslationWork @selection
$work | Format-List GuideId, EditionId, SourceLanguage, Language, TargetIntent, TargetDeclared, CanCreateScaffold
$work.Findings | Format-Table Code, Action -Wrap
$work.Wrapper | Format-List
```

The source language comes from the edition. An absent target's proposed path does not create an inventory entry. Wrapper files, local i18n observations and declared downloads are included. Local observations do not establish effective fallback, complete wrapper coverage or publication readiness; use Prepare and later build results.

Translation availability is independent for each guide edition. A French translation of v1 does not imply a French translation of v2. Editing v1 requires no v2 translation and never edits or creates one. Explicit creation in v2 creates only that target. Source corrections use Set-GuideContent; all translated-document corrections use Set-GuideTranslation with that edition's source and target hashes. The shared writer rejects a source path from another edition and cannot substitute an existing translation from elsewhere.

## Create a new translation

```powershell
New-GuideTranslation @selection -WhatIf
$created = New-GuideTranslation @selection
$created.Status
```

This delegates to the retained `New-GuideTranslationScaffold`: an empty body with source metadata, existing alias rules and preservation of existing targets. Creation requires an explicit `disabled: true` entry for the language in `hugo.production.yaml`. If missing, review the main/preview settings and apply the production exclusion through the existing wrapper configuration workflow. Never enable production as a workaround. Source/protected paths remain protected.

The wrapper configuration command updates existing configuration files. If `hugo.yaml` or `hugo.production.yaml` itself is absent, report that setup prerequisite and restore or create the appropriate site-owned configuration within the authorized scope; do not claim the wrapper command can create it or invent a generic site configuration.

After creation, refresh discovery rather than editing its JSON:

```powershell
$output = '.processing/translation/' + [guid]::NewGuid().ToString('N')
./build.ps1 -Stage Prepare -Target preview -OutputPath $output -PlatformSource Path -PlatformPath $platform
$policy = Import-GuidePolicy -Path "$output/discovered-site.json"
$selection.Policy = $policy
$work = Get-GuideTranslationWork @selection
```

Prepare can report missing translation or wrapper work here. Inspect the assessment: valid discovery can support repairs, but a failed Prepare is not a readiness pass. If discovery failed, resolve it first. Explicit policy callers must review declared intent separately; these commands do not rewrite policy or convert fallback/PDF-only intent.

## Write, check and apply a candidate

Start from the existing target, then edit the candidate in your preferred editor:

```powershell
$candidatePath = Join-Path $workspace "$output/candidate.md"
[IO.File]::WriteAllText($candidatePath, $work.Target.Content, [Text.UTF8Encoding]::new($false))
# Open $candidatePath in your editor. Use $work.Source.Content as the source.
# Translate the body and, where present, title, description and summary. Save.
$candidate = [IO.File]::ReadAllText($candidatePath)
$check = Test-GuideTranslation @selection -CandidateContent $candidate
$check | Format-List Outcome, TranslationQualityAssessed, BuildRequired
$check.Findings | Format-Table Code, Severity, Action -Wrap
$check.SourceOutline | Format-Table
$check.CandidateOutline | Format-Table
```

`blocked` means a prerequisite, metadata constraint or body check failed. `review-required` means no such blocker was found; it does not approve translation quality. Review terminology, omissions, links, shortcodes, code examples and rendered output. ATX heading outlines exclude fenced code but do not fully parse Markdown, setext headings or embedded markup. Outline differences and source-identical text are review findings, never automatic deletion rules.

Only `title`, `description` and `summary` metadata may change; existing editorial fields must remain present and supplied fields must be nonempty strings. Other metadata must remain semantically unchanged, including aliases, identifiers, dates, version, layout, fonts and custom fields. No `lang` is permitted. Custom metadata translation requires separate explicit review. The exact candidate is written, so review comments and formatting too.

Use hashes captured when the source and target were read:

```powershell
$change = @{
    CandidateContent = $candidate
    ExpectedSourceSha256 = $work.Source.Sha256
    ExpectedSha256 = $work.Target.Sha256
}
Set-GuideTranslation @selection @change -WhatIf
$result = Set-GuideTranslation @selection @change
git diff -- $result.Path
```

Both hashes are checked before staging and again before replacement. A stale rejection requires reconciling the candidate, not simply substituting new hashes. Cooperative locks coordinate OGP content operations but are not an OS-level transaction with every editor. The command writes one existing target only; source, other translations, wrapper, policy, configuration and PDFs remain untouched. Results contain `planned`, `unchanged` or `updated`, hashes, findings and verification requirements.

## Reconcile against source changes

Choose an explicit Git revision useful for the review. It may be the known source revision previously translated, if the contributor has that evidence, or another explicitly selected comparison point. The tool does not infer history from dates, translation commits or a populated body.

```powershell
$sourceRevision = 'full-commit-id-selected-for-review'
$work = Get-GuideTranslationWork @selection -SourceRevision $sourceRevision
$work.Comparison | Format-List Commit, Path, Sha256, CurrentSha256, Changed, Meaning
$work.Comparison.Diff
$work.Target.Content
```

The report includes historical/current source, current translation and a unified source diff. Current content includes uncommitted changes; hash changes include metadata and line endings. If the source moved, pass its exact old repository-relative `-SourcePathAtRevision`. Missing commits/files fail explicitly. Git is required only for historical comparison, not ordinary creation or application.

Start the candidate from `$work.Target.Content`, preserving translated passages, and revise it against the source diff. Use the candidate check above. To record the comparison in the returned application result, use the resolved immutable commit:

```powershell
$change = @{
    CandidateContent = $candidate
    ExpectedSourceSha256 = $work.Source.Sha256
    ExpectedSha256 = $work.Target.Sha256
    SourceRevision = $work.Comparison.Commit
    SourcePathAtRevision = $work.Comparison.Path
}
Set-GuideTranslation @selection @change -WhatIf
$result = Set-GuideTranslation @selection @change
```

The result records the comparison and current source hash checked. It does not claim every difference was translated or identify the translation's prior baseline. No tracked provenance file or front matter field is imposed. Include relevant result fields in the change review; optionally save the result under `.processing` using `ConvertTo-Json -Depth 30`.

## Finish wrapper, downloads and verification

Review the work report and effective Prepare assessment. Use `Set-GuideWrapperTranslation` for authorized wrapper Markdown, i18n and language configuration, preserving site conventions. Files are separate operations: after a partial failure, inspect completed changes and resume with fresh discovery and hashes.

Declared generated PDFs use the existing plan/generation/receipt workflow when required. Supplied/protected PDFs stay untouched. PDF generation and visual review remain explicit steps.

```powershell
./build.ps1 -Target preview -PlatformSource Path -PlatformPath $platform
./build.ps1 -Target production -PlatformSource Path -PlatformPath $platform
```

Inspect reports and rendered output, including navigation, links, fallback and downloads. A production build verifies configured exclusion, not approval to enable a language. No deployment occurs. Report changed files, candidate checks, editorial review still needed, build outcomes and unresolved work separately.

For the OGP reference site, use the development equivalents in the Core README: import the local module and invoke root `build.ps1 -Product GuideSite -SourcePath examples/reference-guide-site` with the same stages and fresh output directories. Shipped skills follow this same procedure.
