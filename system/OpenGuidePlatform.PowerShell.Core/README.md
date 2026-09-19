# Publishing Core

This PowerShell 7.4 module contains publishing operations organised by capability. It accepts an explicit workspace and policy-shaped inventory, normally produced by Prepare's discovery; explicit reviewed policies remain supported. It has no GitHub or agent dependency. Guide and edition collections are not limited to fixture counts.

Use the complete workflow below to load the site's installed module and discover its content. Platform developers can import the module from this directory directly.

Policy loading and document operations use powershell-yaml 0.4.12. Only PDF generation requires Pandoc and XeLaTeX; explicit font choices require font diagnostics. No command installs fonts automatically. Tests require Pester 5.7.1; run `./build.ps1 -Version 0.0.0-local` from the platform root for tests, packaging and sample acceptance.

Capabilities include inventory and translation readiness, publication exclusions, write-policy decisions, empty translation scaffolding, guide body corrections, draft edition snapshots, contributor records, Gravatar hashing, and PDF generation. Mutation commands support WhatIf. Supplied and protected downloads cannot be regenerated. Supported replacements require reviewed hashes; creation operations refuse or preserve existing destinations.

PDF language comes from the filename suffix or declared source language and is passed explicitly to Pandoc metadata. Source front matter does not need a lang field. Generation checks native failures and PDF format before publishing a new file; returned evidence includes input, policy, executable and output hashes. Visual review remains necessary.

This module enforces the supplied policy, not the authenticity of that policy. GuideSite packages distribute these commands through installation and Update. Independent enforcement requires the AgentControls evaluator to be configured with an external trusted baseline; installing skills does not configure that enforcement.

## Correct an existing guide

This workflow works in an adopted guide-site repository without an agent. It covers source-language body corrections while preserving front matter exactly. Use Set-GuideTranslation for translated documents, including typo corrections, with both reviewed source and target hashes. Metadata changes and new translations are separate tasks. Use your normal editor to prepare the correction; no editor or AI provider is required by Core.

### Load the installed commands and discover content

Run from the repository root in PowerShell 7.4 or later:

```powershell
$workspace = $PWD.Path
$platform = ./.OpenGuidePlatform/Resolve-OpenGuidePlatform.ps1 -WorkspaceRoot $workspace -UseInstalled
Import-Module "$platform/system/OpenGuidePlatform.PowerShell.Core/OpenGuidePlatform.PowerShell.Core.psd1" -Force
$output = '.processing/content-edit/' + [guid]::NewGuid().ToString('N')
./build.ps1 -Stage Prepare -Target preview -OutputPath $output -PlatformSource Path -PlatformPath $platform
$policy = Import-GuidePolicy -Path "$output/discovered-site.json"
Get-GuideContent -WorkspaceRoot $workspace -Policy $policy |
    Format-Table GuideId, EditionId, Language, State, WriteAllowed, Path
```

The explicit platform path keeps Prepare on the same installed package as Core, including when settings select a floating release family. If the installed package predates these commands, use the coordinated Update workflow first. If Prepare fails, read `<output>/prepare/assessment.md` and the reported error. Its discovered inventory may still support repairing the reported problem, but it is not evidence of a successful build. If discovery did not produce a valid file, resolve that failure before proceeding. Do not reuse an older run's inventory. Refresh Prepare after adding/removing guides, editions or languages or changing configuration.

In the OGP checkout, import `./system/OpenGuidePlatform.PowerShell.Core/OpenGuidePlatform.PowerShell.Core.psd1` instead of invoking the installed resolver, and use `./build.ps1 -Product GuideSite -SourcePath examples/reference-guide-site -Stage Prepare -Target preview -OutputPath $output`. Continue to use the repository root as WorkspaceRoot.

### Select, edit and apply

Replace these identifiers with values from the discovery table; there are no fixed guide counts or language lists:

```powershell
$selection = @{ GuideId = 'your-guide'; EditionId = 'your-edition'; Language = 'en' }
$document = Get-GuideContent -WorkspaceRoot $workspace -Policy $policy @selection
$document | Format-List GuideId, EditionId, Language, Path, WriteAllowed, WriteReason, Sha256
$candidatePath = Join-Path $workspace "$output/candidate-body.md"
[IO.File]::WriteAllText($candidatePath, $document.Body, [Text.UTF8Encoding]::new($false))
# Open $candidatePath in your preferred editor. Edit only the body, then save.
$body = [IO.File]::ReadAllText($candidatePath)
$change = @{
    WorkspaceRoot = $workspace; Policy = $policy
    ExpectedSha256 = $document.Sha256; CandidateBody = $body
}
Set-GuideContent @selection @change -WhatIf
# After reviewing the candidate and intended destination:
Set-GuideContent @selection @change
git diff -- $document.Path
```

Select an existing writable source document using that edition's SourceLanguage from discovery. Set-GuideContent refuses translations and protected content. Missing translations use New-GuideTranslation or the retained New-GuideTranslationScaffold. Keep the original reviewed hash: a stale-file rejection requires reading the new content and reconciling your correction, not just replacing the expected hash.

Get-GuideContent returns one object per matching translation, including missing files and protected selections. Filters match exact case-sensitive identifiers; unmatched filters fail with guidance. Set-GuideContent requires all three identifiers, preserves UTF-8 front matter bytes and accepts a nonempty replacement body. It returns `planned`, `unchanged` or `updated`, the path and hashes, and `VerificationRequired`. WhatIf does not write a file. Cooperative locks and a second hash check detect observed conflicts; they do not prevent every race with external editors. No other guide, metadata, configuration or PDF is rewritten.

### Verify the result

In the adopted site, run the full entry point for both publication targets:

```powershell
./build.ps1 -Target preview -PlatformSource Path -PlatformPath $platform
./build.ps1 -Target production -PlatformSource Path -PlatformPath $platform
```

In OGP, use `./build.ps1 -Product GuideSite -SourcePath examples/reference-guide-site -Target preview` and repeat with `-Target production`. Review failures and warnings, the content diff and rendered output. These builds do not deploy the site. Content corrections may make generated-PDF receipts stale; use the PDF workflow if the assessment requires regeneration. Supplied/protected PDFs remain untouched. A successful write or WhatIf is not a successful build or editorial approval.

Use `Get-Help Get-GuideContent -Full` and `Get-Help Set-GuideContent -Full` for command help. Agents use this same workflow and verification, with any proposed editorial changes scoped to the user's request.

### Command boundaries and edition independence

Commands operate on the exact guide, edition and language selected. A translation in one edition neither supplies a missing translation in another nor requires every edition to be translated. Source language is resolved per edition. Creation preserves existing targets; editing requires an existing target in that selected edition.

Set-GuideContent edits only the selected edition's source body. Set-GuideTranslation edits its translated document and requires both hashes. The shared document writer rechecks the operation, destination and same-edition source before staging and replacement. Wrapper commands reject guide content, and PDF commands accept only eligible declared PDF downloads. There is no Force switch to bypass these boundaries. These are command correctness checks under the supplied inventory, not restrictions on direct filesystem access by other tools.

## Wrapper publishing and readiness

For complete translation creation and source-change reconciliation, follow [Create and reconcile guide translations](TranslationReadiness/README.md). `Get-GuideTranslationWork`, `New-GuideTranslation`, `Test-GuideTranslation` and `Set-GuideTranslation` provide the same workflow to people and agents, including explicit Git source comparisons and reviewed source/target hashes. Existing scaffold and content commands remain available.

Set-GuideWrapperTranslation creates or applies exact reviewed candidate text to language-specific wrapper Markdown, YAML catalogues and selected Hugo language configuration entries. Existing files require ExpectedSha256; guide content and supplied-policy protected paths are refused. New languages must be disabled in production, unrelated configuration is preserved, and legacy shared download aliases cannot be extended. Changes are staged per file; a multi-file adoption is not one transaction.

Use the installed `./build.ps1 -Stage Prepare` assessment for both human/skill translation status and CI. It supplies effective Hugo catalogue/fallback evidence to Core. Local catalogue diagnostics alone must not replace that assessment. See [shared skill usage](../OpenGuidePlatform.Agents.Integration/skills/USAGE.md).

PDF replacement and cache-evidence checks are implemented. Prepare collects and validates declared generated-PDF receipts and retains them as build evidence. Supplied/protected PDFs do not require generation receipts or a PDF toolchain. Abrupt termination can leave staging/lock evidence for inspection; automatic crash recovery is not claimed. Translation quality, full plural-form coverage and runtime integration readiness are not inferred from available strings.

Fallback observation follows declared chains to populated web content and treats cycles, undeclared targets and non-web targets as unavailable. Edition snapshots publish by a same-parent directory rename after all files are copied. An existing destination is never replaced.

Contributor updates accept exact candidate YAML, one existing contributor name and the reviewed source SHA-256. They preserve the existing .yml/.yaml path and reject semantic changes to other records. Candidate comments and formatting must be reviewed because the command writes the supplied text exactly. A cooperative lock, staged replacement and second hash check catch observed conflicts; they are not an OS-level compare-and-swap against other editors. Existing site-specific roles are retained. Adding, removing and renaming records through this update operation are unsupported.

Generated PDFs can now be replaced using ExpectedOutputSha256. They remain untouched on rendering/input failures; supplied/protected downloads remain ineligible. A successful receipt can carry CacheKey when EnvironmentSha256 is supplied. Test-GuidePdfCache rechecks input/output hashes and recipe/tool/environment evidence; callers must provide a digest covering fonts, TeX packages and indirect resources. No timestamp-based reuse occurs. Local wrapper catalogue checks support YAML mappings/sequences and numeric/script language tags; effective Hugo fallback requires the evidence produced by Prepare, and plural completeness is not inferred. Required routes/integration points remain unknown until the build adapter provides observations.


### Retain generated-PDF evidence

For a `generated` download, declare `generationReceipt` in the reviewed site policy with a repository-relative JSON `path` and an approved `environmentSha256`. The digest must describe the reviewed fonts, TeX packages and indirect resources; do not invent it. Establish the policy before generation, since receipts bind its digest.

Capture the result of `New-GuidePdf -EnvironmentSha256 <approved-digest>`, then pass that result to `Save-GuidePdfReceipt -WorkspaceRoot ... -Policy ... -Receipt ... -ReceiptPath ...`. Existing receipt replacement requires its reviewed `-ExpectedReceiptSha256`. Review and commit the receipt with the generated PDF. This records generation evidence; it does not approve visual output.

Prepare validates receipt identity, PDF/input hashes, policy digest, approved environment digest and recorded toolchain. It retains the receipt in `prepare/pdf-receipts.json`; absent or stale evidence produces an actionable blocker. Routine builds never run Pandoc or compare against tools installed on the CI runner. Existing supplied/protected publications remain byte-preserved and need no receipt.


For a permanent guide or edition exclusion, declare `artifactPrefixes` alongside the rule (for example `guide-x/2026.1` and its existing language variants). These are reviewed public output prefixes, not inferred content IDs. Prepare checks that evidence can be gathered and reports the pending artifact check. Validate rejects files and indexed URLs under those prefixes for the selected target; Verify checks the excluded deployed routes. A preview build does not certify the production artifact. Permanent language exclusions retain their independent effective-production check during Prepare.


Existing legacy aliases may be recorded in `wrapper.legacyAliases`: exact source file, language, legacy alias values and observed output targets. Prepare rejects new or missing declarations, and Validate permits only their matching duplicate output counts. This preserves existing `/download/`, `/downloads/` and `/translationsdirectory/` compatibility without assigning a new owner or extending it to new languages. Other aliases and duplicate routes receive no exemption. Populate this record from the existing site during adoption; the platform does not add aliases.
