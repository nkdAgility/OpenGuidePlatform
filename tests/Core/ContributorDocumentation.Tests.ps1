BeforeAll {
    $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $checker = "$root/system/OpenGuidePlatform.PowerShell.PlatformBuild/Testing/Test-ContributorDocumentation.ps1"
    function New-ContributorGuideFixture([string]$Name) {
        $fixture = Join-Path $TestDrive $Name
        $integration = 'system/OpenGuidePlatform.Agents.Integration'
        [IO.Directory]::CreateDirectory("$fixture/system") | Out-Null
        Copy-Item "$root/$integration" "$fixture/system" -Recurse
        foreach ($relative in @('system/OpenGuidePlatform.PowerShell.Core/README.md','system/OpenGuidePlatform.PowerShell.Core/TranslationReadiness/README.md')) {
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName("$fixture/$relative")) | Out-Null
            Copy-Item "$root/$relative" "$fixture/$relative"
        }
        $fixture
    }
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
    It 'rejects a link to an existing file outside the package' {
        $fixture = Join-Path $TestDrive 'escaping-link'
        $guide = "$fixture/system/OpenGuidePlatform.Agents.Integration/contributor-guide"
        [IO.Directory]::CreateDirectory($guide) | Out-Null
        $outside = Join-Path $TestDrive 'outside.md'
        Set-Content $outside '# Outside the distribution'
        $relative = [IO.Path]::GetRelativePath($guide, $outside).Replace('\', '/')
        Set-Content "$guide/README.md" "[Outside]($relative)"
        { & $checker -PackageRoot $fixture } | Should -Throw '*escapes package*'
    }
    It 'rejects a manual-first entry page even when its references are valid' {
        $fixture = New-ContributorGuideFixture 'manual-first'
        $page = "$fixture/system/OpenGuidePlatform.Agents.Integration/contributor-guide/README.md"
        $text = [IO.File]::ReadAllText($page).Replace('## Work with an agent','## Agent information')
        [IO.File]::WriteAllText($page,$text)
        { & $checker -PackageRoot $fixture } | Should -Throw '*agent route before the manual alternative*'
    }
    It 'rejects primary-route terminal commands using <Fence> with <IndentCount> spaces' -ForEach @(
        @{Fence='```';IndentCount=0},
        @{Fence='~~~';IndentCount=0},
        @{Fence='```';IndentCount=3},
        @{Fence='~~~';IndentCount=3}
    ) {
        $fixture = New-ContributorGuideFixture "commands-first-$IndentCount-$($Fence[0])"
        $page = "$fixture/system/OpenGuidePlatform.Agents.Integration/contributor-guide/README.md"
        $indent = ' ' * $IndentCount
        $example = $indent+$Fence+"powershell`nGet-Content example`n"+$indent+$Fence+"`n"
        [IO.File]::WriteAllText($page,$example+[IO.File]::ReadAllText($page))
        { & $checker -PackageRoot $fixture } | Should -Throw '*primary route into commands*'
    }
    It 'rejects an early detour into the technical Core reference' {
        $fixture = New-ContributorGuideFixture 'core-first'
        $page = "$fixture/system/OpenGuidePlatform.Agents.Integration/contributor-guide/README.md"
        [IO.File]::WriteAllText($page,"[Start here](../../OpenGuidePlatform.PowerShell.Core/README.md)`n"+[IO.File]::ReadAllText($page))
        { & $checker -PackageRoot $fixture } | Should -Throw '*primary route into commands or Core references*'
    }
    It 'rejects a generic agent route with no explicit skill binding' {
        $fixture = New-ContributorGuideFixture 'generic-agent'
        $page = "$fixture/system/OpenGuidePlatform.Agents.Integration/contributor-guide/README.md"
        $text = [regex]::Replace([IO.File]::ReadAllText($page),'\[[^\]]*\]\(\.\./skills/guide\.[a-z]+/SKILL\.md\)','Ask any assistant')
        [IO.File]::WriteAllText($page,$text)
        { & $checker -PackageRoot $fixture } | Should -Throw '*link an actual OGP skill*'
    }
}
