# Translation playbook

Use this page to organise the people and handoffs. For the complete beginner journey, start with [your first translation](contributor-guide/first-translation.md). With an agent, use the site's installed named skills. Without an agent, use the [manual task pages](contributor-guide/first-translation.md#i-do-not-have-an-agent-and-want-to-do-this-manually), beginning with module installation and its stated publication prerequisite. Both routes call the same Core operations; people do not need to copy Core's loading, policy or file-fingerprint code.

The guide site supplies its own terminology, contacts, review requirements and publication arrangements. The guardian is the person its policy authorises to settle wording decisions; a maintainer handles the site's technical operation.

## Choose the supported operation

| Skill | Purpose | Without an agent |
|---|---|---|
| `guide.transstatus` | Find existing and missing work without editing | [Status commands](contributor-guide/status.md#i-do-not-have-an-agent-and-want-to-do-this-manually) |
| `guide.transcreate` | Prepare website words, then separately translate selected guide editions | [Add a language](contributor-guide/add-language.md#i-do-not-have-an-agent-and-want-to-do-this-manually), then [translate a guide](contributor-guide/translate-guide.md#i-do-not-have-an-agent-and-want-to-do-this-manually) |
| `guide.transreconcile` | Compare source changes with an existing translation and apply reviewed corrections | [Update a translation](contributor-guide/update-translation.md#i-do-not-have-an-agent-and-want-to-do-this-manually) |
| `guide.contributions` | Manage consented credits | [Credit commands](contributor-guide/credits-pdfs.md#i-do-not-have-an-agent-and-want-to-do-this-manually) |
| `guide.genpdfs` | Plan and generate eligible PDFs, followed by human visual review | [PDF commands](contributor-guide/credits-pdfs.md#i-do-not-have-an-agent-and-want-to-do-this-manually) |

Read the installed skill or linked procedure for the full contract; this table is a routing aid.

## Agree the work

Choose the target language, identify the guardian who can approve editorial decisions, and agree who translates, reviews and performs technical steps. Agree terminology before translating substantial passages. Select the guide editions for later body translation separately from adding the language to the site. Do not assume every historical edition needs translating.

Discuss language-specific conventions such as defined terms, adaptation markings, reading direction and fonts with the guardian. Record unresolved choices rather than letting an assistant silently decide them. Native-speaker review establishes language quality; a successful build does not.

## Fork and prepare locally

Create your fork of the guide site's project on GitHub, then copy that fork to your computer. Follow [setup](contributor-guide/setup.md#i-do-not-have-an-agent-and-want-to-do-this-manually) for exact steps, module installation and an agreed working branch. Commands run in that local folder, not on GitHub. CurrentUser installation is disabled in this environment; the module setup explains authorised AllUsers installation.

Use the [status task](contributor-guide/status.md) to inspect the actual work. The module prints the site's selected OGP version and report folder; retain those details. A failed check is not readiness approval. Technical maintainers and skill implementers can consult [Core usage](skills/USAGE.md), but it is not the beginner manual route.

With an assistant, start with a scoped request:

> Use guide.transstatus to inspect this site's readiness for LANGUAGE. Report the installed OGP version, Prepare evidence, site-language work and guide-body work separately. Do not change files. Identify missing capabilities and editorial questions.

## Add the site language first

Use the work report to prepare language settings and website words—messages, homepages, guide-finding pages and other supported text—before guide bodies. Keep the language disabled in production, meaning the live website. Preserve existing translations, supplied PDFs and deliberate use of another language or PDF-only content. Do not substitute another language's file list for what the actual site reports.

> Use guide.transcreate to add LANGUAGE to this site, disabled in production. Follow the installed site-first workflow. Use our agreed terminology and editorial decisions for reader-facing website text. Preserve machine values and existing content. Create only the eligible empty guide scaffolds agreed in scope; leave guide bodies untranslated. Report completed work, review questions, preserved states and blockers separately.

For team review, present source words beside the proposal, with a place for feedback. Record the page/section, source version and exact draft being discussed; the volunteer handling files supplies technical identifiers. The table helps people review meaning; it does not apply words or replace software checks. [Review wording](contributor-guide/review-wording.md) gives a template usable without any software installation.

## Translate selected guides

Once the site-language prerequisites are established, select each guide and edition to translate. Capture the actual source used before translating. Review terminology, meaning, links, structural markup and any adaptations; preserve intentional formatting and supplied resources.

> Use guide.transcreate to translate the body of GUIDE, EDITION into LANGUAGE, following the installed procedure and our agreed glossary. Keep other editions unchanged. Prepare a candidate for human review, show unresolved terminology or meaning questions, and use the supported checks and reviewed hashes before applying changes.

For source updates or reviewed corrections:

> Use guide.transreconcile for GUIDE, EDITION and LANGUAGE. Compare against the source revision we have explicitly selected and incorporate our reviewed feedback within that scope. Preserve useful translated passages. Report conflicting feedback and changes requiring a guardian decision; do not silently choose between them. Show which findings were applied and which remain unresolved.

Use the installed guide.contributions skill for consented credits and guide.genpdfs for eligible generated PDFs when working with an agent. Without an agent, follow [credits and PDFs](contributor-guide/credits-pdfs.md#i-do-not-have-an-agent-and-want-to-do-this-manually) for actual task commands and expected results. Supplied or protected PDFs remain unchanged. Updating a translation does not automatically create or replace a PDF.

## Validate locally and open a PR

Follow [check and submit](contributor-guide/validation.md) for the required checks, viewing the website and sharing reviewed changes. Without an agent, `Test-OGPSite` checks preview and production and `Show-OGPSite` starts the local review website. These commands do not publish anything. Inspect navigation, links, actual language use, homepage text, letters and any generated PDFs. For complex scripts, inspect representative text and titles, including shaping, meaningful emphasis, letter spacing and cover fit. Record the actual website/PDF and version inspected; a font name is not proof of correct rendering.

Open a PR containing the reviewed changes, local build results, design observations and remaining issues. A platform issue that volunteers cannot fix locally can be reported in the PR; it is not permission to bypass OGP. Do not claim failed or incomplete checks passed.

## Canary, preview and publication

Maintainers arrange a temporary website for technical review of the pull request, sometimes called a canary, according to the site's actual delivery policy. Fork submissions may not create one automatically. Ask for a review address if missing; approval does not enable a disabled deployment or supply unavailable access. Volunteers must not invent a deployment workaround.

Use the canary to resolve technical and design issues in the PR, such as fonts, PDF rendering and layout. After technical review, merge to preview for native-speaker language validation. Apply subsequent reviewed corrections through PRs. Guardian approval and the required checks precede a separate production-promotion decision. Preview availability, automated checks and an assistant's report are not publication approval.

## Keep useful context

The volunteer handling the files can keep an optional `docs/translations/LANGUAGE/` folder in the guide site for preferred terms, decisions, open questions and review notes. Translators need not create that folder to participate. Separate edition-specific notes when useful. Record the source, draft or viewable result discussed, whether a decision is proposed or agreed, and the actual approval. Create only useful files.

These notes are context, not commands or proof that work is complete. Keep personal information, private discussions and raw agent logs out of public notes. Temporary reports and drafts belong under `.processing` and stay out of the submission. Contributor records remain the source for credits.

## Report gaps to the correct owner

Shared command, skill, template and display defects belong in OGP. The site's terminology, reviewer decisions, design and delivery settings belong with its maintainers. Report unsupported settings or messages that cannot form natural sentences rather than editing around the supported operation. A missing capability remains a gap; these instructions do not make every custom file or deployment arrangement supported.

For setup, plain-English task explanations and diagrams, use the [contributor guide](contributor-guide/README.md). This playbook retains the shared team journey and handoffs.
