BeforeAll {
    $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $checker = "$root/system/OpenGuidePlatform.PowerShell.PlatformBuild/Testing/Test-ContributorDocumentation.ps1"
}
Describe 'Distributed contributor documentation' {
    It 'has complete task navigation, references and accessible SVG structure' {
        & $checker -PackageRoot $root
    }
    It 'rejects a missing page in a distribution' {
        { & $checker -PackageRoot $TestDrive } | Should -Throw '*documentation missing*'
    }
    It 'rejects a broken local reference rather than silently accepting a partial package' {
        $fixture = Join-Path $TestDrive 'broken'
        $guide = "$fixture/system/OpenGuidePlatform.Agents.Integration/contributor-guide"
        [IO.Directory]::CreateDirectory($guide) | Out-Null
        Set-Content "$guide/README.md" '[Setup](setup.md)'
        { & $checker -PackageRoot $fixture } | Should -Throw '*Broken contributor link*'
    }
    It 'rejects a missing diagram referenced as a Markdown image' {
        $fixture = Join-Path $TestDrive 'missing-image'
        $guide = "$fixture/system/OpenGuidePlatform.Agents.Integration/contributor-guide"
        [IO.Directory]::CreateDirectory($guide) | Out-Null
        Set-Content "$guide/README.md" '![System overview](diagrams/missing.svg)'
        { & $checker -PackageRoot $fixture } | Should -Throw '*Broken contributor link*'
    }
}
