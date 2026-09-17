#Requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Release','Validate')][string]$Stage,
    [Parameter(Mandatory)][string]$AssetsPath,
    [Parameter(Mandatory)][ValidatePattern('^[a-f0-9]{40}$')][string]$SourceCommit,
    [string]$ReleaseTag,
    [string]$Repository='nkdAgility/OpenGuidePlatform'
)
$ErrorActionPreference='Stop'
$assets=[IO.Path]::GetFullPath($AssetsPath)
$manifest=Get-Content (Join-Path $assets 'release-manifest.json') -Raw|ConvertFrom-Json
if($manifest.sourceCommit -cne $SourceCommit){throw 'Release source commit does not match the package.'}
$tag="v$($manifest.version)"
if($ReleaseTag -and $ReleaseTag -cne $tag){throw 'Requested release tag does not match the package.'}
if($Stage -eq 'Release'){
    & "$PSScriptRoot/system/OpenGuidePlatform.PowerShell.PlatformBuild/Release/Publish-PlatformRelease.ps1" -WorkspaceRoot $assets -OutputPath $assets -SourceCommit $SourceCommit -Repository $Repository
    return
}
$published=& gh release view $tag --repo $Repository --json targetCommitish,isDraft,isPrerelease | ConvertFrom-Json
if($LASTEXITCODE -ne 0 -or $published.targetCommitish -cne $SourceCommit -or $published.isDraft -or [bool]$published.isPrerelease -ne $manifest.version.Contains('-')){throw 'Published release identity differs from the package.'}
$verify=Join-Path $assets ('published-'+[guid]::NewGuid().ToString('N'))
& gh release download $tag --repo $Repository --pattern OpenGuidePlatform-GuideSite.zip --pattern OpenGuidePlatform-PlatformBuild.zip --pattern release-manifest.json --dir $verify
if($LASTEXITCODE -ne 0){throw 'Cannot download published release assets.'}
foreach($name in @('release-manifest.json','OpenGuidePlatform-GuideSite.zip','OpenGuidePlatform-PlatformBuild.zip')){
    if((Get-FileHash (Join-Path $verify $name)).Hash -cne (Get-FileHash (Join-Path $assets $name)).Hash){throw "Published $name differs from the tested package."}
}
Write-Host "Verified published release $tag from $SourceCommit."
