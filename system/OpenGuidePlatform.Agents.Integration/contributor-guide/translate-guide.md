# Translate a guide

Choose the guide, edition (version) and language with the site team. If the website has not been prepared for this language, first follow [add a language](add-language.md). You do not need to translate every older edition.

## Work with an agent

This task uses [guide.transcreate](../skills/guide.transcreate/SKILL.md) for a separately selected guide translation. Use [guide.transstatus](../skills/guide.transstatus/SKILL.md) first if you do not know what exists. If you need help opening the site in an agent, start with [setup](setup.md).

Replace the example selections with the guide, edition and language agreed with your team:

> Use this site's installed **guide.transcreate** skill to translate the body of our selected guide and edition into Kannada. Confirm the exact selections with me before proceeding. Use our agreed terms and site policy. Show proposed passages beside their source in this conversation and wait for my approval before changing files. Preserve links, references, meaningful formatting, settings, existing PDFs and other editions. Follow only the skill's supported workflow and checks. Report anything it cannot do instead of inventing another way.

You can write the translation yourself or ask for a proposal. Work a section at a time if that makes review easier. Ask the language reviewer about unclear meaning, defined terms, licences and source conventions such as italics. The agent must not silently decide these for you.

**You should receive:** source and proposed wording, questions needing a human answer, the exact source used, and results of the skill's checks. A software check is not a language review. If someone changed the source while you worked, the agent must compare the changes and seek renewed review rather than overwrite them.

Use [review wording](review-wording.md) to give corrections. If this is an existing translation being brought up to date with source changes, use [guide.transreconcile](../skills/guide.transreconcile/SKILL.md) through [update a translation](update-translation.md).

**Next:** [credits and PDFs](credits-pdfs.md), then [check and submit](validation.md). The intended guide should contain the reviewed words; an empty starting page or generated proposal is unfinished work.

## I do not have an agent and want to do this manually

### Before you start

Complete [setup](setup.md#i-do-not-have-an-agent-and-want-to-do-this-manually) first. The contributor module must be installed and PowerShell must be open in the local folder of your fork, containing `build.ps1`. Start at the first block on this page and keep the same window open; every value used below is set on this page. If you closed the window, reopen that folder and repeat the blocks you need. The [website-language stage](add-language.md#i-do-not-have-an-agent-and-want-to-do-this-manually) must be ready first. Agree the guide, edition, language, preferred terms and reviewer. You can write the translation yourself; no agent is needed.

### Run the PowerShell steps

#### 1. Select the guide and edition

```powershell
$language = Read-Host 'Enter the language code agreed with the team, for example kn'
$work = Get-OGPTranslationStatus -Language $language
$work.Guides | Format-Table GuideId, EditionId, State, Intent, CanCreateScaffold -Wrap
$guide = Read-Host 'Copy the GuideId of the guide you selected from the table'
$edition = Read-Host 'Copy its EditionId from that same row'
```

**You should see:** the actual guides and editions for this language. The names are identifiers: copy them exactly, including capitals. An edition is a version of a guide. Do not copy identifiers from another site's example. If the selected row is protected, excluded, deliberately uses another language or only provides a PDF, ask the maintainer; do not convert it into a new web translation.

If an eligible starting page is missing, create it through step 5 of [add a language](add-language.md#i-do-not-have-an-agent-and-want-to-do-this-manually). For an existing translation, keep its current words and skip creation.

#### 2. Make a separate draft

```powershell
$draft = New-OGPTranslationDraft -GuideId $guide -EditionId $edition -Language $language
$draft | Format-List Path, SourcePath, Next
```

**You should see:** the proposed file's `Path` and the current source's `SourcePath`. Neither original is changed by making the draft.

Open your plain-text editor—the editor agreed during setup—and choose **File → Open**. Paste the full `Path` printed by the command. That is your draft, not the website's current file. Open `SourcePath` in another tab to read the source beside the draft without editing the original. If an expected file cannot be opened, give its printed path to the maintainer instead of editing a different file.

Save the words in your editor and have the agreed language reviewer check them. Saving in the editor changes only the draft. It does not yet apply the words to the website.

The section between `---` lines at the top contains page settings. Translate only agreed `title`, `description` and `summary` wording there; preserve other settings. Translate the body after that section, keeping headings, references, links, deliberate emphasis and software placeholders. Ask the language reviewer how source conventions should transfer. [Files explained](files.md#i-do-not-have-an-agent-and-want-to-do-this-manually) shows simple examples.

#### 3. Preview and apply the reviewed words

```powershell
Save-OGPDraft -Path $draft.Path -Reviewed -WhatIf
```

`-Reviewed` says you reviewed this exact draft. `-WhatIf` prints a preview naming the intended file without applying it; the translation preview returns `Status: planned`. Temporary reports can still be written. If the command throws an error, stop and resolve it with the maintainer. This preview does not certify meaning: complete the agreed human wording review before the real save.

When the wording and preview have been reviewed and you are authorised to apply them, run:

```powershell
Save-OGPDraft -Path $draft.Path -Reviewed
```

**You should see:** an applied result of `updated`, or `unchanged` when the same content is already present. Check its destination is the file you intended. If a source, target or site version changed while you worked, create a fresh draft from the latest files, carry across only the still-agreed wording, and review again. Do not change the stored check information to force the old draft through.

### Check the result

The intended guide should contain your reviewed translation. An empty page or unreviewed proposal is not complete. Follow [credits and PDFs](credits-pdfs.md#i-do-not-have-an-agent-and-want-to-do-this-manually), then [check and submit](validation.md#i-do-not-have-an-agent-and-want-to-do-this-manually). Those steps include viewing the website, not just saving text. [Command reference](../../OpenGuidePlatform.PowerShell.Contributor/README.md#translate-separately-selected-guides).

If a command fails, stop at that step. Send the maintainer the page, step, expected result and exact visible error. Include the printed report folder if available; leave out passwords and access tokens. Do not change software versions, delete existing files or bypass a refusal to make the command continue.
