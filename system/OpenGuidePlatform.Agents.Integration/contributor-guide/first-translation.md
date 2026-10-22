# Your first translation, from agreement to review

Use this page as the team's working checklist. The linked pages belong to the same OGP package, so everyone can use one procedure. The website may contain several guides and editions; the team chooses which bodies to translate after introducing the site language.

The **guardian** settles editorial questions, **translators** propose words, **reviewers** check them, a **technical volunteer** runs the commands, and a **maintainer** arranges review environments and publication. One person can hold several roles. Translators and reviewers can work without Git, PowerShell or an AI account: start with [reviewing wording](review-wording.md). The technical volunteer follows the command route on their behalf.

The [translation diagram](translation.md) shows the whole journey. A technical check and an editorial decision answer different questions; neither replaces the other.

## 1. Agree the people and the language

**Guardian and team:** use the site's contribution channel to agree the target language/variant, the people involved and the guide editions planned for later translation. Read the site's translation policy. Decide glossary terms, treatment of licences/references, acknowledgements and any meaningful source formatting. If capitals or italics do not transfer to the target script, record the question and the guardian's decision before drafting substantial passages.

**Hand over:** agreed scope, policy link, glossary and unresolved questions. Notes may live in the site's optional language folder described in [the journey](translation.md). Mark proposed and agreed decisions separately. Do not publish private contact details.

**Move on when:** the team knows who decides wording and who operates the tools. The required number and type of reviewers comes from site policy, not a universal OGP number.

## 2. Set up and find out what already exists

**Technical volunteer:** follow [setup](setup.md), then [check status](status.md). Run the assessment rather than copying another language's files. Record the installed package version and Prepare report path. Report site-language work separately from guide-body work, and preserve existing translations, supplied PDFs and intentional fallback/PDF-only states.

With an assistant, paste into its conversation, replacing LANGUAGE with your agreed language and code:

> Read this site's contributor instructions and use guide.transstatus for LANGUAGE. Report the installed version, Prepare evidence, website-language work and guide bodies separately. Do not edit. Explain prerequisites and missing capabilities in plain English.

Without an assistant, use the complete PowerShell blocks on the status page. `guide.transstatus` is a skill name, not a terminal command.

**Move on when:** discovery is valid and the next operations are supported. If the installed package lacks a capability, hand the version and missing operation to the maintainer for a coordinated update. A failed Prepare report remains failed even when valid discovery allows a specific repair.

## 3. Prepare the website words

**Technical volunteer:** follow [add a site language](add-language.md) and its linked Core command examples. Disable the language in production first; then prepare language configuration, interface labels, wrapper pages and selected site-owned data. Only then create the eligible empty guide scaffolds agreed in scope. Leave body translation for step 5.

With an assistant:

> Use guide.transcreate to add LANGUAGE to this site, disabled in production, using the installed site-first procedure and our glossary. Prepare website wording and agreed eligible empty scaffolds. Leave guide bodies untranslated. Present a review table tied to the exact source and candidate, and list preserved states, incomplete checks and unsupported operations. Follow the site's permissions for applying changes and Git actions.

**Translators and reviewers:** use [review wording](review-wording.md) to propose or check text in the review sheet. You do not need to change YAML, JSON or platform files. Ask the guardian to resolve disagreements.

**Move on when:** the technical volunteer can show what was applied, what remains empty, the preview/build findings and evidence that production remains excluded. A copied English value or empty scaffold does not count as translated wording. Record incomplete checks explicitly rather than hiding them.

## 4. Make work visible early

**Technical volunteer and maintainer:** use [save and submit](validation.md#save-and-submit-the-reviewed-change) to open a draft PR after the initial coherent change is locally checked. Describe it as website/scaffold work if guide bodies are still empty. Link the agreed scope and report outstanding findings honestly.

**Maintainer:** arrange the actual canary according to site delivery policy. A fork PR may run checks without producing a deployed site. Tell reviewers where they can inspect the change; workflow approval does not override a caller that disables deployment.

**Move on when:** the PR and review arrangement are clear. A missing canary remains a maintainer-owned blocker for the intended canary review; it does not authorise a deployment workaround or imply that production is approved.

## 5. Translate one selected guide edition

**Technical volunteer:** select the actual guide/edition/language through discovery and follow [translate a guide](translate-guide.md). Capture the exact source used, prepare a separate candidate, run its checks, and retain the reviewed source/target hashes for application. Use the complete Core examples linked from that task; they are the command route for people without an assistant too.

With an assistant:

> Use guide.transcreate for the body of GUIDE, EDITION into LANGUAGE, using our glossary and recorded editorial decisions. Work section by section if helpful. Present source and proposed wording for human review, preserve structural markup and other editions, and report meaning questions. Use the installed candidate checks and reviewed hashes before applying agreed text.

**Translators and reviewers:** check each passage against its source and glossary. Preserve source meaning and deliberate structure; follow the site's policy for references, names, numbers, adaptation markings and acknowledgement sections. [Review wording](review-wording.md) explains how to give usable feedback.

**Move on when:** reviewed changes are applied to the selected edition, unresolved questions are visible and the actual diff has been checked. A candidate check does not establish language quality. Repeat this stage only for other editions separately selected by the team.

## 6. Check what readers will see

**Technical volunteer:** follow [validation](validation.md) for preview and production builds on the same package. Inspect navigation, language/edition switching, links, fallback and downloads. Apply reviewed corrections through the appropriate [translation update](update-translation.md) or wrapper operation.

**Team and maintainer:** use [credits and PDFs](credits-pdfs.md) for consented records and eligible downloads. Check representative script shaping, meaningful emphasis, letter spacing, titles and PDF covers on actual rendered artifacts. Proposed font/CSS changes need the responsible maintainer's review; supplied PDFs remain untouched.

**Move on when:** technical/design findings are resolved and the intended PR/canary review is complete. The maintainer may then merge to preview for the site's native-speaker validation. Reviewers identify the exact preview artifact and give feedback; later corrections still go through PRs. Record what was actually checked, not merely which configuration files exist.

## 7. Approve publication and keep the translation current

**Guardian:** approve the wording and completed language review according to site policy. **Maintainer:** separately approve and perform the site's production-promotion/release procedure, check any site-owned issue forms or publication tests affected by the language, and verify the published result. There is no universal one-line release command for every guide site. Permanent production exclusions remain in force.

Keep the glossary, actual source baseline and useful review decisions for future volunteers. For a later source change, follow [update a translation](update-translation.md) with an explicitly agreed comparison revision. Do not assume the newest source commit is the one previously translated or merge unrelated work just to run a comparison.

## Handoff checklist

- [ ] Scope, glossary and applicable site policy are agreed; unresolved decisions are identified.
- [ ] Installed version and valid discovery/Prepare evidence are recorded; failures are accurately labelled.
- [ ] Website text and selected guide bodies have traceable review; empty/protected/fallback states are distinguished.
- [ ] Consented credits and any required acknowledgement are correct; eligible PDFs have receipts and visual review.
- [ ] Preview and production checks, rendered review and actual artifact/revision are recorded.
- [ ] Technical and language findings are resolved or explicitly block the next decision.
- [ ] Production promotion has its own approval and maintainer action; it is not inferred from these ticks.

Tick only completed work. This checklist records the team's evidence; it is not a new permission mechanism or a replacement for the installed operations.
