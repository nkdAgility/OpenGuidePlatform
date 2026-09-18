BeforeAll {
    $root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    . "$root/system/OpenGuidePlatform.PowerShell.GuideSiteBuild/Toolchain/Install-GuideBuildDependencies.ps1"
    # Avoid PowerShellGet's dynamic parameter discovery (and real user-profile
    # changes) while testing the installer's repository orchestration.
    function Register-PSRepository {
        [CmdletBinding()]
        param([switch]$Default)
        throw 'Repository registration must be mocked in this test'
    }
}
Describe 'Guide build dependency repository setup' {
    BeforeEach {
        Mock Get-PSRepository { [pscustomobject]@{Name='PSGallery'} }
        Mock Register-PSRepository {}
        Mock Install-Module {}
    }
    It 'preserves an existing repository registration' {
        Install-GuideBuildDependencies -WorkspaceRoot $TestDrive
        Should -Invoke Register-PSRepository -Times 0 -Exactly
        Should -Invoke Install-Module -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'powershell-yaml' -and $Repository -eq 'PSGallery' -and $MinimumVersion -eq '0.4.12'
        }
    }
    It 'registers the default repository before installing on a fresh runner' {
        Mock Get-PSRepository { $null }
        Mock Install-Module {
            Should -Invoke Register-PSRepository -Times 1 -Exactly -ParameterFilter { $Default }
        }
        Install-GuideBuildDependencies -WorkspaceRoot $TestDrive
        Should -Invoke Install-Module -Times 1 -Exactly
    }
    It 'stops before installation when registration fails' {
        Mock Get-PSRepository { $null }
        Mock Register-PSRepository { throw 'Repository registration failed' }
        { Install-GuideBuildDependencies -WorkspaceRoot $TestDrive } | Should -Throw '*Repository registration failed*'
        Should -Invoke Install-Module -Times 0 -Exactly
    }
    It 'propagates a module installation failure' {
        Mock Install-Module { Write-Error 'Module installation failed' }
        { Install-GuideBuildDependencies -WorkspaceRoot $TestDrive } | Should -Throw '*Module installation failed*'
    }
}
