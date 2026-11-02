# The translation journey

The goal is a website and selected guides that people can read comfortably in their language. Translation includes the menus and introductory pages, not just the guide body.

## Work with an agent

Follow [your first translation](first-translation.md) for the complete journey and requests to paste. That page uses these installed skills in sequence:

1. [guide.transstatus](../skills/guide.transstatus/SKILL.md): find what exists and agree the work.
2. [guide.transcreate](../skills/guide.transcreate/SKILL.md): prepare the website language, then separately translate the selected guide editions.
3. [guide.contributions](../skills/guide.contributions/SKILL.md): record the consented credits. Use [guide.genpdfs](../skills/guide.genpdfs/SKILL.md) only for eligible generated PDFs.
4. [Check and submit](validation.md): complete the translation skill's checks and use the site's review process. There is no separate submission or publication skill.
5. Later, [guide.transreconcile](../skills/guide.transreconcile/SKILL.md): update reviewed translations when the source changes.

If you are not yet using an agent with site access, start with [setup](setup.md). Missing skills or unsupported operations require maintainer help, not a generic agent workflow.

![Agree the work, find what exists, prepare website words, translate selected guides, review and submit, then decide publication separately.](diagrams/translation.svg)

**You decide:** the language, selected guides, preferred terms and wording, with the site's reviewers. Discuss source conventions such as meaningful italics or capitals rather than assuming software knows how they should transfer.

**You should receive:** proposed words beside their source, clear human decisions, a viewable result or a maintainer arranging one, actual check results and a submission or explicit handoff. Keep the language excluded from the live site throughout preparation. Existing translations and PDFs stay intact.

**Next:** [your first translation](first-translation.md). You can also [review wording](review-wording.md) while someone else operates the skills.

## I do not have an agent and want to do this manually

The same stages work without an agent. Use the manual sections on each linked task page, starting with [setup](setup.md#i-do-not-have-an-agent-and-want-to-do-this-manually). The background below explains team responsibilities and notes to retain. A guardian means the person authorised by your site to settle language decisions; it is not a software role you must configure.

The goal is a complete reader experience whose wording people have reviewed. The guardian decides editorial questions; translators propose wording; reviewers check it; a technical volunteer operates commands; maintainers arrange review environments and publication. One person may have several roles.

For a practical step-by-step handoff, follow [your first translation](first-translation.md). Translators and reviewers who do not run commands can start with [review wording](review-wording.md).

![Agree scope, assess the site, add the site language, translate selected guide editions, review and validate, then obtain separate publication approval.](diagrams/translation.svg)

In words: agree people and terminology, inspect the actual site, introduce the language around the guides, then translate separately selected guide editions. Review rendering and language, resolve feedback, and obtain publication approval. Keep the new language excluded from production throughout preparation.

## Before translating sentences

Agree language and regional variant, guide editions, reviewers and the person who resolves disagreements. Build a glossary. Discuss conventions that may not survive translation: meaningful capitals, adaptation italics, reading direction and fonts. Record unresolved choices rather than letting software decide them. Follow the site's rules for licences, acknowledgements, consent and minimum reviewer counts; these are not universal OGP rules.

Use the [translation playbook](../translation-playbook.md) for team handoffs and scoped assistant requests. Then follow:

1. [Assess readiness](status.md).
2. [Add the site language](add-language.md), leaving guide bodies for the next stage.
3. [Translate selected guides](translate-guide.md).
4. [Record credits and prepare eligible PDFs](credits-pdfs.md).
5. [Validate and submit](validation.md).

An optional `docs/translations/LANGUAGE/` folder in the site can retain the glossary, proposed/agreed decisions, source revisions and review notes. Link actual approvals and identify the exact candidate or rendered artifact. These notes are context, not an inventory or automatic permission to publish. Later use [reconciliation](update-translation.md).
