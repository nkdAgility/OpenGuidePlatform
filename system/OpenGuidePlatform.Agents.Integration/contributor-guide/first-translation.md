# Your first translation

You bring the language knowledge. An agent can help with the files, checks and submission. This page takes you through the work; the linked task pages give the next request to send.

You will prepare the website language first, then translate the guide editions the team selects. An edition is one version of a guide; choosing one does not commit you to translating its whole history.

## Work with an agent

Use an agent that can access this guide site's files and installed OGP skills. A skill is a set of task instructions, not a command you need to learn. If you have not connected an agent to the site, start with [setup](setup.md). If it cannot load a required skill, ask the maintainer for help; do not replace it with a general translation request.

### 1. Choose the work with the site team

Tell the team which language and regional variant you want to help with. Agree who will review the wording and who settles disagreements. Follow the site's translation policy for terminology, licences, acknowledgements and reviewer requirements. Keep questions visible when the team has not decided something.

### 2. Find out what exists

Paste this into the agent conversation, replacing Kannada with your language:

> Use this site's installed **guide.transstatus** skill to inspect translation work for Kannada. Do not change files. Confirm the language and its code with me. Explain website work separately from guide translations. Tell me what exists, what is missing and what help is needed. Identify the installed version and report you used. If you cannot access the files or skill, say so instead of guessing.

This uses [guide.transstatus](../skills/guide.transstatus/SKILL.md). Expect an understandable list, not instructions to copy another language's files. Existing text, PDFs and deliberate use of another language must be preserved.

### 3. Prepare the website language

Follow [add a language](add-language.md), which uses [guide.transcreate](../skills/guide.transcreate/SKILL.md). It covers menus, buttons, homepages and pages for finding guides. You approve proposed wording before the agent applies it. The language stays excluded from the live website.

Before creating empty guide starting pages, the agent shows the eligible guides and editions and asks you to choose which to include. **An empty page is not a translated guide.** It must report unfinished work plainly.

### 4. Translate the guide you selected

Follow [translate a guide](translate-guide.md), also using **guide.transcreate**, for the separately selected guide and edition. You can supply the translation or ask for a draft. Use the agreed terms, compare it with the source, and have people review it. Ask questions about meaning rather than accepting software's guess.

Use [review wording](review-wording.md) to give corrections a person or agent can apply. You do not need to calculate file fingerprints or edit settings.

### 5. Check the words, appearance and credits

Ask the agent to run the required checks through the translation skill and show how to inspect the prepared website. Ask the maintainer for a review link if one is not available. Read navigation and guide text, follow links, and check the letters on a phone and larger screen.

Follow [credits and PDFs](credits-pdfs.md) for **guide.contributions** and, only when an eligible new PDF is needed, **guide.genpdfs**. Confirm the names people consent to publish. Supplied PDFs remain unchanged. People must inspect any newly generated PDF.

### 6. Submit for review

Follow [check and submit](validation.md). Ask for a clear account of changed text, review decisions, actual check results and unresolved work. A pull request is the submission asking the site team to review changes; it does not publish them.

An agent's ability to submit depends on repository access and the site's permissions. There is no separate OGP submission skill. If it cannot submit, give the reviewed work and check results to the maintainer and ask them to confirm the submission link. You can share a checked website-only stage early, clearly marked as unfinished guide translation.

The site team arranges technical and language review. Publication needs a separate decision by the responsible people. Keep the agreed terminology and source used so later volunteers can [update the translation](update-translation.md) through **guide.transreconcile**.

**You are ready to hand over when:** reviewers can find the proposed words, understand what was checked, see what is unfinished, and identify the submission or the maintainer who will make it. Do not mark incomplete checks as passed.

## I do not have an agent and want to do this manually

### Before you start

Agree the language and regional variant, guide editions, reviewers and preferred terms with the site team. Ask who settles wording disagreements. Follow local requirements for licences, acknowledgements and review; there is no universal reviewer count.

### Run the PowerShell steps

Follow these manual task pages in order. Each explains what to open, run, expect and do next:

1. [setup](setup.md#i-do-not-have-an-agent-and-want-to-do-this-manually) for your fork, local folder and module installation. Publication is still pending; use the maintainer-confirmed installation route.
2. [Status](status.md#i-do-not-have-an-agent-and-want-to-do-this-manually) to find actual work without changing text.
3. [Add a website language](add-language.md#i-do-not-have-an-agent-and-want-to-do-this-manually) if needed, keeping a new language off the live site. Preserve an already configured language and agree only its missing work. Choose eligible empty guide pages; they are not translated bodies.
4. [Translate one selected guide edition](translate-guide.md#i-do-not-have-an-agent-and-want-to-do-this-manually), reviewing the words against their source.
5. [Credits and PDFs](credits-pdfs.md#i-do-not-have-an-agent-and-want-to-do-this-manually), with consent and preservation of supplied originals.
6. [Check and submit](validation.md#i-do-not-have-an-agent-and-want-to-do-this-manually) for technical checks, visual review and the PR or maintainer handoff.

You can instead use [review wording](review-wording.md#i-do-not-have-an-agent-and-want-to-do-this-manually) while another volunteer handles the commands. For later source changes, use [update a translation](update-translation.md#i-do-not-have-an-agent-and-want-to-do-this-manually) with an explicitly agreed comparison version.

### Check the result

Reviewers can find the proposed words and source, agreed decisions, credits, actual checks and unfinished work. Confirm a submission link or explicit maintainer handoff. Technical review, native-speaker review and publication are separate decisions; neither an empty page nor passing software checks completes them.
