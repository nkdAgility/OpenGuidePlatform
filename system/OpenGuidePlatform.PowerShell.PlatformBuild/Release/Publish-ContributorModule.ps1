#Requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ModulePath,
    [Parameter(Mandatory)][string]$ExpectedVersion,
    [Parameter(Mandatory)][string]$ExpectedCommit,
    [string]$Repository='PSGallery',
    [ValidateSet('AllUsers','CurrentUser')][string]$DependencyScope='AllUsers',
    [Parameter(Mandatory)][string]$NuGetApiKey
)
$ErrorActionPreference='Stop'
$identity=Get-Content -LiteralPath "$ModulePath/ogp-module.json" -Raw|ConvertFrom-Json
if($identity.version -cne $ExpectedVersion -or $identity.sourceCommit -cne $ExpectedCommit){throw 'Contributor module identity differs from the validated coordinated release.'}
$data=Import-PowerShellDataFile "$ModulePath/OpenGuidePlatform.psd1"
foreach($required in $data.RequiredModules){
    if(-not (Get-Module -ListAvailable -Name $required.ModuleName|Where-Object { $null -ne $_ -and $_.Version -ge ([version]$required.ModuleVersion) })){
        if(-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)){Register-PSRepository -Default -ErrorAction Stop}
        Install-Module -Name $required.ModuleName -MinimumVersion $required.ModuleVersion -Repository PSGallery -Scope $DependencyScope -Force -ErrorAction Stop
    }
}
$module=Test-ModuleManifest -Path "$ModulePath/OpenGuidePlatform.psd1" -ErrorAction Stop
$prerelease=$module.PrivateData.PSData['Prerelease']
$version=$module.Version.ToString()+$(if($prerelease){'-'+$prerelease})
if($version -cne $identity.galleryVersion){throw 'Contributor manifest version differs from its package identity.'}
# Publication is explicit. The caller supplies credentials; never read or log keys.
Publish-Module -Path $ModulePath -Repository $Repository -NuGetApiKey $NuGetApiKey -ErrorAction Stop
