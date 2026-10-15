# Set up your computer

The goal is to open a working copy of the guide site and run its installed tools. Translators who only supply wording or review a web page can work with a technical volunteer instead of installing everything themselves.

## Prepare access and tools

1. Read the site's contribution instructions. Agree the work and identify the maintainer or translation guardian who can answer questions.
2. Create a GitHub account. Use GitHub's Fork button on the site's repository if its contribution policy calls for a fork. A fork is your GitHub copy; a clone is the copy on your computer.
3. Follow the site's setup instructions to install Git, PowerShell 7.4 or later, Hugo Extended, Go and the GitHub CLI. The site's requirements may exceed the platform minimums. PDF generation needs additional tools only when you reach that task.
4. Open PowerShell: on Windows use PowerShell 7, rather than Windows PowerShell 5.1. On macOS or Linux, open Terminal and type `pwsh`. All subsequent command blocks marked PowerShell run inside that session.

If the site's instructions only list prerequisites, use these official installation pages. Choose your operating system and meet the site's version requirements; you do not need to install an AI assistant.

| Tool | Installation instructions | Why it is needed |
|---|---|---|
| Git | [Windows, macOS or Linux](https://git-scm.com/install/) | Clone and review repository changes |
| PowerShell | [Windows, macOS or Linux](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell) | Run OGP's commands |
| Hugo | [Choose your operating system](https://gohugo.io/installation/) and Extended support | Render the website |
| Go | [Download and install](https://go.dev/doc/install) | Resolve Hugo modules |
| GitHub CLI | [Install GitHub CLI](https://cli.github.com/) | Restore release assets where authenticated access is required |

Restart your terminal after installing tools so it sees their command paths. To sign the GitHub CLI in, run `gh auth login` and follow its prompts; see [official authentication help](https://cli.github.com/manual/gh_auth_login). Never paste credentials into a review document or assistant conversation.

Check each tool, one line at a time:

```powershell
git --version
pwsh --version
hugo version
go version
gh --version
gh auth status
```

Expect version output, Hugo reporting Extended support, and the GitHub CLI reporting an authenticated account with the required release access. If a command is missing or access fails, fix that prerequisite before building. Use your site's documented installation instructions; do not guess package names or install a different platform version to get past an error.

## Get your working copy

On your fork's GitHub page, use Code to copy its HTTPS clone URL. Run:

```powershell
$repositoryUrl = Read-Host 'Paste your fork HTTPS clone URL'
git clone $repositoryUrl
```

Git prints the directory it created. Enter it with `Set-Location`, using that actual directory name. Run `git status`: it should identify the repository and show a clean working tree. Follow the site's branch naming and approval rules before making changes. Do not create a second checkout inside another repository.

From that root folder, follow [check translation status](status.md) to resolve the installed package and run your first assessment. Success means you can identify the installed version and locate the Prepare report, even if that report identifies content work still needed.

## With an assistant

Ask: “Read this site's contributor instructions. Check the required tools, repository location and installed OGP version. Explain missing prerequisites before making changes.” Paste this into the assistant's conversation, not the terminal. You do not need an AI subscription to use the manual route.

**If blocked:** [troubleshooting](troubleshooting.md). **Technical reference:** [installed module loading](../../OpenGuidePlatform.PowerShell.Core/README.md#load-the-installed-commands-and-discover-content).
