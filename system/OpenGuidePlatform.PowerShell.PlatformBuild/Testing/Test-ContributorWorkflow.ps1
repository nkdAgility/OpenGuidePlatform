#Requires -Version 7.4
[CmdletBinding()]
param([Parameter(Mandatory)][string]$WorkspaceRoot,[Parameter(Mandatory)][string]$CandidateRoot,[Parameter(Mandatory)][string]$OutputPath)
$ErrorActionPreference='Stop'
Import-Module "$CandidateRoot/system/OpenGuidePlatform.PowerShell.Core/OpenGuidePlatform.PowerShell.Core.psd1" -Force
$scratch="$OutputPath/contributor-"+[guid]::NewGuid().ToString('N')
$source="$scratch/site"
$destination=Resolve-GuideWorkspacePath $WorkspaceRoot $source
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination))|Out-Null
Copy-Item -LiteralPath "$WorkspaceRoot/examples/reference-guide-site" -Destination $destination -Recurse
$shell=Join-Path $PSHOME $(if($IsWindows){'pwsh.exe'}else{'pwsh'})
function Invoke-CandidateBuild([string]$Stage,[string]$Target,[string]$Output) {
    & $shell -NoProfile -File "$CandidateRoot/build.ps1" -Product GuideSite -WorkspaceRoot $WorkspaceRoot -SourcePath $source -Stage $Stage -Target $Target -OutputPath $Output
    if($LASTEXITCODE -ne 0){throw "Contributor workflow $Stage/$Target failed. See $Output."}
}
Invoke-CandidateBuild Prepare preview "$scratch/discovery"
$policy=Import-GuidePolicy -Path "$WorkspaceRoot/$scratch/discovery/discovered-site.json"
$available=@(Get-GuideContent -WorkspaceRoot $WorkspaceRoot -Policy $policy)
$document=$available|Where-Object { $_.Exists -and $_.WriteAllowed -and $_.Language -eq $_.SourceLanguage -and $_.Intent -eq 'web' }|Select-Object -First 1
if(-not $document){throw 'Contributor acceptance needs a discovered writable source document in the sample.'}
$before=@{}
foreach($file in Get-ChildItem "$destination/content" -Recurse -File){$before[$file.FullName]=(Get-FileHash -LiteralPath $file.FullName).Hash}
$selected=@{WorkspaceRoot=$WorkspaceRoot;Policy=$policy;GuideId=$document.GuideId;EditionId=$document.EditionId;Language=$document.Language}
$marker='Contributor workflow acceptance correction.'
$body=$document.Body+"`n`n$marker`n"
$preview=Set-GuideContent @selected -CandidateBody $body -ExpectedSha256 $document.Sha256 -WhatIf
if($preview.Status -ne 'planned' -or (Get-GuideContent @selected).Sha256 -cne $document.Sha256){throw 'Contributor WhatIf changed content or did not report the plan.'}
$result=Set-GuideContent @selected -CandidateBody $body -ExpectedSha256 $document.Sha256
if($result.Status -ne 'updated' -or (Get-GuideContent @selected).Body -cne $body){throw 'Contributor correction was not applied to the selected document.'}
$selectedPath=Resolve-GuideWorkspacePath $WorkspaceRoot $document.Path
foreach($path in $before.Keys){
    if($path -ne $selectedPath -and (Get-FileHash -LiteralPath $path).Hash -cne $before[$path]){throw "Contributor workflow changed an unrelated file: $path"}
}
# Simulate a missing translation only in the disposable copy. Choose a language
# already configured as disabled in production; no fixed guide/language inventory.
$productionFile="$destination/hugo.production.yaml"
$productionHash=(Get-FileHash $productionFile).Hash
$production=Get-Content $productionFile -Raw|ConvertFrom-Yaml
$language=@($production.languages.Keys|Where-Object {$production.languages[$_].disabled -eq $true}|Sort-Object)|Select-Object -First 1
if(-not $language){throw 'Translation acceptance needs a production-disabled sample language.'}
$translationSelection=@{WorkspaceRoot=$WorkspaceRoot;Policy=$policy;GuideId=$document.GuideId;EditionId=$document.EditionId;Language=$language}
$initial=Get-GuideTranslationWork @translationSelection
if(-not $initial.Target -or [string]::IsNullOrWhiteSpace($initial.Target.Body)){throw 'Translation acceptance needs existing sample text to use as its fixture candidate.'}
$fixtureBody=$initial.Target.Body
$translationPath=Resolve-GuideWorkspacePath $WorkspaceRoot $initial.TargetPath
[IO.File]::Delete($translationPath)
Invoke-CandidateBuild Prepare preview "$scratch/translation-missing"
$translationSelection.Policy=Import-GuidePolicy "$WorkspaceRoot/$scratch/translation-missing/discovered-site.json"
if((New-GuideTranslation @translationSelection -WhatIf).Status -ne 'planned' -or [IO.File]::Exists($translationPath)){throw 'Translation creation WhatIf did not preserve the missing target.'}
if((New-GuideTranslation @translationSelection).Status -ne 'created'){throw 'Translation scaffold was not created.'}
Invoke-CandidateBuild Prepare preview "$scratch/translation-scaffold"
$translationSelection.Policy=Import-GuidePolicy "$WorkspaceRoot/$scratch/translation-scaffold/discovered-site.json"
$translationWork=Get-GuideTranslationWork @translationSelection
$translationCandidate=$translationWork.Target.Content+$fixtureBody
if((Test-GuideTranslation @translationSelection -CandidateContent $translationCandidate).Outcome -eq 'blocked'){throw 'Discovered translation candidate was blocked.'}
$translationChange=@{CandidateContent=$translationCandidate;ExpectedSha256=$translationWork.Target.Sha256;ExpectedSourceSha256=$translationWork.Source.Sha256}
if((Set-GuideTranslation @translationSelection @translationChange -WhatIf).Status -ne 'planned'){throw 'Translation application preview failed.'}
$createdTranslation=Set-GuideTranslation @translationSelection @translationChange
if($createdTranslation.Status -ne 'updated'){throw 'Translation content was not applied.'}
$sourceCommit=(& git -C $WorkspaceRoot rev-parse HEAD).Trim()
if($LASTEXITCODE -ne 0){throw 'Cannot resolve sample source comparison commit.'}
$historicalPath='examples/reference-guide-site'+$document.Path.Substring($source.Length)
$reconciliation=Get-GuideTranslationWork @translationSelection -SourceRevision $sourceCommit -SourcePathAtRevision $historicalPath
if(-not $reconciliation.Comparison.Changed -or $reconciliation.Comparison.Diff -notmatch [regex]::Escape($marker)){throw 'Source comparison did not report the sample correction.'}
$revised=$reconciliation.Target.Content+"`nTranslation reconciliation acceptance note.`n"
$reconciled=Set-GuideTranslation @translationSelection -CandidateContent $revised -ExpectedSha256 $reconciliation.Target.Sha256 -ExpectedSourceSha256 $reconciliation.Source.Sha256 -SourceRevision $sourceCommit -SourcePathAtRevision $historicalPath
if($reconciled.Status -ne 'updated' -or -not [IO.File]::ReadAllText($translationPath).StartsWith($translationCandidate,[StringComparison]::Ordinal)){throw 'Reconciliation did not preserve existing translated content.'}
if((Get-FileHash $productionFile).Hash -cne $productionHash){throw 'Translation workflow changed production configuration.'}
if((Get-FileHash $selectedPath).Hash -ine $result.CandidateSha256){throw 'Translation workflow changed source content.'}
foreach($path in $before.Keys){
    if($path -notin @($selectedPath,$translationPath) -and (Get-FileHash -LiteralPath $path).Hash -cne $before[$path]){throw "Translation workflow changed an unrelated file: $path"}
}
foreach($target in @('preview','production')){Invoke-CandidateBuild All $target "$scratch/$target"}
[ordered]@{
    schemaVersion=1;outcome='pass';packageRoot=$CandidateRoot
    guide=$document.GuideId;edition=$document.EditionId;language=$document.Language
    path=$document.Path;previousSha256=$document.Sha256;candidateSha256=$result.CandidateSha256
    translation=@{language=$language;path=$initial.TargetPath;sourceComparisonCommit=$sourceCommit;sourceComparisonPath=$historicalPath;sha256=$reconciled.CandidateSha256;qualityAssessed=$false}
    verification=@('discovered inventory','WhatIf preserves bytes','body applied','other content preserved','translation scaffold and rediscovery','translation application','explicit source comparison and reconciliation','production configuration preserved','preview build','production build')
}|ConvertTo-Json -Depth 5|Set-Content "$WorkspaceRoot/$scratch/result.json"
Write-Host "PASS packaged contributor workflow. Evidence: $scratch/result.json"
