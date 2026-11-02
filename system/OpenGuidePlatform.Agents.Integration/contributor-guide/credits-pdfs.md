# Credit people and prepare PDFs

People should be credited as agreed, and downloads should show the right words. Adding a translation does not automatically create a new PDF.

## Work with an agent

Use [guide.contributions](../skills/guide.contributions/SKILL.md) for credits and [guide.genpdfs](../skills/guide.genpdfs/SKILL.md) only for eligible generated PDFs. If the agent cannot access the site and its installed skills, follow [setup](setup.md) with the maintainer.

### Agree the credits

Ask each person which name, role and optional profile link they consent to publish. Follow the site's acknowledgement rules and preserve existing credits.

> Use this site's installed **guide.contributions** skill for the guide, edition and language we selected. Show the existing credits and exact proposed changes in this conversation. Wait for my approval before changing files. Use only the details and consent we supplied. Preserve other people and their roles. If the requested change is unsupported or ambiguous, explain it and ask the maintainer; do not guess identities or use another workflow.

**You should receive:** the proposed credit records and, after the agreed supported change, the names as readers will see them. Check spelling, links and roles. Do not infer a person's identity from a similar name.

### Check whether a PDF can be created

> Use this site's installed **guide.genpdfs** skill to inspect the selected download. Tell me whether it is an eligible generated PDF or a supplied/protected original. Preserve supplied originals. For an eligible generated PDF, show the exact plan and explain missing tools, fonts and required presentation decisions. Wait for my approval before changing files or generating the PDF. Use only the skill's documented workflow. Report what cannot be done instead of substituting fonts or another method.

The skill can generate only downloads explicitly configured for generation. Agree any necessary presentation changes with the maintainer first. The agent must not silently install software, replace supplied PDFs or treat a file being produced as visual approval.

**You should receive:** the generation/check results and the actual new PDF when eligible and authorised. People must inspect its title, letters, reading direction, links, credits and page breaks. If it is not eligible or tools are missing, ask the maintainer what happens next.

**Next:** [check and submit](validation.md). Correct credit data and a technically valid PDF still need human review.

## I do not have an agent and want to do this manually

### Before you start

Complete [setup](setup.md#i-do-not-have-an-agent-and-want-to-do-this-manually) first. The contributor module must be installed and PowerShell must be open in the local folder of your fork, containing `build.ps1`. Start at the first block on this page and keep the same window open; every value used below is set on this page. If you closed the window, reopen that folder and repeat the blocks you need. Agree the guide, edition and translated language. Obtain each person's consent for the exact published name, role and optional account link. Preserve existing credits and any acknowledgement required by site policy. The add command below is for new translation-team members; source-author credits and corrections to existing records need the maintainer's reviewed procedure. Adding credits does not regenerate PDFs.

### Run the PowerShell steps

#### 1. Select the guide and inspect its credits

```powershell
$language = Read-Host 'Enter the language code agreed with the team, for example kn'
$work = Get-OGPTranslationStatus -Language $language
$work.Guides | Format-Table GuideId, EditionId, State, Intent, CanCreateScaffold -Wrap
$guide = Read-Host 'Copy the GuideId of the guide you selected from the table'
$edition = Read-Host 'Copy its EditionId from that same row'
```

**You should see:** the actual guides and editions for this language. The names are identifiers: copy them exactly, including capitals. An edition is a version of a guide. Do not copy identifiers from another site's example. If the selected row is protected, excluded, deliberately uses another language or only provides a PDF, ask the maintainer; do not convert it into a new web translation.

```powershell
$credits = Get-OGPCredits -GuideId $guide -EditionId $edition -Language $language
$credits.Authors | Format-Table name, role, url -Wrap
$credits.Contributors | Format-Table name, role, url -Wrap
$credits.Translators | Format-Table name, role, url -Wrap
```

**You should see:** the selected edition's guide credits and translation-team records, with roles shown. Check whether the person is already credited. Do not add a duplicate to correct an existing record; ask the maintainer for its reviewed update procedure.

#### 2. Add one consented translator or reviewer

```powershell
$name = Read-Host 'Enter the exact name this person agreed to publish'
$role = Read-Host 'Enter the agreed role: translator or reviewer'
$username = Read-Host 'Enter the GitHub username they supplied for publication, or press Enter for none'
New-OGPContribution -GuideId $guide -EditionId $edition -Language $language -Name $name -Role $role -GitHubUsername $username -ConsentConfirmed -WhatIf
```

Type the role exactly as shown, in lower case. `-ConsentConfirmed` states that consent has actually been obtained; it does not obtain it. The preview should show the proposed operation without adding the person. If the name, role or edition is wrong, correct the values and preview again. When approved:

```powershell
New-OGPContribution -GuideId $guide -EditionId $edition -Language $language -Name $name -Role $role -GitHubUsername $username -ConsentConfirmed
$credits = Get-OGPCredits -GuideId $guide -EditionId $edition -Language $language
$credits.Translators | Format-Table name, role, url -Wrap
```

Confirm the new record and unchanged existing people. A blank username leaves that optional account link out. Do not guess an account or substitute a different name after a duplicate/ambiguity error. Other profile-link changes need the maintainer's supported procedure; do not invent a command parameter.

#### 3. Find out whether a PDF can be generated

```powershell
$work = Get-OGPTranslationStatus -Language $language
$work.Guides | ForEach-Object { $_.Downloads } | Format-List
```

Ask the maintainer which exact declared download belongs to this guide, edition and language. An existing supplied/protected PDF must stay unchanged. If the team confirms a new declared generated PDF is needed:

```powershell
$download = Read-Host 'Paste the exact declared download path confirmed by the maintainer'
$plan = Get-OGPPdfPlan -GuideId $guide -EditionId $edition -Language $language -DownloadPath $download
$plan | Format-List
$plan.Output
```

**You should see:** the selected input, output file, settings and font/tool requirements. A refusal for supplied or protected content means stop. Ask the maintainer to resolve missing tools/fonts or presentation choices; do not silently substitute fonts or invent a download declaration.

#### 4. Arrange complete generation evidence

After the plan and requirements are reviewed, you can preview an eligible new PDF without generating it:

```powershell
New-OGPPdf -GuideId $guide -EditionId $edition -Language $language -DownloadPath $download -WhatIf
```

Before generating, ask the maintainer to confirm that this download declares both an approved fonts/tool environment and a location for its generation receipt—the record needed to check how the PDF was made. The command cannot establish those decisions for you. If either is missing, stop and ask for the [reviewed generation and receipt procedure](../../OpenGuidePlatform.PowerShell.Core/README.md#retain-generated-pdf-evidence). If a PDF or receipt already exists, preserve it and ask for the reviewed regeneration procedure; do not delete either to force generation.

Once the maintainer confirms those declarations and you approve the preview, run generation separately:

```powershell
$result = New-OGPPdf -GuideId $guide -EditionId $edition -Language $language -DownloadPath $download
$result | Format-List Status, Path, ReceiptPath, VisualReviewRequired, ValidationRequired
```

**You should see:** the new PDF path and its saved receipt path, with visual review and validation still required. If saving the receipt fails, a PDF may already have been created. Stop and send the error to the maintainer; do not rerun or delete files to bypass it.

### Check the result

After the maintainer completes generation and the required receipt, open the actual output path in a PDF viewer. With reviewers, check the title, letters, reading direction, links, names, meaningful emphasis and page breaks. A generated file is not proof that these are right. Submit the reviewed generated PDF and its required receipt together; PDF covers can select different credit roles according to site settings. Follow [check and submit](validation.md#i-do-not-have-an-agent-and-want-to-do-this-manually). [Command reference](../../OpenGuidePlatform.PowerShell.Contributor/README.md#credits-and-pdfs).

If a command fails, stop at that step. Send the maintainer the page, step, expected result and exact visible error. Include the printed report folder if available; leave out passwords and access tokens. Do not change software versions, delete existing files or bypass a refusal to make the command continue.
