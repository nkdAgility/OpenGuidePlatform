# Find out what needs translating

Before changing anything, find out what already exists for your language. Website text and guide translations are different parts of the work.

## Work with an agent

Use [guide.transstatus](../skills/guide.transstatus/SKILL.md). It inspects the site without changing its files. If your agent cannot access the site or this installed skill, follow [setup](setup.md) with the maintainer.

Replace Kannada with the language and regional variant you agreed with the team, then paste:

> Use this site's installed **guide.transstatus** skill to check Kannada. Do not change files. Confirm the language and code with me. Explain what exists and what remains, separating website wording, guide translations and PDFs. Identify the installed version and report used. Explain failed or unavailable checks and the next supported step. If the skill is missing, ask for maintainer help; do not guess a status or use another workflow.

**You should receive:** a plain-English work list. It should distinguish translated text, empty starting pages, missing work, and guides that deliberately use another language or only a PDF. Text being present does not mean it has been reviewed.

**You decide:** which work the team will take on, with the site's language reviewer. The agent must not turn a request for status into permission to repair files.

**Next:** [add a language](add-language.md), [translate a selected guide](translate-guide.md), or [update a translation](update-translation.md). If the report says it cannot establish a result, use [troubleshooting](troubleshooting.md).

## I do not have an agent and want to do this manually

### Before you start

Complete [setup](setup.md#i-do-not-have-an-agent-and-want-to-do-this-manually) first. The contributor module must be installed and PowerShell must be open in the local folder of your fork, containing `build.ps1`. Start at the first block on this page and keep the same window open; every value used below is set on this page. If you closed the window, reopen that folder and repeat the blocks you need. Agree the language and regional variant with the team and ask for its language code. `kn` means Kannada; it is an example, not a default for your work.

### Run the PowerShell steps

#### Run the status commands

```powershell
$language = Read-Host 'Enter the agreed language code, for example kn'
$work = Get-OGPTranslationStatus -Language $language
$work.Configuration | Format-List
```

**You should see:** the site's OGP version, a folder for its reports, and the website language settings. This is a read-only check of site content. It can write temporary reports. The module loads the site's selected runtime itself.

Next, display website wording and guide work separately:

```powershell
$work.Wrappers | Format-Table Kind, SourcePath, TargetPath, State, SupportedOperation -Wrap
$work.Guides | Format-Table GuideId, EditionId, State, Intent, CanCreateScaffold -Wrap
$work.Findings | Format-List
```

**Read the result:** `Wrappers` means the website around the guides: homepages, menus, messages, history and translation listings. `SourcePath` is the original file; `TargetPath` is the translated file. `GuideId` and `EditionId` are the exact identifiers to copy when choosing a guide version. An empty starting page is unfinished text. A PDF-only guide or deliberate use of another language is not a request to create a web translation. `CanCreateScaffold` tells whether an empty starting page can be created; discuss the selection first.

A failed Prepare assessment means unresolved checks, even when a work table is available. Ask the maintainer which supported repair is needed. If no valid report can be produced, do not guess file names or edit around the failure.

### Check the result

You should have a work list separating website wording, guide bodies and downloads. Choose the next task with the team: [add the language](add-language.md#i-do-not-have-an-agent-and-want-to-do-this-manually), [translate a guide](translate-guide.md#i-do-not-have-an-agent-and-want-to-do-this-manually), or [update existing wording](update-translation.md#i-do-not-have-an-agent-and-want-to-do-this-manually).

The module reports the selected site version. To get the assessment file's full path, run:

```powershell
$work.PrepareReport
```

Copy the printed path into your editor's **File → Open** dialog. Read the report and keep its path with your work. If it cannot be produced or opened, tell the maintainer; do not invent a version or report path. [Command reference](../../OpenGuidePlatform.PowerShell.Contributor/README.md#find-the-work).

If a command fails, stop at that step. Send the maintainer the page, step, expected result and exact visible error. Include the printed report folder if available; leave out passwords and access tokens. Do not change software versions, delete existing files or bypass a refusal to make the command continue.
