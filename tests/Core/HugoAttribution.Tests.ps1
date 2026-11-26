BeforeAll {
    $root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $module=Join-Path $root 'system/OpenGuidePlatform.Hugo.Guides'
}
Describe 'Guide attribution across Hugo content boundaries' {
    It 'loads YAML teams and aggregates credits for <Shape> content' -ForEach @(
        @{Shape='explicit';Mounted=$false;Implicit=$false},
        @{Shape='implicit';Mounted=$false;Implicit=$true},
        @{Shape='mounted';Mounted=$true;Implicit=$false}
    ) {
        $fixture=Join-Path $TestDrive $Shape
        $content=if($Mounted){Join-Path $TestDrive 'external-content'}else{"$fixture/content"}
        foreach($directory in @("$fixture/layouts/_partials","$content/guide/data","$content/guide/2025.1")){
            [IO.Directory]::CreateDirectory($directory)|Out-Null
        }
        Copy-Item "$module/layouts/_partials/functions" "$fixture/layouts/_partials/" -Recurse
        $languages=if($Implicit){"  en: {}"}else{"  en: {}`n  fa: {}"}
        $config="baseURL: https://fixture.example/`ndisableKinds: [taxonomy, term, RSS, sitemap]`nlanguages:`n$languages`nparams:`n  contributorFilters:`n    everyone: {}`n"
        if($Mounted){$config+="module:`n  mounts:`n    - source: $($content.Replace('\','/'))`n      target: content`n"}
        if(-not $Mounted){$config+="module:`n  mounts:`n"}
        $config+="    - source: assets`n      target: assets`n    - source: $($content.Replace('\','/'))/guide/data`n      target: assets/ogp-attribution/guide`n"
        [IO.File]::WriteAllText("$fixture/hugo.yaml",$config)
        if(-not $Implicit){
            [IO.File]::WriteAllText("$content/guide/_index.md","---`ntitle: Guide`ntype: guide`n---")
            [IO.File]::WriteAllText("$content/guide/_index.fa.md","---`ntitle: Guide fa`ntype: guide`n---")
            [IO.File]::WriteAllText("$content/guide/2025.1/index.fa.md","---`ntitle: Translation`n---")
        }
        [IO.File]::WriteAllText("$content/guide/2025.1/index.md","---`ntitle: Edition`n---")
        # Resource type must identify flow-style YAML even on Hugo 0.146.
        [IO.File]::WriteAllText("$content/guide/data/contributors.yml",'- {name: Creator, role: creator, contributions: ["2025.1"]}')
        [IO.File]::WriteAllText("$content/guide/data/translators.fa.yml",'- {name: Translator, role: translator, contributions: ["2025.1"]}')
        [IO.File]::WriteAllText("$content/guide/data/translators.xx.yml",'- {name: PDF Translator, role: reviewer, contributions: ["2025.1"]}')
        [IO.File]::WriteAllText("$fixture/layouts/index.html",@'
<script id="credits" type="application/json">{{ dict "files" (partial "functions/get-guide-attribution.html" (dict "guide" "guide")) "everyone" (partial "functions/get-contributors.html" (dict "context" . "filter" "everyone")) | jsonify | safeJS }}</script>
'@)
        $log=@(& hugo --source $fixture --destination "$fixture/public" 2>&1)
        if($LASTEXITCODE -ne 0){throw ($log -join "`n")}
        $html=[IO.File]::ReadAllText("$fixture/public/index.html")
        $json=[regex]::Match($html,'(?s)<script[^>]*>(.*?)</script>').Groups[1].Value | ConvertFrom-Json
        $json.files.contributors[0].name | Should -Be Creator
        $json.files.'translators.fa'[0].name | Should -Be Translator
        $json.files.'translators.xx'[0].name | Should -Be 'PDF Translator'
        @($json.everyone.name) | Should -Contain Creator
        @($json.everyone.name) | Should -Contain Translator
        @($json.everyone.name) | Should -Contain 'PDF Translator'
    }
}
