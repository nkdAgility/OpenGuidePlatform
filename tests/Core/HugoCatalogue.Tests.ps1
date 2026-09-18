BeforeAll {
    $root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $fixture=Join-Path $TestDrive 'catalogue'
    $module=Join-Path $root 'system/OpenGuidePlatform.Hugo.Guides'
    [IO.Directory]::CreateDirectory("$fixture/themes/guides/layouts/_partials")|Out-Null
    Copy-Item "$module/layouts/_partials/*" "$fixture/themes/guides/layouts/_partials" -Recurse
    [IO.Directory]::CreateDirectory("$fixture/layouts/guide")|Out-Null
    [IO.Directory]::CreateDirectory("$fixture/layouts/shortcodes")|Out-Null
    [IO.File]::WriteAllText("$fixture/layouts/shortcodes/catalogue-count.html",'{{ len (partial "openguide/guides/get-guide-catalogue.html" .Page).Guides }}')
    [IO.File]::WriteAllText("$fixture/hugo.yaml",@'
baseURL: https://catalogue.example/
theme: guides
defaultContentLanguage: en
disableKinds: [taxonomy, term, RSS, sitemap]
languages:
  en: {languageName: English, weight: 1}
  fr: {languageName: French, weight: 2}
  es-419: {languageName: Latin American Spanish, weight: 3}
  min: {languageName: Minionese, weight: 4}
'@)
    [IO.File]::WriteAllText("$fixture/hugo.production.yaml","languages:`n  min:`n    disabled: true`n")
    $homeTemplate='{{ partial "functions/get-guide-translations-catalogue.html" . | jsonify }}'
    $section='{{ partial "functions/get-guide-translations-list.html" . | jsonify }}'
    $single='{{ partial "functions/get-guide-translations-for-version.html" . | jsonify }}'
    [IO.File]::WriteAllText("$fixture/layouts/index.html",$homeTemplate)
    [IO.File]::WriteAllText("$fixture/layouts/guide/list.html",$section)
    [IO.File]::WriteAllText("$fixture/layouts/guide/single.html",$single)
    # Rendering a body can itself query raw metadata. Eager body reads in raw
    # discovery would introduce recursion when the public projection reads Plain.
    $body=('A complete translated guide with enough words and characters for every existing reading availability rule. '*12)+'{{< catalogue-count >}}'
    foreach($guide in @('kanban','open-kanban','third-guide')) {
        [IO.Directory]::CreateDirectory("$fixture/content/$guide")|Out-Null
        foreach($language in @('en','fr','es-419','min')) {
            [IO.File]::WriteAllText("$fixture/content/$guide/_index.$language.md","---`ntitle: $guide`ntype: guide`nweight: 1`n---`n")
        }
    }
    foreach($version in @('2020.12','2025.5')) {
        [IO.Directory]::CreateDirectory("$fixture/content/kanban/$version/pdf")|Out-Null
        foreach($language in @('en','fr','es-419','min')) {
            $content=if($version -eq '2025.5' -and $language -eq 'fr'){''}else{$body}
            [IO.File]::WriteAllText("$fixture/content/kanban/$version/index.$language.md","---`ntitle: Kanban $version $language`ntype: guide`ndate: $(if($version -eq '2025.5'){'2025-05-01'}else{'2020-12-01'})`n---`n$content")
        }
        foreach($language in @('en','fr','de','en-us','es-419')) {
            [IO.File]::WriteAllText("$fixture/content/kanban/$version/pdf/kanban.$language.pdf","%PDF fixture $version $language")
        }
    }
    foreach($guide in @('open-kanban','third-guide')) {
        [IO.Directory]::CreateDirectory("$fixture/content/$guide/2025.7/pdf")|Out-Null
        $fork=if($guide -eq 'open-kanban'){"forked_from: kanban/2020.12`n"}else{''}
        [IO.File]::WriteAllText("$fixture/content/$guide/2025.7/index.en.md","---`ntitle: $guide 2025.7`ntype: guide`ndate: 2025-07-01`n${fork}---`n$body")
        [IO.File]::WriteAllText("$fixture/content/$guide/2025.7/pdf/$guide.en.pdf",'%PDF fixture')
    }
    [IO.File]::WriteAllText("$fixture/content/open-kanban/2025.7/pdf/open-kanban.en-us.pdf",'%PDF US variant')
    [IO.File]::WriteAllText("$fixture/content/open-kanban/2025.7/pdf/open-kanban-print.en.pdf",'%PDF print variant')
    [IO.Directory]::CreateDirectory("$fixture/content/third-guide/2025.07")|Out-Null
    [IO.File]::WriteAllText("$fixture/content/third-guide/2025.07/index.en.md","---`ntitle: Early tie`ntype: guide`nweight: 1`ndate: 2025-07-01`n---`n$body")
    [IO.File]::WriteAllText("$fixture/content/third-guide/2025.7/index.en.md","---`ntitle: Later tie`ntype: guide`nweight: 20`ndate: 2025-07-01`n---`n$body")
    function Invoke-CatalogueFixture([string]$target) {
        $config=if($target -eq 'production'){'hugo.yaml,hugo.production.yaml'}else{'hugo.yaml'}
        $log=@(& hugo --source $fixture --config $config --destination "$fixture/$target" --environment $target 2>&1)
        if($LASTEXITCODE -ne 0 -or @($log|Where-Object {$_ -match '^ERROR'}).Count){throw "Catalogue fixture failed: $($log -join [Environment]::NewLine)"}
    }
    Invoke-CatalogueFixture preview
    Invoke-CatalogueFixture production
    $catalogue=Get-Content "$fixture/preview/index.html" -Raw|ConvertFrom-Json
    $current=Get-Content "$fixture/preview/kanban/2025.5/index.html" -Raw|ConvertFrom-Json
    $preferred=Get-Content "$fixture/preview/kanban/index.html" -Raw|ConvertFrom-Json
    # Exercise the internal contract without serialising Hugo Page/Resource objects.
    [IO.File]::WriteAllText("$fixture/layouts/index.html",@'
{{- $catalogue := partial "openguide/guides/get-guide-catalogue.html" . -}}
{{- $rows := slice -}}
{{- range $catalogue.Guides -}}
  {{- $id := .Id -}}
  {{- range .Versions -}}
    {{- $version := .Version -}}
    {{- range .Translations -}}
      {{- $pdfs := slice -}}
      {{- range .PDFs -}}
        {{- $pdfs = $pdfs | append (dict "Name" .Name "URL" .Resource.RelPermalink "MediaType" .Resource.MediaType.Type) -}}
      {{- end -}}
      {{- $rows = $rows | append (dict "Guide" $id "Version" $version "Language" .Language "HasPage" (not (not .Page)) "EditionKind" .EditionPage.Kind "PDFs" $pdfs) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $guide := .Site.GetPage "open-kanban" -}}
{{- $chain := partial "openguide/history/get-guide-history-chain.html" $guide -}}
{{- $forkURL := "" -}}{{- with $chain.forkSource }}{{ $forkURL = .RelPermalink }}{{ end -}}
{{- $options := slice -}}
{{- range partial "openguide/editions/get-guide-version-options.html" (.Site.GetPage "kanban") -}}
  {{- $options = $options | append (dict "Version" .version "URL" .url "Latest" .isLatest) -}}
{{- end -}}
{{- $ties := slice -}}
{{- range partial "functions/get-all-versions.html" (.Site.GetPage "third-guide") }}{{ $ties = $ties | append .version }}{{ end -}}
{{- $preferredTie := partial "functions/get-guide-translations-list.html" (.Site.GetPage "third-guide") -}}
{{- dict "Language" $catalogue.SiteLanguage "Rows" $rows "ForkURL" $forkURL "Options" $options "Ties" $ties "PreferredTie" $preferredTie | jsonify -}}
'@)
    Invoke-CatalogueFixture probe
    $probe=Get-Content "$fixture/probe/index.html" -Raw|ConvertFrom-Json
    # A consumer can override these old entry points. Dependent callers must
    # continue observing those overrides, not just leave the entry points callable.
    [IO.Directory]::CreateDirectory("$fixture/layouts/_partials/functions")|Out-Null
    [IO.File]::WriteAllText("$fixture/layouts/_partials/functions/get-guide-translations-for-version.html",'{{ return (slice (dict "Language" "custom" "ReadOnline" true "ReadPDF" false "Weight" 1 "Title" "Consumer override")) }}')
    [IO.File]::WriteAllText("$fixture/layouts/_partials/functions/get-latest-version.html",'{{ return "2020.12" }}')
    [IO.File]::WriteAllText("$fixture/layouts/index.html",@'
{{ $options := slice }}
{{ range partial "functions/get-all-versions.html" (.Site.GetPage "kanban") }}
  {{ $options = $options | append (dict "Version" .version "Latest" .isLatest "URL" .url) }}
{{ end }}
{{ dict "Catalogue" (partial "functions/get-guide-translations-catalogue.html" .) "Options" $options | jsonify }}
'@)
    Invoke-CatalogueFixture overrides
    $overrides=Get-Content "$fixture/overrides/index.html" -Raw|ConvertFrom-Json
    $overridePreferred=Get-Content "$fixture/overrides/kanban/index.html" -Raw|ConvertFrom-Json
    [IO.File]::WriteAllText("$fixture/layouts/_partials/functions/get-all-versions.html",'{{ return (slice (dict "version" "2020.12" "page" (.Site.GetPage "kanban/2020.12"))) }}')
    [IO.File]::WriteAllText("$fixture/layouts/index.html",'{{ $chain := partial "functions/get-history-chain.html" (.Site.GetPage "kanban") }}{{ dict "Current" $chain.current.RelPermalink | jsonify }}')
    Invoke-CatalogueFixture historyOverride
    $overrideHistory=Get-Content "$fixture/historyOverride/index.html" -Raw|ConvertFrom-Json
}

Describe 'Hugo capability catalogue' {
    It 'preserves consumer overrides through catalogue, preferred translations, version options and history' {
        $guide=$overrides.Catalogue|Where-Object Section -EQ kanban
        $guide.LatestVersion | Should -Be '2020.12'
        ($guide.Versions|Where-Object Version -EQ '2020.12').Latest | Should -BeTrue
        $guide.Versions[0].Translations[0].Title | Should -Be 'Consumer override'
        $overridePreferred[0].Language | Should -Be 'custom'
        $overridePreferred[0].Version | Should -Be '2025.5'
        ($overrides.Options|Where-Object Latest).Version | Should -Be '2020.12'
        ($overrides.Options|Where-Object Latest).URL | Should -Be '/kanban/'
        $overrideHistory.Current | Should -Be '/kanban/2020.12/'
    }
    It 'preserves original page ordering for equal dates and equal numeric edition keys' {
        @($probe.Ties) | Should -Be @('2025.07','2025.7')
        ($probe.PreferredTie|Where-Object Language -EQ en).Version | Should -Be '2025.07'
    }
    It 'retains multiple PDFs and usable Hugo objects without inventing a translated page' {
        $english=$probe.Rows|Where-Object { $_.Guide -eq 'open-kanban' -and $_.Language -eq 'en' }
        @($english.PDFs).Count | Should -Be 2
        $english.EditionKind | Should -Be 'page'
        @($english.PDFs|Where-Object MediaType -NE 'application/pdf').Count | Should -Be 0
        @($english.PDFs|Where-Object { -not $_.URL }).Count | Should -Be 0
        ($probe.Rows|Where-Object { $_.Guide -eq 'kanban' -and $_.Version -eq '2025.5' -and $_.Language -eq 'de' }).HasPage | Should -BeFalse
    }
    It 'preserves latest root URLs and explicit fork ancestry' {
        ($probe.Options|Where-Object Latest).URL | Should -Be '/kanban/'
        ($probe.Options|Where-Object Version -EQ '2020.12').URL | Should -Be '/kanban/2020.12/'
        $probe.ForkURL | Should -Be '/kanban/2020.12/'
    }
    It 'scopes the catalogue to the calling Hugo language site' {
        $french=Get-Content "$fixture/probe/fr/index.html" -Raw|ConvertFrom-Json
        $probe.Language | Should -Be 'en'
        $french.Language | Should -Be 'fr'
    }
}

Describe 'Existing catalogue contracts' {
    It 'preserves language-code ordering when preferred translations share a weight' {
        @($preferred|Where-Object Weight -EQ 1|ForEach-Object Language) | Should -Be @('de','en','en-us')
    }
    It 'discovers any number of guides and retains dated editions' {
        @($catalogue).Count | Should -Be 3
        $guide=$catalogue|Where-Object Section -EQ kanban
        @($guide.Versions.Version) | Should -Be @('2025.5','2020.12')
        $guide.LatestVersion | Should -Be '2025.5'
    }
    It 'retains the exact public translation field set' {
        @($current[0].PSObject.Properties.Name|Sort-Object) | Should -Be @('Date','Language','LanguageName','Path','PathPdf','ReadOnline','ReadOnlineStub','ReadPDF','RelPermalink','Status','Title','VersionPath','Weight'|Sort-Object)
    }
    It 'distinguishes an empty translated page from a PDF-only language with no page' {
        $french=$current|Where-Object Language -EQ fr
        $french.ReadOnline | Should -BeFalse
        $french.ReadOnlineStub | Should -BeTrue
        $french.ReadPDF | Should -BeTrue
        $german=$current|Where-Object Language -EQ de
        $german.ReadOnlineStub | Should -BeFalse
        $german.ReadPDF | Should -BeTrue
    }
    It 'preserves the preference for an older readable translation over a newer PDF-only edition' {
        ($preferred|Where-Object Language -EQ fr).Version | Should -Be '2020.12'
        ($preferred|Where-Object Language -EQ de).Version | Should -Be '2025.5'
    }
    It 'preserves numeric-region languages and unconfigured English PDF variants' {
        ($current|Where-Object Language -EQ 'es-419').PathPdf | Should -Match 'kanban.es-419.pdf$'
        ($current|Where-Object Language -EQ 'en-us').PathPdf | Should -Match 'kanban.en-us.pdf$'
    }
    It 'keeps site language context isolated between preview and production' {
        Test-Path "$fixture/preview/min/kanban/2025.5/index.html" | Should -BeTrue
        Test-Path "$fixture/production/min/kanban/2025.5/index.html" | Should -BeFalse
        $production=Get-Content "$fixture/production/kanban/2025.5/index.html" -Raw|ConvertFrom-Json
        @($production|Where-Object Language -EQ min).Count | Should -Be 0
    }
}
