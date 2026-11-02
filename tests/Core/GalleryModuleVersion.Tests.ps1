BeforeAll {
    $root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    . "$root/system/OpenGuidePlatform.PowerShell.PlatformBuild/Packaging/ConvertTo-GalleryModuleVersion.ps1"
}
Describe 'Coordinated Gallery version mapping' {
    It 'keeps stable release numbers unchanged' {
        $version=ConvertTo-GalleryModuleVersion '1.2.3'
        $version.GalleryVersion | Should -Be '1.2.3'
        $version.Prerelease | Should -BeNullOrEmpty
    }
    It 'preserves SemVer ordering including numeric rollovers and mixed identifiers' {
        $versions=@('1.2.3-0','1.2.3-9','1.2.3-10','1.2.3-999','1.2.3-1000','1.2.3-A','1.2.3-Z','1.2.3-a','1.2.3-alpha','1.2.3-alpha.1','1.2.3-alpha.9','1.2.3-alpha.10','1.2.3-alpha.a','1.2.3-beta','1.2.3-Preview.9','1.2.3-Preview.10','1.2.3-rc.1','1.2.3')
        foreach($left in $versions){foreach($right in $versions){
            $expected=[Math]::Sign(([semver]$left).CompareTo([semver]$right))
            $actual=[Math]::Sign(([semver](ConvertTo-GalleryModuleVersion $left).GalleryVersion).CompareTo([semver](ConvertTo-GalleryModuleVersion $right).GalleryVersion))
            $actual | Should -Be $expected -Because "$left and $right must retain release precedence"
        }}
    }
    It 'does not conflate separators or case in distinct labels' {
        $versions=@('1.2.3-alpha-1','1.2.3-alpha.1','1.2.3-Alpha.1','1.2.3-alpha1')
        @($versions|ForEach-Object {(ConvertTo-GalleryModuleVersion $_).GalleryVersion}|Sort-Object -Unique).Count | Should -Be $versions.Count
    }
    It 'uses an alphabetic single prerelease identifier compatible with PowerShellGet' {
        (ConvertTo-GalleryModuleVersion '1.2.3-Preview.10').Prerelease | Should -Match '^pre[a-z0-9]+$'
    }
    It 'rejects noncanonical numbers rather than colliding with another release' -ForEach @('01.2.3','1.02.3','1.2.03','1.2.3-01','1.2.3-alpha.01') {
        { ConvertTo-GalleryModuleVersion $_ } | Should -Throw
    }
}
