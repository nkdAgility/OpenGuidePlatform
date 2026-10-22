# Translate or review wording without running commands

You can contribute language knowledge without installing developer tools. Ask the technical volunteer for the source text, a review sheet, the agreed glossary and, when available, the link to the rendered candidate. They operate OGP and apply agreed text; you focus on what readers will understand.

## Ask for a useful review sheet

The technical volunteer uses discovery to identify the actual files and selected fields. They can prepare a Markdown table or spreadsheet, with or without an assistant. Blank proposed-translation cells are useful when humans are drafting; generated proposals remain proposals.

Include this context above the table:

| Context | What the technical volunteer records |
|---|---|
| Scope | Target language/variant, website areas or selected guide/edition |
| Source | Actual file and revision or content hash used for this review |
| Candidate | Candidate identifier/hash and the target hash, or that a target is new |
| Decisions | Agreed glossary and applicable editorial-policy links |
| Rendered review | Artifact/revision and review URL when available; otherwise say unavailable |

Use one row per field or passage, retaining enough surrounding text to understand its meaning:

| Row | Source path and field/section | Source wording | Proposed translation | Reviewer feedback | Resolution |
|---|---|---|---|---|---|
| A1 | Actual discovered location | Actual source text | Human or assistant proposal | Suggested correction and reason | Proposed / agreed / unresolved |

This is a template, not an inventory or import format. The technical volunteer supplies actual paths and hashes. Reviewers do not need to calculate hashes or fill in technical identifiers. An agreed row records a wording decision; supported OGP checks still precede its application. Keep unconsented personal information and private discussions out of public sheets.

With an assistant, the technical volunteer can ask:

> Prepare a review sheet for our selected website text or guide passages. Use actual discovery and source/candidate evidence. Include source path and field/section, source wording, proposed translation, reviewer feedback and resolution. Preserve surrounding context. Do not invent approvals, identities, hashes or readiness. Do not apply changes just because a sheet exists.

## Give feedback the volunteer can apply

Read for meaning, missing text, terminology, tone and natural word order. Suggest the replacement wording and explain the reason. For example: “A1: use the glossary term for a work item; the current wording means a whole project.” Mark a question as unresolved when the source or intended term is unclear. Do not silently settle a guardian decision or overwrite a conflicting reviewer comment.

For website messages, preserve placeholders such as `{{ .Site.Title }}` and `{count}`, links and machine identifiers. You may propose a different word order around placeholders. If separate fragments cannot form a natural sentence in your language, flag a template defect rather than accepting misleading wording or editing software identifiers.

For guide passages, preserve references, links, headings, lists, anchors, shortcodes and intentional emphasis. Confirm the site's rules for reserved terms, licences, references, acknowledgements and change history; another language is not authority for those decisions.

Use the rendered review when available: check the actual homepage and guide, narrow/wide layouts, reading direction, shaping and meaningful typography. For PDFs, inspect pages rather than assuming an installed font makes them correct. Identify the page/section and artifact with each rendering finding. A screenshot can help locate a problem but does not approve the whole translation.

## Hand back feedback and check the correction

Return the completed sheet through the agreed site review channel. Written, audio or video feedback can be used when site policy permits; the technical volunteer should trace each finding to its row/passage. The guardian resolves conflicts.

The volunteer applies only agreed wording through supported wrapper or guide-translation operations, using the original reviewed hashes. If source or target changed, they reconcile and request renewed review for affected text. An old sheet is not permission to overwrite newer work.

Ask for a result showing applied rows, unchanged rows, unresolved questions and failed/unsupported operations, followed by the new rendered artifact. Inspect your corrections there. Review approval, completed automation and permission to publish are separate decisions: follow [validation and publication](validation.md).
