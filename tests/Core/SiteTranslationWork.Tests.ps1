BeforeAll {
    $root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Import-Module "$root/system/OpenGuidePlatform.PowerShell.Core/OpenGuidePlatform.PowerShell.Core.psd1" -Force
}
Describe 'Site language work inventory' {
    BeforeEach {
        $workspace=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        foreach($folder in @('site/content/a/v1','site/content/b/v2','site/content/a/history','site/i18n','site/data/home')){New-Item -ItemType Directory "$workspace/$folder" -Force|Out-Null}
        Set-Content "$workspace/site/hugo.yaml" "defaultContentLanguage: en`nlanguages:`n  en:`n    languageName: English"
        Set-Content "$workspace/site/hugo.production.yaml" "languages:`n  en:`n    disabled: false"
        Set-Content "$workspace/site/i18n/en.yaml" 'home: Home'
        Set-Content "$workspace/site/data/home/en.json" '{"title":"Hello","color":"blue","items":["Text"]}'
        foreach($file in @('_index.md','a/_index.md','a/history/index.md','a/v1/index.md','b/v2/index.md')){Set-Content "$workspace/site/content/$file" "---`ntitle: Source`n---`nSource body"}
        $policy=@{siteId='test';wrapper=@{sourcePath='site';requiredFiles=@('site/content/a/_index.md','site/content/a/history/index.md')};guides=@(
            @{id='a';contentRoot='site/content/a';protectSource=$false;editions=@(@{id='v1';path='v1';sourceLanguage='en';translations=@()})},
            @{id='b';contentRoot='site/content/b';protectSource=$false;editions=@(@{id='v2';path='v2';sourceLanguage='en';translations=@()})}
        );protectedPaths=@();publication=@{permanentExclusions=@();environments=@()}}
    }
    It 'discovers an absent language across the site and every guide without writes' {
        $work=Get-GuideSiteTranslationWork -WorkspaceRoot $workspace -Policy $policy -Language kn
        $work.Configuration.LanguageDeclared|Should -BeFalse
        $work.Configuration.ProductionExplicitlyDisabled|Should -BeFalse
        $work.Guides.Count|Should -Be 2
        $work.Wrappers.Count|Should -Be 5
        $work.Wrappers.TargetPath|Should -Contain 'site/content/a/history/index.kn.md'
        $work.Wrappers.TargetPath|Should -Contain 'site/data/home/kn.json'
        @($work.Guides|Where-Object CanCreateScaffold).Count|Should -Be 0
        Test-Path "$workspace/site/content/_index.kn.md"|Should -BeFalse
    }
    It 'preserves populated, empty and PDF-only states' {
        Set-Content "$workspace/site/hugo.production.yaml" "languages:`n  kn:`n    disabled: true"
        Set-Content "$workspace/site/content/a/v1/index.kn.md" "---`ntitle: Kannada`n---`nBody"
        $policy.guides[1].editions[0].translations=@(@{language='kn';intent='pdf-only';downloads=@(@{path='supplied.kn.pdf';handling='supplied'})})
        $work=Get-GuideSiteTranslationWork -WorkspaceRoot $workspace -Policy $policy -Language kn
        $work.Guides[0].State|Should -Be populated
        $work.Guides[1].Intent|Should -Be pdf-only
        @($work.Guides|Where-Object CanCreateScaffold).Count|Should -Be 0
        Set-Content "$workspace/site/content/a/v1/index.kn.md" "---`ntitle: Kannada`n---`n"
        (Get-GuideSiteTranslationWork -WorkspaceRoot $workspace -Policy $policy -Language kn).Guides[0].State|Should -Be empty-stub
    }
    It 'allows discovered guide wrappers but never edition resources or unknown guide files' {
        Set-Content "$workspace/site/hugo.production.yaml" "languages:`n  kn:`n    disabled: true"
        $wrapperArgs=@{WorkspaceRoot=$workspace;Policy=$policy;Language='kn';CandidateContent="---`ntitle: Kannada`n---`n"}
        (Set-GuideWrapperTranslation @wrapperArgs -RelativePath site/content/a/history/index.kn.md).Status|Should -Be created
        New-Item -ItemType Directory "$workspace/site/content/a/details"|Out-Null
        Set-Content "$workspace/site/content/a/details/index.md" "---`ntitle: Details`n---`nDetails"
        (Set-GuideWrapperTranslation @wrapperArgs -RelativePath site/content/a/details/index.kn.md).Status|Should -Be created
        {Set-GuideWrapperTranslation @wrapperArgs -RelativePath site/content/a/v1/index.kn.md}|Should -Throw '*guide content*'
        {Set-GuideWrapperTranslation @wrapperArgs -RelativePath site/content/./a/v1/index.kn.md}|Should -Throw '*canonical*'
        {Set-GuideWrapperTranslation @wrapperArgs -RelativePath site/content//a/v1/index.kn.md}|Should -Throw '*canonical*'
        New-Item -ItemType Directory "$workspace/site/content/a/suffixed"|Out-Null
        Set-Content "$workspace/site/content/a/suffixed/index.en.md" "---`ntitle: Details`n---`nDetails"
        (Set-GuideWrapperTranslation @wrapperArgs -RelativePath site/content/a/suffixed/index.kn.md).Status|Should -Be created
        {Set-GuideWrapperTranslation @wrapperArgs -RelativePath site/content/a/unknown.kn.md}|Should -Throw '*undiscovered*'
        $policy.protectedPaths=@('site/content/a/history')
        {Set-GuideWrapperTranslation @wrapperArgs -RelativePath site/content/a/history/index.kn.md}|Should -Throw '*PROTECTED_RESOURCE*'
    }
    It 'applies only explicitly reviewed JSON text leaves and preserves machine values' {
        Set-Content "$workspace/site/hugo.production.yaml" "languages:`n  kn:`n    disabled: true"
        $wrapperArgs=@{WorkspaceRoot=$workspace;Policy=$policy;Language='kn';RelativePath='site/data/home/kn.json';ExpectedSourceSha256=(Get-FileHash "$workspace/site/data/home/en.json").Hash;JsonTextPaths=@('/title','/items/0')}
        $candidate='{"title":"Namaskara","color":"blue","items":["Translated"]}'
        (Set-GuideWrapperTranslation @wrapperArgs -CandidateContent $candidate).Status|Should -Be created
        $wrapperArgs.ExpectedSha256=(Get-FileHash "$workspace/site/data/home/kn.json").Hash
        {Set-GuideWrapperTranslation @wrapperArgs -CandidateContent ($candidate.Replace('blue','red'))}|Should -Throw '*unselected*'
        {Set-GuideWrapperTranslation @wrapperArgs -CandidateContent '{"title":"X"}'}|Should -Throw '*structure*'
        $wrapperArgs.JsonTextPaths=@('/missing')
        {Set-GuideWrapperTranslation @wrapperArgs -CandidateContent $candidate}|Should -Throw '*existing string leaf*'
        $wrapperArgs.JsonTextPaths=@('/title');$wrapperArgs.ExpectedSourceSha256='0'*64
        {Set-GuideWrapperTranslation @wrapperArgs -CandidateContent $candidate}|Should -Throw '*source changed*'
    }
    It 'reports source ambiguity and preserves an existing catalogue extension' {
        Set-Content "$workspace/site/content/_index.en.md" "---`ntitle: Other`n---`n"
        Set-Content "$workspace/site/i18n/kn.yml" 'home: Translated'
        $work=Get-GuideSiteTranslationWork -WorkspaceRoot $workspace -Policy $policy -Language kn
        @($work.Wrappers|Where-Object State -EQ ambiguous-source).Count|Should -Be 2
        $work.Wrappers.TargetPath|Should -Contain 'site/i18n/kn.yml'
        $work.Findings.Code|Should -Contain WRAPPER_SCOPE_UNSUPPORTED
    }
    It 'reads Hugo configuration casing and reports unsupported custom content directories' {
        Set-Content "$workspace/site/hugo.yaml" "defaultcontentlanguage: en`ncontentdir: pages`nlanguages:`n  en:`n    languageName: English"
        New-Item -ItemType Directory "$workspace/site/pages"|Out-Null
        Set-Content "$workspace/site/pages/_index.md" "---`ntitle: Home`n---`n"
        $work=Get-GuideSiteTranslationWork -WorkspaceRoot $workspace -Policy $policy -Language kn
        ($work.Wrappers|Where-Object TargetPath -EQ 'site/pages/_index.kn.md').State|Should -Be unsupported-custom-directory
    }
    It 'never proposes translating an edition into its own source language' {
        Set-Content "$workspace/site/hugo.production.yaml" "languages:`n  kn:`n    disabled: true"
        $policy.guides[1].editions[0].sourceLanguage='kn'
        $work=Get-GuideSiteTranslationWork -WorkspaceRoot $workspace -Policy $policy -Language kn
        $work.Guides[0].CanCreateScaffold|Should -BeTrue
        $work.Guides[1].SourceLanguage|Should -Be kn
        $work.Guides[1].SourceLanguageSelected|Should -BeTrue
        $work.Guides[1].CanCreateScaffold|Should -BeFalse
    }
}