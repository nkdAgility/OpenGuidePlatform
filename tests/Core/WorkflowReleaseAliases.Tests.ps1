BeforeAll {
    $root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    . "$root/system/OpenGuidePlatform.PowerShell.PlatformBuild/Release/Publish-PlatformWorkflowAliases.ps1"
    function global:gh {
        $global:LASTEXITCODE=0
        $global:OgpAliasCalls.Add(($args -join ' '))
        if($args[0] -ne 'api'){throw 'Unexpected command'}
        if($args[1] -like 'repos/*/git/matching-refs/tags/v'){
            if($global:OgpAliasRaw){return $global:OgpAliasRaw}
            return ('['+($global:OgpAliasRefs|ConvertTo-Json -Depth 5 -AsArray)+']')
        }
        if($args[1] -eq 'graphql' -and $args -match 'query=query'){
            return (@{data=@{repository=@{id='repo-id';ref=@{target=@{oid=$global:OgpAliasObservedOid}}}}}|ConvertTo-Json -Depth 6)
        }
        if($args[1] -eq 'graphql'){
            if($global:OgpAliasFail){$global:LASTEXITCODE=1;return (@{errors=@(@{message='stale oid'})}|ConvertTo-Json)}
            return (@{data=@{updateRefs=@{clientMutationId=$null}}}|ConvertTo-Json -Depth 6)
        }
        if($global:OgpAliasFail){$global:LASTEXITCODE=1}
    }
}
Describe 'Version-family workflow publication' {
    BeforeEach {$global:OgpAliasRefs=@();$global:OgpAliasRaw=$null;$global:OgpAliasCalls=[Collections.Generic.List[string]]::new();$global:OgpAliasFail=$false;$global:OgpAliasObservedOid='b'*40}
    It 'creates only ring-specific major and minor aliases' -ForEach @(
        @{Version='1.2.3';Major='v1';Minor='v1.2'},@{Version='0.6.0-Preview.2';Major='v0-preview';Minor='v0.6-preview'}
    ) {
        Publish-PlatformWorkflowAliases -WorkspaceRoot $root -Repository example/platform -Version $Version -Commit ('a'*40)
        $creates=@($global:OgpAliasCalls|Where-Object {$_ -like 'api repos/*/git/refs --method POST*'})
        $creates.Count|Should -Be 2
        $creates[0]|Should -Match ([regex]::Escape("refs/tags/$Major"))
        $creates[1]|Should -Match ([regex]::Escape("refs/tags/$Minor"))
    }
    It 'does not move aliases backwards when an older release is published' {
        $global:OgpAliasRefs=@(foreach($name in @('v1','v1.2','v1.2.9')){@{ref="refs/tags/$name";object=@{sha=('b'*40)}}})
        Publish-PlatformWorkflowAliases -WorkspaceRoot $root -Repository example/platform -Version 1.2.3 -Commit ('a'*40)
        @($global:OgpAliasCalls|Where-Object {$_ -match 'POST|graphql'}).Count|Should -Be 0
    }
    It 'reads refs from every returned page before deciding whether to move aliases' {
        $old='b'*40
        $global:OgpAliasRaw='[[{"ref":"refs/tags/v1","object":{"sha":"'+$old+'"}},{"ref":"refs/tags/v1.2","object":{"sha":"'+$old+'"}}],[{"ref":"refs/tags/v1.2.9","object":{"sha":"'+$old+'"}}]]'
        Publish-PlatformWorkflowAliases -WorkspaceRoot $root -Repository example/platform -Version 1.2.3 -Commit ('a'*40)
        @($global:OgpAliasCalls|Where-Object {$_ -match 'POST|graphql'}).Count|Should -Be 0
    }
    It 'updates existing aliases with the expected oid' {
        $global:OgpAliasRefs=@(foreach($name in @('v1','v1.2','v1.2.2')){@{ref="refs/tags/$name";object=@{sha=('b'*40)}}})
        Publish-PlatformWorkflowAliases -WorkspaceRoot $root -Repository example/platform -Version 1.2.3 -Commit ('a'*40)
        $updates=@($global:OgpAliasCalls|Where-Object {$_ -match 'api graphql.*updateRefs'})
        $updates.Count|Should -Be 2
        $updates[0]|Should -Match ('beforeOid:"'+('b'*40)+'"')
    }
    It 'fails on a lost lease rather than overwriting a concurrent publication' {
        $global:OgpAliasRefs=@(foreach($name in @('v1','v1.2','v1.2.2')){@{ref="refs/tags/$name";object=@{sha=('b'*40)}}})
        $global:OgpAliasObservedOid='c'*40
        {Publish-PlatformWorkflowAliases -WorkspaceRoot $root -Repository example/platform -Version 1.2.3 -Commit ('a'*40)}|Should -Throw '*changed concurrently*'
        @($global:OgpAliasCalls|Where-Object {$_ -match 'api graphql.*updateRefs'}).Count|Should -Be 0
    }
}
