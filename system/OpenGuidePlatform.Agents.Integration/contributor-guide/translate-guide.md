# Translate a guide

Choose the guide, edition (version) and language with the site team. If the website has not been prepared for this language, first follow [add a language](add-language.md). You do not need to translate every older edition.

## Work with an agent

This task uses [guide.transcreate](../skills/guide.transcreate/SKILL.md) for a separately selected guide translation. Use [guide.transstatus](../skills/guide.transstatus/SKILL.md) first if you do not know what exists. If you need help opening the site in an agent, start with [setup](setup.md).

Replace the example selections with the guide, edition and language agreed with your team:

> Use this site's installed **guide.transcreate** skill to translate the body of our selected guide and edition into Kannada. Confirm the exact selections with me before proceeding. Use our agreed terms and site policy. Show proposed passages beside their source in this conversation and wait for my approval before changing files. Preserve links, references, meaningful formatting, settings, existing PDFs and other editions. Follow only the skill's supported workflow and checks. Report anything it cannot do instead of inventing another way.

You can write the translation yourself or ask for a proposal. Work a section at a time if that makes review easier. Ask the language reviewer about unclear meaning, defined terms, licences and source conventions such as italics. The agent must not silently decide these for you.

**You should receive:** source and proposed wording, questions needing a human answer, the exact source used, and results of the skill's checks. A software check is not a language review. If someone changed the source while you worked, the agent must compare the changes and seek renewed review rather than overwrite them.

Use [review wording](review-wording.md) to give corrections. If this is an existing translation being brought up to date with source changes, use [guide.transreconcile](../skills/guide.transreconcile/SKILL.md) through [update a translation](update-translation.md).

**Next:** [credits and PDFs](credits-pdfs.md), then [check and submit](validation.md). The intended guide should contain the reviewed words; an empty starting page or generated proposal is unfinished work.

## I do not have an agent and want to do this manually

Use an editor to prepare a separate proposed translation, then the documented commands to check and apply it. A candidate means that proposed file. A hash is its exact file fingerprint: the commands use it to avoid replacing text someone else changed. [Setup](setup.md#i-do-not-have-an-agent-and-want-to-do-this-manually) explains the tools; [status](status.md#i-do-not-have-an-agent-and-want-to-do-this-manually) supplies the actual guide and edition identifiers. The examples linked below give runnable commands for this release.

Choose one guide, edition and language explicitly. Adding the site language is a prerequisite; it does not mean every historical edition must be translated. Use [status](status.md) to discover actual identifiers and preserve existing protected or PDF-only publications.

## Prepare, review and apply

Follow [select a guide body](../../OpenGuidePlatform.PowerShell.Core/TranslationReadiness/README.md#select-a-guide-body-for-a-separate-translation-stage), then its candidate/check/application examples. Start from the existing target; create an eligible empty target through the documented operation only when absent. Record the actual source used.

Translate agreed text using the glossary. Preserve headings, links, references, explicit anchors, shortcodes and meaningful formatting. Read the site's rules for adaptation markers and acknowledgements. The standard translated-document operation permits changes to `title`, `description` and `summary`; other custom metadata needs separate supported review. Do not add `lang` or copy another guide's metadata conventions.

Use the same [review sheet and handoff](review-wording.md) as website wording. Work section by section when that helps reviewers, retaining the actual source and candidate evidence. The technical volunteer handles command inputs and hashes; translators can focus on text. Source conventions, licence wording and translator sections come from the site's policy and explicit guardian decisions, not an assumed copy of another translation.

Run `Test-GuideTranslation` on the candidate. `blocked` means a constraint failed. `review-required` means people must still assess meaning; it is not approval. Compare source and candidate outlines and investigate findings. Have reviewers identify omissions, awkward wording and terminology conflicts before applying with the original source and target hashes.


**Success:** reviewed wording is applied to the intended document only, the diff agrees with scope, and [build and visual checks](validation.md) are recorded. Native speakers still establish language quality. **If hashes changed:** reconcile your candidate with the new files; never just replace the expected hash. **Next:** [credits/PDFs](credits-pdfs.md), then [review](validation.md).
