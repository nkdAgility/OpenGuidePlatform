# Understand files and changes

You can review words without learning the site's file formats. The agent or a volunteer can handle them while you focus on what readers will understand.

## Work with an agent

Use [guide.transstatus](../skills/guide.transstatus/SKILL.md) to identify the selected work without editing. If the agent cannot access the project or skill, start with [setup](setup.md).

> Use this site's installed **guide.transstatus** skill to identify the files involved in our agreed translation. Do not change files. Explain which words readers see, which settings must stay intact, and what is still unknown. Use actual findings, not another site's file list. Explain unfamiliar terms as they arise.

**You should receive:** a short explanation connected to your chosen language and guide. You do not need to supply technical file identifiers yourself.

For example, in `Download {{ .Site.Title }}`, translate “Download” but keep `{{ .Site.Title }}` intact: the software fills that part in. In a link, the words may change while the address stays the same.

**You decide:** the proposed words, not whether an unfamiliar software setting should be translated. Ask the agent to flag uncertain fields. Approved file changes must use the appropriate installed skill on [add a language](add-language.md), [translate a guide](translate-guide.md) or [update a translation](update-translation.md).

**Next:** return to [your first translation](first-translation.md). The explanation below is optional background, not a prerequisite for wording review.

## I do not have an agent and want to do this manually

### Before you start

This is optional background, not another software task. You can review words without editing files.

### Choose your next step

| Term | What it means for your work |
|---|---|
| Fork | Your copy of the site's project on GitHub. |
| Local copy / clone | The folder on your computer copied from that fork. Commands run here. |
| Draft | A separate proposed file to review before applying it to the site. |
| Page settings / front matter | The section between `---` lines at the start of a page. Preserve unselected settings. |
| Branch | The line of work agreed for this task. |
| Commit / push / pull request | Save selected changes locally / share them with GitHub / ask the site team to review them. |

In `Download {{ .Site.Title }}`, translate “Download” and preserve `{{ .Site.Title }}`: software fills it in. In `[Read the guide](guide-url)`, the label may be translated while the destination stays intact. A setting containing English is not automatically a word you should translate.

OGP keeps working drafts and reports under `.processing`. Apply reviewed words through the task command before submitting the resulting site-file changes; do not submit that temporary folder or edit its check records. The module checks whether source/destination files changed while you worked. A refusal means review again, not change the recorded fingerprint to force a save.

### Check the result

You should know which words you are changing and which identifiers/settings must remain intact. Ask the maintainer about an uncertain field. Continue to [translate a guide](translate-guide.md#i-do-not-have-an-agent-and-want-to-do-this-manually) or [update a translation](update-translation.md#i-do-not-have-an-agent-and-want-to-do-this-manually).
