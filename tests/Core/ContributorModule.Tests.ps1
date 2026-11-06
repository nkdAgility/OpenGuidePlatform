BeforeDiscovery {
    $root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Import-Module "$root/system/OpenGuidePlatform.PowerShell.Contributor/OpenGuidePlatform.psd1" -Force
}

Describe 'Installable contributor task safeguards' {
    InModuleScope OpenGuidePlatform {
        BeforeEach {
            $script:testContext=@{
                WorkspaceRoot=$TestDrive;Identity=@{version='1.2.3';sourceCommit=('a'*40)}
                OutputPath='.processing/draft-test'
                Policy=@{guides=@(@{id='guide';editions=@(@{id='2026'})})}
            }
            Mock New-OGPContext { $script:testContext }
        }

        It 'does not create a body for a PDF-only or fallback edition' {
            Mock Invoke-OGPCore { [pscustomobject]@{Guides=@([pscustomobject]@{GuideId='guide';EditionId='2026';CanCreateScaffold=$false;Intent='pdf-only'})} } -ParameterFilter {$Command -eq 'Get-GuideSiteTranslationWork'}
            Mock Invoke-OGPCore { throw 'Writer must not run' } -ParameterFilter {$Command -eq 'New-GuideTranslation'}
            { New-OGPTranslation -GuideId guide -EditionId 2026 -Language fr } | Should -Throw '*not eligible*'
            Should -Invoke Invoke-OGPCore -Times 0 -Exactly -ParameterFilter {$Command -eq 'New-GuideTranslation'}
        }

        It 'requires explicit review before loading a draft' {
            { Save-OGPDraft -Path candidate.md } | Should -Throw '*Review the exact candidate*'
            Should -Invoke New-OGPContext -Times 0 -Exactly
        }

        It 'refuses a draft from another runtime' {
            $candidate=Join-Path $TestDrive 'candidate.md'
            Set-Content $candidate 'text'
            @{schemaVersion=1;workspace=$TestDrive;version='1.2.2';sourceCommit=('a'*40)}|ConvertTo-Json|Set-Content "$candidate.ogp.json"
            { Save-OGPDraft -Path $candidate -Reviewed } | Should -Throw '*another workspace or OGP runtime*'
        }

        It 'refuses a stale target without refreshing its retained hash' {
            $candidate=Join-Path $TestDrive 'candidate.md'
            $target=Join-Path $TestDrive 'target.md'
            Set-Content $candidate 'new wording';Set-Content $target 'changed concurrently'
            @{schemaVersion=1;workspace=$TestDrive;version='1.2.3';sourceCommit=('a'*40);target='target.md';targetHash=('b'*64);source=$null;sourceHash=$null}|ConvertTo-Json|Set-Content "$candidate.ogp.json"
            Mock Invoke-OGPCore { Join-Path $TestDrive 'target.md' } -ParameterFilter {$Command -eq 'Resolve-GuideWorkspacePath'}
            { Save-OGPDraft -Path $candidate -Reviewed } | Should -Throw '*changed since this draft*'
        }

        It 'previews a draft without applying the target' {
            $candidate=Join-Path $TestDrive 'candidate.md'
            $target=Join-Path $TestDrive 'target.md'
            Set-Content $candidate 'new wording';Set-Content $target 'old wording'
            @{schemaVersion=1;workspace=$TestDrive;version='1.2.3';sourceCommit=('a'*40);kind='translation';selection=@{};target='target.md';targetHash=(Get-FileHash $target).Hash;source='target.md';sourceHash=(Get-FileHash $target).Hash}|ConvertTo-Json|Set-Content "$candidate.ogp.json"
            Mock Invoke-OGPCore { Join-Path $TestDrive 'target.md' } -ParameterFilter {$Command -eq 'Resolve-GuideWorkspacePath'}
            Mock Invoke-OGPCore { [pscustomobject]@{WhatIf=$Arguments.WhatIf} } -ParameterFilter {$Command -eq 'Set-GuideTranslation'}
            (Save-OGPDraft -Path $candidate -Reviewed -WhatIf).WhatIf | Should -BeTrue
            (Get-Content $target -Raw).Trim() | Should -Be 'old wording'
        }

        It 'requires consent before credit discovery or mutation' {
            { New-OGPContribution -GuideId guide -EditionId 2026 -Language fr -Name Person -Role translator } | Should -Throw '*consent*'
            Should -Invoke New-OGPContext -Times 0 -Exactly
        }

        It 'retains a resolved historical comparison through draft creation and save' {
            $source=Join-Path $TestDrive 'source.md';$target=Join-Path $TestDrive 'target.md'
            Set-Content $source 'current source';Set-Content $target 'current translation'
            Mock Invoke-OGPCore {
                [pscustomobject]@{
                    Source=[pscustomobject]@{Path='source.md';Sha256=(Get-FileHash (Join-Path $TestDrive 'source.md')).Hash}
                    Target=[pscustomobject]@{Content='current translation';Sha256=(Get-FileHash (Join-Path $TestDrive 'target.md')).Hash}
                    TargetPath='target.md'
                    Comparison=[pscustomobject]@{Commit=('b'*40);Path='old/source.md';Content='earlier source';Diff="-earlier source`n+current source"}
                }
            } -ParameterFilter {$Command -eq 'Get-GuideTranslationWork' -and $Arguments.SourceRevision -eq 'reviewed-baseline' -and $Arguments.SourcePathAtRevision -eq 'old/source.md'}
            $draft=New-OGPTranslationDraft -GuideId guide -EditionId 2026 -Language fr -SourceRevision reviewed-baseline -SourcePathAtRevision old/source.md
            (Get-Content $draft.SourceBaselinePath -Raw) | Should -Be 'earlier source'
            (Get-Content $draft.SourceDifferencePath -Raw) | Should -Match 'current source'
            Mock Invoke-OGPCore { Join-Path $TestDrive $Arguments.RelativePath } -ParameterFilter {$Command -eq 'Resolve-GuideWorkspacePath'}
            Mock Invoke-OGPCore { [pscustomobject]@{Status='planned'} } -ParameterFilter {$Command -eq 'Set-GuideTranslation' -and $Arguments.SourceRevision -eq ('b'*40) -and $Arguments.SourcePathAtRevision -eq 'old/source.md'}
            (Save-OGPDraft -Path $draft.Path -Reviewed -WhatIf).Status | Should -Be 'planned'
            Should -Invoke Invoke-OGPCore -Times 1 -Exactly -ParameterFilter {$Command -eq 'Set-GuideTranslation' -and $Arguments.SourceRevision -eq ('b'*40)}
        }

        It 'passes the supported selection to the PDF generator without a Plan parameter' {
            Mock Invoke-OGPCore { [pscustomobject]@{Output=(Join-Path $TestDrive 'absent.pdf');RelativeOutput='site/guide.fr.pdf'} } -ParameterFilter {$Command -eq 'Get-GuidePdfPlan'}
            Mock Invoke-OGPCore { [pscustomobject]@{Required=@([pscustomobject]@{Guide='guide';Edition='2026';Language='fr';SourcePath='site/guide.fr.pdf';GenerationReceipt=@{path='receipt.json';environmentSha256=('c'*64)}});Forbidden=@()} } -ParameterFilter {$Command -eq 'Get-GuideDownloadRequirements'}
            Mock Invoke-OGPCore { Join-Path $TestDrive 'receipt.json' } -ParameterFilter {$Command -eq 'Resolve-GuideWorkspacePath'}
            Mock Invoke-OGPCore { $Arguments } -ParameterFilter {$Command -eq 'New-GuidePdf'}
            New-OGPPdf -GuideId guide -EditionId 2026 -Language fr -DownloadPath guide.fr.pdf -WhatIf
            Should -Invoke Invoke-OGPCore -Times 1 -Exactly -ParameterFilter {$Command -eq 'New-GuidePdf' -and $Arguments.GuideId -eq 'guide' -and $Arguments.Policy -and -not $Arguments.ContainsKey('Plan') -and $Arguments.WhatIf -and $Arguments.EnvironmentSha256 -eq ('c'*64)}
        }

        It 'does not generate a PDF without approved environment and receipt declarations' {
            Mock Invoke-OGPCore { [pscustomobject]@{Output=(Join-Path $TestDrive 'absent.pdf');RelativeOutput='site/guide.fr.pdf'} } -ParameterFilter {$Command -eq 'Get-GuidePdfPlan'}
            Mock Invoke-OGPCore { [pscustomobject]@{Required=@();Forbidden=@()} } -ParameterFilter {$Command -eq 'Get-GuideDownloadRequirements'}
            { New-OGPPdf -GuideId guide -EditionId 2026 -Language fr -DownloadPath guide.fr.pdf } | Should -Throw '*approved generation environment*'
        }

        It 'retains generation evidence through the Core receipt writer' {
            Mock Invoke-OGPCore { [pscustomobject]@{Output=(Join-Path $TestDrive 'absent.pdf');RelativeOutput='site/guide.fr.pdf'} } -ParameterFilter {$Command -eq 'Get-GuidePdfPlan'}
            Mock Invoke-OGPCore { [pscustomobject]@{Required=@([pscustomobject]@{Guide='guide';Edition='2026';Language='fr';SourcePath='site/guide.fr.pdf';GenerationReceipt=@{path='receipt.json';environmentSha256=('c'*64)}});Forbidden=@()} } -ParameterFilter {$Command -eq 'Get-GuideDownloadRequirements'}
            Mock Invoke-OGPCore { Join-Path $TestDrive 'receipt.json' } -ParameterFilter {$Command -eq 'Resolve-GuideWorkspacePath'}
            Mock Invoke-OGPCore { [pscustomobject]@{Status='created';Path='site/guide.fr.pdf';EnvironmentSha256=$Arguments.EnvironmentSha256} } -ParameterFilter {$Command -eq 'New-GuidePdf'}
            Mock Invoke-OGPCore { [pscustomobject]@{Path=$Arguments.ReceiptPath} } -ParameterFilter {$Command -eq 'Save-GuidePdfReceipt'}
            $result=New-OGPPdf -GuideId guide -EditionId 2026 -Language fr -DownloadPath guide.fr.pdf
            $result.ReceiptPath | Should -Be 'receipt.json'
            $result.VisualReviewRequired | Should -BeTrue
            $result.ValidationRequired | Should -BeTrue
            Should -Invoke Invoke-OGPCore -Times 1 -Exactly -ParameterFilter {$Command -eq 'Save-GuidePdfReceipt' -and $Arguments.Receipt.EnvironmentSha256 -eq ('c'*64)}
        }

        It 'preserves an existing PDF instead of automatically regenerating it' {
            $pdf=Join-Path $TestDrive 'supplied.pdf';Set-Content $pdf 'protected bytes'
            Mock Invoke-OGPCore { [pscustomobject]@{Output=(Join-Path $TestDrive 'supplied.pdf')} } -ParameterFilter {$Command -eq 'Get-GuidePdfPlan'}
            { New-OGPPdf -GuideId guide -EditionId 2026 -Language fr -DownloadPath supplied.pdf } | Should -Throw '*already exists*'
            (Get-Content $pdf -Raw).Trim() | Should -Be 'protected bytes'
        }
    }
}
