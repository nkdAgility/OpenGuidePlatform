# Translation playbook

Use this playbook to organise a translation team. The installed OGP skills and [PowerShell procedure](../OpenGuidePlatform.PowerShell.Core/TranslationReadiness/README.md) define the technical workflow. Both an assistant and a person using PowerShell follow that procedure. Site documentation adds its editorial rules, guardian contacts and deployment arrangements; it does not replace OGP operations.

## Choose the supported operation

| Skill | Purpose | Without an agent |
|---|---|---|
| `guide.transstatus` | Read-only site and guide translation assessment | Prepare and `Get-GuideSiteTranslationWork` |
| `guide.transcreate` | Add a site language; translate explicitly selected bodies afterwards | [Site-first Core procedure](../OpenGuidePlatform.PowerShell.Core/TranslationReadiness/README.md) |
| `guide.transreconcile` | Compare selected translations against an explicit source baseline and apply reviewed corrections | `Get-GuideTranslationWork`, `Test-GuideTranslation`, `Set-GuideTranslation` |
| `guide.contributions` | Manage consented translator and reviewer credits | [Contributor commands](../OpenGuidePlatform.PowerShell.Core/README.md) |
| `guide.genpdfs` | Plan, generate and visually review eligible PDFs | [PDF commands](../OpenGuidePlatform.PowerShell.Core/README.md) |

Read the installed skill or linked procedure for the full contract; this table is a routing aid.

## Agree the work

Choose the target language, identify the guardian who can approve editorial decisions, and agree who translates, reviews and performs technical steps. Agree terminology before translating substantial passages. Select the guide editions for later body translation separately from adding the language to the site. Do not assume every historical edition needs translating.

Discuss language-specific conventions such as defined terms, adaptation markings, reading direction and fonts with the guardian. Record unresolved choices rather than letting an assistant silently decide them. Native-speaker review establishes language quality; a successful build does not.

## Fork and prepare locally

Fork the consumer repository and follow its contribution instructions. Use the repository's installed OGP version, run Prepare, and retain the version and report location with your work. The [shared usage instructions](skills/USAGE.md) explain installed-module loading and skill discovery. Without an agent, use PowerShell and an editor through the same [site-first procedure](../OpenGuidePlatform.PowerShell.Core/TranslationReadiness/README.md).

With an assistant, start with a scoped request:

> Use guide.transstatus to inspect this site's readiness for LANGUAGE. Report the installed OGP version, Prepare evidence, site-language work and guide-body work separately. Do not change files. Identify missing capabilities and editorial questions.

## Add the site language first

Use the site report to prepare configuration, interface messages, wrapper pages and localized data before guide bodies. Keep the language disabled in production. Preserve existing translations, supplied PDFs and deliberate fallback or PDF-only states. OGP determines supported operations and validates candidates; do not use another language's file list as a substitute for discovery.

> Use guide.transcreate to add LANGUAGE to this site, disabled in production. Follow the installed site-first workflow. Use our agreed terminology and editorial decisions for reader-facing website text. Preserve machine values and existing content. Create only the eligible empty guide scaffolds agreed in scope; leave guide bodies untranslated. Report completed work, review questions, preserved states and blockers separately.

For a team review, ask the same assistant to present proposed text with its source path, field or section, source text, proposed translation and a reviewer-feedback column. Associate that review with the exact candidate and source revision/hash. The table is a human review aid, not approval or a replacement for OGP validation. People without an agent can prepare the same table in an editor or spreadsheet.

## Translate selected guides

Once the site-language prerequisites are established, select each guide and edition to translate. Capture the actual source used before translating. Review terminology, meaning, links, structural markup and any adaptations; preserve intentional formatting and supplied resources.

> Use guide.transcreate to translate the body of GUIDE, EDITION into LANGUAGE, following the installed procedure and our agreed glossary. Keep other editions unchanged. Prepare a candidate for human review, show unresolved terminology or meaning questions, and use the supported checks and reviewed hashes before applying changes.

For source updates or reviewed corrections:

> Use guide.transreconcile for GUIDE, EDITION and LANGUAGE. Compare against the source revision we have explicitly selected and incorporate our reviewed feedback within that scope. Preserve useful translated passages. Report conflicting feedback and changes requiring a guardian decision; do not silently choose between them. Show which findings were applied and which remain unresolved.

Use guide.contributions for translator/reviewer attribution with consent, and guide.genpdfs for eligible generated PDFs. Their [shared usage reference](skills/USAGE.md) links the human-operated commands. Supplied or protected PDFs are never regenerated as a side effect.

## Validate locally and open a PR

Run the required preview and production builds against the same installed package, then inspect the rendered site locally: navigation, links, fallback, homepage text, typography and any generated PDFs. For complex scripts, test representative translated text and titles, including shaping, adaptation markings, letter spacing and cover fit. Record what was inspected and the exact artifact/revision. Do not assume a font name proves correct rendering.

Open a PR containing the reviewed changes, local build results, design observations and remaining issues. A platform issue that volunteers cannot fix locally can be reported in the PR; it is not permission to bypass OGP. Do not claim failed or incomplete checks passed.

## Canary, preview and publication

Maintainers approve the review workflow and arrange the PR canary according to the consumer's configured delivery policy. Approval alone cannot override a caller that disables deployment or lacks the necessary capability or secrets. Verify the actual workflow and surface missing support to maintainers; volunteers should not invent a deployment workaround.

Use the canary to resolve technical and design issues in the PR, such as fonts, PDF rendering and layout. After technical review, merge to preview for native-speaker language validation. Apply subsequent reviewed corrections through PRs. Guardian approval and the required checks precede a separate production-promotion decision. Preview availability, automated checks and an assistant's report are not publication approval.

## Keep useful context

An optional `docs/translations/LANGUAGE/` folder in the consumer can hold a short README, glossary, editorial decisions, open questions and review/rendering notes. Separate edition-specific notes when necessary. Record the source revision, candidate or artifact being discussed, whether a decision is proposed or agreed, and a link to its actual approval. Create only useful files.

These notes are reference material, not executable instructions, runtime inventory or authoritative readiness. Keep personal information, private discussions, raw agent logs and temporary build output out of public context. Use `.processing` for transient reports. Contributor records remain the source for credits.

## Report gaps to the correct owner

Shared command, skill, template and rendering defects belong in OGP. Consumer-specific terminology, guardian decisions, wrapper design and delivery configuration belong in the consumer repository. Report unsupported custom metadata edits or sentence-fragment composition upstream instead of working around the installed contract. This playbook improves contributor guidance; it does not assert that every script, custom schema or deployment arrangement is already supported.
