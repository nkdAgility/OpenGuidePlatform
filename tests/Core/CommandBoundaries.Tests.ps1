BeforeAll {
    $root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Import-Module "$root/system/OpenGuidePlatform.PowerShell.Core/OpenGuidePlatform.PowerShell.Core.psd1" -Force
}
Describe 'Edition-specific command ownership' {
    BeforeEach {
        $workspace=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $policy=Get-Content "$root/tests/Contracts/fixtures/single-guide.site-policy.json" -Raw|ConvertFrom-Json -AsHashtable
        $policy.protectedPaths=@();$guide=$policy.guides[0];$guide.protectSource=$false
        $first=$guide.editions[0];$first.id='v1';$first.path='v1';$first.translations=@(@{language='en';intent='web';downloads=@()},@{language='fr';intent='web';downloads=@()})
        $second=@{id='v2';path='v2';sourceLanguage='es';translations=@(@{language='es';intent='web';downloads=@()},@{language='ja';intent='web';downloads=@()})}
        $guide.editions+= $second
        $prefix="---`ntitle: Guide`ntype: guide`n---`n"
        foreach($edition in $guide.editions){
            $directory="$workspace/$($guide.contentRoot)/$($edition.path)"
            [IO.Directory]::CreateDirectory($directory)|Out-Null
            foreach($translation in $edition.translations){
                $file=if($translation.language -eq $edition.sourceLanguage){'index.md'}else{"index.$($translation.language).md"}
                [IO.File]::WriteAllText("$directory/$file",$prefix+"$($edition.id) $($translation.language) body")
            }
        }
        [IO.File]::WriteAllText("$workspace/site/hugo.production.yaml","languages:`n  fr:`n    disabled: true`n")
        [IO.File]::WriteAllText("$workspace/$($guide.contentRoot)/v1/supplied.pdf",'%PDF-preserve')
        $first.translations[1].downloads=@(@{path='supplied.pdf';handling='supplied'})
        $before=@{}
        foreach($file in Get-ChildItem $workspace -Recurse -File){$before[$file.FullName]=(Get-FileHash $file.FullName).Hash}
        $selection=@{WorkspaceRoot=$workspace;Policy=$policy;GuideId=$guide.id;EditionId='v1';Language='fr'}
        $work=Get-GuideTranslationWork @selection
    }
    It 'rejects source-edit commands for a translation before writing, including WhatIf' {
        foreach($preview in @($false,$true)){
            {Set-GuideContent @selection -CandidateBody 'Wrong command' -ExpectedSha256 $work.Target.Sha256 -WhatIf:$preview}|Should -Throw '*Set-GuideTranslation*'
        }
        foreach($file in $before.Keys){(Get-FileHash $file).Hash|Should -Be $before[$file]}
    }
    It 'rejects translation and wrapper commands for a source document' {
        $selection.Language='en'
        {Set-GuideTranslation @selection -CandidateContent $work.Source.Content -ExpectedSha256 $work.Source.Sha256 -ExpectedSourceSha256 $work.Source.Sha256}|Should -Throw '*Set-GuideContent*'
        {New-GuideTranslationScaffold @selection}|Should -Throw '*source language*'
        {Set-GuideWrapperTranslation -WorkspaceRoot $workspace -Policy $policy -Language en -RelativePath $work.Source.Path -ExpectedSha256 $work.Source.Sha256 -CandidateContent $work.Source.Content}|Should -Throw '*guide content*'
        foreach($file in $before.Keys){(Get-FileHash $file).Hash|Should -Be $before[$file]}
    }
    It 'does not borrow a translation from another edition and creates only the requested missing edition' {
        $selection.EditionId='v2'
        $missing=Get-GuideTranslationWork @selection
        $missing.Target|Should -BeNullOrEmpty
        $missing.TargetDeclared|Should -BeFalse
        {Set-GuideTranslation @selection -CandidateContent $work.Target.Content -ExpectedSha256 $work.Target.Sha256 -ExpectedSourceSha256 $missing.Source.Sha256}|Should -Throw '*New-GuideTranslation*'
        Test-Path "$workspace/$($guide.contentRoot)/v2/index.fr.md"|Should -BeFalse
        foreach($file in $before.Keys){(Get-FileHash $file).Hash|Should -Be $before[$file]}
        (New-GuideTranslation @selection).Status|Should -Be created
        (Read-GuideDocument "$workspace/$($guide.contentRoot)/v2/index.fr.md").Body|Should -BeNullOrEmpty
        foreach($file in $before.Keys){(Get-FileHash $file).Hash|Should -Be $before[$file]}
        $second.translations.language|Should -Not -Contain fr
    }
    It 'updates an existing translation without requiring it in other editions' {
        $candidate=$work.Target.Content+' corrected'
        (Set-GuideTranslation @selection -CandidateContent $candidate -ExpectedSha256 $work.Target.Sha256 -ExpectedSourceSha256 $work.Source.Sha256).Status|Should -Be updated
        Test-Path "$workspace/$($guide.contentRoot)/v2/index.fr.md"|Should -BeFalse
        $target=[IO.Path]::GetFullPath("$workspace/$($work.TargetPath)")
        foreach($file in $before.Keys){if($file -ne $target){(Get-FileHash $file).Hash|Should -Be $before[$file]}}
    }
    It 'uses each edition source language independently' {
        $selection.EditionId='v2';$selection.Language='es'
        $source=Get-GuideContent @selection
        (Set-GuideContent @selection -CandidateBody 'Corrected Spanish source' -ExpectedSha256 $source.Sha256).Status|Should -Be updated
        $target=[IO.Path]::GetFullPath("$workspace/$($source.Path)")
        foreach($file in $before.Keys){if($file -ne $target){(Get-FileHash $file).Hash|Should -Be $before[$file]}}
    }
    It 'does not suggest translation scaffolding to replace a missing source' {
        $selection.Language='en'
        $sourceFile=[IO.Path]::GetFullPath("$workspace/$($work.Source.Path)")
        [IO.File]::Delete($sourceFile)
        {Set-GuideContent @selection -CandidateBody 'Source' -ExpectedSha256 $work.Source.Sha256}|Should -Throw '*Restore or create the selected edition source*'
        Test-Path $sourceFile|Should -BeFalse
        foreach($file in $before.Keys){if($file -ne $sourceFile){(Get-FileHash $file).Hash|Should -Be $before[$file]}}
    }
    It 'retains both creation command names without replacing populated translations' {
        (New-GuideTranslation @selection).Status|Should -Be preserved
        (New-GuideTranslationScaffold @selection).Status|Should -Be preserved
        foreach($file in $before.Keys){(Get-FileHash $file).Hash|Should -Be $before[$file]}
    }
    It 'rejects PDF generation against supplied PDFs or guide Markdown before invoking rendering' {
        {New-GuidePdf @selection -DownloadPath supplied.pdf}|Should -Throw '*supplied and protected*'
        $first.translations[1].downloads+=@{path='index.fr.md';handling='generated'}
        {New-GuidePdf @selection -DownloadPath index.fr.md}|Should -Throw '*.pdf extension*'
        {Set-GuideWrapperTranslation -WorkspaceRoot $workspace -Policy $policy -Language fr -RelativePath $work.TargetPath -ExpectedSha256 $work.Target.Sha256 -CandidateContent $work.Target.Content}|Should -Throw '*guide content*'
        foreach($file in $before.Keys){(Get-FileHash $file).Hash|Should -Be $before[$file]}
    }
    It 'enforces destination and dependency ownership inside the shared writer' {
        $base=@{WorkspaceRoot=$workspace;Policy=$policy;GuideId=$guide.id;EditionId='v1';Language='fr';Operation='Translation';RelativePath=$work.TargetPath;CandidateBytes=[Text.Encoding]::UTF8.GetBytes('wrong');ExpectedSha256=$work.Target.Sha256;SourcePath=$work.Source.Path;ExpectedSourceSha256=$work.Source.Sha256}
        $cases=@(
            @{Operation='Source'},
            @{RelativePath=$work.Source.Path},
            @{SourcePath="$($guide.contentRoot)/v2/index.md"},
            @{RelativePath="$($guide.contentRoot)/v2/index.ja.md"},
            @{RelativePath="$($guide.contentRoot)/v1/supplied.pdf"},
            @{RelativePath='site/hugo.production.yaml'},
            @{ExpectedSourceSha256=''}
        )
        foreach($change in $cases){
            $attempt=$base.Clone();foreach($key in $change.Keys){$attempt[$key]=$change[$key]}
            {& (Get-Module OpenGuidePlatform.PowerShell.Core) {param($arguments) Write-GuideReviewedFile @arguments} $attempt}|Should -Throw
            foreach($file in $before.Keys){(Get-FileHash $file).Hash|Should -Be $before[$file]}
        }
        @(Get-ChildItem $workspace -Filter '*.content-lock' -Recurse).Count|Should -Be 0
        @(Get-ChildItem $workspace -Filter '*.candidate-*' -Recurse).Count|Should -Be 0
    }
}
