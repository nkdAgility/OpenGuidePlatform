# Get help when something goes wrong

You do not need to diagnose a software failure yourself. Keep the result and ask for a plain-English explanation of what failed and who can help.

## Work with an agent

For a translation problem, start with the read-only [guide.transstatus](../skills/guide.transstatus/SKILL.md) skill. If the agent cannot access it, follow [setup](setup.md) with the maintainer rather than asking for a generic repair.

> Use this site's installed **guide.transstatus** skill to inspect our selected language without changing files. Explain the first useful failure, what it prevents, the installed version and report used, and the next supported action. If you cannot load the skill or produce the report, tell me exactly what help is needed. Do not change versions, overwrite files or invent a repair workflow to get past the failure.

**You should receive:** an explanation, actual evidence or an explicit missing-result statement, and an owner for the next action. A failed or unavailable check must not be described as passed.

| What you see | What to ask for |
|---|---|
| Agent cannot access files or skills | Ask the maintainer for supported access or a volunteer to operate the skills. |
| Agent says a tool or capability is missing | Keep its exact message; ask the maintainer to resolve the prerequisite. |
| Source text changed while you were reviewing | Ask for a comparison and renewed review before applying old wording. |
| English still appears | Ask whether it is missing translation or deliberate use of another language. |
| No website review link | Ask the maintainer to arrange one; do not assume a site was deployed. |
| Letters, direction or PDF pages look wrong | Identify the actual page and result; ask for the appropriate site or **guide.genpdfs** review. Preserve supplied PDFs. |

Do not send passwords, private conversations or raw assistant logs. Share only the relevant failure and report through the site's agreed channel.

After the cause is understood, repairs stay with the appropriate installed skill: [guide.transcreate](../skills/guide.transcreate/SKILL.md), [guide.transreconcile](../skills/guide.transreconcile/SKILL.md), [guide.contributions](../skills/guide.contributions/SKILL.md) or [guide.genpdfs](../skills/guide.genpdfs/SKILL.md). Unsupported work goes to the maintainer or OGP.

**Next:** return to [your task](README.md) when the prerequisite is resolved. The manual troubleshooting table and glossary below explain technical terms if you need them.

## I do not have an agent and want to do this manually

If you are running the tools yourself, start with [manual setup](setup.md#i-do-not-have-an-agent-and-want-to-do-this-manually). Read the first useful error and the report printed by the command. The table below explains common messages; the glossary defines terms used by the technical references. Do not keep retrying without understanding the failure.

Read the first actionable failure and its report before retrying. Share the command, installed OGP version, report path and relevant error with the maintainer. Omit credentials, private conversations and raw assistant logs. A failed or missing check stays failed/unknown until verified again.

| Symptom | What to do |
|---|---|
| `./build.ps1` gives shell syntax errors or permission denied | In macOS/Linux Terminal, start `pwsh`, then run the PowerShell instructions from the repository root. |
| Tool is not found | Complete the site's setup, restart the shell if needed and check its version. |
| Release cannot be restored | Check network access, `gh auth status` and access to the selected release. Do not switch OGP versions to bypass it. |
| Output directory already exists | Choose a fresh `.processing` directory; status examples use a unique identifier. Preserve earlier evidence. |
| Prepare fails | Read `prepare/assessment.md` if present. Valid discovery can support repairs; absent/invalid discovery blocks dependent operations. |
| Command or playbook is missing | Report the installed version and missing capability. Maintainers use coordinated Update on a review branch. |
| Stale hash | Reread source/target, reconcile the candidate and review again. Do not just refresh the hash. |
| JSON schema reconciliation is unsupported | Report the path and schema change. Text selection cannot add/remove keys or change structure. |
| A translation shows English | Check declared fallback, actual populated text and Prepare findings. English is not proof of complete translation. |
| Missing interface labels | Check effective catalogue findings and rendered output. Preserve placeholders; report sentence-fragment composition to OGP. |
| No PR canary link | Ask the maintainer to check delivery policy, caller configuration and access. Do not invent a deployment workaround. |
| Broken script rendering or stale PDF receipt | Use the explicit PDF/font workflow and human visual review; preserve supplied PDFs. |

## Words you will see

| Word | Meaning |
|---|---|
| Repository / fork / clone | Shared file history / your GitHub copy / your local copy |
| Branch / commit / PR | A line of work / saved snapshot / request to review and merge changes |
| Edition | One version of a guide, independently translated |
| Wrapper / i18n | Website around the guides / interface-message catalogue |
| Front matter | Page settings before its Markdown body |
| Candidate / hash | Proposed replacement / fingerprint of exact reviewed bytes |
| Prepare / discovery | Assessment stage / its generated inventory of the actual site |
| Scaffold / fallback | Empty translation starting point / use of another declared language |
| Canary / preview / production | PR review environment / pre-publication review / public reader environment |
| Guardian | Person authorised by the site to resolve translation editorial decisions |
| Receipt | Recorded evidence tying a generated PDF to inputs and generation conditions |

**Next:** return to [your task](README.md). Shared command/template defects belong in OGP; editorial decisions, wrapper design and delivery arrangements belong with site maintainers.
