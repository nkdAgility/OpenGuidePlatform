BeforeAll {
    $root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $launcher=Join-Path $root 'system/OpenGuidePlatform.PowerShell.PlatformBuild/Release/release.ps1'
    function git {
        $global:LASTEXITCODE=0
        if($global:OgpPackagedMissingTag){return}
        if($global:OgpPackagedAnnotatedTag){return @((('b'*40)+"`t"+$args[2]),($global:OgpPackagedReleaseCommit+"`t"+$args[3]))}
        return $global:OgpPackagedReleaseCommit+"`t"+$args[2]
    }
    function global:gh {
        $global:LASTEXITCODE=0
        if($args[0] -eq 'api' -and $args[1] -like 'repos/*/commits/*'){return $global:OgpPackagedReleaseCommit}
        if($args[0] -eq 'release' -and $args[1] -eq 'view'){
            return (@{targetCommitish='main';isDraft=$false;isPrerelease=$false}|ConvertTo-Json)
        }
        if($args[0] -eq 'release' -and $args[1] -eq 'download'){
            $index=[Array]::IndexOf($args,'--dir')
            [IO.Directory]::CreateDirectory($args[$index+1])|Out-Null
            foreach($name in @('release-manifest.json','OpenGuidePlatform-GuideSite.zip','OpenGuidePlatform-PlatformBuild.zip')){
                Copy-Item (Join-Path $global:OgpPackagedReleaseAssets $name) $args[$index+1]
            }
            if($global:OgpPackagedReleaseCorrupt){Set-Content (Join-Path $args[$index+1] 'OpenGuidePlatform-GuideSite.zip') 'changed'}
            return
        }
        throw 'Unexpected GitHub command'
    }
}
Describe 'Packaged release launcher' {
    BeforeEach {
        $global:OgpPackagedReleaseAssets=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($global:OgpPackagedReleaseAssets)|Out-Null
        $global:OgpPackagedReleaseCorrupt=$false
        $global:OgpPackagedReleaseCommit='a'*40
        $global:OgpPackagedMissingTag=$false
        $global:OgpPackagedAnnotatedTag=$false
        @{version='1.2.3';sourceCommit=('a'*40)}|ConvertTo-Json|Set-Content "$global:OgpPackagedReleaseAssets/release-manifest.json"
        Set-Content "$global:OgpPackagedReleaseAssets/OpenGuidePlatform-GuideSite.zip" 'guide bytes'
        Set-Content "$global:OgpPackagedReleaseAssets/OpenGuidePlatform-PlatformBuild.zip" 'platform bytes'
    }
    It 'rejects an artifact from another source commit before publication' {
        { & $launcher -Stage Validate -AssetsPath $global:OgpPackagedReleaseAssets -SourceCommit ('b'*40) }|Should -Throw '*source commit does not match*'
    }
    It 'validates published bytes using only the artifact and GitHub release' {
        & $launcher -Stage Validate -AssetsPath $global:OgpPackagedReleaseAssets -SourceCommit ('a'*40) -ReleaseTag v1.2.3
    }
    It 'rejects changed published assets' {
        $global:OgpPackagedReleaseCorrupt=$true
        { & $launcher -Stage Validate -AssetsPath $global:OgpPackagedReleaseAssets -SourceCommit ('a'*40) }|Should -Throw '*differs from the tested package*'
    }
    It 'rejects an immutable published tag at another commit' {
        $global:OgpPackagedReleaseCommit='b'*40
        {& $launcher -Stage Validate -AssetsPath $global:OgpPackagedReleaseAssets -SourceCommit ('a'*40)}|Should -Throw '*Published release tag differs*'
    }
    It 'rejects a missing tag even when release metadata and a branch could match' {
        $global:OgpPackagedMissingTag=$true
        {& $launcher -Stage Validate -AssetsPath $global:OgpPackagedReleaseAssets -SourceCommit ('a'*40)}|Should -Throw '*Published release tag differs*'
    }
    It 'validates the peeled commit of an annotated immutable version tag' {
        $global:OgpPackagedAnnotatedTag=$true
        & $launcher -Stage Validate -AssetsPath $global:OgpPackagedReleaseAssets -SourceCommit ('a'*40)
    }
}
