#Requires -Version 7.4
[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
. "$PSScriptRoot/../system/OpenGuidePlatform.PowerShell.GuideSiteBuild/GitHubActions/GuidePreviewCleanup.ps1"
$number=Resolve-GuidePreviewCleanup -Repository $env:GITHUB_REPOSITORY -PullRequest $env:CLEANUP_PULL_REQUEST
if(-not $env:GITHUB_OUTPUT){throw 'Preview cleanup requires a GitHub Actions output file.'}
[IO.File]::AppendAllText($env:GITHUB_OUTPUT,"pull-request=$number`n")
Write-Host "Validated closed PR $number in $env:GITHUB_REPOSITORY for automated preview cleanup."
