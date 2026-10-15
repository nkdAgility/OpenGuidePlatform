# Translate a guide

Choose one guide, edition and language explicitly. Adding the site language is a prerequisite; it does not mean every historical edition must be translated. Use [status](status.md) to discover actual identifiers and preserve existing protected or PDF-only publications.

## Prepare, review and apply

Follow [select a guide body](../../OpenGuidePlatform.PowerShell.Core/TranslationReadiness/README.md#select-a-guide-body-for-a-separate-translation-stage), then its candidate/check/application examples. Start from the existing target; create an eligible empty target through the documented operation only when absent. Record the actual source used.

Translate agreed text using the glossary. Preserve headings, links, references, explicit anchors, shortcodes and meaningful formatting. Read the site's rules for adaptation markers and acknowledgements. The standard translated-document operation permits changes to `title`, `description` and `summary`; other custom metadata needs separate supported review. Do not add `lang` or copy another guide's metadata conventions.

Run `Test-GuideTranslation` on the candidate. `blocked` means a constraint failed. `review-required` means people must still assess meaning; it is not approval. Compare source and candidate outlines and investigate findings. Have reviewers identify omissions, awkward wording and terminology conflicts before applying with the original source and target hashes.

With an assistant: “Use guide.transcreate to translate GUIDE, EDITION into LANGUAGE using our glossary and the installed procedure. Prepare a candidate, present questions and check findings, and use reviewed hashes before applying. Preserve other editions.”

**Success:** reviewed wording is applied to the intended document only, the diff agrees with scope, and [build and visual checks](validation.md) are recorded. Native speakers still establish language quality. **If hashes changed:** reconcile your candidate with the new files; never just replace the expected hash. **Next:** [credits/PDFs](credits-pdfs.md), then [review](validation.md).
