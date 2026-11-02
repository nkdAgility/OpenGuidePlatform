# Get ready to work on a translation

You can contribute words without installing developer tools. If you want an agent to handle the files, it needs a working copy of the guide site and the skills installed for that site.

## Work with an agent

Start in an agent that can work with project files. If you do not have one connected to this site, ask the maintainer which supported setup they recommend and how to open the site's files. These instructions do not assume you have bought an AI subscription or chosen a particular product.

Once the site is open, paste:

> Use this site's installed **guide.transstatus** skill to check whether you can inspect translation work. Do not change files. Explain the required access and missing tools in plain English. Identify the installed OGP version and the report you used, or explain why you cannot produce one. Do not install tools, create a branch or change software versions without the site's required permission.

This invokes [guide.transstatus](../skills/guide.transstatus/SKILL.md), a read-only check. It does not install software. If the skill or a required tool is missing, ask the maintainer to help set it up; the agent must not invent a replacement workflow.

**You decide:** the site, language and work you want to help with. Never paste passwords or access tokens into the conversation.

**You should receive:** either a translation work report or a short list of specific setup problems and who can help. A list of files alone does not prove the checks ran.

**Next:** [your first translation](first-translation.md), or [review wording](review-wording.md) while someone else handles setup.

## I do not have an agent and want to do this manually

The steps below teach the tools, where to enter commands and how to obtain a working copy. A terminal is the window where you type commands; a repository is the project and its file history. Run one step at a time and ask the maintainer if its result differs from the explanation.

The goal is to open a working copy of the guide site and run its installed tools. Translators who only supply wording or review a web page can work with a technical volunteer instead of installing everything themselves.

## Prepare access and tools

1. Read the site's contribution instructions. Agree the work and identify the maintainer or translation guardian who can answer questions.
2. Create a GitHub account. Use GitHub's Fork button on the site's repository if its contribution policy calls for a fork. A fork is your GitHub copy; a clone is the copy on your computer.
3. Follow the site's setup instructions to install Git, PowerShell 7.4 or later, Hugo Extended, Go and the GitHub CLI. The site's requirements may exceed the platform minimums. PDF generation needs additional tools only when you reach that task.
4. Open PowerShell: on Windows use PowerShell 7, rather than Windows PowerShell 5.1. On macOS or Linux, open Terminal and type `pwsh`. All subsequent command blocks marked PowerShell run inside that session.

## Know where to paste things

Use two different inputs: commands go into the PowerShell terminal; requests beginning “Use guide…” go into your assistant's conversation. Follow prompts in the terminal when a command such as `Read-Host` asks for a value. Do not paste the surrounding prose or the three backticks that mark a code block. Run one command at a time and read its result before continuing.

On a Mac, Terminal normally starts another shell, often zsh. Typing `pwsh` starts PowerShell inside it; you can then use the shared command examples unchanged. If `pwsh` is not found, complete PowerShell installation and restart Terminal first. You do not need a separate set of Mac translation procedures.

Words such as LANGUAGE, GUIDE and EDITION in assistant requests are placeholders: replace them with the agreed values before sending. Do not type angle-bracket placeholders into a shell. In command examples, quoted sample identifiers such as `'your-guide'` also need replacement with discovered identifiers. Paths with spaces belong inside quotes. Do not run `guide.transcreate` as a terminal command; it names assistant instructions.

## Install and check the tools

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

On Windows, enable Developer Mode or obtain equivalent symbolic-link privileges before cloning. OGP uses symbolic links for the shared contributor/agent instructions; ordinary files containing link targets are not a working substitute. The clone command below enables `core.symlinks` for this repository without changing your global Git configuration. If Windows refuses to create links, stop and resolve the prerequisite with your maintainer.

On your fork's GitHub page, or the site repository when direct contributions are allowed, use Code to copy its HTTPS clone URL. Run:

```powershell
$repositoryUrl = Read-Host 'Paste the agreed repository HTTPS clone URL'
git clone -c core.symlinks=true $repositoryUrl
```

Git prints the directory it created. Enter it using that actual directory name:

```powershell
$cloneDirectory = Read-Host 'Enter the directory Git created (or its full path)'
Set-Location -LiteralPath $cloneDirectory
Get-Location
git status
```

The displayed location should be the guide-site folder, containing `build.ps1` and `.OpenGuidePlatform`. `git status` should identify that repository and show a clean working tree. Follow the site's branch naming and approval rules before making changes. Once the maintainer has agreed a branch name and authorised its creation, `git switch -c` with that name creates it; for an already existing branch, follow their instructions rather than creating another. Do not create a second checkout inside another repository.

On Windows, also confirm `git config --get core.symlinks` prints `true` and inspect `AGENTS.md` and `CLAUDE.md` with `Get-Item`: they should be symbolic links. A clean `git status` alone does not prove links were checked out correctly. Ask the maintainer to help repair an existing incorrectly checked-out clone while preserving your work.

From that root folder, follow [check translation status](status.md) to resolve the installed package and run your first assessment. Success means you can identify the installed version and locate the Prepare report, even if that report identifies content work still needed.
