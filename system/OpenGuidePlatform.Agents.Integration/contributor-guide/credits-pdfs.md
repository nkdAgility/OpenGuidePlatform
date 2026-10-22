# Credits and PDFs

Credits recognise people; PDFs are published artifacts that need their own checks. Neither should be an accidental side effect of a text edit.

## Credit people with consent

Ask people which name and optional profile link they consent to publish. Guide creator/contributor records and translation-team records are separate. Use [contributor commands](../../OpenGuidePlatform.PowerShell.Core/README.md#guide-credits) or the installed [contributions skill](../skills/guide.contributions/SKILL.md) for the supported operation. Adding a person and updating an existing record have different contracts.

Structured credits do not replace any acknowledgement section required by the site's editorial policy. Preserve existing people and roles; report unsupported removals, renames or reordering instead of using an unrelated operation. Review the displayed website and PDF credits, not only YAML syntax.

## Prepare eligible downloads

Ask the maintainer whether the selected download is generated or supplied/protected. Only explicitly eligible generated PDFs may be generated. Preserve supplied originals and their filenames/bytes.

Follow the [PDF skill](../skills/guide.genpdfs/SKILL.md) and [Core PDF reference](../../OpenGuidePlatform.PowerShell.Core/README.md#pdf-configuration): inspect the plan, diagnose fonts and tools, agree configuration, generate the selected artifact, visually inspect actual pages and record the required receipt. A receipt records generation evidence; it does not approve appearance. Ordinary site builds do not generate PDFs automatically.

Inspect representative text and titles: glyphs, conjunct shaping, reading direction, italics/adaptation marks, page breaks, links, cover fit and attribution. A font name is not proof of correct rendering. Keep font choices in PDF configuration, not guide front matter. For scripts such as Kannada, the guardian must decide how source conventions transfer before the maintainer chooses and checks presentation.

With an assistant: “Use guide.contributions for our consented records, then guide.genpdfs to assess the selected download. Show eligibility, tools/fonts, candidate changes and required visual review. Preserve supplied PDFs.”

**Success:** correct consented attribution is visible, eligible downloads have generation evidence and human visual review, and [Prepare/build checks](validation.md) agree. **If tools or approved fonts are missing:** report them before generation; do not silently substitute fonts or regenerate protected files.
