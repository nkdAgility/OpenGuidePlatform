BeforeAll {
    $root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Import-Module (Join-Path $root 'system/OpenGuidePlatform.PowerShell.Core/OpenGuidePlatform.PowerShell.Core.psd1') -Force
    function Find-ContributorIssues($Workspace,$Policy){InModuleScope OpenGuidePlatform.PowerShell.Core -Parameters @{Workspace=$Workspace;Policy=$Policy} {param($Workspace,$Policy) Get-GuideContributorFindings $Workspace $Policy}}
    function Write-Fixture($relative,$text){$path=Join-Path $workspace $relative;[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path))|Out-Null;[IO.File]::WriteAllText($path,$text)}
}
Describe 'Contributor records and credits' {
    BeforeEach {
        $policy=Get-Content -Raw (Join-Path $root 'tests/Contracts/fixtures/single-guide.site-policy.json')|ConvertFrom-Json -AsHashtable
        $policy.protectedPaths=@()
        $guide=$policy.guides[0];$edition=$guide.editions[0]
        $guide.id='example'
        $edition.translations=@(@{language='en';intent='web';downloads=@()},@{language='fa';intent='web';downloads=@()},@{language='es-ES';intent='web';downloads=@()})
        $edition.sourceLanguage='en'
        $editionId=[string]$edition.id
        $guide.editions=@($edition)+@(@{id='1999.1';path='1999.1';sourceLanguage='en';translations=@(@{language='en';intent='web';downloads=@()})})
        $workspace=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $data="$($policy.wrapper.sourcePath)/data/contributions"
        Write-Fixture "$data/example.yml" @"
- name: Zoe Creator
  role: creator
  contributions: ["$editionId"]
  weight: 2
- name: Adam Creator
  role: creator
  contributions: ["$editionId"]
  weight: 1
  localizedNames:
    fa: آدام
- name: Rita Reviewer
  githubUsername: rita
  role: reviewer
  contributions: ["$editionId"]
- name: Earlier Person
  role: contributor
  contributions: ["1999.1"]
- name: Ivy Involved
  role: involved
  contributions: ["$editionId"]
"@
        Write-Fixture "$data/example.fa.yml" "- name: Parisa Translator`n  role: translator`n  contributions: [`"$editionId`"]`n- name: Omid Reviewer`n  role: reviewer`n  contributions: [`"$editionId`"]`n"
    }
    It 'resolves authors, contributors and translators for one edition and language' {
        $credits=Get-GuideCredits $workspace $policy example $editionId fa
        @($credits.Authors|ForEach-Object {$_.name}) | Should -Be @('آدام','Zoe Creator')
        @($credits.Contributors|ForEach-Object {$_.name}) | Should -Be @('Rita Reviewer')
        $credits.Contributors[0].url | Should -Be 'https://github.com/rita'
        @($credits.Translators|ForEach-Object {$_.name}) | Should -Be @('Parisa Translator')
        $credits.Files | Should -Contain "$data/example.fa.yml"
    }
    It 'omits translators for the source language and honours selected roles' {
        $credits=Get-GuideCredits $workspace $policy example $editionId en -ContributorRoles @('reviewer','involved') -TranslatorRoles @('translator','reviewer')
        @($credits.Authors|ForEach-Object {$_.name}) | Should -Be @('Adam Creator','Zoe Creator')
        @($credits.Contributors|ForEach-Object {$_.name}) | Should -Be @('Rita Reviewer','Ivy Involved') -Because 'equal weights keep the data file order'
        @($credits.Translators).Count | Should -Be 0
    }
    It 'creates and updates a translation team file' {
        (New-GuideContributions $workspace $policy example @(@{name='Sofia';role='translator';contributions=@($editionId)}) -Language es-ES).Path | Should -Be "$data/example.es-ES.yml"
        { New-GuideContributions $workspace $policy example @(@{name='Other';role='creator';contributions=@($editionId)}) -Language fr } | Should -Throw '*not allowed*'
        $path=Join-Path $workspace "$data/example.fa.yml"
        $original=[IO.File]::ReadAllText($path)
        $candidate=$original.Replace("role: translator`n  contributions","role: translator`n  weight: 3`n  contributions")
        $result=Update-GuideContributions $workspace $policy example 'Parisa Translator' (Get-FileHash $path).Hash $candidate -Language fa
        $result.Status | Should -Be updated
        $result.Path | Should -Be "$data/example.fa.yml"
        [IO.File]::ReadAllText($path) | Should -BeExactly $candidate
    }
    It 'reports no findings for valid data' {
        @(Find-ContributorIssues $workspace $policy|Where-Object Severity -eq blocker).Count | Should -Be 0
    }
    It 'appends one reviewer while preserving comments, BOM, line endings and every original byte' {
        $path=Join-Path $workspace "$data/example.fa.yml"
        $original=[char]0xFEFF+"# Keep this comment`r`n"+[IO.File]::ReadAllText($path).Replace("`n","`r`n").TrimEnd()
        [IO.File]::WriteAllText($path,$original,[Text.UTF8Encoding]::new($false))
        $hash=(Get-FileHash $path).Hash
        $candidate=$original+"`r`n- name: New Reviewer`r`n  role: reviewer`r`n  contributions: [`"$editionId`"]`r`n"
        Add-GuideContribution $workspace $policy example fa $hash $candidate -WhatIf
        (Get-FileHash $path).Hash | Should -Be $hash
        $result=Add-GuideContribution $workspace $policy example fa $hash $candidate
        $result.Status | Should -Be appended
        [IO.File]::ReadAllBytes($path) | Should -Be ([Text.UTF8Encoding]::new($false).GetBytes($candidate))
        @(Find-ContributorIssues $workspace $policy|Where-Object Severity -eq blocker).Count | Should -Be 0
    }
    It 'rejects an extra YAML document in the candidate without changing the file' {
        $path=Join-Path $workspace "$data/example.fa.yml"
        $original=[IO.File]::ReadAllText($path);$hash=(Get-FileHash $path).Hash
        $candidate=$original+"- name: New Reviewer`n  role: reviewer`n  contributions: [`"$editionId`"]`n---`n- name: Hidden Contributor`n"
        {Add-GuideContribution $workspace $policy example fa $hash $candidate} | Should -Throw '*exactly one YAML document*'
        (Get-FileHash $path).Hash | Should -Be $hash
        [IO.File]::ReadAllText($path) | Should -BeExactly $original
    }
    It 'rejects an existing multi-document source without changing the file' {
        $path=Join-Path $workspace "$data/example.fa.yml"
        $original=[IO.File]::ReadAllText($path)+"---`n- name: Hidden Contributor`n"
        [IO.File]::WriteAllText($path,$original)
        $hash=(Get-FileHash $path).Hash
        $candidate=$original+"- name: New Reviewer`n  role: reviewer`n  contributions: [`"$editionId`"]`n"
        {Add-GuideContribution $workspace $policy example fa $hash $candidate} | Should -Throw '*exactly one YAML document*'
        (Get-FileHash $path).Hash | Should -Be $hash
        [IO.File]::ReadAllText($path) | Should -BeExactly $original
    }
    It 'rejects unsafe contributor appends without changing the file' {
        $path=Join-Path $workspace "$data/example.fa.yml"
        $original=[IO.File]::ReadAllText($path);$hash=(Get-FileHash $path).Hash
        $suffix="- name: New Reviewer`n  role: reviewer`n  contributions: [`"$editionId`"]`n"
        {Add-GuideContribution $workspace $policy example fa ('0'*64) ($original+$suffix)} | Should -Throw '*changed since review*'
        {Add-GuideContribution $workspace $policy example fa $hash ($original.Replace('Parisa','Changed')+$suffix)} | Should -Throw '*existing byte*'
        {Add-GuideContribution $workspace $policy example fa $hash ($original+$suffix+$suffix)} | Should -Throw '*exactly one*'
        {Add-GuideContribution $workspace $policy example fa $hash ($original+$suffix.Replace('New Reviewer','Parisa Translator'))} | Should -Throw '*identity already exists*'
        {Add-GuideContribution $workspace $policy example fa $hash ($original+$suffix.Replace('role: reviewer','role: creator'))} | Should -Throw '*allowed translation role*'
        {Add-GuideContribution $workspace $policy example fa $hash ($original+$suffix.Replace($editionId,'2099.9'))} | Should -Throw '*existing guide editions*'
        {Add-GuideContribution $workspace $policy example fa $hash ($original+$suffix+"  localizedNames: wrong`n")} | Should -Throw '*localizedNames*'
        $policy.protectedPaths=@("$data/example.fa.yml")
        {Add-GuideContribution $workspace $policy example fa $hash ($original+$suffix)} | Should -Throw
        (Get-FileHash $path).Hash | Should -Be $hash
    }
    It 'reports invalid roles, unknown editions, duplicates and unknown files' {
        Write-Fixture "$data/example.es-ES.yml" "- name: Ana`n  role: Translator`n  contributions: [`"$editionId`"]`n- name: Ana`n  role: translator`n  contributions: [`"2030.1`"]`n"
        Write-Fixture "$data/unknown-guide.yml" "- name: Nobody`n  role: creator`n  contributions: [`"$editionId`"]`n"
        Write-Fixture "$data/example.ja.yml" "- name: Kenji`n  role: translator`n  contributions: [`"$editionId`"]`n"
        $codes=@(Find-ContributorIssues $workspace $policy|ForEach-Object Code)
        $codes | Should -Contain CONTRIBUTOR_RECORD_INVALID
        $codes | Should -Contain CONTRIBUTOR_EDITION_UNKNOWN
        @($codes|Where-Object {$_ -eq 'CONTRIBUTOR_FILE_UNKNOWN'}).Count | Should -Be 1 -Because 'an unknown guide is an error'
        (Find-ContributorIssues $workspace $policy|Where-Object Code -eq CONTRIBUTOR_FILE_UNUSED).Severity | Should -Be warning -Because 'a translation team may exist before or while its translation does'
    }
    It 'warns about missing creators and translators only when the site keeps contributor data' {
        Remove-Item (Join-Path $workspace "$data/example.fa.yml")
        $findings=@(Find-ContributorIssues $workspace $policy)
        @($findings|Where-Object Code -eq TRANSLATORS_MISSING|ForEach-Object Subject) | Should -Be @("example/$editionId/fa","example/$editionId/es-ES")
        ($findings|Where-Object Code -eq TRANSLATORS_MISSING|Select-Object -First 1).Severity | Should -Be warning
        Remove-Item (Join-Path $workspace $data) -Recurse
        @(Find-ContributorIssues $workspace $policy).Count | Should -Be 0
    }
    It 'flags ambiguous extensions' {
        Write-Fixture "$data/example.yaml" "- name: Copy`n  role: creator`n  contributions: [`"$editionId`"]`n"
        @(Find-ContributorIssues $workspace $policy|ForEach-Object Code) | Should -Contain CONTRIBUTOR_FILE_AMBIGUOUS
        { Get-GuideCredits $workspace $policy example $editionId en } | Should -Throw '*Ambiguous*'
    }
}
