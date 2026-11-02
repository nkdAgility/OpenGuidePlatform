# Add a language to the website

Readers need menus, buttons and introductory pages in their language too. This page helps you prepare those parts of the website.

**Translating the guide itself comes afterwards.** The language stays off the live website while the work is prepared and reviewed.

## Work with an agent

This route uses two OGP skills:

- [**guide.transstatus**](../skills/guide.transstatus/SKILL.md) finds out what already exists and what needs doing.
- [**guide.transcreate**](../skills/guide.transcreate/SKILL.md) prepares the website language using the supported workflow.

A **skill** is a set of instructions your agent follows. Paste the requests below into your agent's conversation; they are not terminal commands.

Your agent needs access to the guide site's files and its installed skills. If it cannot access them, ask a site maintainer—the person responsible for the website—for help. The agent must not replace these skills with a different translation workflow.

### 1. Choose the language and check what exists

Agree the language with the site team, including any regional variant. For example, Brazilian Portuguese and European Portuguese may need different wording.

Then send this request, replacing **Kannada** with your language:

> Use this site's installed **guide.transstatus** skill to check what is needed for Kannada. Do not change files. Confirm the language and its code with me rather than guessing. Explain what already exists, what needs doing for the website, and what guide translations exist separately. Report anything that prevents the work, and identify the installed version and status report you used. If you cannot access the files or load the skill, explain what help I need.

**You should receive:** an understandable list of the work needed. Existing translations should be identified, not replaced. Some guides deliberately provide only a PDF or use another language; those arrangements must be preserved.

### 2. Agree the website wording

Follow the site's translation policy. Agree who will review the wording and who will settle disagreements.

Make a short list of preferred translations for recurring terms. You can supply the words yourself or ask the agent to propose them. People still need to check their meaning and naturalness.

### 3. Ask the agent to prepare the language

> Use this site's installed **guide.transcreate** skill to add Kannada across the website. Use only that skill's documented workflow.
>
> First show the proposed website wording beside its source in this conversation. Do not change files until I approve the proposals.
>
> Keep the language excluded from the live website while we work. Preserve existing translations, PDFs and deliberate language arrangements. Before creating any empty guide starting pages, show the eligible guides and editions and wait for me to choose which to include. Leave guide bodies untranslated.
>
> Run the required checks and explain the results. If the skill cannot complete a step, report what is missing and ask for maintainer help; do not invent another way.

The agent handles the work in this order:

1. Keep the language excluded from the live website, then add its language settings.
2. Prepare the website wording: menus, buttons, homepages and pages for finding guides, editions and translations.
3. Prepare any other supported reader-facing website text.
4. Show which guides and editions can have empty starting pages. You choose which to include; only then does the agent create them for later guide translation.

**An empty starting page is not a translated guide.**

### 4. Review what readers will see

Ask the agent how to view the prepared website. If no review version is available, ask the maintainer to arrange one.

Read it in the new language. Check the menus, buttons, links and how the letters appear on both a phone and a larger screen.

The agent should report:

- What changed and what was preserved.
- Which guide starting pages remain empty.
- Which checks passed, failed or have not been completed.
- Whether the language remains excluded from the live website.

Passing software checks does not establish that the translation reads correctly.

### 5. Share the work or continue translating

Once the website wording has been reviewed and the required checks pass, continue to [translate a guide](translate-guide.md).

You can also [submit this stage for review](validation.md) first. Explain that the website language is being prepared and guide starting pages are still empty.

**Submitting work asks the site team to review it. It does not publish the language.**

## I do not have an agent and want to do this manually

You can complete the same work using an editor and OGP's commands.

Start with [computer setup](setup.md#i-do-not-have-an-agent-and-want-to-do-this-manually) if these tools are unfamiliar. It explains what to install and where commands go. Alternatively, you can [supply and review wording](review-wording.md) while another volunteer handles the files.

Follow the same order:

1. [Check what already exists](status.md#i-do-not-have-an-agent-and-want-to-do-this-manually).
2. Exclude the language from the live website **before** adding its main language settings. Preserve unrelated settings.
3. Prepare and review the website wording: messages, homepages, guide-finding pages and supported site-owned text.
4. Create only the agreed, eligible empty guide starting pages. Preserve existing translations, protected content, supplied PDFs and deliberate alternative-language/PDF-only arrangements. Leave guide bodies untranslated.
5. Run the preview and production checks and inspect the prepared website. These checks do not publish it.

Keep links and software placeholders unchanged. For example, translate “Download” in `Download {{ .Site.Title }}`, but leave `{{ .Site.Title }}` intact.

For each file, review a separate proposed version before using OGP's supported command to apply it. The commands check that the original has not changed while you worked. If it has, review again rather than overwrite newer work.

The [step-by-step command reference](../../OpenGuidePlatform.PowerShell.Core/TranslationReadiness/README.md#add-a-language-across-the-site) provides the exact commands, including refreshing the work report after changes and resuming interrupted work. Use the reference supplied with your site's installed OGP release. If an operation is unsupported or a check fails, retain the result and ask the maintainer for help; do not bypass the supported commands.

Then return to **Review what readers will see** above.
