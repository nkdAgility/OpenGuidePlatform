#Requires -Version 7.4
[CmdletBinding()]
param([Parameter(Mandatory)][string]$WorkspaceRoot,[Parameter(Mandatory)][string]$CandidateRoot,[Parameter(Mandatory)][string]$OutputPath)
$ErrorActionPreference='Stop'
Import-Module "$CandidateRoot/system/OpenGuidePlatform.PowerShell.Core/OpenGuidePlatform.PowerShell.Core.psd1" -Force
Import-Module powershell-yaml -MinimumVersion 0.4.12
$instructions=Get-Content "$CandidateRoot/system/OpenGuidePlatform.Agents.Integration/instructions/guide-site.md" -Raw
foreach($required in @('guide.transcreate','guide.transstatus','guide.transreconcile','Get-GuideSiteTranslationWork','separately selected stage','do not enforce permissions')){
    if(-not $instructions.Contains($required)){throw "Packaged contributor instructions omit site translation contract: $required"}
}
$skill=Get-Content "$CandidateRoot/system/OpenGuidePlatform.Agents.Integration/skills/guide.transcreate/SKILL.md" -Raw
if($skill -notmatch 'Get-GuideSiteTranslationWork'){throw 'Packaged translation creation skill does not route through the site work inventory.'}
# The installation adapter distributes these exact bytes to the canonical agent
# file. This checks the package contract, not whether an AI obeys instructions.
$adapter=Get-Content "$CandidateRoot/system/OpenGuidePlatform.PowerShell.GuideSiteAdoption/OpenGuidePlatform.PowerShell.GuideSiteAdoption.psm1" -Raw
if(-not $adapter.Contains("`$files['.agents/agents.md']=`$instructions")){throw 'Installation no longer distributes the reviewed canonical instructions.'}
$scratch="$OutputPath/site-translation-"+[guid]::NewGuid().ToString('N')
$source="$scratch/source"
$destination=Resolve-GuideWorkspacePath $WorkspaceRoot $source
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination))|Out-Null
Copy-Item -LiteralPath "$WorkspaceRoot/examples/reference-guide-site" -Destination $destination -Recurse
$shell=Join-Path $PSHOME $(if($IsWindows){'pwsh.exe'}else{'pwsh'})
function Invoke-CandidateBuild([string]$Stage,[string]$Target,[string]$Output) {
    & $shell -NoProfile -File "$CandidateRoot/build.ps1" -Product GuideSite -WorkspaceRoot $WorkspaceRoot -SourcePath $source -Stage $Stage -Target $Target -OutputPath $Output
    if($LASTEXITCODE -ne 0){throw "Site translation workflow $Stage/$Target failed. See $Output."}
}
function Assert-Refused([scriptblock]$Action,[string]$Message) {
    $refused=$false
    try{& $Action|Out-Null}catch{$refused=$true}
    if(-not $refused){throw $Message}
}
function Read-Relative([string]$Path){[IO.File]::ReadAllText((Resolve-GuideWorkspacePath $WorkspaceRoot $Path))}

# Synthetic data exists only in this disposable fixture. Explicitly selected prose
# exercises JSON safety without claiming a semantic translation of real content.
$main=Get-Content "$destination/hugo.yaml" -Raw|ConvertFrom-Yaml
$sourceLanguage=[string]$main.defaultContentLanguage
$language=@('de','kn','fr')|Where-Object {-not $main.languages.Contains($_)}|Select-Object -First 1
if(-not $language){throw 'Site translation acceptance needs a language absent from sample configuration.'}
$jsonDirectory="$destination/data/site-translation-fixture"
[IO.Directory]::CreateDirectory($jsonDirectory)|Out-Null
[IO.File]::WriteAllText("$jsonDirectory/$sourceLanguage.json",'{"title":"Synthetic source title","url":"/preserve-me/","enabled":true,"count":3}')
$before=@{}
foreach($file in Get-ChildItem $destination -File -Recurse){$before[$file.FullName]=(Get-FileHash -LiteralPath $file.FullName).Hash}
Invoke-CandidateBuild Prepare preview "$scratch/initial"
$policy=Import-GuidePolicy "$WorkspaceRoot/$scratch/initial/discovered-site.json"
$siteSelection=@{WorkspaceRoot=$WorkspaceRoot;Policy=$policy;Language=$language}
$initial=Get-GuideSiteTranslationWork @siteSelection
if($initial.Configuration.LanguageDeclared -or $initial.Configuration.ProductionExplicitlyDisabled -or @($initial.Wrappers|Where-Object State -ne 'missing').Count){throw 'Fixture language is not wholly absent.'}
if(@($initial.Guides|Where-Object State -ne 'missing').Count){throw 'Fixture already has a selected-language guide body.'}

$production=Read-Relative $initial.Configuration.ProductionPath|ConvertFrom-Yaml
$production.languages[$language]=@{disabled=$true}
$productionCandidate=ConvertTo-Yaml $production
$main.languages[$language]=@{label='Synthetic acceptance language';weight=999;title='Synthetic acceptance title'}
$mainCandidate=ConvertTo-Yaml $main
Assert-Refused {Set-GuideWrapperTranslation @siteSelection -RelativePath $initial.Configuration.MainPath -CandidateContent $mainCandidate -ExpectedSha256 $initial.Configuration.MainSha256} 'Main language creation must require production exclusion first.'
Set-GuideWrapperTranslation @siteSelection -RelativePath $initial.Configuration.ProductionPath -CandidateContent $productionCandidate -ExpectedSha256 $initial.Configuration.ProductionSha256|Out-Null
Set-GuideWrapperTranslation @siteSelection -RelativePath $initial.Configuration.MainPath -CandidateContent $mainCandidate -ExpectedSha256 $initial.Configuration.MainSha256|Out-Null
Invoke-CandidateBuild Prepare preview "$scratch/configured"
$siteSelection.Policy=Import-GuidePolicy "$WorkspaceRoot/$scratch/configured/discovered-site.json"

# Site-first discovery must include guide landing/history/translations wrappers,
# but never classify edition body files as wrapper work.
$configured=Get-GuideSiteTranslationWork @siteSelection
foreach($guide in $policy.guides){
    foreach($suffix in @('/_index.md','/history/index.md','/translations/index.md')){
        $expected=$guide.contentRoot+$suffix
        if(Test-Path -LiteralPath (Resolve-GuideWorkspacePath $WorkspaceRoot $expected)){
            if(@($configured.Wrappers|Where-Object SourcePath -CEQ $expected).Count -ne 1){throw "Site work omitted wrapper $expected"}
        }
    }
}
foreach($wrapper in $configured.Wrappers){
    if($wrapper.SourcePath -cin @($configured.Guides.SourcePath)){throw 'Edition bodies were classified as wrappers.'}
    $candidate=Read-Relative $wrapper.SourcePath
    $arguments=@{RelativePath=$wrapper.TargetPath;CandidateContent=$candidate}
    if($wrapper.Kind -eq 'markdown'){
        # Remove forbidden shared aliases from the new-language candidate only.
        $match=[regex]::Match($candidate,'\A---\r?\n(?<yaml>.*?)\r?\n---(?:\r?\n|\z)(?<body>.*)\z',[Text.RegularExpressions.RegexOptions]::Singleline)
        $metadata=ConvertFrom-Yaml $match.Groups['yaml'].Value
        if($metadata.Contains('aliases')){
            $aliases=@($metadata.aliases|Where-Object {$_ -notmatch '^/(?:[A-Za-z0-9-]+/)?(?:download|downloads|translationsdirectory)/?$'})
            if($aliases.Count){$metadata.aliases=$aliases}else{$metadata.Remove('aliases')|Out-Null}
        }
        $arguments.CandidateContent="---`n$((ConvertTo-Yaml $metadata).TrimEnd())`n---`n$($match.Groups['body'].Value)"
    }elseif($wrapper.Kind -eq 'json-text-selection-required'){
        $json=$candidate|ConvertFrom-Json -AsHashtable
        $json.title='Synthetic target title'
        $arguments.CandidateContent=$json|ConvertTo-Json -Depth 20
        $arguments.JsonTextPaths=@('/title')
        $arguments.ExpectedSourceSha256=$wrapper.SourceSha256
    }
    Set-GuideWrapperTranslation @siteSelection @arguments|Out-Null
}
Invoke-CandidateBuild Prepare preview "$scratch/wrappers"
$siteSelection.Policy=Import-GuidePolicy "$WorkspaceRoot/$scratch/wrappers/discovered-site.json"
$wrapperWork=Get-GuideSiteTranslationWork @siteSelection
$eligible=@($wrapperWork.Guides|Where-Object CanCreateScaffold)
foreach($guide in $eligible){
    New-GuideTranslation @siteSelection -GuideId $guide.GuideId -EditionId $guide.EditionId|Out-Null
}
Invoke-CandidateBuild Prepare preview "$scratch/scaffold"
$siteSelection.Policy=Import-GuidePolicy "$WorkspaceRoot/$scratch/scaffold/discovered-site.json"
$scaffold=Get-GuideSiteTranslationWork @siteSelection
if(@($scaffold.Wrappers|Where-Object State -eq 'missing').Count -or @($scaffold.Guides|Where-Object State -eq 'populated').Count){throw 'Site scaffolding omitted wrappers or populated guide bodies.'}
if(-not @($scaffold.Guides|Where-Object State -eq 'empty-stub').Count){throw 'Site scaffolding did not create any empty edition stub.'}
foreach($expected in $eligible){
    $actual=@($scaffold.Guides|Where-Object TargetPath -CEQ $expected.TargetPath)
    if($actual.Count -ne 1 -or $actual[0].State -ne 'empty-stub' -or -not [IO.File]::Exists((Resolve-GuideWorkspacePath $WorkspaceRoot $expected.TargetPath))){throw "Site scaffolding omitted an eligible edition: $($expected.TargetPath)"}
}
foreach($path in $before.Keys){
    if($path -notin @((Resolve-GuideWorkspacePath $WorkspaceRoot $initial.Configuration.MainPath),(Resolve-GuideWorkspacePath $WorkspaceRoot $initial.Configuration.ProductionPath)) -and (Get-FileHash -LiteralPath $path).Hash -cne $before[$path]){throw "Site scaffolding changed original content: $path"}
}
$scaffold|ConvertTo-Json -Depth 30|Set-Content "$WorkspaceRoot/$scratch/site-scaffold-report.json"

# A separate, explicit edition selection is necessary before any guide body edit.
$selected=$scaffold.Guides|Where-Object State -eq 'empty-stub'|Select-Object -First 1
$editionSelection=@{WorkspaceRoot=$WorkspaceRoot;Policy=$siteSelection.Policy;Language=$language;GuideId=$selected.GuideId;EditionId=$selected.EditionId}
$work=Get-GuideTranslationWork @editionSelection
$candidate=$work.Target.Content+$work.Source.Body+"`n`nSynthetic translation acceptance fixture; no language-quality claim.`n"
Set-GuideTranslation @editionSelection -CandidateContent $candidate -ExpectedSha256 $work.Target.Sha256 -ExpectedSourceSha256 $work.Source.Sha256|Out-Null
$populatedHash=(Get-FileHash (Resolve-GuideWorkspacePath $WorkspaceRoot $selected.TargetPath)).Hash
if((New-GuideTranslation @editionSelection).Status -ne 'preserved' -or (Get-FileHash (Resolve-GuideWorkspacePath $WorkspaceRoot $selected.TargetPath)).Hash -cne $populatedHash){throw 'Scaffold rerun did not preserve the populated target.'}
Assert-Refused {Set-GuideWrapperTranslation @siteSelection -RelativePath $selected.TargetPath -CandidateContent $candidate -ExpectedSha256 $populatedHash} 'Wrapper operation accepted an edition body.'
$wrapper=$scaffold.Wrappers|Where-Object Kind -eq 'markdown'|Select-Object -First 1
$wrapperCandidate=(Read-Relative $wrapper.TargetPath)+"`nSynthetic wrapper acceptance update.`n"
Set-GuideWrapperTranslation @siteSelection -RelativePath $wrapper.TargetPath -CandidateContent $wrapperCandidate -ExpectedSha256 $wrapper.TargetSha256|Out-Null
Assert-Refused {Set-GuideWrapperTranslation @siteSelection -RelativePath $wrapper.TargetPath -CandidateContent $wrapperCandidate -ExpectedSha256 $wrapper.TargetSha256} 'Wrapper update accepted a stale hash.'
$final=Get-GuideSiteTranslationWork @siteSelection
if(@($final.Guides|Where-Object State -eq 'populated').Count -ne 1){throw 'Selected edition translation changed unrelated edition bodies.'}
foreach($other in $scaffold.Guides|Where-Object {$_.TargetPath -cne $selected.TargetPath -and $_.TargetSha256}){
    if((Get-FileHash (Resolve-GuideWorkspacePath $WorkspaceRoot $other.TargetPath)).Hash -ine $other.TargetSha256){throw "Selected translation changed another edition stub: $($other.TargetPath)"}
}
foreach($target in @('preview','production')){Invoke-CandidateBuild All $target "$scratch/$target"}
$configurationPaths=@((Resolve-GuideWorkspacePath $WorkspaceRoot $initial.Configuration.MainPath),(Resolve-GuideWorkspacePath $WorkspaceRoot $initial.Configuration.ProductionPath))
foreach($path in $before.Keys){
    if($path -notin $configurationPaths -and (Get-FileHash -LiteralPath $path).Hash -cne $before[$path]){throw "Site translation changed existing content or supplied PDF: $path"}
}
if(-not (Test-Path "$WorkspaceRoot/$scratch/preview/site/$language/index.html")){throw 'Preview omitted the new site language route.'}
if(Test-Path "$WorkspaceRoot/$scratch/production/site/$language"){throw 'Production published the excluded site language.'}
[ordered]@{
    schemaVersion=1;outcome='pass';packageRoot=$CandidateRoot;language=$language
    selectedGuide=$selected.GuideId;selectedEdition=$selected.EditionId;translationQualityAssessed=$false
    wrapperCount=@($final.Wrappers).Count;editionCount=@($final.Guides).Count
    verification=@('absent site language','production exclusion before main configuration','guide subpath wrappers discovered','explicit JSON text selection','site scaffold report before body translation','empty edition stubs','one selected body','rerun preservation','stale wrapper hash refused','edition body refused by wrapper writer','existing content and PDFs preserved','preview route present','production route absent')
}|ConvertTo-Json -Depth 5|Set-Content "$WorkspaceRoot/$scratch/result.json"
Write-Host "PASS packaged site translation workflow. Evidence: $scratch/result.json"
