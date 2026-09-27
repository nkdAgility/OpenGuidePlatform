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
    It 'preserves explicitly excluded translations with missing target files' {
        Set-Content "$workspace/site/hugo.production.yaml" "languages:`n  kn:`n    disabled: true"
        $policy.guides[0].editions[0].translations=@(@{language='kn';intent='excluded';downloads=@()})
        $work=Get-GuideSiteTranslationWork -WorkspaceRoot $workspace -Policy $policy -Language kn
        $work.Configuration.ProductionExplicitlyDisabled|Should -BeTrue
        $work.Guides[0].State|Should -Be missing
        $work.Guides[0].Intent|Should -Be excluded
        $work.Guides[0].Excluded|Should -BeTrue
        $work.Guides[0].WriteAllowed|Should -BeTrue
        $work.Guides[0].CanCreateScaffold|Should -BeFalse
        $work.Guides[1].CanCreateScaffold|Should -BeTrue
        Test-Path "$workspace/site/content/a/v1/index.kn.md"|Should -BeFalse
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
    It 'reports unsupported JSON schema drift and refuses writes for <Name>' -ForEach @(
        @{Name='changed scalar type';Source='{"title":42,"color":"blue","items":["Text"]}'},
        @{Name='added source key';Source='{"title":"Hello","color":"blue","items":["Text"],"new":"New"}'},
        @{Name='removed source key';Source='{"title":"Hello","items":["Text"]}'},
        @{Name='changed array length';Source='{"title":"Hello","color":"blue","items":["Text","More"]}'},
        @{Name='changed object shape';Source='{"title":"Hello","color":"blue","items":{"label":"Text"}}'}
    ) {
        Set-Content "$workspace/site/hugo.production.yaml" "languages:`n  kn:`n    disabled: true"
        $candidate='{"title":"Namaskara","color":"blue","items":["Translated"]}'
        Set-Content "$workspace/site/data/home/kn.json" $candidate
        $hash=(Get-FileHash "$workspace/site/data/home/kn.json").Hash
        Set-Content "$workspace/site/data/home/en.json" $Source
        $work=Get-GuideSiteTranslationWork -WorkspaceRoot $workspace -Policy $policy -Language kn
        $json=@($work.Wrappers|Where-Object Kind -EQ json-text-selection-required)[0]
        $json.State|Should -Be unsupported-json-schema-reconciliation
        $json.SupportedOperation|Should -BeNullOrEmpty
        $work.Findings.Code|Should -Contain WRAPPER_SCOPE_UNSUPPORTED
        {Set-GuideWrapperTranslation -WorkspaceRoot $workspace -Policy $policy -Language kn -RelativePath site/data/home/kn.json -CandidateContent $candidate -ExpectedSha256 $hash -ExpectedSourceSha256 $json.SourceSha256 -JsonTextPaths '/title'}|Should -Throw '*Schema reconciliation is unsupported*'
        (Get-FileHash "$workspace/site/data/home/kn.json").Hash|Should -Be $hash
    }
    It 'reports invalid JSON without aborting the inventory or writing a target' {
        Set-Content "$workspace/site/data/home/en.json" '{invalid'
        $work=Get-GuideSiteTranslationWork -WorkspaceRoot $workspace -Policy $policy -Language kn
        $json=@($work.Wrappers|Where-Object Kind -EQ json-text-selection-required)[0]
        $json.State|Should -Be unsupported-invalid-json
        $json.SupportedOperation|Should -BeNullOrEmpty
        $work.Guides.Count|Should -Be 2
        {Set-GuideWrapperTranslation -WorkspaceRoot $workspace -Policy $policy -Language kn -RelativePath site/data/home/kn.json -CandidateContent '{}' -ExpectedSourceSha256 $json.SourceSha256 -JsonTextPaths '/title'}|Should -Throw '*JSON is invalid*'
        Test-Path "$workspace/site/data/home/kn.json"|Should -BeFalse
    }
    It 'preserves an existing malformed JSON target when refusing text changes' {
        Set-Content "$workspace/site/data/home/kn.json" '{invalid'
        $hash=(Get-FileHash "$workspace/site/data/home/kn.json").Hash
        $work=Get-GuideSiteTranslationWork -WorkspaceRoot $workspace -Policy $policy -Language kn
        $json=@($work.Wrappers|Where-Object Kind -EQ json-text-selection-required)[0]
        $json.State|Should -Be unsupported-invalid-json
        $json.SupportedOperation|Should -BeNullOrEmpty
        $work.Findings.Code|Should -Contain WRAPPER_SCOPE_UNSUPPORTED
        {Set-GuideWrapperTranslation -WorkspaceRoot $workspace -Policy $policy -Language kn -RelativePath site/data/home/kn.json -CandidateContent '{"title":"Translated","color":"blue","items":["Text"]}' -ExpectedSha256 $hash -ExpectedSourceSha256 $json.SourceSha256 -JsonTextPaths '/title'}|Should -Throw '*JSON is invalid*'
        (Get-FileHash "$workspace/site/data/home/kn.json").Hash|Should -Be $hash
    }
    It 'reports source ambiguity and preserves an existing catalogue extension' {
        Set-Content "$workspace/site/content/_index.en.md" "---`ntitle: Other`n---`n"
        Set-Content "$workspace/site/i18n/kn.yml" 'home: Translated'
        $work=Get-GuideSiteTranslationWork -WorkspaceRoot $workspace -Policy $policy -Language kn
        @($work.Wrappers|Where-Object State -EQ ambiguous-source).Count|Should -Be 2
        $work.Wrappers.TargetPath|Should -Contain 'site/i18n/kn.yml'
        $work.Findings.Code|Should -Contain WRAPPER_SCOPE_UNSUPPORTED
    }
    It 'checks protection on the actual existing catalogue extension' {
        Set-Content "$workspace/site/i18n/kn.yml" 'home: Translated'
        $policy.protectedPaths=@('site/i18n/kn.yml')
        $catalogue=@((Get-GuideSiteTranslationWork -WorkspaceRoot $workspace -Policy $policy -Language kn).Wrappers|Where-Object Kind -EQ catalogue)[0]
        $catalogue.TargetPath|Should -Be site/i18n/kn.yml
        $catalogue.WriteAllowed|Should -BeFalse
    }
    It 'reports duplicate catalogue extensions as unsupported for <Location>' -ForEach @(
        @{Location='target';LanguageCode='kn';Expected='ambiguous-target-catalogue'},
        @{Location='source';LanguageCode='en';Expected='ambiguous-source-catalogue'}
    ) {
        Set-Content "$workspace/site/i18n/$LanguageCode.yaml" 'home: Text'
        Set-Content "$workspace/site/i18n/$LanguageCode.yml" 'home: Text'
        $work=Get-GuideSiteTranslationWork -WorkspaceRoot $workspace -Policy $policy -Language kn
        $catalogues=@($work.Wrappers|Where-Object Kind -EQ catalogue)
        foreach($item in $catalogues){$item.State|Should -Be $Expected;$item.SupportedOperation|Should -BeNullOrEmpty}
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
    It 'refuses ambiguous source catalogues for <TargetState> and preserves target bytes' -ForEach @(
        @{TargetState='new target';Existing=$false},
        @{TargetState='existing target with a different extension';Existing=$true}
    ) {
        Set-Content "$workspace/site/hugo.production.yaml" "languages:`n  kn:`n    disabled: true"
        Set-Content "$workspace/site/i18n/en.yml" 'home: Other source'
        $target='site/i18n/kn.yaml'
        $arguments=@{WorkspaceRoot=$workspace;Policy=$policy;Language='kn';CandidateContent='home: Translated'}
        if($Existing){
            $target='site/i18n/kn.yml'
            Set-Content "$workspace/$target" 'home: Existing translation'
            $hash=(Get-FileHash "$workspace/$target").Hash
            $arguments.ExpectedSha256=$hash
        }
        {Set-GuideWrapperTranslation @arguments -RelativePath $target}|Should -Throw '*uniquely discovered*'
        if($Existing){(Get-FileHash "$workspace/$target").Hash|Should -Be $hash}
        else{Test-Path "$workspace/$target"|Should -BeFalse}
    }
    It 'reports timestamp strings versus numbers as schema drift and preserves an existing target' {
        Set-Content "$workspace/site/data/home/en.json" '{"title":"2026-09-27T12:00:00Z"}'
        Set-Content "$workspace/site/data/home/kn.json" '{"title":42}'
        $hash=(Get-FileHash "$workspace/site/data/home/kn.json").Hash
        $json=@((Get-GuideSiteTranslationWork -WorkspaceRoot $workspace -Policy $policy -Language kn).Wrappers|Where-Object Kind -EQ json-text-selection-required)[0]
        $json.State|Should -Be unsupported-json-schema-reconciliation
        {Set-GuideWrapperTranslation -WorkspaceRoot $workspace -Policy $policy -Language kn -RelativePath site/data/home/kn.json -CandidateContent '{"title":"Translated"}' -ExpectedSha256 $hash -ExpectedSourceSha256 $json.SourceSha256 -JsonTextPaths '/title'}|Should -Throw '*Schema reconciliation is unsupported*'
        (Get-FileHash "$workspace/site/data/home/kn.json").Hash|Should -Be $hash
    }
    It 'accepts compatible timestamp string leaves and preserves unselected literal strings' {
        Set-Content "$workspace/site/hugo.production.yaml" "languages:`n  kn:`n    disabled: true"
        $source='{"title":"2026-09-27T12:00:00Z","published":"2026-09-27T12:00:00+00:00","items":[null,true,1,"Text"]}'
        Set-Content "$workspace/site/data/home/en.json" $source
        Set-Content "$workspace/site/data/home/kn.json" $source
        $json=@((Get-GuideSiteTranslationWork -WorkspaceRoot $workspace -Policy $policy -Language kn).Wrappers|Where-Object Kind -EQ json-text-selection-required)[0]
        $json.State|Should -Be existing-review-required
        $candidate=$source.Replace('2026-09-27T12:00:00Z','Translated date')
        $arguments=@{WorkspaceRoot=$workspace;Policy=$policy;Language='kn';RelativePath='site/data/home/kn.json';ExpectedSha256=$json.TargetSha256;ExpectedSourceSha256=$json.SourceSha256;JsonTextPaths='/title'}
        (Set-GuideWrapperTranslation @arguments -CandidateContent $candidate).Status|Should -Be updated
        [IO.File]::ReadAllText("$workspace/site/data/home/kn.json")|Should -BeExactly $candidate
        $arguments.ExpectedSha256=(Get-FileHash "$workspace/site/data/home/kn.json").Hash
        {Set-GuideWrapperTranslation @arguments -CandidateContent $candidate.Replace('2026-09-27T12:00:00+00:00','2026-09-27T12:00:00Z')}|Should -Throw '*unselected*'
        (Get-FileHash "$workspace/site/data/home/kn.json").Hash|Should -Be $arguments.ExpectedSha256
    }
    It 'preserves case-distinct machine keys, nested arrays and null values' {
        Set-Content "$workspace/site/hugo.production.yaml" "languages:`n  kn:`n    disabled: true"
        $source='{"title":"Hello","Name":"Upper","name":"Lower","values":[[],[null],null,{"Null":null,"null":false}]}'
        Set-Content "$workspace/site/data/home/en.json" $source
        $candidate=$source.Replace('Hello','Translated')
        $arguments=@{WorkspaceRoot=$workspace;Policy=$policy;Language='kn';RelativePath='site/data/home/kn.json';ExpectedSourceSha256=(Get-FileHash "$workspace/site/data/home/en.json").Hash;JsonTextPaths='/title'}
        (Set-GuideWrapperTranslation @arguments -CandidateContent $candidate).Status|Should -Be created
        [IO.File]::ReadAllText("$workspace/site/data/home/kn.json")|Should -BeExactly $candidate
        $arguments.ExpectedSha256=(Get-FileHash "$workspace/site/data/home/kn.json").Hash
        {Set-GuideWrapperTranslation @arguments -CandidateContent $candidate.Replace('Lower','Changed')}|Should -Throw '*unselected*'
        {Set-GuideWrapperTranslation @arguments -CandidateContent $candidate.Replace('[null]','[]')}|Should -Throw '*array structure*'
        (Get-FileHash "$workspace/site/data/home/kn.json").Hash|Should -Be $arguments.ExpectedSha256
    }
    It 'reports duplicate identical JSON keys as invalid without writes' {
        Set-Content "$workspace/site/data/home/en.json" '{"title":"First","title":"Second"}'
        $json=@((Get-GuideSiteTranslationWork -WorkspaceRoot $workspace -Policy $policy -Language kn).Wrappers|Where-Object Kind -EQ json-text-selection-required)[0]
        $json.State|Should -Be unsupported-invalid-json
        {Set-GuideWrapperTranslation -WorkspaceRoot $workspace -Policy $policy -Language kn -RelativePath site/data/home/kn.json -CandidateContent '{"title":"Translated"}' -ExpectedSourceSha256 $json.SourceSha256 -JsonTextPaths '/title'}|Should -Throw '*JSON is invalid*'
        Test-Path "$workspace/site/data/home/kn.json"|Should -BeFalse
    }
    It 'updates a uniquely discovered existing catalogue with its retained extension' {
        Set-Content "$workspace/site/i18n/kn.yml" 'home: Existing translation'
        $hash=(Get-FileHash "$workspace/site/i18n/kn.yml").Hash
        (Set-GuideWrapperTranslation -WorkspaceRoot $workspace -Policy $policy -Language kn -RelativePath site/i18n/kn.yml -CandidateContent 'home: Reviewed translation' -ExpectedSha256 $hash).Status|Should -Be updated
        [IO.File]::ReadAllText("$workspace/site/i18n/kn.yml")|Should -BeExactly 'home: Reviewed translation'
        Test-Path "$workspace/site/i18n/kn.yaml"|Should -BeFalse
    }
}
