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

### Before you start

Stop at the first unexpected result. Keep the page and step you were following and the exact visible error. You do not need to diagnose software yourself.

### Choose your next step

Send the maintainer: “I am following PAGE, step STEP. I expected RESULT but saw ERROR. What should I do next?” Replace those words with your actual situation. Include the printed version/report folder if the command produced them; say unavailable if it did not. Leave out passwords, tokens and private conversations.

| What happened | What to do next |
|---|---|
| The module cannot be found during installation | Confirm publication and the approved package with the maintainer. Do not pick another similarly named module. |
| Installation requests permissions you do not have | Ask an authorised administrator to complete AllUsers installation. CurrentUser scope is disabled; do not use it or relocate folders as a workaround. |
| A command is not recognised | Confirm setup completed in PowerShell 7.4 or later. Ask the maintainer for the installed module/version; do not substitute an invented command. |
| GitHub sign-in or a release download fails | Follow the setup sign-in step and share the exact failure if it persists. |
| A draft is refused because a file or runtime changed | Keep the draft, ask for the actual changes, create a fresh draft and review affected text again. |
| A report says a file or setting is unsupported | Give the maintainer its path and requested action. Do not edit around the refusal. |
| English still appears | Ask whether wording is missing or the site deliberately uses another language there. |
| No review website is available | Ask the maintainer to arrange one; record visual review as incomplete. |
| Letters or PDF pages look wrong | Identify the actual page, reviewed version and visible problem. Preserve supplied PDFs; ask for the relevant rendering review. |

If you can safely repeat the read-only check, use [status](status.md#i-do-not-have-an-agent-and-want-to-do-this-manually). If it cannot start, report that instead of guessing a version or report path. Do not rerun a write blindly.

### Check the result

You should receive a specific next action and a person responsible for help. A failed or unavailable check stays failed or unknown until it is actually rerun and verified. Return to the task only when that prerequisite is resolved.

### Words the software may print

| Word | Plain meaning |
|---|---|
| Prepare / discovery / inventory | Assess the actual site files / inspect them / the resulting work list. |
| Wrapper / catalogue | Website pages around the guide / the list of interface messages. |
| Scaffold / fallback | Empty guide starting page / deliberate use of another language. |
| Candidate / hash | Proposed file / exact-file fingerprint used internally to detect changes. |
| Artifact / canary | Built website or PDF result / temporary website for technical review of a pull request. |
| Baseline / provenance | Earlier version chosen for comparison / evidence of what source was used. |
| Coordinated update | The maintainer's procedure for updating the site's selected OGP package together. |
| Receipt | A record connecting a draft or generated PDF to the inputs checked. |
