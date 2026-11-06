# Translate using PowerShell

This command interface is implemented in the current development branch. **It
has not yet been published to PowerShell Gallery.** A maintainer must publish
the module before the installation command below will work. Installing the
module does not install OGP into a website or upgrade that website.

## Open your local website folder

Start with your GitHub fork and its local copy. A fork is your copy of the
website's repository on GitHub; the local copy is the folder on your computer
where you edit it. If you do not have these yet, ask the website team to help
you follow its contribution instructions.

Install [PowerShell 7.4 or later](https://aka.ms/powershell-release?tag=stable).
On Windows, open **PowerShell 7**, rather than Windows PowerShell. In File
Explorer, find your local website folder and copy its full address. In
PowerShell, type `Set-Location`, a space, and that address in double quotes:

```powershell
Set-Location "C:\Users\YourName\Documents\your-website"
```

Replace the example address with yours. Press Enter to run each command. Keep
this PowerShell window open while working. If you open another window later,
run Set-Location again. Every command below runs from this same folder.

Your website team must already have installed OGP into this website. You also
need [Git](https://git-scm.com/downloads), [GitHub CLI](https://cli.github.com/),
[Hugo Extended](https://gohugo.io/installation/) and
[Go](https://go.dev/doc/install). OGP needs Hugo Extended 0.146 or later and Go
1.24.5 or later; the website may require newer versions. Ask the team for its
supported versions if you are unsure. PDF creation additionally needs Pandoc,
XeLaTeX and the fonts selected by the website; other tasks do not need them.

## Install the contributor commands

After the maintainer confirms Gallery publication, open **PowerShell 7 as
administrator** on Windows: find PowerShell 7 in Start, right-click it and
choose **Run as administrator**. Follow your organisation's installation
policy; ask an administrator to install the module if you cannot do this.
Then run:

```powershell
Install-Module OpenGuidePlatform -Repository PSGallery -Scope AllUsers
```

This installs the commands and their YAML dependency for all users. It needs
permission to install software on the computer. PowerShell may ask you to confirm
installation from PowerShell Gallery. For a preview-only module release, use
the same command with `-AllowPrerelease`, only when the maintainer asks you to.
If PowerShell reports that no matching module exists, confirm publication with
the maintainer. Do not download another module with a similar name.

After installation, close the administrator window and return to the ordinary
PowerShell window opened in your local website folder. Daily translation work
does not require an administrator window. This workflow does not use
per-user module installation as a workaround where that scope is disabled.
When installation succeeds, PowerShell returns to its prompt without an error.
The first status command below confirms that the task commands are available.

You do not need an Import-Module command. PowerShell loads these commands when
you use them. Each task uses the OGP release already selected by this website,
runs its preparation checks and prints its version and report folder. The
module's version and the website's version can differ. A missing operation
requires a maintainer's coordinated website update.

If a download or sign-in fails, run `gh auth login` and follow GitHub CLI's
sign-in prompts, then retry. If a prerequisite is missing, install the named
tool or ask the team for help. Keep the full error and report location.

## Find the work

Agree the language and its code with the website team. These examples use
`kn` for Kannada; replace it with your agreed code throughout.

```powershell
$work = Get-OGPTranslationStatus -Language kn
$work.Configuration | Format-List
$work.Wrappers | Format-Table Kind, SourcePath, TargetPath, State, SupportedOperation -Wrap
$work.Guides | Format-Table GuideId, EditionId, SourcePath, TargetPath, State, Intent, CanCreateScaffold -Wrap
$work.Findings | Format-List
```

Expect website configuration, website text files, guide editions and findings.
An edition is one version of a guide. A missing translation is work to discuss,
not an instruction to translate every edition. Existing text, protected pages,
supplied PDFs and deliberate fallback to another language must be preserved.
A warning that Prepare failed means checks remain unresolved; it is not a
successful validation. Its discovery report may still help you repair them.

## Prepare the website language

Ask the team to review the proposed language settings. Start with the
`ProductionPath` shown under `Configuration`:

```powershell
New-OGPWrapperDraft -Language kn -RelativePath site/hugo.production.yaml
```

Replace the example path with the report's exact path. The command returns a
draft `Path` and leaves the website file unchanged. Open that draft in your
text editor. Add the agreed language under `languages` with `disabled: true`.
Preserve all other settings. Have the team check this first configuration edit
if you are unfamiliar with YAML.

Save your editor changes, then preview applying them. Replace the example
draft path with the full `Path` the command returned:

```powershell
Save-OGPDraft -Path "C:\path\returned\candidate.yaml" -Reviewed -WhatIf
Save-OGPDraft -Path "C:\path\returned\candidate.yaml" -Reviewed
```

The first command checks the candidate without changing the website file. The
second applies it after your review. `-Reviewed` records that you reviewed this
exact candidate; it does not approve publication. If the source, destination
or website's OGP version changed, OGP refuses the save. Compare the changes,
create a new draft and review it again.

Repeat the status command. Draft and review `MainPath` to add the language's
main settings. Then select supported `TargetPath` entries from `Wrappers` to
draft interface messages and website pages with New-OGPWrapperDraft. Preserve
formatting, keys, placeholders and URLs. Translate reader-facing words only.
JSON files require explicitly selected text fields using `-JsonTextPaths`;
ask the maintainer to identify these fields. Unsupported files need maintainer
help. Do not copy another language's files or bypass a refusal with direct edits.

## Translate separately selected guides

After website preparation, choose eligible guide editions with the team. Use
the report's exact `GuideId` and `EditionId`:

```powershell
New-OGPTranslation -GuideId guide-a -EditionId 2026 -Language kn -WhatIf
New-OGPTranslation -GuideId guide-a -EditionId 2026 -Language kn
New-OGPTranslationDraft -GuideId guide-a -EditionId 2026 -Language kn
```

These identifiers are examples; replace both with the report's values. The
first two commands preview and create an eligible empty page. An empty page is
not a translated guide. For an existing translation, skip those two commands.
New-OGPTranslationDraft returns an editable copy and records its starting
source. Open both its `Path` and `SourcePath` in your editor so the source and
draft are visible side by side. Translate or revise its body and reader-facing title, description and
summary; preserve all other metadata. Review it against the actual source
with a native speaker, save it in your editor, and apply it using the two
Save-OGPDraft commands above with this draft's path. Inspect the website diff
with the team after applying each change.

For a source update, agree the comparison commit with the team. Add
`-SourceRevision` followed by that commit to New-OGPTranslationDraft. If the
source moved, also supply its old repository-relative `-SourcePathAtRevision`.
The command returns `SourceBaselinePath` and `SourceDifferencePath`; open both
alongside the current `SourcePath` and translation draft. The difference file
marks removed lines with `-` and added lines with `+`. Empty differences mean
these sources match. This is your explicitly chosen comparison, not proof of
which revision the previous translator used. Saving retains the resolved
comparison commit and still refuses changed current source or target content.

## Credits and PDFs

To inspect attribution, run this with the report's actual guide and edition:

```powershell
$credits = Get-OGPCredits -GuideId guide-a -EditionId 2026 -Language kn
$credits.Authors | Format-List
$credits.Contributors | Format-List
$credits.Translators | Format-List
```

The last list includes every supported translation-team role, including
reviewers. Obtain each person's consent before adding a credit:

```powershell
New-OGPContribution -GuideId guide-a -EditionId 2026 -Language kn -Name "Example Person" -Role translator -ConsentConfirmed -WhatIf
```

Replace the name with the consented published name. Add `-GitHubUsername` when
the person supplies it. Review the proposed name, role and edition; remove
`-WhatIf` to add the credit. Existing records are preserved. To correct an
existing credit, ask the maintainer or use the installed guide.contributions
skill rather than adding a duplicate identity.

To see declared download paths and handling, run:

```powershell
$work.Guides | Where-Object { $_.GuideId -eq 'guide-a' -and $_.EditionId -eq '2026' } | ForEach-Object { $_.Downloads } | Format-List
```

Use Get-OGPPdfPlan with the same selection and a declared `-DownloadPath` from
that list. A supplied or protected PDF cannot be generated. For a new
eligible PDF, the maintainer must first supply separately reviewed site-policy
setup, an approved generation environment and a receipt declaration. The
installed guide.genpdfs skill does not supply that setup or approval procedure.
Source discovery does not currently invent generated-PDF declarations
or environment evidence; a missing capability is a blocker requiring maintainer
help. When the selected policy provides that evidence, New-OGPPdf uses it and
saves the generation receipt automatically. It refuses generation without that
evidence and reports any receipt-save failure explicitly. Existing PDFs require
the maintainer's reviewed regeneration procedure or installed guide.genpdfs
skill. People must open and inspect any generated PDF; generation alone is not
visual approval.

## Check and submit

```powershell
Test-OGPSite
```

This builds and validates both preview and production locally. It does not
deploy or publish. A failure means checks remain unresolved: share the error
and printed report folder with the website team. When checks pass, inspect the
rendered website by running:

```powershell
Show-OGPSite
```

Keep this window open. Copy the local website address printed by Hugo into your
browser and inspect navigation, links, translated letters and layout. Return to
PowerShell and press **Ctrl+C** to stop the server. Open any generated PDF in
your PDF viewer and inspect it with the team. Then follow the website's pull
request instructions. Keep the language excluded from production. Maintainers
arrange canary and preview review; guardian approval and a separate production
decision are still required. Report unfinished work explicitly.

## Working with an agent

Explicitly ask the agent to use the website's **installed** `guide.transstatus`,
`guide.transcreate`, `guide.transreconcile`, `guide.contributions` and
`guide.genpdfs` skills for the matching tasks. If it cannot load a required
skill, ask the maintainer for help. These commands and those skills use the
same Core operations and publishing rules; the module does not replace skills.

For command options, use `Get-Help Get-OGPTranslationStatus -Full`, replacing
the name with the command you want. `-WorkspaceRoot` selects a different local
website folder. `-PlatformPath` is an explicit engineering candidate override
for package testing, not the normal contributor setup.
