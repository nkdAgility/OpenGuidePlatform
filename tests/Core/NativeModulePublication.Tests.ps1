BeforeAll {
    function ConvertTo-PackageManifest($Manifest) {
        $copy=@{}+$Manifest
        $copy.schemaVersion=2
        $copy.packages=@{GuideSite=@{archive='OpenGuidePlatform-GuideSite.zip';version=$copy.version;sha256=$copy.sha256}}
        $copy.packages.PlatformBuild=@{archive='OpenGuidePlatform-PlatformBuild.zip';version=$copy.version;sha256=(Get-FileHash "$assets/OpenGuidePlatform-PlatformBuild.zip").Hash.ToLowerInvariant()}
        $copy.Remove('archive');$copy.Remove('sha256');$copy.Remove('bootstrapSha256')
        return $copy
    }

    $root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $publisher=Join-Path $root 'system/OpenGuidePlatform.PowerShell.PlatformBuild/Release/Publish-PlatformRelease.ps1'
    function git {
        $global:LASTEXITCODE=0
        if($args -contains 'rev-parse'){return 'a'*40}
        if($args[0] -eq 'ls-remote'){
            if($args[2] -like 'refs/tags/system/*'){return $global:OgpNativeTagExisting}
            if($global:OgpMissingRootTag){return}
            if($global:OgpRootTagExisting.Count){return $global:OgpRootTagExisting}
            if($global:OgpExistingRelease){return $global:OgpReleaseTagCommit+"`t"+$args[2]}
            return
        }
        if($args -contains 'push'){return}
        throw 'Unexpected Git operation.'
    }
    function gh {
        $global:LASTEXITCODE=0
        $global:OgpNativeTagCalls.Add(($args -join ' '))
        if($args[0] -eq 'api'){
            if($args[1] -like 'repos/*/commits/*'){return $global:OgpReleaseTagCommit}
            if($args[1] -like 'repos/*/git/matching-refs/tags/v'){return '[]'}
            if($global:OgpNativeTagFailure){$global:LASTEXITCODE=1}
            return
        }
        if($args[0] -eq 'release' -and $args[1] -eq 'view'){if($global:OgpExistingRelease){return ($global:OgpExistingRelease|ConvertTo-Json)};$global:LASTEXITCODE=1;return}
        if($args[0] -eq 'release' -and $args[1] -eq 'create'){return}
        if($args[0] -eq 'release' -and $args[1] -eq 'upload'){return}
        if($args[0] -eq 'release' -and $args[1] -eq 'download'){
            $destination=$args[[Array]::IndexOf($args,'--dir')+1]
            [IO.Directory]::CreateDirectory($destination)|Out-Null
            foreach($name in @('release-manifest.json','OpenGuidePlatform-GuideSite.zip','OpenGuidePlatform-PlatformBuild.zip')){Copy-Item (Join-Path $global:OgpReleaseAssets $name) $destination}
            if($global:OgpReleaseCorrupt){Set-Content (Join-Path $destination 'OpenGuidePlatform-GuideSite.zip') 'corrupt'}
            return
        }
        throw 'Unexpected GitHub operation.'
    }
}
Describe 'Coordinated native module publication' {
    BeforeEach {
        $global:OgpNativeTagCalls=[Collections.Generic.List[string]]::new()
        $global:OgpNativeTagExisting=@();$global:OgpExistingRelease=$null
        $global:OgpRootTagExisting=@()
        $global:OgpMissingRootTag=$false
        $global:OgpNativeTagFailure=$false
        $assets=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($assets)|Out-Null
        $global:OgpReleaseAssets=$assets;$global:OgpReleaseTagCommit='a'*40;$global:OgpReleaseCorrupt=$false
        [IO.File]::WriteAllText("$assets/OpenGuidePlatform-GuideSite.zip",'already validated package bytes')
        [IO.File]::WriteAllText("$assets/OpenGuidePlatform-PlatformBuild.zip",'platform engineering bytes')
        $manifest=@{version='0.1.0-Preview.1';channel='preview';archive='OpenGuidePlatform-GuideSite.zip';sourceCommit=('a'*40);sha256=(Get-FileHash "$assets/OpenGuidePlatform-GuideSite.zip").Hash.ToLowerInvariant();nativeHugoModule=@{path='github.com/nkdAgility/OpenGuidePlatform/system/OpenGuidePlatform.Hugo.Guides';version='v0.1.0-Preview.1';tag='system/OpenGuidePlatform.Hugo.Guides/v0.1.0-Preview.1';sourceCommit=('a'*40)}}
        [IO.File]::WriteAllText("$assets/release-manifest.json",(ConvertTo-PackageManifest $manifest|ConvertTo-Json -Depth 10))
        $priorRepo=$env:GITHUB_REPOSITORY
        $env:GITHUB_REPOSITORY='example/platform'
    }
    AfterEach { $env:GITHUB_REPOSITORY=$priorRepo }
    It 'publishes a nested module tag before making its coordinated release available' {
        & $publisher -WorkspaceRoot $root -Repository example/platform -OutputPath $assets
        $global:OgpNativeTagCalls[0] | Should -Match 'refs/tags/system/OpenGuidePlatform.Hugo.Guides/v0.1.0-Preview.1'
        $releaseCall=$global:OgpNativeTagCalls|Where-Object {$_ -like 'release create *'}|Select-Object -Last 1
        $releaseCall | Should -Match '^release create v0.1.0-Preview.1 '
        $releaseCall | Should -Match '--generate-notes'
        $releaseCall | Should -Match '--title v0.1.0-Preview.1'
        $notes=Get-Content "$assets/release-notes.md" -Raw
        $notes|Should -Match 'Update -ring preview -PlatformRelease v0.1.0-Preview.1'
        $notes|Should -Match 'First installation|OpenGuidePlatform-GuideSite.zip|settings.yaml'
    }
    It 'publishes a stable version as a normal release with the matching module tag' {
        $manifest.version='0.1.0';$manifest.channel='stable'
        $manifest.nativeHugoModule.version='v0.1.0';$manifest.nativeHugoModule.tag='system/OpenGuidePlatform.Hugo.Guides/v0.1.0'
        ConvertTo-PackageManifest $manifest|ConvertTo-Json -Depth 10|Set-Content "$assets/release-manifest.json"
        & $publisher -WorkspaceRoot $root -OutputPath $assets
        $global:OgpNativeTagCalls[0]|Should -Match 'refs/tags/system/OpenGuidePlatform.Hugo.Guides/v0.1.0'
        $releaseCall=$global:OgpNativeTagCalls|Where-Object {$_ -like 'release create *'}|Select-Object -Last 1
        $releaseCall|Should -Match '^release create v0.1.0 '
        $releaseCall|Should -Not -Match '--prerelease|--latest=false'
        $releaseCall|Should -Match '--title v0.1.0'
        Get-Content "$assets/release-notes.md" -Raw|Should -Match 'Update -ring production -PlatformRelease v0.1.0'
    }
    It 'keeps prerelease versions as preview releases' {
        & $publisher -WorkspaceRoot $root -OutputPath $assets
        ($global:OgpNativeTagCalls|Where-Object {$_ -like 'release create *'}|Select-Object -Last 1)|Should -Match '--prerelease --latest=false'
    }
    It 'rejects a manifest channel inconsistent with its version' {
        $manifest.channel='stable'
        ConvertTo-PackageManifest $manifest|ConvertTo-Json -Depth 10|Set-Content "$assets/release-manifest.json"
        { & $publisher -WorkspaceRoot $root -OutputPath $assets }|Should -Throw '*channel disagrees*'
        $global:OgpNativeTagCalls.Count|Should -Be 0
    }
    It 'rejects an existing release with the wrong prerelease classification' {
        $global:OgpExistingRelease=@{targetCommitish=('a'*40);isDraft=$false;isPrerelease=$false}
        { & $publisher -WorkspaceRoot $root -OutputPath $assets }|Should -Throw '*Existing release identity differs*'
        @($global:OgpNativeTagCalls|Where-Object {$_ -match '^release create '}).Count|Should -Be 0
    }
    It 'completes an empty release whose immutable tag matches despite branch target metadata' {
        $global:OgpExistingRelease=@{targetCommitish='main';isDraft=$false;isPrerelease=$true;assets=@()}
        & $publisher -WorkspaceRoot $root -OutputPath $assets
        @($global:OgpNativeTagCalls|Where-Object {$_ -like 'release upload *'}).Count|Should -Be 1
        @($global:OgpNativeTagCalls|Where-Object {$_ -match '--clobber|release create'}).Count|Should -Be 0
    }
    It 'rejects an empty release whose actual tag differs before uploading' {
        $global:OgpExistingRelease=@{targetCommitish=('a'*40);isDraft=$false;isPrerelease=$true;assets=@()}
        $global:OgpReleaseTagCommit='b'*40
        {& $publisher -WorkspaceRoot $root -OutputPath $assets}|Should -Throw '*Existing immutable release tag differs*'
        @($global:OgpNativeTagCalls|Where-Object {$_ -like 'release upload *'}).Count|Should -Be 0
    }
    It 'refuses partial release assets without uploading' {
        $global:OgpExistingRelease=@{isDraft=$false;isPrerelease=$true;assets=@(@{name='release-manifest.json'})}
        {& $publisher -WorkspaceRoot $root -OutputPath $assets}|Should -Throw '*partial or unexpected*'
        @($global:OgpNativeTagCalls|Where-Object {$_ -like 'release upload *'}).Count|Should -Be 0
    }
    It 'refuses an existing release with no immutable version tag' {
        $global:OgpExistingRelease=@{targetCommitish='main';isDraft=$false;isPrerelease=$true;assets=@()}
        $global:OgpMissingRootTag=$true
        {& $publisher -WorkspaceRoot $root -OutputPath $assets}|Should -Throw '*Existing release identity differs*'
        @($global:OgpNativeTagCalls|Where-Object {$_ -like 'release upload *'}).Count|Should -Be 0
    }
    It 'refuses an empty draft instead of publishing it implicitly' {
        $global:OgpExistingRelease=@{isDraft=$true;isPrerelease=$true;assets=@()}
        {& $publisher -WorkspaceRoot $root -OutputPath $assets}|Should -Throw '*Existing release identity differs*'
        @($global:OgpNativeTagCalls|Where-Object {$_ -like 'release upload *'}).Count|Should -Be 0
    }
    It 'rejects a complete release with a different coordinated manifest' {
        $global:OgpExistingRelease=@{isDraft=$false;isPrerelease=$true;assets=@(@{name='release-manifest.json'},@{name='OpenGuidePlatform-GuideSite.zip'},@{name='OpenGuidePlatform-PlatformBuild.zip'})}
        $other=Join-Path $TestDrive 'other-assets'
        Copy-Item $assets $other -Recurse
        Add-Content (Join-Path $other 'release-manifest.json') ' '
        $global:OgpReleaseAssets=$other
        {& $publisher -WorkspaceRoot $root -OutputPath $assets}|Should -Throw '*Existing release manifest differs*'
        @($global:OgpNativeTagCalls|Where-Object {$_ -like 'release upload *'}).Count|Should -Be 0
    }
    It 'verifies complete release bytes without replacing assets' {
        $global:OgpExistingRelease=@{targetCommitish='main';isDraft=$false;isPrerelease=$true;assets=@(@{name='release-manifest.json'},@{name='OpenGuidePlatform-GuideSite.zip'},@{name='OpenGuidePlatform-PlatformBuild.zip'})}
        & $publisher -WorkspaceRoot $root -OutputPath $assets
        @($global:OgpNativeTagCalls|Where-Object {$_ -like 'release upload *'}).Count|Should -Be 0
        $global:OgpReleaseCorrupt=$true
        {& $publisher -WorkspaceRoot $root -OutputPath $assets}|Should -Throw '*Existing release bytes differ*'
    }
    It 'resolves an annotated native tag to its peeled commit' {
        $global:OgpNativeTagExisting=@((('b'*40)+"`trefs/tags/system/OpenGuidePlatform.Hugo.Guides/v0.1.0-Preview.1"),(('a'*40)+"`trefs/tags/system/OpenGuidePlatform.Hugo.Guides/v0.1.0-Preview.1^{}"))
        & $publisher -WorkspaceRoot $root -OutputPath $assets
        @($global:OgpNativeTagCalls|Where-Object {$_ -match '^api .*/git/refs --method POST.*system/OpenGuidePlatform.Hugo.Guides/' }).Count|Should -Be 0
    }
    It 'publishes workspace-relative assets when invoked from another working directory' {
        $workspace=Split-Path $assets -Parent
        $relativeAssets=Split-Path $assets -Leaf
        Push-Location $root
        try { & $publisher -WorkspaceRoot $workspace -Repository example/platform -OutputPath $relativeAssets }
        finally { Pop-Location }
        Test-Path "$assets/release-notes.md" | Should -BeTrue
        ($global:OgpNativeTagCalls|Where-Object {$_ -like 'release create *'}|Select-Object -Last 1) | Should -Match ([regex]::Escape("$assets/OpenGuidePlatform-GuideSite.zip"))
    }
    It 'reuses an existing matching tag without moving or recreating it' {
        $global:OgpNativeTagExisting=@(('a'*40)+"`trefs/tags/system/OpenGuidePlatform.Hugo.Guides/v0.1.0-Preview.1")
        & $publisher -WorkspaceRoot $root -Repository example/platform -OutputPath $assets
        @($global:OgpNativeTagCalls|Where-Object {$_ -match '^api .*/git/refs --method POST.*system/OpenGuidePlatform.Hugo.Guides/' }).Count | Should -Be 0
    }
    It 'refuses a conflicting immutable module tag' {
        $global:OgpNativeTagExisting=@(('b'*40)+"`trefs/tags/system/OpenGuidePlatform.Hugo.Guides/v0.1.0-Preview.1")
        { & $publisher -WorkspaceRoot $root -Repository example/platform -OutputPath $assets } | Should -Throw '*Existing native Hugo tag differs*'
        $global:OgpNativeTagCalls.Count | Should -Be 0
    }
    It 'refuses an existing root tag at another commit before creating a release or native tag' {
        $global:OgpRootTagExisting=@(('b'*40)+"`trefs/tags/v0.1.0-Preview.1")
        {& $publisher -WorkspaceRoot $root -OutputPath $assets}|Should -Throw '*Existing immutable release tag differs*'
        $global:OgpNativeTagCalls.Count|Should -Be 0
    }
    It 'does not publish the platform when module publication fails' {
        $global:OgpNativeTagFailure=$true
        { & $publisher -WorkspaceRoot $root -Repository example/platform -OutputPath $assets } | Should -Throw '*Native Hugo tag publication failed*'
        @($global:OgpNativeTagCalls|Where-Object {$_ -match '^release create '}).Count | Should -Be 0
    }
    It 'rejects a module version inconsistent with the tested package' {
        $manifest.nativeHugoModule.version='v9.0.0'
        [IO.File]::WriteAllText("$assets/release-manifest.json",(ConvertTo-PackageManifest $manifest|ConvertTo-Json -Depth 10))
        { & $publisher -WorkspaceRoot $root -Repository example/platform -OutputPath $assets } | Should -Throw '*Native Hugo publication identity differs*'
        $global:OgpNativeTagCalls.Count | Should -Be 0
    }
}
AfterAll { Remove-Variable OgpNativeTagCalls,OgpNativeTagExisting,OgpExistingRelease,OgpNativeTagFailure,OgpReleaseAssets,OgpReleaseTagCommit,OgpReleaseCorrupt -Scope Global -ErrorAction SilentlyContinue }
