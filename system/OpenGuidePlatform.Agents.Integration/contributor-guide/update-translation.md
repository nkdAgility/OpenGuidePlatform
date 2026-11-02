# Update a translation

Keep the useful translated passages and change only what needs attention. First agree which guide, edition and language you are updating, and which source change you are comparing with.

## Work with an agent

Use [guide.transreconcile](../skills/guide.transreconcile/SKILL.md). It compares source changes with the existing translation and applies reviewed corrections through the installed workflow. If you need help accessing the site, use [setup](setup.md).

> Use this site's installed **guide.transreconcile** skill for our selected guide, edition and language. Help us identify and agree the earlier source version to compare with; do not invent which source was previously translated. Show changed source passages beside the existing translation and your proposed corrections. Wait for my approval before changing files. Keep good existing wording and report conflicting feedback or unclear meaning. Use only the installed skill's supported checks and operations; explain anything it cannot do and ask for maintainer help.

**You decide:** the comparison point and wording, with the language reviewer. If the earlier source is unknown, record that uncertainty and agree a comparison point. A recent translation date does not establish it.

**You should receive:** a traceable list of source changes, agreed corrections, preserved text and unresolved questions. The agent should report actual checks and identify the version used, rather than declaring the translation current just because the file exists.

For a translation typo, the same installed skill supports reviewed corrections within the selected scope; do not ask for an unrelated file-edit workflow. Source-language guide corrections have a different boundary: see [content changes](content.md).

**Next:** [review wording](review-wording.md), then [check and submit](validation.md).

## I do not have an agent and want to do this manually

Reconciliation means comparing what changed in the source with the existing translation. Start with the manual [setup](setup.md#i-do-not-have-an-agent-and-want-to-do-this-manually) and [status](status.md#i-do-not-have-an-agent-and-want-to-do-this-manually) steps. Ask the maintainer to help identify the earlier source revision (a saved point in its history). Use the exact commands below; do not choose a different comparison silently when one is unavailable.

Reconciliation compares source changes with an existing translation so useful translated passages survive. Start with [setup and discovery](status.md), select the exact guide/edition/language, and agree the comparison revision. A populated translation or recent date does not prove which source it used.

Follow [Core reconciliation](../../OpenGuidePlatform.PowerShell.Core/TranslationReadiness/README.md#reconcile-against-source-changes). Supply the explicit source commit, and the old source path if it moved. Read the historical/current source diff alongside the current translation. If the baseline is unknown, record that uncertainty and agree a comparison point with the guardian; do not invent provenance.

Start your candidate from the current translated file. Address changed passages and reviewed feedback, preserve good text, and raise conflicting reviewer requests. Then check the candidate and apply with reviewed current source and target hashes. The recorded comparison is evidence of what was compared, not proof that every difference was translated.


**Success:** reviewers can trace findings to corrections or explicit unresolved questions, and the [rendered result and builds](validation.md) have been checked. A translation typo still uses the translated-document writer; source-language corrections use [content changes](content.md).

**If comparison fails:** check that the commit and historical path exist locally. Ask the maintainer about fetching the needed history; do not silently merge unrelated upstream work or choose a different baseline.
