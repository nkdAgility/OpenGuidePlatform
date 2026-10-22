# Update a translation

Reconciliation compares source changes with an existing translation so useful translated passages survive. Start with [setup and discovery](status.md), select the exact guide/edition/language, and agree the comparison revision. A populated translation or recent date does not prove which source it used.

Follow [Core reconciliation](../../OpenGuidePlatform.PowerShell.Core/TranslationReadiness/README.md#reconcile-against-source-changes). Supply the explicit source commit, and the old source path if it moved. Read the historical/current source diff alongside the current translation. If the baseline is unknown, record that uncertainty and agree a comparison point with the guardian; do not invent provenance.

Start your candidate from the current translated file. Address changed passages and reviewed feedback, preserve good text, and raise conflicting reviewer requests. Then check the candidate and apply with reviewed current source and target hashes. The recorded comparison is evidence of what was compared, not proof that every difference was translated.

With an assistant: “Use guide.transreconcile for GUIDE, EDITION and LANGUAGE against SOURCE_COMMIT. Show source changes and proposed corrections first. Preserve useful translated passages and report conflicting feedback. Apply only the agreed scope using the installed checks.”

**Success:** reviewers can trace findings to corrections or explicit unresolved questions, and the [rendered result and builds](validation.md) have been checked. A translation typo still uses the translated-document writer; source-language corrections use [content changes](content.md).

**If comparison fails:** check that the commit and historical path exist locally. Ask the maintainer about fetching the needed history; do not silently merge unrelated upstream work or choose a different baseline.
