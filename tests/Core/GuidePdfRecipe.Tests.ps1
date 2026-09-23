BeforeAll {
    $root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Import-Module (Join-Path $root 'system/OpenGuidePlatform.PowerShell.Core/OpenGuidePlatform.PowerShell.Core.psd1') -Force
    function Write-Fixture($relative,$text){$path=Join-Path $workspace $relative;[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path))|Out-Null;[IO.File]::WriteAllText($path,$text)}
    function Get-Variable($plan,$name){for($i=0;$i -lt $plan.Arguments.Count-1;$i++){if($plan.Arguments[$i] -eq '-V' -and $plan.Arguments[$i+1] -like "$name=*"){return $plan.Arguments[$i+1].Substring($name.Length+1)}}}
}
Describe 'Layered PDF recipe' {
    BeforeEach {
        $policy=Get-Content -Raw (Join-Path $root 'tests/Contracts/fixtures/single-guide.site-policy.json')|ConvertFrom-Json -AsHashtable
        $policy.protectedPaths=@();$policy.guides[0].protectSource=$false
        $guide=$policy.guides[0];$edition=$guide.editions[0]
        $edition.translations=@(
            @{language='en';intent='web';downloads=@(@{path='pdf/guide.en.pdf';handling='generated'})},
            @{language='fa';intent='web';downloads=@(@{path='pdf/guide.fa.pdf';handling='generated'})})
        $policy.wrapper.languageDirections=@{fa='rtl'}
        $workspace=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $content="$($guide.contentRoot)/$($edition.path)"
        $pdf="site/pdf";$guidePdf="$pdf/$($guide.id)";$editionPdf="$guidePdf/$($edition.path)"
        Write-Fixture "$content/index.md" "---`ntitle: Example Guide`nshort_title: Example`ndate: 2024-08-01`n---`nBody"
        Write-Fixture "$content/index.fa.md" "---`ntitle: راهنمای نمونه`n---`nمتن"
        Write-Fixture "site/data/contributions/$($guide.id).yml" "- name: Jane Author`n  role: creator`n  contributions: [`"$($edition.id)`"]`n"
        Write-Fixture "site/data/contributions/$($guide.id).fa.yml" "- name: Parisa Translator`n  role: translator`n  contributions: [`"$($edition.id)`"]`n"
        Write-Fixture "$pdf/pdf.yaml" "mainfont: Site Serif`nsansfont: Site Sans`nlicence: CC BY-SA 4.0`n"
        Write-Fixture "$guidePdf/pdf.fa.yaml" "mainfont: Persian Serif`n"
        Write-Fixture "$editionPdf/pdf.yaml" "papersize: letter`ndownloads:`n  - path: pdf/guide.en.pdf`n    handling: generated`n    fontsize: 12pt`n"
    }
    It 'merges platform, site, guide, edition, language and download settings' {
        $en=Get-GuidePdfPlan $workspace $policy $guide.id $edition.id en 'pdf/guide.en.pdf'
        Get-Variable $en mainfont | Should -Be 'Site Serif'
        Get-Variable $en papersize | Should -Be 'letter'
        Get-Variable $en fontsize | Should -Be '12pt'
        Get-Variable $en geometry | Should -Be 'margin=2.2cm' -Because 'the platform default applies'
        $en.Fonts.mainfont | Should -Be 'Site Serif'
        $fa=Get-GuidePdfPlan $workspace $policy $guide.id $edition.id fa 'pdf/guide.fa.pdf'
        Get-Variable $fa mainfont | Should -Be 'Persian Serif'
        Get-Variable $fa sansfont | Should -Be 'Site Sans'
        Get-Variable $fa fontsize | Should -Be '11pt' -Because 'download overrides apply only to that download'
        @($fa.Recipe|Where-Object Kind -eq settings|ForEach-Object Path) | Should -Contain "$guidePdf/pdf.fa.yaml"
        $fa.Fingerprints.Path | Should -Contain "$guidePdf/pdf.fa.yaml"
    }
    It 'builds cover metadata from contributor data and suppresses the document title block' {
        $plan=Get-GuidePdfPlan $workspace $policy $guide.id $edition.id en 'pdf/guide.en.pdf'
        $plan.Metadata.title | Should -Be 'Example Guide'
        $plan.Metadata.short_title | Should -Be 'Example'
        $plan.Metadata.date | Should -Be '2024-08-01'
        $plan.Metadata.authors[0].name | Should -Be 'Jane Author'
        $plan.Metadata.licence | Should -Be 'CC BY-SA 4.0'
        $plan.Metadata.labels.authors | Should -Be 'Authors'
        $plan.Metadata.Contains('dir') | Should -BeFalse
        $plan.Arguments | Should -Contain 'title='
        $plan.Arguments | Should -Contain 'lang=en'
        $plan.Fingerprints.Path | Should -Contain "site/data/contributions/$($guide.id).yml"
    }
    It 'marks Latin credits left-to-right in right-to-left documents and adds RTL support' {
        Write-Fixture 'site/i18n/fa.yaml' "- id: pdf_translators_label`n  translation: مترجمان`n"
        $plan=Get-GuidePdfPlan $workspace $policy $guide.id $edition.id fa 'pdf/guide.fa.pdf'
        $plan.Metadata.dir | Should -Be 'rtl'
        $plan.Metadata.translators[0].name | Should -Be "[Parisa Translator$([char]0x200E)]{dir=ltr}"
        $plan.Metadata.labels.translators | Should -Be 'مترجمان'
        $plan.Metadata.title | Should -Be 'راهنمای نمونه'
        @($plan.Includes|Where-Object Part -eq 'rtl').Count | Should -Be 1
        $plan.Fingerprints.Path | Should -Contain 'site/i18n/fa.yaml'
    }
    It 'uses the most specific template for each part and places parts around the body' {
        Write-Fixture "$pdf/cover.tex" 'site cover $title$'
        Write-Fixture "$guidePdf/cover.fa.tex" 'guide persian cover'
        $en=Get-GuidePdfPlan $workspace $policy $guide.id $edition.id en 'pdf/guide.en.pdf'
        ($en.Includes|Where-Object Part -eq cover).Path | Should -Be (Join-Path $workspace "$pdf/cover.tex")
        $fa=Get-GuidePdfPlan $workspace $policy $guide.id $edition.id fa 'pdf/guide.fa.pdf'
        ($fa.Includes|Where-Object Part -eq cover).Path | Should -Be (Join-Path $workspace "$guidePdf/cover.fa.tex")
        @($en.Includes|ForEach-Object {"$($_.Placement):$($_.Part)"}) | Should -Be @('header:style','header:page-header','header:page-footer','header:filter:callouts','before:cover','before:licence','before:body-start','after:back')
        Write-Fixture "$editionPdf/pdf.yaml" "parts: [body]`n"
        @((Get-GuidePdfPlan $workspace $policy $guide.id $edition.id en 'pdf/guide.en.pdf').Includes|Where-Object Placement -ne header).Count | Should -Be 0
    }
    It 'replaces a platform filter by name and adds site filters with their preamble' {
        Write-Fixture "$pdf/filters/callouts.lua" '-- site callouts'
        Write-Fixture "$guidePdf/filters/glossary.lua" '-- glossary'
        Write-Fixture "$guidePdf/filters/glossary.tex" '% glossary preamble'
        $plan=Get-GuidePdfPlan $workspace $policy $guide.id $edition.id en 'pdf/guide.en.pdf'
        $filters=@(for($i=0;$i -lt $plan.Arguments.Count;$i++){if($plan.Arguments[$i] -eq '--lua-filter'){$plan.Arguments[$i+1]}})
        $filters | Should -Contain (Join-Path $workspace "$pdf/filters/callouts.lua")
        $filters | Should -Contain (Join-Path $workspace "$guidePdf/filters/glossary.lua")
        @($filters|Where-Object {$_ -like '*hugo-images.lua'}).Count | Should -Be 1
        @($plan.Includes|Where-Object Part -eq 'filter:callouts').Count | Should -Be 0 -Because 'the site callouts filter has no companion preamble'
        ($plan.Includes|Where-Object Part -eq 'filter:glossary').Path | Should -Be (Join-Path $workspace "$guidePdf/filters/glossary.tex")
    }
    It 'refuses unknown settings, misplaced downloads and PDF keys in front matter' {
        Write-Fixture "$pdf/pdf.yaml" "mainfont: X`ncolour: red`n"
        { Get-GuidePdfPlan $workspace $policy $guide.id $edition.id en 'pdf/guide.en.pdf' } | Should -Throw "*Unknown PDF setting 'colour'*"
        Write-Fixture "$pdf/pdf.yaml" "downloads:`n  - path: pdf/x.pdf`n"
        { Get-GuidePdfPlan $workspace $policy $guide.id $edition.id en 'pdf/guide.en.pdf' } | Should -Throw '*edition folder*'
        Write-Fixture "$pdf/pdf.yaml" "mainfont: X`n"
        Write-Fixture "$content/index.md" "---`ntitle: Example`nmainfont: Old`n---`nBody"
        { Get-GuidePdfPlan $workspace $policy $guide.id $edition.id en 'pdf/guide.en.pdf' } | Should -Throw '*no longer read*'
    }
    It 'reports declared downloads and invalid settings for discovery and Prepare' {
        $declared=@(Get-GuidePdfDeclaredDownloads -SourceDirectory (Join-Path $workspace 'site') -GuideId $guide.id -EditionPath $edition.path)
        $declared.Count | Should -Be 1
        $declared[0].Path | Should -Be 'pdf/guide.en.pdf'
        $declared[0].Handling | Should -Be 'generated'
        Write-Fixture "$pdf/unknown-guide/pdf.yaml" "mainfont: X`n"
        Write-Fixture "$guidePdf/pdf.yaml" "downloads: []`n"
        $findings=@(InModuleScope OpenGuidePlatform.PowerShell.Core -Parameters @{Workspace=$workspace;Policy=$policy} {param($Workspace,$Policy) Get-GuidePdfSettingFindings $Workspace $Policy})
        @($findings|Where-Object Code -eq PDF_SETTINGS_INVALID).Count | Should -Be 2
        @($findings|Where-Object Code -eq PDF_LABEL_MISSING).Subject | Should -Be 'site/i18n/fa'
    }
}
Describe 'Rendering template parts' {
    BeforeEach {
        $policy=Get-Content -Raw (Join-Path $root 'tests/Contracts/fixtures/single-guide.site-policy.json')|ConvertFrom-Json -AsHashtable
        $policy.protectedPaths=@();$policy.guides[0].protectSource=$false
        $guide=$policy.guides[0];$edition=$guide.editions[0]
        $edition.translations[0].downloads=@(@{path='pdf/guide.pdf';handling='generated'})
        $workspace=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        Write-Fixture "$($guide.contentRoot)/$($edition.path)/index.md" "---`ntitle: Example`n---`nBody"
        Mock Get-GuidePdfToolchain -ModuleName OpenGuidePlatform.PowerShell.Core { @([pscustomobject]@{Tool='pandoc';Available=$true},[pscustomobject]@{Tool='xelatex';Available=$true}) }
        Mock Get-Command -ModuleName OpenGuidePlatform.PowerShell.Core -ParameterFilter { $Name -eq 'fc-list' } { $null }
        $script:calls=[Collections.Generic.List[object]]::new()
        Mock Invoke-GuidePandoc -ModuleName OpenGuidePlatform.PowerShell.Core { param($Arguments) $script:calls.Add(@($Arguments));[IO.File]::WriteAllText($Arguments[-1],'%PDF-rendered');0 }
    }
    It 'renders each template part with the metadata before the main run' {
        $result=New-GuidePdf $workspace $policy $guide.id $edition.id en 'pdf/guide.pdf'
        $result.Status | Should -Be created
        $plan=Get-GuidePdfPlan $workspace $policy $guide.id $edition.id en 'pdf/guide.pdf'
        $templates=@($plan.Includes|Where-Object Template)
        $script:calls.Count | Should -Be ($templates.Count+1)
        foreach($call in $script:calls[0..($templates.Count-1)]){ $call | Should -Contain '--template';$call | Should -Contain '--metadata-file' }
        $main=$script:calls[-1]
        $main | Should -Contain '--metadata-file'
        @($main|Where-Object {$_ -in @('--include-in-header','--include-before-body','--include-after-body')}).Count | Should -Be $plan.Includes.Count
        @(Get-ChildItem (Join-Path $workspace "$($guide.contentRoot)/$($edition.path)/pdf") -Force).Count | Should -Be 1 -Because 'staging is removed'
    }
}
