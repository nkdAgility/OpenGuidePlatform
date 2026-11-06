BeforeAll {
    Set-StrictMode -Version Latest
    $root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $publisher="$root/system/OpenGuidePlatform.PowerShell.PlatformBuild/Release/Publish-ContributorModule.ps1"
    # No repository registration, downloads or publication in these unit checks.
    function Register-PSRepository { [CmdletBinding()]param([switch]$Default) throw 'Must be mocked' }
    function Install-Module { [CmdletBinding()]param($Name,$MinimumVersion,$Repository,$Scope,[switch]$Force) throw 'Must be mocked' }
    function Publish-Module { [CmdletBinding()]param($Path,$Repository,$NuGetApiKey) throw 'Must be mocked' }
}
Describe 'Contributor publication prerequisites' {
    BeforeEach {
        $module="$TestDrive/$([guid]::NewGuid().ToString('N'))/OpenGuidePlatform"
        [IO.Directory]::CreateDirectory((Split-Path $module))|Out-Null
        Copy-Item "$root/system/OpenGuidePlatform.PowerShell.Contributor" $module -Recurse
        @{schemaVersion=1;version='1.2.3';galleryVersion='1.2.3';sourceCommit=('a'*40)}|ConvertTo-Json|Set-Content "$module/ogp-module.json"
        Mock Get-Module { $null } -ParameterFilter {$ListAvailable -and $Name -contains 'powershell-yaml'}
        Mock Get-PSRepository { [pscustomobject]@{Name='PSGallery'} }
        Mock Register-PSRepository {}
        Mock Install-Module {}
        Mock Test-ModuleManifest { [pscustomobject]@{Version=[version]'1.2.3';PrivateData=@{PSData=@{}}} }
        Mock Publish-Module {}
        $argsForPublish=@{ModulePath=$module;ExpectedVersion='1.2.3';ExpectedCommit=('a'*40);Repository='Fixture';NuGetApiKey='fixture-key'}
    }
    It 'installs missing manifest prerequisites in AllUsers scope before local publication' {
        Mock Test-ModuleManifest {
            Should -Invoke Install-Module -Times 1 -Exactly -ParameterFilter {$Name -eq 'powershell-yaml' -and $MinimumVersion -eq '0.4.12' -and $Scope -eq 'AllUsers'}
            [pscustomobject]@{Version=[version]'1.2.3';PrivateData=@{PSData=@{}}}
        }
        & $publisher @argsForPublish
        Should -Invoke Publish-Module -Times 1 -Exactly
    }
    It 'honours the hosted adapter scope on a fresh release runner' {
        & $publisher @argsForPublish -DependencyScope CurrentUser
        Should -Invoke Install-Module -Times 1 -Exactly -ParameterFilter {$Scope -eq 'CurrentUser'}
    }
    It 'does not reinstall an available compatible dependency' {
        Mock Get-Module { [pscustomobject]@{Version=[version]'0.4.12'} } -ParameterFilter {$ListAvailable -and $Name -contains 'powershell-yaml'}
        & $publisher @argsForPublish
        Should -Invoke Install-Module -Times 0 -Exactly
    }
    It 'never publishes after dependency installation fails' {
        Mock Install-Module { throw 'Dependencies unavailable' }
        { & $publisher @argsForPublish } | Should -Throw '*Dependencies unavailable*'
        Should -Invoke Test-ModuleManifest -Times 0 -Exactly
        Should -Invoke Publish-Module -Times 0 -Exactly
    }
}
