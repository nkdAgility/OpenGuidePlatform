# Get ready to work on a translation

You can contribute words without installing developer tools. If you want an agent to handle the files, it needs a working copy of the guide site and the skills installed for that site.

## Work with an agent

### Find the team for your guide site

Use the **Start here** contact on the guide site's translation page. For these sites, the public contact is:

- **Kanban Guides:** [translation help and discussions](https://github.com/KanbanGuides/KanbanGuides/discussions). Follow its [local translation policy](https://github.com/KanbanGuides/KanbanGuides/blob/main/docs/translations.md).
- **ScrumExpansion:** [translation help and discussions](https://github.com/ScrumGuides/ScrumGuide-ExpansionPack/discussions). Follow its [local translation policy](https://github.com/ScrumGuides/ScrumGuide-ExpansionPack/blob/main/docs/translations.md).

A GitHub account lets you post and reply; no tools need installing to ask for help. Search for your language and join its existing discussion. If there is none, choose **New discussion**. For another guide site, use its own contribution contact rather than either team above.

Send this, filling in the words in square brackets:

> I want to translate [guide name] into [language and regional variant]. I am new to the tools. Please identify the person who can approve the work and the person who will review the wording. I want to use an agent. Please tell me which supported agent setup to use, how to make and open my own working copy, and how to check that this site's OGP skills are available. If setup cannot be provided, please arrange a review sheet and someone to handle the files and submission.

### Open the project in your agent

The maintainer is the person responsible for the site's technical operation. Ask them to supply the supported agent's name, its opening instructions, your own fork's address and the full path of its local folder, plus confirmation that the site's tools and OGP skills are ready. A fork is your copy on GitHub; the local folder is its copy on your computer. You do not need to buy a subscription or select an unfamiliar product by guesswork.

Open that supported agent and use its supplied instructions to open the exact local folder. Check that its project view shows `build.ps1` and `.agents/skills/guide.transstatus/SKILL.md`. A normal chat with uploaded documents alone is not connected to the project. Do not paste a password or access token to connect it. If you cannot open the folder or see those files, reply in the same site discussion with what you can see and ask for setup help.

Once the site is open, paste this into the agent conversation:

> Use this site's installed **guide.transstatus** skill to check whether you can inspect translation work. Do not change files. Explain the required access and missing tools in plain English. Identify the installed OGP version and the report you used, or explain why you cannot produce one. Do not install tools, create a branch or change software versions without the site's required permission.

This invokes [guide.transstatus](../skills/guide.transstatus/SKILL.md), a read-only check. It does not install software. If the skill or a required tool is missing, ask the maintainer to help set it up; the agent must not invent a replacement workflow.

**You decide:** the site, language and work you want to help with. Never paste passwords or access tokens into the conversation.

**You should receive:** either a translation work report or a short list of specific setup problems and who can help. A list of files alone does not prove the checks ran.

**Next:** [your first translation](first-translation.md), or [review wording](review-wording.md) while someone else handles setup.

## I do not have an agent and want to do this manually

### Before you start

Ask the site team for its GitHub address, contribution policy, supported tool versions and the person who can help with setup. A **fork** is your copy on GitHub. A **local copy** is the folder on your computer where commands run. A **branch** keeps one piece of work together.

**Before installing anything:** use the site contact above and send: “I want to follow the manual translation steps for [guide] in [language]. Please confirm the contributor module's published version, the supported tool versions, who can perform the administrator installation, and who will help if setup fails.” Wait for that information before continuing. You can [supply and review words without installing tools](review-wording.md#i-do-not-have-an-agent-and-want-to-do-this-manually) while setup is arranged.

**Publication status for this unreleased documentation:** the contributor module has been implemented and locally verified, but its PowerShell Gallery publication has not been verified. Do not expect the installation command below to work until the maintainer confirms publication, or supplies a separately verified installation route. Do not choose an unrelated module with a similar name.

### Prepare access and tools

This setup is only for someone running the commands themselves. For [wording-only participation](review-wording.md#i-do-not-have-an-agent-and-want-to-do-this-manually), another volunteer handles these tools and submits the reviewed files for you.

The tools have separate jobs: **Git** copies and shares the project; **PowerShell** runs the OGP commands; **Hugo Extended** makes the review website; **Go** supplies its shared website components; **GitHub CLI** signs in from the command window. Ask the setup volunteer to check which are already installed and install only what is missing, using the supported versions. You do not need to learn their internals to translate.

1. Create a GitHub account, open the guide site's GitHub page and choose **Fork**. Confirm the resulting project is under your account. Keep the original site's address too: the submission goes back there later.
2. Install the versions the site team supports: [Git](https://git-scm.com/install/), [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell), [Hugo Extended](https://gohugo.io/installation/), [Go](https://go.dev/doc/install) and [GitHub CLI](https://cli.github.com/). PowerShell must be 7.4 or later. Ask the team to install any tool you are not authorised to install. PDF generation needs extra tools only if you reach that task.
3. Choose a plain-text editor with the team. It must edit text without word-processor formatting. You will use **File → Open** to open the exact draft path a command prints; do not use a word processor to edit site files.
4. On Windows, open **PowerShell 7** from Start. On macOS/Linux, open Terminal and type `pwsh`, then press Enter. If it says the command is missing, complete installation first.

### Know where to paste things

Paste PowerShell blocks into that PowerShell window, without the surrounding backticks. Run one block at a time. When a command asks a question, type or paste its answer and press Enter. Lines such as `$work = ...` keep a result under a short name for later lines; you do not need to invent its value. Keep the window open while following a task page.

### Install and check the tools

Run these one at a time:

```powershell
$PSVersionTable.PSVersion
git --version
hugo version
go version
gh --version
gh auth status
```

**You should see:** PowerShell 7.4 or newer, version information from each tool, Hugo with Extended support, and a GitHub sign-in result. Compare versions with the site's requirements. If a tool is missing or too old, stop and ask the team to fix that prerequisite.

If GitHub CLI says you are not signed in, run this and follow its sign-in prompts:

```powershell
gh auth login
```

Repeat `gh auth status` and confirm the intended account is signed in. Never put a password or token into a review document or agent conversation.

#### Install the OGP contributor module

After the maintainer confirms publication, an authorised administrator must open an elevated PowerShell 7 session. On Windows, choose **Run as administrator**. On another operating system, ask the administrator to use the organisation's approved elevated PowerShell session. Run:

```powershell
Install-Module OpenGuidePlatform -Repository PSGallery -Scope AllUsers
```

This installs the commands for all users and installs their declared module dependency. Read any installation prompts. Ask the maintainer if the source or package differs from the approved one. `CurrentUser` installation is explicitly disabled in this environment; do not switch to it or relocate module folders as a workaround.

**You should see:** installation completes without an error. If it reports no matching module, publication is not available: stop and ask the maintainer. If it reports a permission or administrator error, the administrator must resolve it; do not suppress it. [Module installation notes](../../OpenGuidePlatform.PowerShell.Contributor/README.md#install-the-contributor-commands) describe this same interface.

Close the administrator window after installation. Open an ordinary PowerShell 7 window for the translation work. Run:

```powershell
Get-Command Get-OGPTranslationStatus
```

It should identify `Get-OGPTranslationStatus` from `OpenGuidePlatform`. No Import-Module, manual runtime loading or file-hash copying is needed. Installing these commands does not install or upgrade OGP inside a guide site; the team must already have prepared that site.

### Get your working copy

On Windows, ask the maintainer to confirm Developer Mode or equivalent file-link permission before cloning. Git must preserve the instruction files as symbolic links—links to the shared instructions, rather than ordinary files containing a path. Do not replace refused links with ordinary files.

In your ordinary PowerShell window, print your home folder's actual address:

```powershell
Write-Output $HOME
```

Copy that printed path. Use it when the next block asks where to create the project folder, or supply another existing folder whose full path you know:

```powershell
$parentFolder = Read-Host 'Paste the full path of the folder where Git should put your project'
Set-Location -LiteralPath $parentFolder
Get-Location
```

**You should see:** the folder you chose. On **your fork's** GitHub page, choose **Code → HTTPS** and copy its clone address. Then run:

```powershell
$forkUrl = Read-Host 'Paste the HTTPS clone address of your fork'
git clone -c core.symlinks=true $forkUrl
```

Git should report that it created a project folder. If it fails, stop; do not continue into an unrelated existing folder. Enter the directory Git actually created:

```powershell
$projectFolder = Read-Host 'Enter the project folder Git created, or its full path'
Set-Location -LiteralPath $projectFolder
Get-Location
Get-Item build.ps1, .OpenGuidePlatform
git status
```

**You should see:** your local project folder, both named items, and Git reporting a clean working tree. On Windows also check:

```powershell
Get-Item AGENTS.md, CLAUDE.md | Select-Object Name, LinkType
```

Both should have `SymbolicLink` as their link type. If the files or links are wrong, ask the maintainer to repair setup without losing your work.

### Agree your working branch

Ask: “Which starting branch and new task-branch name should I use, and may I create it?” When the maintainer has confirmed you are on the correct starting branch and authorised a new one:

```powershell
$branch = Read-Host 'Enter the agreed new task-branch name'
git switch -c $branch
git branch --show-current
```

The printed name should match the one agreed. If you were given an existing task branch, ask for its instructions instead of running `git switch -c`. If anything differs, stop rather than create more branches.

### Check the result

You now have the commands installed, an ordinary PowerShell window in your local fork, and an agreed task branch. Continue to [check what needs translating](status.md#i-do-not-have-an-agent-and-want-to-do-this-manually). If you close PowerShell later, reopen it and use `Set-Location` with this project folder before the next task.

If a command fails, stop at that step. Send the maintainer the page, step, expected result and exact visible error. Include the printed report folder if available; leave out passwords and access tokens. Do not change software versions, delete existing files or bypass a refusal to make the command continue.
