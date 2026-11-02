# Help translate a guide site

You bring the language knowledge. An agent can help with the files, checks and submission. People decide whether the wording is right and when it may be published.

**Start with [your first translation](first-translation.md).** It takes you from choosing the work to submitting it for review. You do not need to learn terminal commands first.

## Work with an agent

An agent is an assistant that can work with the guide site's files. A normal chat without that access cannot complete file changes or a submission. If you are unsure what yours can access, start with this request in its conversation:

> I want to help translate this site. Use its installed **guide.transstatus** skill to check what you can access and what translation work is needed. Do not change files. Explain the next step in plain English. If you cannot access the site or load the skill, tell me what help I need from a maintainer instead of guessing.

A **skill** is the set of instructions the agent follows for a task. The names below are not terminal commands. Always use the skills installed for your site; these links explain their purpose. If that version cannot do the work, the agent must report the gap rather than invent another workflow.

| Your task | Instructions to follow | Skill used by the agent |
|---|---|---|
| Find what already exists | [Check status](status.md) | [guide.transstatus](../skills/guide.transstatus/SKILL.md) |
| Prepare a website language | [Add a language](add-language.md) | [guide.transcreate](../skills/guide.transcreate/SKILL.md) |
| Translate a selected guide | [Translate a guide](translate-guide.md) | [guide.transcreate](../skills/guide.transcreate/SKILL.md) |
| Update a translation | [Update a translation](update-translation.md) | [guide.transreconcile](../skills/guide.transreconcile/SKILL.md) |
| Credit the people involved | [Credits and PDFs](credits-pdfs.md) | [guide.contributions](../skills/guide.contributions/SKILL.md) |
| Prepare an eligible PDF | [Credits and PDFs](credits-pdfs.md) | [guide.genpdfs](../skills/guide.genpdfs/SKILL.md) |

**Your part:** agree the language and guide with the site team, help choose wording, and review what readers will see. The site's maintainer is the person responsible for its technical operation; its language reviewer settles wording questions according to local policy. One person may have several roles.

**What you should receive:** proposed words beside their source, clear questions for people to decide, and an honest account of completed and unfinished work. A prepared page or passing software check does not prove that a translation is correct.

For help, use [setup](setup.md), [review wording](review-wording.md), [submit for review](validation.md), or [troubleshooting](troubleshooting.md). [How the system fits together](system.md), [files explained](files.md), [the journey diagram](translation.md), and [other content changes](content.md) explain the supporting tasks.

## I do not have an agent and want to do this manually

You can use the same OGP tools yourself, or provide words while another volunteer handles the files. Start with [setup](setup.md#i-do-not-have-an-agent-and-want-to-do-this-manually) for the tools, or [review wording](review-wording.md) to help without installing them. Each task page has an explicitly labelled manual route after its agent route.

### Read the instructions your site actually uses

The instructions on OGP's main branch may be newer than your site's tools. Ask the maintainer for its version-matched contributor-guide link. You do not need to work out release identifiers yourself. For a local build that has not been released, the maintainer can share the packaged pages and diagrams instead.

To find that version yourself, from the site folder in PowerShell:

```powershell
$platform = ./.OpenGuidePlatform/Resolve-OpenGuidePlatform.ps1 -WorkspaceRoot $PWD -UseInstalled
$packageInfo = Get-Content "$platform/platform.json" -Raw | ConvertFrom-Json
"https://github.com/nkdAgility/OpenGuidePlatform/blob/$($packageInfo.sourceCommit)/system/OpenGuidePlatform.Agents.Integration/contributor-guide/README.md"
```

PowerShell is the command tool explained in [setup](setup.md). The printed link points to the source used for this installed package. An unreleased local build may need the packaged files instead of a browser link.
