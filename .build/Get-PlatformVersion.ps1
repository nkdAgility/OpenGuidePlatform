#Requires -Version 7.4
[CmdletBinding()]
param([string]$WorkspaceRoot=(Split-Path $PSScriptRoot -Parent))
Import-Module "$PSScriptRoot/../system/OpenGuidePlatform.PowerShell.PlatformBuild/OpenGuidePlatform.PowerShell.PlatformBuild.psm1"
if($env:GITHUB_ACTIONS -eq 'true' -and $env:GITHUB_REF -like 'refs/tags/*'){
    if($env:GITHUB_REF -cnotmatch '^refs/tags/v([0-9]+\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.-]+)?)$'){
        throw "Unsupported platform release tag: $env:GITHUB_REF"
    }
    $releaseVersion=$Matches[1]
    $parsedVersion=$null
    if(-not [System.Management.Automation.SemanticVersion]::TryParse($releaseVersion,[ref]$parsedVersion) -or $parsedVersion.ToString() -cne $releaseVersion){
        throw "Unsupported platform release tag: $env:GITHUB_REF"
    }
    $tagCommit=(& git -C $WorkspaceRoot rev-parse "$($env:GITHUB_REF)^{commit}" 2>$null)
    if($LASTEXITCODE -ne 0){throw "Cannot resolve platform release tag: $env:GITHUB_REF"}
    $version=Get-PlatformBuildVersion -WorkspaceRoot $WorkspaceRoot -Version $releaseVersion
    if($tagCommit.Trim() -cne $version.Sha){throw "Platform release tag $env:GITHUB_REF does not identify the checked-out commit."}
}else{
    $version=Get-PlatformBuildVersion -WorkspaceRoot $WorkspaceRoot
}
if($env:GITHUB_OUTPUT){[IO.File]::AppendAllText($env:GITHUB_OUTPUT,"semVer=$($version.SemVer)`nsha=$($version.Sha)`n")}
$version
