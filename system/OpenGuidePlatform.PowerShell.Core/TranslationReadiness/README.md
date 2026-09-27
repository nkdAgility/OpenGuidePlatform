# Add a site language and translate selected guides

These workflows work in PowerShell without an agent. A person supplies translated Markdown through their editor; an agent may propose the same candidate. Both use the same discovery, checks, hash protections and builds.

## Add a language across the site

Adding a language is a site-scoped operation: configuration, interface catalogue, localized wrapper and site-owned data come first, then empty eligible guide scaffolds. The `guide.transcreate` skill follows this same procedure. Body translation is a separately selected stage. A request to edit one existing guide body remains scoped to that edition; that command boundary does not reduce a new-language request to one edition.

Start from the adopted repository root in PowerShell 7.4 or later:

```powershell
$workspace = $PWD.Path
$platform = ./.OpenGuidePlatform/Resolve-OpenGuidePlatform.ps1 -WorkspaceRoot $workspace -UseInstalled
Import-Module "$platform/system/OpenGuidePlatform.PowerShell.Core/OpenGuidePlatform.PowerShell.Core.psd1" -Force
Get-Content "$platform/platform.json"
$output = '.processing/site-language/' + [guid]::NewGuid().ToString('N')
./build.ps1 -Stage Prepare -Target preview -OutputPath $output -PlatformSource Path -PlatformPath $platform
$policy = Import-GuidePolicy -Path "$output/discovered-site.json"
$language = 'kn' # Replace with the requested language.
$siteWork = Get-GuideSiteTranslationWork -WorkspaceRoot $workspace -Policy $policy -Language $language
$siteWork.Configuration | Format-List
$siteWork.Wrappers | Format-Table Kind, SourcePath, TargetPath, State, SupportedOperation -Wrap
$siteWork.Guides | Format-Table GuideId, EditionId, State, Intent, CanCreateScaffold -Wrap
$siteWork.Findings | Format-List
```

Read the installed instructions and record the package version and Prepare report used. A missing command requires the coordinated Update workflow when authorized; do not use another Core version or a direct-write substitute. Inspect failed Prepare assessments before continuing: valid discovery may support repairs, but no valid discovery means the operation is blocked. The site report accepts a language not yet configured; it is a work inventory, not translation-quality or publication approval.

1. Review the report's production configuration first. Prepare an exact candidate with the requested language explicitly `disabled: true`; preserve every unrelated setting. Apply it with `Set-GuideWrapperTranslation` and the reviewed configuration hash, then add the main language entry through the same command. Never enable production during creation. If the site configuration itself is missing, report the setup prerequisite rather than inventing a generic configuration.
2. Refresh Prepare and the site report. Review each wrapper source and target: site homepage, guide roots, history, translations pages and other discovered wrapper Markdown, plus i18n catalogues. Translate reader-facing text while preserving keys, placeholders, URLs, metadata conventions and legacy aliases. Use `Set-GuideWrapperTranslation` for each reviewed candidate. Existing destinations require their original reviewed `ExpectedSha256`; preserve populated translations unless updates were requested.
3. Review site-owned localized data against its actual schema. For supported JSON resources, explicitly select translatable string leaves with `JsonTextPaths` (RFC 6901 pointers such as `/hero/title`); preserve machine values, keys, arrays and unselected values. Do not translate every string indiscriminately. Unsupported resources remain explicit blockers with their paths and required operation, not silent omissions or improvised edits.
4. Refresh discovery again. Review the report's eligible absent guide targets across the site's actual guide/edition inventory, with no fixed guide count. Use the per-edition `New-GuideTranslation` procedure below for each eligible selection, leaving bodies empty. Preserve populated targets, protected content and declared PDF-only/source-fallback intent. Report skipped targets and reasons. A source-only edition does not by itself require translation, and the site workflow must not silently convert explicit intent.
5. Refresh Prepare, run full preview and production builds against the same package, and inspect the rendered site. Report configuration, localized wrapper/data, empty scaffolds, remaining body work, editorial review and verification separately. An intermediate scaffold may have outstanding wrapper or body findings; a failed build is not a readiness pass. Production exclusion remains in place until separately approved promotion.

For a wrapper file, choose one exact target path from the report. Complete the production-exclusion and main-configuration prerequisites first. This example captures the reviewed hashes, starts from an existing translation when present, and creates a separate candidate for your editor:

```powershell
$targetPath = Read-Host 'Paste the exact TargetPath from the wrapper report'
$wrapperSelections = @($siteWork.Wrappers | Where-Object TargetPath -CEQ $targetPath)
if ($wrapperSelections.Count -ne 1 -or -not $wrapperSelections[0].SupportedOperation) {
    throw 'Select one unambiguous supported wrapper operation.'
}
$wrapper = $wrapperSelections[0]
$reviewedTargetHash = $wrapper.TargetSha256
$reviewedSourceHash = $wrapper.SourceSha256
$startingPath = if ($reviewedTargetHash) { $wrapper.TargetPath } else { $wrapper.SourcePath }
$startingFile = Resolve-GuideWorkspacePath $workspace $startingPath
$candidatePath = Join-Path $workspace "$output/wrapper-candidate$([IO.Path]::GetExtension($targetPath))"
[IO.File]::WriteAllText($candidatePath, [IO.File]::ReadAllText($startingFile), [Text.UTF8Encoding]::new($false))
# Open $candidatePath in your editor. Translate the agreed reader-facing fields and save.
# For JSON, preserve every unselected value and review the string pointers below.
```

After editing, apply the exact candidate against those original hashes:

```powershell
$wrapperChange = @{
    WorkspaceRoot = $workspace; Policy = $policy; Language = $language
    RelativePath = $wrapper.TargetPath
    CandidateContent = [IO.File]::ReadAllText($candidatePath)
}
if ($reviewedTargetHash) { $wrapperChange.ExpectedSha256 = $reviewedTargetHash }
if ($wrapper.Kind -eq 'json-text-selection-required') {
    $wrapperChange.ExpectedSourceSha256 = $reviewedSourceHash
    $wrapperChange.JsonTextPaths = @(
        (Read-Host 'Enter the reviewed RFC 6901 pointer to one translated string leaf')
    )
    # Add further explicitly reviewed pointers if more than one string was translated.
}
Set-GuideWrapperTranslation @wrapperChange -WhatIf
Set-GuideWrapperTranslation @wrapperChange
```

A new target omits `ExpectedSha256`; creation refuses an existing destination. JSON pointers such as `/hero/title` select actual string leaves in that site's schema, not a universal field list. Existing JSON starts from the target; new JSON starts from the source so unselected values remain intact. Inspect the source and candidate together and do not refresh a stale hash merely to apply an old candidate.

Configuration candidates instead start from the existing path and hash in `$siteWork.Configuration` (`ProductionPath`/`ProductionSha256` first, then `MainPath`/`MainSha256`). Edit only the selected language mapping and supply that configuration's hash as `ExpectedSha256` to the same writer. They are not wrapper-source entries and do not use JSON pointers.

Read command help before applying a candidate and review the actual diff after each operation. Multi-file changes are not one transaction: inspect partial progress and refresh reports before resuming.

## Select a guide body for a separate translation stage

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

## Create one eligible empty guide scaffold

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
