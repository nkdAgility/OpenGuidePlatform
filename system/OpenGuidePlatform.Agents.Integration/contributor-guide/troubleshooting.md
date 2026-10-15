# Troubleshooting and glossary

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
