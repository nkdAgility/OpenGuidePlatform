# Your first translation

You bring the language knowledge. An agent can help with the files, checks and submission. This page takes you through the work; the linked task pages give the next request to send.

First check what already exists. For a new website language, prepare its menus and introductory pages before translating a guide. For an existing language, keep its working pages and translate or update only the agreed missing text. An edition is one version of a guide; choosing one does not commit you to translating its whole history.

## Work with an agent

Use an agent that can access this guide site's files and installed OGP skills. A skill is a set of task instructions, not a command you need to learn. If you have not connected an agent to the site, start with [setup](setup.md). If it cannot load a required skill, ask the maintainer for help; do not replace it with a general translation request.

### 1. Choose the work with the site team

Return to the guide site's translation page and use its **Start here** contact link. Send the request provided there: it tells the team your language, selected guide and whether you need help with the tools. Keep that discussion open throughout the work. If you arrived directly at OGP, [find your guide site's contact](setup.md#find-the-team-for-your-guide-site).

Agree who will review the wording and who settles disagreements. Follow the site's translation policy for terminology, licences, acknowledgements and reviewer requirements. Keep questions visible when the team has not decided something.

### 2. Find out what exists

Paste this into the agent conversation, replacing Kannada with your language:

> Use this site's installed **guide.transstatus** skill to inspect translation work for Kannada. Do not change files. Confirm the language and its code with me. Explain website work separately from guide translations. Tell me what exists, what is missing and what help is needed. Identify the installed version and report you used. If you cannot access the files or skill, say so instead of guessing.

This uses [guide.transstatus](../skills/guide.transstatus/SKILL.md). Expect an understandable list, not instructions to copy another language's files. Existing text, PDFs and deliberate use of another language must be preserved.

### 3. Prepare the website language

If the status report says this website language is missing or incomplete, open [add a language → Work with an agent](add-language.md#work-with-an-agent) and paste that page's requests into the same conversation. It uses [guide.transcreate](../skills/guide.transcreate/SKILL.md) for menus, buttons, homepages and pages for finding guides. You approve proposed wording before the agent applies it. A new language stays excluded from the live website.

If the website language is already ready, go straight to step 4. Do not disable an existing live language or recreate its pages.

Before creating empty guide starting pages, the agent shows the eligible guides and editions and asks you to choose which to include. **An empty page is not a translated guide.** It must report unfinished work plainly.

### 4. Translate the guide you selected

Open [translate a guide → Work with an agent](translate-guide.md#work-with-an-agent) and paste its request into the same conversation for the separately selected guide and edition. This uses **guide.transcreate**. If you are updating an existing translation because its source changed, instead open [update a translation](update-translation.md#work-with-an-agent), which uses **guide.transreconcile**. You can supply the translation or ask for a draft. Use the agreed terms, compare it with the source, and have people review it. Ask questions about meaning rather than accepting software's guess.

Use [review wording](review-wording.md) to give corrections a person or agent can apply. You do not need to calculate file fingerprints or edit settings.

### 5. Check the words, appearance and credits

Ask the agent to run the required checks through the translation skill and show how to inspect the prepared website. Ask the maintainer for a review link if one is not available. Read navigation and guide text, follow links, and check the letters on a phone and larger screen.

Follow [credits and PDFs](credits-pdfs.md) for **guide.contributions** and, only when an eligible new PDF is needed, **guide.genpdfs**. Confirm the names people consent to publish. Supplied PDFs remain unchanged. People must inspect any newly generated PDF.

### 6. Submit for review

Open [check and submit → Work with an agent](validation.md#work-with-an-agent) and paste its request into the same conversation. Ask for a clear account of changed text, review decisions, actual check results and unresolved work. A pull request is the submission asking the site team to review changes; it does not publish them.

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
