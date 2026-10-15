# Add a site language

The goal is to make the surrounding website usable in the language before translating selected guide bodies. Start with [agreed scope](translation.md) and a fresh [status report](status.md). A technical volunteer applies reviewed text; translators need not edit JSON or YAML themselves.

Follow the [Core site-first procedure](../../OpenGuidePlatform.PowerShell.Core/TranslationReadiness/README.md#add-a-language-across-the-site) for exact commands and candidates. Its order matters:

1. Add the language **disabled in production first**, then add its main language configuration. Preserve unrelated settings and every other language.
2. Translate discovered interface messages and wrapper pages: homepage, guide landing pages, history and translation listings.
3. Translate selected reader-facing strings in discovered site-owned data. Preserve keys, URLs, placeholders and machine values. JSON pointers select specific string values; they are not a request to translate every string.
4. Refresh Prepare and create only eligible, agreed empty guide scaffolds. Do not replace existing translations or convert protected, PDF-only or fallback states.
5. Refresh discovery, run preview and production builds and inspect the result through [validation](validation.md).

Make a review table with source path, field/section, source text, proposed translation and feedback. Identify its source revision and candidate hashes. The table helps people review; the platform still checks each write.

With an assistant: “Use guide.transcreate to add LANGUAGE, disabled in production, following the installed site-first procedure and our glossary. Localize the website and create agreed eligible empty scaffolds. Leave guide bodies untranslated. Present review text, preserved states and blockers separately.”

**Success:** the website-language work and empty scaffolds are accurately reported; rendered preview and production exclusion have been checked. Any failed checks remain visible. Do not describe scaffolds as completed translations. **Next:** [selected guide bodies](translate-guide.md).

**If interrupted:** several files are separate operations. Inspect the actual diff, refresh Prepare and reconcile completed work before resuming. Missing configuration or unsupported custom metadata/schema operations must be reported; do not copy another language's file list or bypass the installed writer.
