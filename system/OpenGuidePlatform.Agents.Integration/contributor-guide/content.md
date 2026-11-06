# Correct or add content

Agree what you want to change with the site team first. A typo in a translation, a new guide and a new edition are different jobs. This page helps you choose a supported route instead of asking an agent to improvise file changes.

## Work with an agent

If you need help accessing the site and installed skills, start with [setup](setup.md). Use the route matching the work:

| Your change | Installed skill and task page |
|---|---|
| Correct existing translated guide wording | [guide.transreconcile](../skills/guide.transreconcile/SKILL.md), through [update a translation](update-translation.md) |
| Prepare website text in a new language or translate a selected guide | [guide.transcreate](../skills/guide.transcreate/SKILL.md), through [add a language](add-language.md) or [translate a guide](translate-guide.md) |
| Create a draft snapshot of a selected edition | [guide.historicalversion](../skills/guide.historicalversion/SKILL.md), with the maintainer's agreed source and new edition |
| Correct source-language guide text, create an unrelated page or redesign site structure | No dedicated skill is supplied for this task; ask the maintainer to use the documented manual operation or identify the missing capability |

For a draft edition, paste:

> Use this site's installed **guide.historicalversion** skill for the source edition and new edition we agree with the maintainer. Confirm the selections and show the plan first. Preserve the original and its resources. Keep the new edition a draft. Report conflicting paths, unsupported work and check results. Do not publish it or invent another workflow.

**You decide:** the editorial change and intended edition, with the content owner. **You should receive:** a clear supported scope, an unchanged original for a snapshot, and actual verification results. A snapshot is not a newly written or published guide.

There is no generic “edit anything” skill. Do not stretch a translation or snapshot skill to cover source corrections, arbitrary metadata or new site designs. The manual commands below support existing source-body corrections, but that is not a claim that a dedicated agent skill exists.

**Next:** [review wording](review-wording.md) and [check and submit](validation.md).

## I do not have an agent and want to do this manually

### Before you start

Agree the change with the content owner. A correction in a translated guide, a source-language correction, a new page and a new edition are different tasks. Do not treat them as a general request to rewrite files.

### Run the PowerShell steps

- For a translated guide, follow [translate existing wording](translate-guide.md#i-do-not-have-an-agent-and-want-to-do-this-manually) or [compare source changes](update-translation.md#i-do-not-have-an-agent-and-want-to-do-this-manually). Those pages use the contributor module's supported draft/save commands.
- For website wording in a selected language, follow [prepare the website language](add-language.md#i-do-not-have-an-agent-and-want-to-do-this-manually).
- For an existing **source-language** guide body, no beginner contributor-module draft command is currently supplied. Send the maintainer the guide, edition, page/section, existing words and proposed replacement with a reason. Ask them to apply the agreed correction through [the source-body Core procedure](../../OpenGuidePlatform.PowerShell.Core/README.md#correct-an-existing-guide). That link is the technical maintainer procedure, not a claim that you must understand its internal loading or hashes.
- For a new page, edition snapshot or changed site design, ask the maintainer to agree the supported procedure first. Do not use a translation command to create arbitrary content or copy a directory as a workaround.

### Check the result

Ask for the applied file/change and a viewable result. Confirm the intended words changed and unrelated guide text, metadata, protected content and PDFs remain intact. Follow [check and submit](validation.md#i-do-not-have-an-agent-and-want-to-do-this-manually) or ask the maintainer to make that handoff. A missing command or unclear approval remains visible; do not claim unsupported work is complete.
