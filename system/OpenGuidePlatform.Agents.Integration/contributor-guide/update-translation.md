# Update a translation

Keep the useful translated passages and change only what needs attention. First agree which guide, edition and language you are updating, and which source change you are comparing with.

## Work with an agent

Use [guide.transreconcile](../skills/guide.transreconcile/SKILL.md). It compares source changes with the existing translation and applies reviewed corrections through the installed workflow. If you need help accessing the site, use [setup](setup.md).

> Use this site's installed **guide.transreconcile** skill for our selected guide, edition and language. Help us identify and agree the earlier source version to compare with; do not invent which source was previously translated. Show changed source passages beside the existing translation and your proposed corrections. Wait for my approval before changing files. Keep good existing wording and report conflicting feedback or unclear meaning. Use only the installed skill's supported checks and operations; explain anything it cannot do and ask for maintainer help.

**You decide:** the comparison point and wording, with the language reviewer. If the earlier source is unknown, record that uncertainty and agree a comparison point. A recent translation date does not establish it.

**You should receive:** a traceable list of source changes, agreed corrections, preserved text and unresolved questions. The agent should report actual checks and identify the version used, rather than declaring the translation current just because the file exists.

For a translation typo, the same installed skill supports reviewed corrections within the selected scope; do not ask for an unrelated file-edit workflow. Source-language guide corrections have a different boundary: see [content changes](content.md).

**Next:** [review wording](review-wording.md), then [check and submit](validation.md).

## I do not have an agent and want to do this manually

### Before you start

Complete [setup](setup.md#i-do-not-have-an-agent-and-want-to-do-this-manually) first. The contributor module must be installed and PowerShell must be open in the local folder of your fork, containing `build.ps1`. Start at the first block on this page and keep the same window open; every value used below is set on this page. If you closed the window, reopen that folder and repeat the blocks you need. For an ordinary wording correction or typo, use the existing-target path in [translate a guide](translate-guide.md#i-do-not-have-an-agent-and-want-to-do-this-manually); no historical source comparison is required just to correct agreed words.

For source changes, ask the maintainer and language reviewer: “Which earlier source version should we compare with? Please give me its full Git commit identifier, and the old source file path if it moved.” The identifier is a saved point in the source history, not a date or a translation's modification time. If nobody knows which source was originally translated, record that uncertainty and agree a useful comparison point; do not invent history.

### Run the PowerShell steps

#### 1. Select the existing translation

```powershell
$language = Read-Host 'Enter the language code agreed with the team, for example kn'
$work = Get-OGPTranslationStatus -Language $language
$work.Guides | Format-Table GuideId, EditionId, State, Intent, CanCreateScaffold -Wrap
$guide = Read-Host 'Copy the GuideId of the guide you selected from the table'
$edition = Read-Host 'Copy its EditionId from that same row'
```

**You should see:** the actual guides and editions for this language. The names are identifiers: copy them exactly, including capitals. An edition is a version of a guide. Do not copy identifiers from another site's example. If the selected row is protected, excluded, deliberately uses another language or only provides a PDF, ask the maintainer; do not convert it into a new web translation.

#### 2. Supply the comparison agreed by the team

```powershell
$comparison = Read-Host 'Paste the full source commit identifier agreed with the team'
$oldPath = Read-Host 'Paste the old source path if the team supplied one; otherwise press Enter'
if ($oldPath) {
    $draft = New-OGPTranslationDraft -GuideId $guide -EditionId $edition -Language $language -SourceRevision $comparison -SourcePathAtRevision $oldPath
} else {
    $draft = New-OGPTranslationDraft -GuideId $guide -EditionId $edition -Language $language -SourceRevision $comparison
}
$draft | Format-List Path, SourcePath, SourceBaselinePath, SourceDifferencePath, ComparisonCommit
```

The block chooses the right call depending on whether the old path was supplied. **You should see:** the editable draft, current source, earlier source copy, source-difference file and the exact comparison identifier. If the commit or file is unavailable, ask the maintainer to obtain the correct history; do not substitute a different guide or revision to make it run.

#### 3. Read what changed and correct the draft

Open the printed `SourceBaselinePath` and `SourcePath` in your editor to read the earlier and current source. Open `SourceDifferencePath` for the changed passages. In that difference file, content lines beginning `-` show removed text and `+` show added text; file-header lines identify the versions being compared. Ask the maintainer for a side-by-side explanation if that view is unfamiliar.

Open the draft's `Path`. Keep useful translated passages, correct the affected wording, and record questions for the reviewer. Have the language reviewer compare the proposal with the source changes. Save the draft in your editor.

#### 4. Apply only the reviewed correction

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

The comparison identifier is retained through the save. Record what source you compared, what changed, what was kept and what remains unresolved. It does not prove that the earlier translation originally used that version. Follow [check and submit](validation.md#i-do-not-have-an-agent-and-want-to-do-this-manually). [Command reference](../../OpenGuidePlatform.PowerShell.Contributor/README.md#translate-separately-selected-guides).

If a command fails, stop at that step. Send the maintainer the page, step, expected result and exact visible error. Include the printed report folder if available; leave out passwords and access tokens. Do not change software versions, delete existing files or bypass a refusal to make the command continue.
