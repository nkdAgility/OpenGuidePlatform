BeforeAll {
    $root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
}
Describe 'Guide attribution Prepare overlay' {
    It 'preserves custom and default mounts while exposing every declared guide data folder' {
        $workspace=Join-Path $TestDrive 'consumer'
        [IO.Directory]::CreateDirectory($workspace)|Out-Null
        Copy-Item "$root/examples/reference-guide-site" "$workspace/site" -Recurse
        & git -C $workspace init --quiet
        & git -C $workspace -c user.name=Fixture -c user.email=fixture@example.test commit --allow-empty -m Fixture --quiet
        if($LASTEXITCODE -ne 0){throw 'Could not create fixture source identity.'}
        [IO.Directory]::CreateDirectory("$workspace/site/custom-assets")|Out-Null
        [IO.File]::WriteAllText("$workspace/site/custom-assets/sentinel.txt",'custom asset')
        [IO.File]::AppendAllText("$workspace/site/hugo.preview.yaml",@'

module:
  mounts:
    - source: custom-assets
      target: assets
'@)
        $configHash=(Get-FileHash "$workspace/site/hugo.preview.yaml").Hash
        & "$root/build.ps1" -Product GuideSite -Stage Prepare -WorkspaceRoot $workspace -SourcePath site -Target preview -OutputPath .processing/attribution -Version 0.0.0-local
        $overlay=Get-Content "$workspace/.processing/attribution/candidate-platform.json" -Raw|ConvertFrom-Json
        @($overlay.module.mounts | Where-Object { $_.source -eq 'custom-assets' -and $_.target -eq 'assets' }).Count | Should -Be 1
        @($overlay.module.mounts | Where-Object { $_.source -eq 'content' -and $_.target -eq 'content' }).Count | Should -Be 1
        @($overlay.module.mounts | Where-Object { $_.source -eq 'static' -and $_.target -eq 'static' }).Count | Should -Be 1
        $policy=Get-Content "$workspace/.processing/attribution/discovered-site.json" -Raw|ConvertFrom-Json
        foreach($guide in $policy.guides){
            $mount=@($overlay.module.mounts | Where-Object target -eq "assets/ogp-attribution/$($guide.id.ToLowerInvariant())")
            $mount.Count | Should -Be 1
            [IO.Path]::GetFullPath($mount[0].source) | Should -Be ([IO.Path]::GetFullPath("$workspace/$($guide.contentRoot)/data"))
        }
        (Get-FileHash "$workspace/site/hugo.preview.yaml").Hash | Should -Be $configHash
        & "$root/build.ps1" -Product GuideSite -Stage Build -WorkspaceRoot $workspace -SourcePath site -Target preview -OutputPath .processing/attribution -Version 0.0.0-local
        $homepageHtml=Get-Content "$workspace/.processing/attribution/site/index.html" -Raw
        $homepageHtml | Should -Match 'Jane Smith'
        $homepageHtml | Should -Match 'Martin Hinshelwood'
        $editionHtml=Get-Content "$workspace/.processing/attribution/site/guide1/2025.5/index.html" -Raw
        $editionHtml | Should -Match 'Jane Smith'
        $translationHtml=Get-Content "$workspace/.processing/attribution/site/min/guide1/2025.5/index.html" -Raw
        $translationHtml | Should -Match 'Banana Translator'
        # An attribution edit must invalidate the exact passing Prepare evidence.
        [IO.File]::AppendAllText("$workspace/site/content/Guide1/data/contributors.yml","`n# changed since Prepare`n")
        { & "$root/build.ps1" -Product GuideSite -Stage Build -WorkspaceRoot $workspace -SourcePath site -Target preview -OutputPath .processing/attribution -Version 0.0.0-local } | Should -Throw '*PREPARE_INPUTS_CHANGED*'
    }
}
