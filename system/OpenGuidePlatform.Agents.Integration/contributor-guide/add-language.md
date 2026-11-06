# Add a language to the website

Readers need menus, buttons and introductory pages in their language too. This page helps you prepare those parts of the website.

**Translating the guide itself comes afterwards.** A new language stays off the live website while the work is prepared and reviewed. If the language already exists, use the status report to agree only its missing website text. Do not disable a live language or recreate its existing pages; if no website work is needed, go to [translate a guide](translate-guide.md).

## Work with an agent

This route uses two OGP skills:

- [**guide.transstatus**](../skills/guide.transstatus/SKILL.md) finds out what already exists and what needs doing.
- [**guide.transcreate**](../skills/guide.transcreate/SKILL.md) prepares the website language using the supported workflow.

A **skill** is a set of instructions your agent follows. Paste the requests below into your agent's conversation; they are not terminal commands.

Your agent needs access to the guide site's files and its installed skills. If it cannot access them, ask a site maintainer—the person responsible for the website—for help. The agent must not replace these skills with a different translation workflow.

### 1. Choose the language and check what exists

Agree the language with the site team, including any regional variant. For example, Brazilian Portuguese and European Portuguese may need different wording.

Then send this request, replacing **Kannada** with your language:

> Use this site's installed **guide.transstatus** skill to check what is needed for Kannada. Do not change files. Confirm the language and its code with me rather than guessing. Explain what already exists, what needs doing for the website, and what guide translations exist separately. Report anything that prevents the work, and identify the installed version and status report you used. If you cannot access the files or load the skill, explain what help I need.

**You should receive:** an understandable list of the work needed. Existing translations should be identified, not replaced. Some guides deliberately provide only a PDF or use another language; those arrangements must be preserved.

### 2. Agree the website wording

Follow the site's translation policy. Agree who will review the wording and who will settle disagreements.

Make a short list of preferred translations for recurring terms. You can supply the words yourself or ask the agent to propose them. People still need to check their meaning and naturalness.

### 3. Ask the agent to prepare the language

> Use this site's installed **guide.transcreate** skill to add Kannada across the website. Use only that skill's documented workflow.
>
> First show the proposed website wording beside its source in this conversation. Do not change files until I approve the proposals.
>
> If this is a new website language, keep it excluded from the live website while we work. If it already exists, preserve its current availability and prepare only our agreed missing wording for review. Preserve existing translations, PDFs and deliberate language arrangements. Before creating any empty guide starting pages, show the eligible guides and editions and wait for me to choose which to include. Leave guide bodies untranslated.
>
> Run the required checks and explain the results. If the skill cannot complete a step, report what is missing and ask for maintainer help; do not invent another way.

The agent handles the work in this order:

1. For a new language, exclude it from the live website before adding its language settings. For an existing language, preserve its settings and availability unless a separate change was agreed.
2. Prepare the website wording: menus, buttons, homepages and pages for finding guides, editions and translations.
3. Prepare any other supported reader-facing website text.
4. Show which guides and editions can have empty starting pages. You choose which to include; only then does the agent create them for later guide translation.

**An empty starting page is not a translated guide.**

### 4. Review what readers will see

Ask the agent how to view the prepared website. If no review version is available, ask the maintainer to arrange one.

Read it in the new language. Check the menus, buttons, links and how the letters appear on both a phone and a larger screen.

The agent should report:

- What changed and what was preserved.
- Which guide starting pages remain empty.
- Which checks passed, failed or have not been completed.
- Whether a new language remains excluded from the live website, or an existing language's availability was preserved.

Passing software checks does not establish that the translation reads correctly.

### 5. Share the work or continue translating

Once the website wording has been reviewed and the required checks pass, continue to [translate a guide](translate-guide.md).

You can also [submit this stage for review](validation.md) first. Explain that the website language is being prepared and guide starting pages are still empty.

**Submitting work asks the site team to review it. It does not publish the language.**

## I do not have an agent and want to do this manually

### Before you start

Complete [setup](setup.md#i-do-not-have-an-agent-and-want-to-do-this-manually) first. The contributor module must be installed and PowerShell must be open in the local folder of your fork, containing `build.ps1`. Start at the first block on this page and keep the same window open; every value used below is set on this page. If you closed the window, reopen that folder and repeat the blocks you need. Agree the language, preferred terms and reviewers with the site team. This task prepares website wording and selected empty guide starting pages; it does not translate guide bodies. If the language is already configured, agree only the missing work with the maintainer. Do not disable an existing published language just to repeat setup.

### Run the PowerShell steps

#### 1. Find the actual language settings

```powershell
$language = Read-Host 'Enter the language code agreed with the team'
$work = Get-OGPTranslationStatus -Language $language
$work.Configuration | Format-List
```

**You should see:** `ProductionPath` and `MainPath`, identifying the site's actual settings files. If either is missing, ask the maintainer to repair setup. Do not create a guessed configuration file.

#### 2. Keep the language off the live website first

```powershell
$draft = New-OGPWrapperDraft -Language $language -RelativePath $work.Configuration.ProductionPath
$draft | Format-List Path, SourcePath, Next
$originalSettings = Join-Path $PWD.Path $work.Configuration.ProductionPath
$originalSettings
```

**You should see:** a full draft `Path`, then the full path of the original settings file. `SourcePath` identifies the original settings file; the last line also prints that original path for comparison. The live settings file has not changed. Ask the maintainer for the reviewed language entry and exactly where it belongs. It must keep this new language disabled in production—the live website. If YAML settings are unfamiliar, ask the maintainer to prepare or check that entry with you; do not infer settings from another language.

Open your plain-text editor—the editor agreed during setup—and choose **File → Open**. Paste the full `Path` printed by the command. That is your draft, not the website's current file. Open `SourcePath` in another tab to read the original beside the draft. For language settings, this is the current settings file selected in the report. Compare it without editing the original. If an expected file cannot be opened, give its printed path to the maintainer instead of editing a different file.

Save the words in your editor and have the agreed language reviewer check them. Saving in the editor changes only the draft. It does not yet apply the words to the website.

Apply the reviewed settings through these same two commands:

```powershell
Save-OGPDraft -Path $draft.Path -Reviewed -WhatIf
```

`-Reviewed` says you reviewed this exact draft. `-WhatIf` prints a preview naming the intended file without applying it; translation previews can also return `Status: planned`. A website-settings preview may print only the WhatIf message, with no result object. Temporary reports can still be written. If the command throws an error, stop and resolve it with the maintainer. This preview does not certify meaning: complete the agreed human wording review before the real save.

When the wording and preview have been reviewed and you are authorised to apply them, run:

```powershell
Save-OGPDraft -Path $draft.Path -Reviewed
```

**You should see:** an applied result of `updated`, or `unchanged` when the same content is already present. Check its destination is the file you intended. If a source, target or site version changed while you worked, create a fresh draft from the latest files, carry across only the still-agreed wording, and review again. Do not change the stored check information to force the old draft through.

#### 3. Add the main language settings

Refresh the report after changing settings:

```powershell
$work = Get-OGPTranslationStatus -Language $language
$draft = New-OGPWrapperDraft -Language $language -RelativePath $work.Configuration.MainPath
$draft | Format-List Path, SourcePath, Next
$originalSettings = Join-Path $PWD.Path $work.Configuration.MainPath
$originalSettings
```

Ask the maintainer for the approved main language entry, including its name, reading direction and any site-specific choices. Open the returned draft, apply only that entry, save it and review it. Run the two `Save-OGPDraft` commands in step 2 again using this new `$draft`. Confirm the production exclusion remains in place.

#### 4. Translate the website words

```powershell
$work = Get-OGPTranslationStatus -Language $language
$work.Wrappers | Format-Table Kind, SourcePath, TargetPath, State, SupportedOperation -Wrap
$file = Read-Host 'Copy one agreed supported TargetPath from the website-wording table'
```

Find that selected row's `Kind` and `SupportedOperation` in the table. If no supported operation is shown, stop and ask the maintainer. **If its kind is `json-text-selection-required`, skip the next block** and use the JSON steps below. All other supported rows use this ordinary draft block:

```powershell
$draft = New-OGPWrapperDraft -Language $language -RelativePath $file
$draft | Format-List Path, SourcePath, Next
```

**For JSON rows only:** ask the maintainer for the exact field selector before creating the draft. It identifies one translatable value inside that site's file; you do not need to derive it. The command refuses JSON text work without this selection. For one selector supplied by the maintainer:

```powershell
$field = Read-Host 'Paste one exact text-field selector supplied by the maintainer'
$draft = New-OGPWrapperDraft -Language $language -RelativePath $file -JsonTextPaths $field
$draft | Format-List Path, SourcePath, Next
```

After the appropriate block returns a draft, open its printed `Path` and read `SourcePath` alongside it. Work on the homepage, guide landing pages, messages, history and translation listings identified by the report. Translate reader-facing words, preserving keys, links and placeholders such as `{{ .Site.Title }}`. For JSON, change only the selected value. Review and apply the draft with the two save commands from step 2. Repeat with a fresh draft for another agreed value. Existing populated translations must not be replaced unless that update was agreed; unsupported work goes to the maintainer.

#### 5. Choose empty guide starting pages

```powershell
$work = Get-OGPTranslationStatus -Language $language
$work.Guides | Format-Table GuideId, EditionId, State, Intent, CanCreateScaffold -Wrap
```

Choose eligible guide editions with the team. Do not automatically select every old edition. For one agreed row where `CanCreateScaffold` is true:

```powershell
$guide = Read-Host 'Copy the agreed GuideId from that row'
$edition = Read-Host 'Copy its EditionId'
New-OGPTranslation -GuideId $guide -EditionId $edition -Language $language -WhatIf
```

Read the preview and confirm it names the intended guide. After approval, create that empty page:

```powershell
New-OGPTranslation -GuideId $guide -EditionId $edition -Language $language
```

**You should see:** a `created` result for the selected starting page. Its body stays empty. Do not use this to replace an existing translation, protected content, a PDF-only guide or a deliberate fallback to another language.

### Check the result

```powershell
Get-OGPTranslationStatus -Language $language
Test-OGPSite
Show-OGPSite
```

The first command refreshes the work report. The next checks preview and production without publishing. The last prints a local website address: copy it into your browser, keep PowerShell open while reviewing, and press **Ctrl+C** there when finished. If no review site can be started, ask the maintainer for an arrangement instead of claiming it was inspected.

Check the agreed website words, menus and links on a phone-sized and larger view. Confirm the selected guide bodies are still empty, supplied PDFs and existing translations are intact, and the new language remains off the live website. Resolve failures before calling this stage ready. Continue to [translate a selected guide](translate-guide.md#i-do-not-have-an-agent-and-want-to-do-this-manually), or [submit the website-only stage](validation.md#i-do-not-have-an-agent-and-want-to-do-this-manually) clearly marked as unfinished guide translation. [Command reference](../../OpenGuidePlatform.PowerShell.Contributor/README.md#prepare-the-website-language).

If a command fails, stop at that step. Send the maintainer the page, step, expected result and exact visible error. Include the printed report folder if available; leave out passwords and access tokens. Do not change software versions, delete existing files or bypass a refusal to make the command continue.
