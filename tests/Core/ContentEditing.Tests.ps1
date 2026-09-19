BeforeAll {
    $root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Import-Module "$root/system/OpenGuidePlatform.PowerShell.Core/OpenGuidePlatform.PowerShell.Core.psd1" -Force
}
Describe 'Human-operated guide content corrections' {
    BeforeEach {
        $workspace=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $policy=Get-Content "$root/tests/Contracts/fixtures/single-guide.site-policy.json" -Raw|ConvertFrom-Json -AsHashtable
        $policy.protectedPaths=@();$policy.guides[0].protectSource=$false
        $guide=$policy.guides[0];$edition=$guide.editions[0]
        $directory="$workspace/$($guide.contentRoot)/$($edition.path)"
        [IO.Directory]::CreateDirectory("$directory/pdf")|Out-Null
        $prefix="---`r`n# Preserve comments and spelling`r`ntitle: 'A guide'`r`nversion: 2024.8`r`naliases: ['/existing/']`r`n---`r`n"
        $original=$prefix+"Original body café.`r`n"
        [IO.File]::WriteAllText("$directory/index.md",$original,[Text.UTF8Encoding]::new($true))
        $pdf="$directory/$($edition.translations[0].downloads[0].path)"
        [IO.File]::WriteAllText($pdf,'%PDF-supplied-preserve')
        $edition.translations+=@{language='fr';intent='web';downloads=@()}
        [IO.File]::WriteAllText("$directory/index.fr.md",$prefix+'Texte français.')
        $edition.translations+=@{language='ja';intent='scaffold';downloads=@()}
        $select=@{WorkspaceRoot=$workspace;Policy=$policy;GuideId=$guide.id;EditionId=$edition.id;Language='en'}
        $document=Get-GuideContent @select
        $edit=$select.Clone();$edit.ExpectedSha256=$document.Sha256;$edit.CandidateBody="Corrected body café.`r`n"
    }
    It 'supports discover, select, preview, apply and reread without an agent' {
        $all=@(Get-GuideContent -WorkspaceRoot $workspace -Policy $policy)
        $all.Count|Should -Be 3
        ($all|Where-Object Language -EQ ja).Exists|Should -BeFalse
        $before=[IO.File]::ReadAllBytes("$directory/index.md")
        $translationHash=(Get-FileHash "$directory/index.fr.md").Hash
        $pdfHash=(Get-FileHash $pdf).Hash
        (Set-GuideContent @edit -WhatIf).Status|Should -Be planned
        (Get-FileHash "$directory/index.md").Hash|Should -Be $document.Sha256
        $result=Set-GuideContent @edit
        $result.Status|Should -Be updated
        $result.VerificationRequired|Should -BeTrue
        $after=[IO.File]::ReadAllBytes("$directory/index.md")
        $prefixLength=3+[Text.Encoding]::UTF8.GetByteCount($prefix)
        [Convert]::ToBase64String($after[0..($prefixLength-1)])|Should -Be ([Convert]::ToBase64String($before[0..($prefixLength-1)]))
        (Get-GuideContent @select).Body|Should -Be $edit.CandidateBody
        (Get-GuideContent @select).Sha256|Should -Be $result.CandidateSha256
        (Get-FileHash "$directory/index.fr.md").Hash|Should -Be $translationHash
        (Get-FileHash $pdf).Hash|Should -Be $pdfHash
        @(Get-ChildItem $directory -Filter '*.content-lock').Count|Should -Be 0
        @(Get-ChildItem $directory -Filter '*.candidate-*').Count|Should -Be 0
    }
    It 'retains stable existing files for unchanged bodies' {
        $edit.CandidateBody=$document.Body
        (Set-GuideContent @edit).Status|Should -Be unchanged
        (Get-FileHash "$directory/index.md").Hash|Should -Be $document.Sha256
    }
    It 'rejects stale candidates without overwriting subsequent edits' {
        [IO.File]::WriteAllText("$directory/index.md",$prefix+'Another editor changed this.')
        {Set-GuideContent @edit}|Should -Throw '*changed since review*'
        (Read-GuideDocument "$directory/index.md").Body|Should -Be 'Another editor changed this.'
    }
    It 'reports protected content and refuses mutation even with WhatIf' {
        $policy.guides[0].protectSource=$true
        (Get-GuideContent @select).WriteAllowed|Should -BeFalse
        {Set-GuideContent @edit -WhatIf}|Should -Throw '*PROTECTED_RESOURCE*'
        (Get-FileHash "$directory/index.md").Hash|Should -Be $document.Sha256
    }
    It 'rejects unmatched identifiers, missing documents and blank bodies' {
        $edit.GuideId='does-not-exist'
        {Set-GuideContent @edit}|Should -Throw '*No discovered*'
        $edit.GuideId=$guide.id;$edit.Language='ja'
        {Set-GuideContent @edit}|Should -Throw '*missing*'
        $edit.Language='en';$edit.CandidateBody=" `r`n "
        {Set-GuideContent @edit}|Should -Throw '*nonempty body*'
        (Get-FileHash "$directory/index.md").Hash|Should -Be $document.Sha256
    }
    It 'supports multiple guides and exact selection without choosing the first match' {
        $second=($guide|ConvertTo-Json -Depth 30|ConvertFrom-Json -AsHashtable)
        $second.id='another-guide';$second.contentRoot='site/content/another-guide'
        $policy.guides+= $second
        @(Get-GuideContent -WorkspaceRoot $workspace -Policy $policy -Language en).Count|Should -Be 2
        (Get-GuideContent @select).GuideId|Should -Be $guide.id
        $edit.GuideId=$guide.id.ToUpperInvariant()
        {Set-GuideContent @edit}|Should -Throw '*No discovered*'
    }
    It 'does not bypass an existing cooperative lock' {
        [IO.File]::WriteAllText("$directory/index.md.content-lock",'another operation')
        {Set-GuideContent @edit}|Should -Throw
        (Get-FileHash "$directory/index.md").Hash|Should -Be $document.Sha256
        [IO.File]::ReadAllText("$directory/index.md.content-lock")|Should -Be 'another operation'
    }
    It 'rejects a conflict observed immediately before replacement and cleans staging' {
        Mock Get-FileHash -ModuleName OpenGuidePlatform.PowerShell.Core { [pscustomobject]@{Hash=('0'*64)} }
        {Set-GuideContent @edit}|Should -Throw '*changed during preparation*'
        (Get-FileHash "$directory/index.md").Hash|Should -Be $document.Sha256
        @(Get-ChildItem $directory -Filter '*.content-lock').Count|Should -Be 0
        @(Get-ChildItem $directory -Filter '*.candidate-*').Count|Should -Be 0
    }
    It 'provides discoverable command help' {
        (Get-Help Set-GuideContent).Synopsis|Should -Match 'reviewed body correction'
        (Get-Help Get-GuideContent).examples.example.Count|Should -BeGreaterThan 0
    }
}
