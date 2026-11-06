# Review wording

You can help without editing files or running commands. Your job is to check that readers get the intended meaning in natural language.

## Work with an agent

Ask the agent or the volunteer operating it to use [guide.transstatus](../skills/guide.transstatus/SKILL.md) to identify the actual work and source text. This read-only skill does not apply translations. If it cannot access the site, ask the maintainer to arrange a review sheet for you.

> Use this site's installed **guide.transstatus** skill to inspect our agreed language and scope without changing files. Prepare a human-readable review sheet from the actual source and existing translation. Show the source, proposed wording or a blank space for my translation, and a feedback column. Record where the text came from and what version we are reviewing. Do not invent approvals or treat the sheet as permission to edit. Report missing access or unsupported work.

Read each passage for meaning, omissions, consistent terms and natural wording. Give a suggested replacement and a reason, for example: “Use our agreed term for a work item; this wording means a whole project.” Ask the language reviewer to settle disagreements.

**You should receive:** source and proposed words together, enough context to understand them, and a place to record questions. You do not need to calculate file fingerprints or fill in technical identifiers; the agent or volunteer supplies those.

Approved website or new-guide wording is applied through [guide.transcreate](../skills/guide.transcreate/SKILL.md); existing translated-guide corrections through [guide.transreconcile](../skills/guide.transreconcile/SKILL.md). Those skills must check the actual files again. A stale review sheet must not overwrite newer text.

**Next:** inspect your corrections in the prepared website through [check and submit](validation.md). Ask for a review link if you do not have one. A screenshot or successful check alone does not approve all the wording.

## I do not have an agent and want to do this manually

### Before you start

No software installation or PowerShell is needed to review words. Ask the maintainer which person or channel receives feedback, and send: “Please give me the source, current translation, preferred terms, review sheet and review link for our chosen language and guide edition.”

### Choose your next step

Use one row per field or passage. The volunteer handling the files records where it came from and which version you are reviewing; you need not calculate fingerprints or technical identifiers.

| Passage | Source words | Proposed translation | Your suggested correction and reason | Decision |
|---|---|---|---|---|
| Named page or section | Actual source text, with context | Proposal or blank space for your words | Explain missing meaning, awkward wording or a term to change | Proposed / agreed / unresolved |

Read for meaning, missing text, consistent terms and natural wording. For example: “Use our agreed term for a work item; this wording means a whole project.” Ask the language reviewer to settle conflicting suggestions. Preserve links, references, meaningful emphasis and placeholders such as `{{ .Site.Title }}` and `{count}`. Report fragments that cannot form a natural sentence rather than translating software identifiers.

Return the sheet through the agreed channel. Keep private contact details and unconsented personal information out of public review. The person applying it must check the current files; an old sheet is not permission to overwrite newer wording.

### Check the result

Ask for the corrected sheet and the updated website/PDF to inspect, or an explicit statement that a review result is not yet available. Check your corrections there and identify the page, section and reviewed version in any remaining feedback. A screenshot can locate an issue but does not approve the whole translation. Publication still needs the site's separate approval.
