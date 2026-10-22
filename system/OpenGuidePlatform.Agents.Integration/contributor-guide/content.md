# Correct or add content

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

With an assistant: “Read the site's instructions and use installed Core discovery to select the source body for GUIDE, EDITION. Prepare the agreed correction as a candidate, preserve metadata and resources, show the diff and run the required builds.”

**Success:** the diff contains the agreed addition/correction in the intended component, other content remains intact, and local verification is recorded. Follow site editorial review before publication. A PDF may need explicit regeneration if its generated receipt becomes stale; supplied PDFs remain protected.
