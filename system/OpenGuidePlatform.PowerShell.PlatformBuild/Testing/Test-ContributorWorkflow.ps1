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
foreach($target in @('preview','production')){Invoke-CandidateBuild All $target "$scratch/$target"}
[ordered]@{
    schemaVersion=1;outcome='pass';packageRoot=$CandidateRoot
    guide=$document.GuideId;edition=$document.EditionId;language=$document.Language
    path=$document.Path;previousSha256=$document.Sha256;candidateSha256=$result.CandidateSha256
    verification=@('discovered inventory','WhatIf preserves bytes','body applied','other content preserved','preview build','production build')
}|ConvertTo-Json -Depth 5|Set-Content "$WorkspaceRoot/$scratch/result.json"
Write-Host "PASS packaged contributor workflow. Evidence: $scratch/result.json"
