# Find out what needs translating

Before changing anything, find out what already exists for your language. Website text and guide translations are different parts of the work.

## Work with an agent

Use [guide.transstatus](../skills/guide.transstatus/SKILL.md). It inspects the site without changing its files. If your agent cannot access the site or this installed skill, follow [setup](setup.md) with the maintainer.

Replace Kannada with the language and regional variant you agreed with the team, then paste:

> Use this site's installed **guide.transstatus** skill to check Kannada. Do not change files. Confirm the language and code with me. Explain what exists and what remains, separating website wording, guide translations and PDFs. Identify the installed version and report used. Explain failed or unavailable checks and the next supported step. If the skill is missing, ask for maintainer help; do not guess a status or use another workflow.

**You should receive:** a plain-English work list. It should distinguish translated text, empty starting pages, missing work, and guides that deliberately use another language or only a PDF. Text being present does not mean it has been reviewed.

**You decide:** which work the team will take on, with the site's language reviewer. The agent must not turn a request for status into permission to repair files.

**Next:** [add a language](add-language.md), [translate a selected guide](translate-guide.md), or [update a translation](update-translation.md). If the report says it cannot establish a result, use [troubleshooting](troubleshooting.md).

## I do not have an agent and want to do this manually

The commands below create a report and then list work for your selected language. They do not translate or repair files. Start with the manual [setup instructions](setup.md#i-do-not-have-an-agent-and-want-to-do-this-manually) if PowerShell or the site folder is unfamiliar. Prepare is the name of OGP's assessment step; its report may identify problems rather than pass.

This assessment answers “what work remains?” without editing site content. First complete [setup](setup.md). Run from the guide-site root in PowerShell:

```powershell
$workspace = $PWD.Path
$platform = ./.OpenGuidePlatform/Resolve-OpenGuidePlatform.ps1 -WorkspaceRoot $workspace -UseInstalled
Import-Module "$platform/system/OpenGuidePlatform.PowerShell.Core/OpenGuidePlatform.PowerShell.Core.psd1" -Force
Get-Content "$platform/platform.json"
$output = '.processing/translation-status/' + [guid]::NewGuid().ToString('N')
./build.ps1 -Stage Prepare -Target preview -OutputPath $output -PlatformSource Path -PlatformPath $platform
```

The unique output name prevents overwriting earlier evidence. Open `$output/prepare/assessment.md` in your editor. Record the installed version and report path. Inspect reports even when Prepare fails, if they exist. A missing report is unknown evidence; a failed assessment is not a pass.

When discovery produced a valid `discovered-site.json`, inspect the requested language:

```powershell
$policy = Import-GuidePolicy -Path "$output/discovered-site.json"
$language = Read-Host 'Enter the agreed language code'
$siteWork = Get-GuideSiteTranslationWork -WorkspaceRoot $workspace -Policy $policy -Language $language
$siteWork.Configuration | Format-List
$siteWork.Wrappers | Format-Table Kind, SourcePath, TargetPath, State, SupportedOperation -Wrap
$siteWork.Guides | Format-Table GuideId, EditionId, State, Intent, CanCreateScaffold -Wrap
$siteWork.Findings | Format-List
```

Read configuration and website work separately from guide bodies. A proposed target path is not a created file. An empty scaffold is not a translation. Fallback means readers use another declared language; PDF-only means a download exists without equivalent web text. Preserve those deliberate states. “Unsupported” requires a maintainer/platform decision, not an improvised write.


**Success:** you can identify each finding's owner and the next supported action. It does not prove language quality or complete rendering. **Next:** [add a language](add-language.md), [translate a guide](translate-guide.md) or [troubleshoot](troubleshooting.md). **Reference:** [Core site-first procedure](../../OpenGuidePlatform.PowerShell.Core/TranslationReadiness/README.md).
