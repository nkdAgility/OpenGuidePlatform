# Help translate a guide site

You bring the language knowledge. An agent can help with the files, checks and submission. People decide whether the wording is right and when it may be published.

**Start with [your first translation](first-translation.md).** If you need a person to help you start, [find your guide site’s team](setup.md#find-the-team-for-your-guide-site). It takes you from choosing the work to submitting it for review. You do not need to learn terminal commands first.

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

### Before you start

Agree the language and work with the site team. You can supply words without operating the tools, or run the whole manual process. These pages do not assume you know Git or PowerShell.

### Run the PowerShell steps

1. Follow [setup](setup.md#i-do-not-have-an-agent-and-want-to-do-this-manually) to make your fork/local copy and install the module. That page states the current publication limitation; do not assume Gallery installation is already available.
2. [Check what needs translating](status.md#i-do-not-have-an-agent-and-want-to-do-this-manually).
3. [Prepare the website language](add-language.md#i-do-not-have-an-agent-and-want-to-do-this-manually), then [translate selected guide editions](translate-guide.md#i-do-not-have-an-agent-and-want-to-do-this-manually).
4. [Review credits and eligible PDFs](credits-pdfs.md#i-do-not-have-an-agent-and-want-to-do-this-manually), then [check and submit](validation.md#i-do-not-have-an-agent-and-want-to-do-this-manually).

Where a task command is supported, the pages show what to run and what its result means. Where support is incomplete, they give an explicit maintainer handoff instead. The module handles the site's selected version and file checks internally. It does not upgrade the site just because you install newer commands.

### Check the result

A completed handoff includes reviewed words, actual check results and a PR link or a named maintainer making the submission. It does not mean the language has been published. Ask the maintainer for the instructions matching the site's installed release; for an unreleased build, use its supplied package rather than assuming OGP's main branch matches it.
