BeforeAll {
    $root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Import-Module "$root/system/OpenGuidePlatform.PowerShell.Core/OpenGuidePlatform.PowerShell.Core.psd1" -Force
}
Describe 'Human-operated translation workflows' {
    BeforeEach {
        $workspace=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $policy=Get-Content "$root/tests/Contracts/fixtures/single-guide.site-policy.json" -Raw|ConvertFrom-Json -AsHashtable
        $policy.protectedPaths=@();$policy.guides[0].protectSource=$false
        $guide=$policy.guides[0];$edition=$guide.editions[0]
        $edition.sourceLanguage='es';$edition.translations[0].language='es'
        $edition.translations+=@{language='fr';intent='web';downloads=@()}
        $directory="$workspace/$($guide.contentRoot)/$($edition.path)"
        [IO.Directory]::CreateDirectory("$directory/pdf")|Out-Null
        $sourcePath="$directory/index.md";$targetPath="$directory/index.fr.md"
        $source="---`ntitle: Guía`nversion: 2024.8`ntype: guide`naliases: ['/guide/latest']`n---`n# Introducción`nTexto original.`n"
        $target="---`ntitle: Guide`nversion: 2024.8`ntype: guide`naliases: ['/guide/latest']`n---`n# Introduction`nTraduction existante.`n"
        [IO.File]::WriteAllText($sourcePath,$source)
        [IO.File]::WriteAllText($targetPath,$target)
        [IO.File]::WriteAllText("$workspace/site/hugo.production.yaml","languages:`n  es:`n    disabled: false`n  fr:`n    disabled: true`n  fa:`n    disabled: true`n")
        [IO.File]::WriteAllText("$directory/pdf/supplied.fr.pdf",'%PDF-protected fixture')
        $selection=@{WorkspaceRoot=$workspace;Policy=$policy;GuideId=$guide.id;EditionId=$edition.id;Language='fr'}
        $candidate=$target.Replace('title: Guide','title: Guide traduit').Replace('Traduction existante.','Traduction révisée.')
        $work=Get-GuideTranslationWork @selection
        $edit=$selection.Clone();$edit.CandidateContent=$candidate;$edit.ExpectedSha256=$work.Target.Sha256;$edit.ExpectedSourceSha256=$work.Source.Sha256
    }
    It 'reports source, target, wrapper work and an explicit lack of quality approval' {
        $work.SourceLanguage|Should -Be es
        $work.Source.Body|Should -Match 'Texto original'
        $work.Target.Body|Should -Match 'Traduction existante'
        $work.Comparison|Should -BeNullOrEmpty
        $work.Findings.Code|Should -Contain EFFECTIVE_READINESS_REQUIRED
        $work.TranslationQualityAssessed|Should -BeFalse
        $work.PublicationVerified|Should -BeFalse
    }
    It 'creates a missing translation through the retained scaffold without inventing inventory' {
        $new=$selection.Clone();$new.Language='fa'
        $before=(Get-FileHash $sourcePath).Hash
        $config=(Get-FileHash "$workspace/site/hugo.production.yaml").Hash
        (New-GuideTranslation @new -WhatIf).Status|Should -Be planned
        Test-Path "$directory/index.fa.md"|Should -BeFalse
        $created=New-GuideTranslation @new
        $created.Status|Should -Be created
        $created.Work.Target.Body|Should -BeNullOrEmpty
        $created.RefreshDiscoveryRequired|Should -BeTrue
        $created.Work.TargetDeclared|Should -BeFalse
        $created.Work.Findings.Code|Should -Contain REFRESH_DISCOVERY
        $policy.guides[0].editions[0].translations.Count|Should -Be 2
        (Get-FileHash $sourcePath).Hash|Should -Be $before
        (Get-FileHash "$workspace/site/hugo.production.yaml").Hash|Should -Be $config
        (New-GuideTranslation @new).Status|Should -Be preserved
    }
    It 'refuses new-language creation without explicit production exclusion' {
        $selection.Language='ja'
        {New-GuideTranslation @selection}|Should -Throw '*disabled*'
        Test-Path "$directory/index.ja.md"|Should -BeFalse
    }
    It 'previews and applies complete candidates while preserving source, configuration and PDFs' {
        $before=@{}
        foreach($path in @($sourcePath,"$workspace/site/hugo.production.yaml","$directory/pdf/supplied.fr.pdf")){$before[$path]=(Get-FileHash $path).Hash}
        (Test-GuideTranslation @selection -CandidateContent $candidate).Outcome|Should -Be review-required
        (Set-GuideTranslation @edit -WhatIf).Status|Should -Be planned
        [IO.File]::ReadAllText($targetPath)|Should -BeExactly $target
        $result=Set-GuideTranslation @edit
        $result.Status|Should -Be updated
        $result.VerificationRequired|Should -BeTrue
        [IO.File]::ReadAllText($targetPath)|Should -BeExactly $candidate
        foreach($path in $before.Keys){(Get-FileHash $path).Hash|Should -Be $before[$path]}
    }
    It 'preserves populated translations when asked to start them again' {
        (New-GuideTranslation @selection).Status|Should -Be preserved
        [IO.File]::ReadAllText($targetPath)|Should -BeExactly $target
    }
    It 'blocks stale source and target candidates' {
        [IO.File]::WriteAllText($sourcePath,$source+'new source')
        {Set-GuideTranslation @edit}|Should -Throw '*source changed*'
        [IO.File]::ReadAllText($targetPath)|Should -BeExactly $target
        [IO.File]::WriteAllText($sourcePath,$source)
        [IO.File]::WriteAllText($targetPath,$target+'another translator')
        {Set-GuideTranslation @edit}|Should -Throw '*target changed*'
        [IO.File]::ReadAllText($targetPath)|Should -BeExactly ($target+'another translator')
    }
    It 'blocks changes to structural metadata, lang, empty bodies and removed editorial fields' {
        foreach($invalid in @($candidate.Replace('2024.8','2025.1'),$candidate.Replace('/guide/latest','/downloads/'),$candidate.Replace('type: guide',"type: guide`nlang: fr"),$candidate.Replace('title: Guide traduit' + "`n",''),"---`ntitle: Guide`n---`n")){
            (Test-GuideTranslation @selection -CandidateContent $invalid).Outcome|Should -Be blocked
            $edit.CandidateContent=$invalid
            {Set-GuideTranslation @edit}|Should -Throw '*blocked*'
        }
        [IO.File]::ReadAllText($targetPath)|Should -BeExactly $target
    }
    It 'requires discovery refresh for existing but undeclared targets' {
        $edition.translations=@($edition.translations|Where-Object language -NE fr)
        (Test-GuideTranslation @selection -CandidateContent $candidate).Findings.Code|Should -Contain REFRESH_DISCOVERY
        {Set-GuideTranslation @edit}|Should -Throw '*rerun Prepare*'
    }
    It 'preserves intentional fallback and PDF-only intent without claiming publication readiness' {
        $edition.translations[1].intent='fallback';$edition.translations[1].fallbackLanguage='es'
        (Get-GuideTranslationWork @selection).TargetIntent|Should -Be fallback
        Set-GuideTranslation @edit|Out-Null
        $edition.translations[1].intent|Should -Be fallback
        $edition.translations[1].intent='pdf-only';$edition.translations[1].downloads=@(@{path='pdf/supplied.fr.pdf';handling='supplied'})
        $observed=Get-GuideTranslationWork @selection
        $observed.Findings.Code|Should -Contain DOWNLOAD_REVIEW_REQUIRED
        $observed.PublicationVerified|Should -BeFalse
    }
    It 'rejects protected targets and source-language selections' {
        $policy.protectedPaths=@("$($guide.contentRoot)/$($edition.path)/index.fr.md")
        {Set-GuideTranslation @edit}|Should -Throw '*protects*'
        $selection.Language='es'
        {Get-GuideTranslationWork @selection}|Should -Throw '*different*'
    }
    It 'provides heading differences as review findings without rewriting content' {
        $check=Test-GuideTranslation @selection -CandidateContent $candidate.Replace('# Introduction','## Introduction')
        $check.Outcome|Should -Be review-required
        $check.Findings.Code|Should -Contain HEADING_STRUCTURE_REVIEW
        $check.TranslationQualityAssessed|Should -BeFalse
        [IO.File]::ReadAllText($targetPath)|Should -BeExactly $target
    }
    It 'selects exact guide and edition identities when several are available' {
        $other=($guide|ConvertTo-Json -Depth 30|ConvertFrom-Json -AsHashtable)
        $other.id='another-guide';$other.contentRoot='site/content/another-guide'
        $policy.guides+=$other
        $extra=($edition|ConvertTo-Json -Depth 30|ConvertFrom-Json -AsHashtable)
        $extra.id='another-edition';$extra.path='another-edition';$guide.editions+=$extra
        (Get-GuideTranslationWork @selection).Target.Sha256|Should -Be $work.Target.Sha256
        $selection.EditionId='unknown'
        {Get-GuideTranslationWork @selection}|Should -Throw '*exactly one declared edition*'
    }
    It 'rejects a source conflict observed during staging and preserves the translation' {
        $script:sourceChecks=0
        Mock Get-FileHash -ModuleName OpenGuidePlatform.PowerShell.Core -ParameterFilter {[IO.Path]::GetFileName($LiteralPath) -eq 'index.md'} {
            $script:sourceChecks++
            [pscustomobject]@{Hash=if($script:sourceChecks -eq 1){$work.Source.Sha256}else{'0'*64}}
        }
        {Set-GuideTranslation @edit}|Should -Throw '*source changed during preparation*'
        [IO.File]::ReadAllText($targetPath)|Should -BeExactly $target
        @(Get-ChildItem $directory -Filter '*.candidate-*').Count|Should -Be 0
        @(Get-ChildItem $directory -Filter '*.content-lock').Count|Should -Be 0
    }
    It 'compares an explicit historical source with working changes, never inferring translator provenance' {
        & git init -q $workspace
        & git -C $workspace add .
        & git -C $workspace -c user.name=Test -c user.email=test@example.invalid commit -qm baseline
        if($LASTEXITCODE -ne 0){throw 'Cannot create Git history fixture.'}
        $commit=(& git -C $workspace rev-parse HEAD).Trim()
        [IO.File]::WriteAllText($sourcePath,$source.Replace('Texto original.','Texto cambiado.'))
        $compared=Get-GuideTranslationWork @selection -SourceRevision $commit
        $compared.Comparison.Commit|Should -Be $commit
        $compared.Comparison.Diff|Should -Match '\+Texto cambiado'
        $compared.Comparison.Diff|Should -Match '\-Texto original'
        $compared.Comparison.Changed|Should -BeTrue
        $compared.Comparison.Body|Should -Match 'Texto original'
        $compared.Target.Body|Should -Match 'Traduction existante'
        $compared.Comparison.Meaning|Should -Match 'not evidence'
        $edit.ExpectedSourceSha256=$compared.Source.Sha256;$edit.SourceRevision=$commit
        (Set-GuideTranslation @edit).Comparison.Commit|Should -Be $commit
        $currentRelative="$($guide.contentRoot)/$($edition.path)/index.md"
        $historical="$($guide.contentRoot)/$($edition.path)/previous-source.md"
        & git -C $workspace mv -- $currentRelative $historical
        & git -C $workspace -c user.name=Test -c user.email=test@example.invalid commit -qm moved-source
        if($LASTEXITCODE -ne 0){throw 'Cannot create renamed-source history fixture.'}
        $renamedCommit=(& git -C $workspace rev-parse HEAD).Trim()
        [IO.File]::WriteAllText($sourcePath,$source)
        (Get-GuideTranslationWork @selection -SourceRevision $renamedCommit -SourcePathAtRevision $historical).Comparison.Path|Should -Be $historical
        {Get-GuideTranslationWork @selection -SourceRevision nonexistent}|Should -Throw '*Git*'
        {Get-GuideTranslationWork @selection -SourceRevision $commit -SourcePathAtRevision '../outside.md'}|Should -Throw '*Unsafe*'
        {Get-GuideTranslationWork @selection -SourcePathAtRevision 'old.md'}|Should -Throw '*requires*'
    }
}
