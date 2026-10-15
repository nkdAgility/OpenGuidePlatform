# Start here

You can help a guide site without being a programmer. You need knowledge of the subject or language; one technical volunteer can operate the tools while other people translate and review. An AI assistant is optional.

These pages explain the work. The linked Core procedures supply the exact commands for this OGP release. Use your site's contribution rules alongside them: the site decides editorial policy, contacts and publication approval.

## Choose your activity

| I want to… | Start with |
|---|---|
| Understand where things belong | [How the system fits together](system.md) |
| Prepare my computer | [Setup](setup.md) |
| Understand unfamiliar files and terms | [Files and changes](files.md) |
| Organise a translation team | [Translation journey](translation.md) |
| Find what is missing | [Check translation status](status.md) |
| Introduce a language | [Add a site language](add-language.md) |
| Translate one guide edition | [Translate a guide](translate-guide.md) |
| Update an existing translation | [Update a translation](update-translation.md) |
| Correct or add content | [Content changes](content.md) |
| Credit people or prepare downloads | [Credits and PDFs](credits-pdfs.md) |
| Check and submit work | [Validation and publication](validation.md) |
| Recover from a problem | [Troubleshooting and glossary](troubleshooting.md) |

Each task explains the purpose, human decisions, supported route and evidence needed. Experienced contributors can go directly to [Core commands](../../OpenGuidePlatform.PowerShell.Core/README.md), the [translation procedure](../../OpenGuidePlatform.PowerShell.Core/TranslationReadiness/README.md) or [assistant skill usage](../skills/USAGE.md).

## Read the version your site uses

From the guide-site repository root, in PowerShell:

```powershell
$platform = ./.OpenGuidePlatform/Resolve-OpenGuidePlatform.ps1 -WorkspaceRoot $PWD -UseInstalled
Get-Content "$platform/platform.json"
Join-Path $platform 'system/OpenGuidePlatform.Agents.Integration/contributor-guide/README.md'
```

Open the printed Markdown path in an editor with Markdown preview. The diagrams are included beside the pages. This resolves the installed package; uncached restoration may require network access and authenticated release access. If restoration fails, see [troubleshooting](troubleshooting.md).

For browser reading, find the same path in the OGP GitHub repository at the immutable `sourceCommit` printed in `platform.json`. Do not assume the repository's main branch describes your installed release. A guide site can link to that revision and retain its own short policy page; it need not copy these procedures. A dedicated documentation hosting service is not required to read them on GitHub.
