# Credit people and prepare PDFs

People should be credited as agreed, and downloads should show the right words. Adding a translation does not automatically create a new PDF.

## Work with an agent

Use [guide.contributions](../skills/guide.contributions/SKILL.md) for credits and [guide.genpdfs](../skills/guide.genpdfs/SKILL.md) only for eligible generated PDFs. If the agent cannot access the site and its installed skills, follow [setup](setup.md) with the maintainer.

### Agree the credits

Ask each person which name, role and optional profile link they consent to publish. Follow the site's acknowledgement rules and preserve existing credits.

> Use this site's installed **guide.contributions** skill for the guide, edition and language we selected. Show the existing credits and exact proposed changes in this conversation. Wait for my approval before changing files. Use only the details and consent we supplied. Preserve other people and their roles. If the requested change is unsupported or ambiguous, explain it and ask the maintainer; do not guess identities or use another workflow.

**You should receive:** the proposed credit records and, after the agreed supported change, the names as readers will see them. Check spelling, links and roles. Do not infer a person's identity from a similar name.

### Check whether a PDF can be created

> Use this site's installed **guide.genpdfs** skill to inspect the selected download. Tell me whether it is an eligible generated PDF or a supplied/protected original. Preserve supplied originals. For an eligible generated PDF, show the exact plan and explain missing tools, fonts and required presentation decisions. Wait for my approval before changing files or generating the PDF. Use only the skill's documented workflow. Report what cannot be done instead of substituting fonts or another method.

The skill can generate only downloads explicitly configured for generation. Agree any necessary presentation changes with the maintainer first. The agent must not silently install software, replace supplied PDFs or treat a file being produced as visual approval.

**You should receive:** the generation/check results and the actual new PDF when eligible and authorised. People must inspect its title, letters, reading direction, links, credits and page breaks. If it is not eligible or tools are missing, ask the maintainer what happens next.

**Next:** [check and submit](validation.md). Correct credit data and a technically valid PDF still need human review.

## I do not have an agent and want to do this manually

Credits are structured lists of people; their approved details belong there rather than in guide page settings. Ask the maintainer which record to select before editing it. PDF generation is a separate task with extra tools. The references below explain both procedures; [manual setup](setup.md#i-do-not-have-an-agent-and-want-to-do-this-manually) covers the ordinary tools first. Never regenerate a supplied original just to complete a checklist.

Credits recognise people; PDFs are published artifacts that need their own checks. Neither should be an accidental side effect of a text edit.

## Credit people with consent

Ask people which name and optional profile link they consent to publish. Guide creator/contributor records and translation-team records are separate. Use [contributor commands](../../OpenGuidePlatform.PowerShell.Core/README.md#guide-credits) or the installed [contributions skill](../skills/guide.contributions/SKILL.md) for the supported operation. Adding a person and updating an existing record have different contracts.

Structured credits do not replace any acknowledgement section required by the site's editorial policy. Preserve existing people and roles; report unsupported removals, renames or reordering instead of using an unrelated operation. Review the displayed website and PDF credits, not only YAML syntax.

## Prepare eligible downloads

Ask the maintainer whether the selected download is generated or supplied/protected. Only explicitly eligible generated PDFs may be generated. Preserve supplied originals and their filenames/bytes.

Follow the [PDF skill](../skills/guide.genpdfs/SKILL.md) and [Core PDF reference](../../OpenGuidePlatform.PowerShell.Core/README.md#pdf-configuration): inspect the plan, diagnose fonts and tools, agree configuration, generate the selected artifact, visually inspect actual pages and record the required receipt. A receipt records generation evidence; it does not approve appearance. Ordinary site builds do not generate PDFs automatically.

Inspect representative text and titles: glyphs, conjunct shaping, reading direction, italics/adaptation marks, page breaks, links, cover fit and attribution. A font name is not proof of correct rendering. Keep font choices in PDF configuration, not guide front matter. For scripts such as Kannada, the guardian must decide how source conventions transfer before the maintainer chooses and checks presentation.


**Success:** correct consented attribution is visible, eligible downloads have generation evidence and human visual review, and [Prepare/build checks](validation.md) agree. **If tools or approved fonts are missing:** report them before generation; do not silently substitute fonts or regenerate protected files.
