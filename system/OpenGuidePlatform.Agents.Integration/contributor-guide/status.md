# Check translation status

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

With an assistant: “Use guide.transstatus for LANGUAGE. Report the installed version, Prepare evidence, site-language work and guide-body work separately. Do not edit. Explain the next action and blockers.”

**Success:** you can identify each finding's owner and the next supported action. It does not prove language quality or complete rendering. **Next:** [add a language](add-language.md), [translate a guide](translate-guide.md) or [troubleshoot](troubleshooting.md). **Reference:** [Core site-first procedure](../../OpenGuidePlatform.PowerShell.Core/TranslationReadiness/README.md).
