BeforeAll {
    $root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $module=Join-Path $root 'system/OpenGuidePlatform.Hugo.Guides'
    $fixture=Join-Path $TestDrive 'rendering'
    foreach($directory in @('themes/guides/layouts/_partials','layouts/guide','content/guide/latest/pdf','content/guide/data')){
        [IO.Directory]::CreateDirectory("$fixture/$directory")|Out-Null
    }
    # Exercise the production partials and three callers with small, deterministic
    # content. The fixture wrapper omits unrelated theme assets and remote modules.
    Copy-Item "$module/layouts/_partials/*" "$fixture/themes/guides/layouts/_partials/" -Recurse
    Copy-Item "$module/layouts/index.html" "$fixture/themes/guides/layouts/index.html"
    Copy-Item "$module/layouts/guide/details.html" "$fixture/layouts/guide/details.html"
    [IO.File]::WriteAllText("$fixture/layouts/baseof.html",'<html><body>{{ block "main" . }}{{ end }}</body></html>')
    [IO.File]::WriteAllText("$fixture/layouts/guide/probe.html",'{{ define "main" }}{{ partial "components/guide/guide-creators.html" . }}{{ partial "components/guide/guide-translators.html" . }}{{ partial "components/versions/version-card.html" (dict "page" . "itemType" "latest") }}<script id="catalogue" type="application/json">{{ partial "functions/get-guide-translations-for-version.html" . | jsonify | safeJS }}</script>{{ end }}')
    [IO.File]::WriteAllText("$fixture/hugo.yaml",@'
baseURL: https://fixture.example/
theme: guides
defaultContentLanguage: en
disableKinds: [taxonomy, term, RSS, sitemap]
languages:
  en: {languageName: English}
  fa: {languageName: Persian}
  fr: {languageName: French}
  ja: {languageName: Japanese}
  min: {languageName: Minionese}
  es-ES: {languageName: Spanish}
  pt-BR: {languageName: Portuguese}
params:
  contributorPresentation:
    starFlag: featured
  contributorFilters:
    homepage: {requireAnyRole: [creator, contributor]}
    guideDetails: {}
    versionCard: {}
    creators: {requireAnyRole: [creator]}
    guideContributors: {}
'@)
    [IO.File]::WriteAllText("$fixture/content/guide/data/contributors.yaml",@'
- name: Fixture Creator
  githubUsername: fixture-creator
  role: creator
  flags: [founder, featured]
  weight: 1
  localizedNames:
    fa: سازنده آزمایشی
- name: Fixture Contributor
  gravatarHash: fixture-hash
  role: contributor
  flags: [founder]
  weight: 2
'@)
    # Translation teams: the data key keeps the content language's case (es-ES)
    # while Hugo reports the page language in lower case (es-es).
    [IO.File]::WriteAllText("$fixture/content/guide/data/translators.es-ES.yml","- name: Fixture Traductora`n  role: translator`n  weight: 2`n- name: Fixture Revisora`n  role: reviewer`n  weight: 1`n")
    [IO.File]::WriteAllText("$fixture/content/guide/_index.md","---`ntitle: Fixture guide`ntype: guide`nlayout: details`n---`nGuide overview.")
    foreach($language in @('en','fa','fr','ja','min','es-ES','pt-BR')){
        [IO.File]::WriteAllText("$fixture/content/guide/latest/index.$($language.ToLowerInvariant()).md","---`ntitle: Fixture guide $language`ntype: guide`nlayout: probe`n---`nThis is a complete guide body with enough words to represent an online translation in the catalogue.")
    }
    # en-us is deliberately NOT a configured language, so Hugo exposes that PDF
    # in every translation's resources. Spanish deliberately has no PDF.
    foreach($language in @('en','en-us','fa','fr','ja','min','pt-br')){
        [IO.File]::WriteAllText("$fixture/content/guide/latest/pdf/guide.$language.pdf","%PDF fixture $language")
    }
    $originalConfig=[IO.File]::ReadAllText("$fixture/hugo.yaml")
    [IO.File]::WriteAllText("$fixture/hugo.yaml", @'
module:
  mounts:
    - source: assets
      target: assets
    - source: content/guide/data
      target: assets/ogp-attribution/guide
    - source: content/second/data
      target: assets/ogp-attribution/second


'@+"`n"+$originalConfig)
    $log=@(& hugo --source $fixture --destination "$fixture/public" 2>&1)
    if($LASTEXITCODE -ne 0 -or @($log|Where-Object {$_ -match '^ERROR'}).Count){throw "Hugo fixture failed: $($log -join [Environment]::NewLine)"}
    $html=[IO.File]::ReadAllText("$fixture/public/min/guide/latest/index.html")
    $json=[regex]::Match($html,'(?s)<script id="catalogue" type="application/json">(.*?)</script>').Groups[1].Value
    $catalogue=ConvertFrom-Json $json
    Copy-Item "$root/examples/reference-guide-site/layouts/index.html" "$fixture/layouts/index.html"
    $log=@(& hugo --source $fixture --destination "$fixture/sample-public" 2>&1)
    if($LASTEXITCODE -ne 0 -or @($log|Where-Object {$_ -match '^ERROR'}).Count){throw "Sample wrapper fixture failed: $($log -join [Environment]::NewLine)"}
}
Describe 'Guide contributor rendering' {
    It 'links a version card to its own guide translations' {
        $html | Should -Match 'href="https://fixture.example/guide/translations/"'
        $html | Should -Not -Match 'href="https://fixture.example//?translations/"'
    }
    It 'renders creator names and avatars from the real creator partial' {
        $html | Should -Match 'Fixture Creator'
        $html | Should -Match 'avatars.githubusercontent.com/fixture-creator'
    }
    It 'renders visible contributor names in the sample homepage override' {
        $rendered=[IO.File]::ReadAllText("$fixture/sample-public/index.html")
        $rendered | Should -Match '<strong>Fixture Creator</strong>'
        $rendered | Should -Match '<strong>Fixture Contributor</strong>'
        $rendered | Should -Match 'avatars.githubusercontent.com/fixture-creator'
        $rendered | Should -Match 'gravatar.com/avatar/fixture-hash'
    }
    It 'renders contributor identities on the homepage and guide details page' {
        foreach($page in @('index.html','guide/index.html')){
            $rendered=[IO.File]::ReadAllText("$fixture/public/$page")
            $rendered | Should -Match 'Fixture Creator'
            $rendered | Should -Match 'Fixture Contributor'
            $rendered | Should -Match 'avatars.githubusercontent.com/fixture-creator'
            $rendered | Should -Match 'gravatar.com/avatar/fixture-hash'
        }
    }
}
Describe 'Site contributor filter configuration' {
    It 'shows a star only for the configured badge flag and never uses it to filter the list' {
        $rendered=[IO.File]::ReadAllText("$fixture/public/index.html")
        ([regex]::Matches($rendered,'fa-star')).Count | Should -Be 1
        $rendered | Should -Match 'Fixture Contributor'
        $config="$fixture/hugo.yaml"
        $original=[IO.File]::ReadAllText($config)
        try {
            [IO.File]::WriteAllText($config,($original -replace '(?m)^  contributorPresentation:\r?\n    starFlag: featured\r?\n',''))
            $log=@(& hugo --source $fixture --destination "$fixture/no-star-public" 2>&1)
            if($LASTEXITCODE){throw ($log -join [Environment]::NewLine)}
            $rendered=[IO.File]::ReadAllText("$fixture/no-star-public/index.html")
            $rendered | Should -Not -Match 'fa-star'
            $rendered | Should -Match 'Fixture Creator'
            $rendered | Should -Match 'Fixture Contributor'
        } finally {
            [IO.File]::WriteAllText($config,$original)
        }
    }

    It 'combines conditions before deduplicating and distinguishes empty filters from zero matches' {
        $config="$fixture/hugo.yaml"
        $layout="$fixture/layouts/index.html"
        $team="$fixture/content/second/data/contributors.yaml"
        $originalConfig=[IO.File]::ReadAllText($config)
        $originalLayout=[IO.File]::ReadAllText($layout)
        try {
            [IO.File]::AppendAllText($config,@'

    board:
      requireAnyRole: [creator]
      requireAllFlags: [founder, invited]
      requireAnyFlag: [advisory, executive]
      excludeAnyFlag: [hidden]
    everyone: {}
    emptyResult:
      requireAnyFlag: [absent]
'@)
            [IO.Directory]::CreateDirectory("$fixture/content/second/data")|Out-Null
            [IO.File]::WriteAllText("$fixture/content/second/_index.md","---`ntitle: Second guide`ntype: guide`n---")
            [IO.File]::WriteAllText($team,@'
- {name: Matched Creator, githubUsername: fixture-creator, role: creator, flags: [founder, invited, advisory]}
- {name: Hidden Creator, role: creator, flags: [founder, invited, advisory, hidden]}
- {name: Uninvited Creator, role: creator, flags: [founder, advisory]}
- {name: Other Creator, role: creator, flags: [founder, invited]}
- {name: Board Reviewer, role: reviewer, flags: [founder, invited, executive]}
'@)
            [IO.File]::WriteAllText($layout,@'
{{ define "main" }}
{{ $page := . }}
{{ range slice "board" "everyone" "emptyResult" }}
  <div id="{{ . }}">{{ range partial "functions/get-contributors.html" (dict "context" $page "filter" .) }}{{ .name }}|{{ end }}</div>
{{ end }}
{{ end }}
'@)
            $log=@(& hugo --source $fixture --destination "$fixture/filter-public" 2>&1)
            if($LASTEXITCODE){throw ($log -join [Environment]::NewLine)}
            $result=[IO.File]::ReadAllText("$fixture/filter-public/index.html")
            $result | Should -Match '<div id="board">Matched Creator\|</div>'
            $result | Should -Match '<div id="everyone">[^<]*Board Reviewer\|'
            $result | Should -Match '<div id="emptyResult"></div>'
            [IO.File]::AppendAllText($config,"`n    malformed:`n      requireAnyFlag: founder`n")
            $log=@(& hugo --source $fixture --destination "$fixture/invalid-filter-public" 2>&1)
            $LASTEXITCODE | Should -Not -Be 0
            ($log -join "`n") | Should -Match 'contributorFilters.malformed.requireanyflag must be a list'

            [IO.File]::WriteAllText($config,$originalConfig)
            [IO.File]::WriteAllText($layout,@'
{{ define "main" }}
  {{ partial "components/guide/guide-contributors.html" (dict "context" . "roles" (slice "creator")) }}
  {{ range partial "functions/get-contributors.html" (dict "context" . "filter" "jsonLdAuthors") }}{{ .name }}{{ end }}
{{ end }}
'@)
            $log=@(& hugo --source $fixture --destination "$fixture/retired-arguments-public" 2>&1)
            $LASTEXITCODE | Should -Not -Be 0
            $errors=$log -join "`n"
            $errors | Should -Match 'argument "roles" is retired'
            $errors | Should -Match 'unknown contributor filter "jsonldauthors"'
            $errors | Should -Not -Match '%!q'
        } finally {
            [IO.File]::WriteAllText($config,$originalConfig)
            [IO.File]::WriteAllText($layout,$originalLayout)
            [IO.File]::Delete($team)
        }
    }
}
Describe 'Translator and localized name rendering' {
    It 'renders the translation team from the guide language data file' {
        $spanish=[IO.File]::ReadAllText("$fixture/public/es-es/guide/latest/index.html")
        $spanish | Should -Match 'Fixture Traductora'
        $spanish.IndexOf('Fixture Revisora') | Should -BeLessThan $spanish.IndexOf('Fixture Traductora') -Because 'records are ordered by weight'
        [IO.File]::ReadAllText("$fixture/public/guide/latest/index.html") | Should -Not -Match 'Fixture Traductora'
    }
    It 'uses localizedNames for the page language only' {
        [IO.File]::ReadAllText("$fixture/public/fa/guide/latest/index.html") | Should -Match 'سازنده آزمایشی'
        [IO.File]::ReadAllText("$fixture/public/fr/guide/latest/index.html") | Should -Match 'Fixture Creator'
    }
}
Describe 'Guide-local attribution migration diagnostics' {
    It 'rejects ambiguous extensions rather than selecting one silently' {
        $duplicate="$fixture/content/guide/data/contributors.yml"
        try {
            Copy-Item "$fixture/content/guide/data/contributors.yaml" $duplicate
            $log=@(& hugo --source $fixture --destination "$fixture/ambiguous-public" 2>&1)
            $LASTEXITCODE | Should -Not -Be 0
            ($log -join "`n") | Should -Match 'Ambiguous attribution files'
        } finally { [IO.File]::Delete($duplicate) }
    }
    It 'rejects unmigrated site data rather than silently omitting credits' {
        $legacy="$fixture/data/contributions"
        [IO.Directory]::CreateDirectory($legacy)|Out-Null
        try {
            [IO.File]::WriteAllText("$legacy/guide.yml","- name: Legacy Author`n  role: creator`n")
            $log=@(& hugo --source $fixture --destination "$fixture/legacy-public" 2>&1)
            $LASTEXITCODE | Should -Not -Be 0
            ($log -join "`n") | Should -Match 'OGP v2.2.0: move data/contributions'
        } finally { [IO.File]::Delete("$legacy/guide.yml");[IO.Directory]::Delete($legacy) }
    }
}
Describe 'Translation PDF resource selection' {
    It 'selects each language PDF rather than a shared untagged English resource' {
        foreach($language in @('en','fa','fr','ja','min','pt-br')){
            $row=@($catalogue|Where-Object Language -EQ $language)
            $row.Count | Should -Be 1
            $row[0].ReadPDF | Should -BeTrue -Because $language
            $row[0].PathPdf | Should -Match ([regex]::Escape("guide.$language.pdf")+'$')
            $relative=[uri]::UnescapeDataString($row[0].PathPdf).TrimStart('/')
            Test-Path -LiteralPath "$fixture/public/$relative" | Should -BeTrue
        }
    }
    It 'keeps PDF-only languages and does not invent downloads for missing translations' {
        $english=@($catalogue|Where-Object Language -EQ 'en-us')
        $english[0].ReadPDF | Should -BeTrue
        $english[0].PathPdf | Should -Match 'guide.en-us.pdf$'
        $spanish=@($catalogue|Where-Object Language -EQ 'es-es')
        $spanish.Count | Should -Be 1
        $spanish[0].ReadPDF | Should -BeFalse
        $spanish[0].PathPdf | Should -BeNullOrEmpty
        $spanish[0].ReadOnline | Should -BeTrue
    }
}
