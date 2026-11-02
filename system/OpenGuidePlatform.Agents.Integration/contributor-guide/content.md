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

The table below explains which component owns a change. For an existing source guide, prepare a separate proposed body and use the documented read/check/write operation; it preserves page settings and protected resources. A new page or design needs maintainer agreement first. [Setup](setup.md#i-do-not-have-an-agent-and-want-to-do-this-manually) introduces the tools, and [files explained](files.md) defines the file terms.

First agree the change through the site's contribution process. Identify whether you are editing an existing source-language guide body, a translation, website text, or introducing a new page/edition. They have different owners and supported operations.

| Change | Supported route |
|---|---|
| Correct or add paragraphs in an existing source guide | [Core correct-an-existing-guide workflow](../../OpenGuidePlatform.PowerShell.Core/README.md#correct-an-existing-guide) |
| Correct translated text | [Update a translation](update-translation.md) with same-edition source/target checks |
| Localize surrounding website text | [Site-language workflow](add-language.md) for supported wrapper resources |
| Introduce a new guide/page, restructure metadata or change routing | Agree the site-owned design and supported operation with maintainers first |
| Create a draft edition snapshot | Review the [Core edition commands](../../OpenGuidePlatform.PowerShell.Core/README.md) and the installed [historical-version skill](../skills/guide.historicalversion/SKILL.md); a snapshot is not publication |

For an existing source body, run discovery, use `Get-GuideContent` to select its actual guide, edition and source language, and save a separate candidate body. Edit that candidate in your editor, preview `Set-GuideContent` with `-WhatIf`, then apply with the original reviewed hash. Inspect `git diff` and [validate](validation.md). The linked Core workflow gives the complete runnable example.

Do not guess a path from another site's guide count or copy an edition directory manually as a substitute for a supported workflow. Source correction preserves front matter and protected resources. If your request includes unsupported metadata or new resource types, report that boundary; an existing-body writer cannot create arbitrary pages.


**Success:** the diff contains the agreed addition/correction in the intended component, other content remains intact, and local verification is recorded. Follow site editorial review before publication. A PDF may need explicit regeneration if its generated receipt becomes stale; supplied PDFs remain protected.
