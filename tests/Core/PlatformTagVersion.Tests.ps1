BeforeAll {
    $root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $entry=Join-Path $root '.build/Get-PlatformVersion.ps1'
}

Describe 'Platform version selection for a pushed release tag' {
    BeforeEach {
        $fixture=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory $fixture|Out-Null
        git init -q -b main $fixture
        git -C $fixture -c user.name=Test -c user.email=test@example.test commit --allow-empty -qm 'Release source'
        git -C $fixture tag v1.0.1
        git -C $fixture tag v1.0.1-Preview.6
        git -C $fixture tag v1.0.2
        $commit=(git -C $fixture rev-parse HEAD).Trim()
        $priorActions=$env:GITHUB_ACTIONS
        $priorRef=$env:GITHUB_REF
        $priorOutput=$env:GITHUB_OUTPUT
        $env:GITHUB_ACTIONS='true'
        $env:GITHUB_REF='refs/tags/v1.0.2'
        $env:GITHUB_OUTPUT=Join-Path $TestDrive 'github-output.txt'
    }
    AfterEach {
        $env:GITHUB_ACTIONS=$priorActions
        $env:GITHUB_REF=$priorRef
        $env:GITHUB_OUTPUT=$priorOutput
    }
    It 'uses the pushed exact tag even when other release tags identify the same commit' {
        $result=& $entry -WorkspaceRoot $fixture
        $result.SemVer|Should -BeExactly '1.0.2'
        $result.Sha|Should -BeExactly $commit
        Get-Content $env:GITHUB_OUTPUT|Should -Be @('semVer=1.0.2',"sha=$commit")
    }
    It 'rejects a tag that does not identify the checked-out source' {
        git -C $fixture -c user.name=Test -c user.email=test@example.test commit --allow-empty -qm 'Later source'
        { & $entry -WorkspaceRoot $fixture }|Should -Throw '*does not identify the checked-out commit*'
    }
    It 'rejects an unsupported tag before calculating a version' {
        $env:GITHUB_REF='refs/tags/v1.0'
        { & $entry -WorkspaceRoot $fixture }|Should -Throw '*Unsupported platform release tag*'
    }
}
