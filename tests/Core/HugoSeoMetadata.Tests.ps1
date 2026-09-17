BeforeAll {
    $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $module = Join-Path $root 'system/OpenGuidePlatform.Hugo.Guides'
    $fixture = Join-Path $TestDrive 'seo'
    foreach ($directory in @('themes/guides/layouts/_partials','layouts/guide','content/guide/2025.1','content/guide/2024.1','content/unknown/2025.1','data/contributions')) {
        [IO.Directory]::CreateDirectory("$fixture/$directory") | Out-Null
    }
    Copy-Item "$module/layouts/_partials/*" "$fixture/themes/guides/layouts/_partials/" -Recurse
    Copy-Item "$module/layouts/baseof.html" "$fixture/themes/guides/layouts/baseof.html"
    # Keep the complete production head; suppress unrelated body components only.
    $wrapper = '{{ define "menu" }}{{ end }}{{ define "breadcrumbs" }}{{ end }}{{ define "main" }}{{ .Content }}{{ end }}'
    foreach ($layout in @('index.html','guide/single.html','guide/list.html')) {
        [IO.File]::WriteAllText("$fixture/layouts/$layout", $wrapper)
    }
    [IO.File]::WriteAllText("$fixture/data/contributions/guide.yaml", @'
- name: 'Creator "One"'
  role: creator
  founder: true
  githubUsername: creator-one
  contributions: ['2025.1', '2024.1']
  weight: 1
- name: Creator Two
  role: creator
  founder: true
  contributions: ['2025.1']
  weight: 2
- name: Contributor Only
  role: contributor
  founder: true
  contributions: ['2025.1']
'@)
    foreach ($guide in @('guide','unknown')) {
        [IO.File]::WriteAllText("$fixture/content/$guide/_index.md", "---`ntitle: Fixture $guide`ntype: guide`n---")
    }
    foreach ($language in @('en','ja')) {
        [IO.File]::WriteAllText("$fixture/content/guide/2025.1/index.$language.md", "---`ntitle: Current guide`ntype: guide`ndate: 2025-01-01`nguide_license: 'CC BY 4.0'`nog_image: https://cdn.example/edition.png`n---`nUnchanged guide body.")
        [IO.File]::WriteAllText("$fixture/content/guide/2024.1/index.$language.md", "---`ntitle: Older guide`ntype: guide`ndate: 2024-01-01`n---`nHistorical guide body.")
    }
    [IO.File]::WriteAllText("$fixture/content/unknown/2025.1/index.md", "---`ntitle: Unknown authors`ntype: guide`ndate: 2025-01-01`n---`nBody.")
    function Build-SeoFixture([string]$name, [string]$extra) {
        [IO.File]::WriteAllText("$fixture/hugo.yaml", @"
baseURL: https://fixture.example/
title: Fixture site
theme: guides
defaultContentLanguage: en
disableKinds: [taxonomy, term, RSS, sitemap]
languages:
  en: {weight: 1}
  ja: {weight: 2}
params:
  description: A long description which must not become the homepage title.
  keywords: guides
  siteProdUrl: https://fixture.example
$extra
"@)
        $log = @(& hugo --source $fixture --destination "$fixture/$name" 2>&1)
        if ($LASTEXITCODE -ne 0 -or @($log | Where-Object { $_ -match '^ERROR' }).Count) {
            throw "SEO fixture failed: $($log -join [Environment]::NewLine)"
        }
    }
    function Read-SeoPage([string]$path) { [IO.File]::ReadAllText("$fixture/$path") }
    function Read-Schema([string]$html, [string]$type) {
        @([regex]::Matches($html, '(?s)<script type="application/ld\+json">(.*?)</script>') | ForEach-Object {
            ConvertFrom-Json $_.Groups[1].Value
        }) | Where-Object { $_.'@type' -eq $type }
    }
    Build-SeoFixture 'configured' "  logo_image: /images/brand.png`n  og_image: /images/social.png`n  seo_title: Editorial homepage title"
    Build-SeoFixture 'fallback' '  logo_image: https://cdn.example/logo.png'
    Build-SeoFixture 'absent' ''
}

Describe 'Rendered SEO metadata' {
    It 'uses a separate homepage title with site-name fallback' {
        (Read-SeoPage 'configured/index.html') | Should -Match '<title>Editorial homepage title</title>'
        (Read-SeoPage 'fallback/index.html') | Should -Match '<title>Fixture site</title>'
        (Read-SeoPage 'fallback/index.html') | Should -Match 'name="description" content="A long description'
    }
    It 'uses configured publisher logos and removes the nonexistent search endpoint' {
        $schema = Read-Schema (Read-SeoPage 'configured/index.html') 'WebSite'
        $schema.publisher.logo.url | Should -Be 'https://fixture.example/images/brand.png'
        $schema.PSObject.Properties.Name | Should -Not -Contain 'potentialAction'
        (Read-Schema (Read-SeoPage 'absent/index.html') 'WebSite').publisher.PSObject.Properties.Name | Should -Not -Contain 'logo'
    }
    It 'uses absolute social URLs, page then site image overrides, and logo fallback' {
        $homepageHtml = Read-SeoPage 'configured/index.html'
        $homepageHtml | Should -Match 'property="og:url" content="https://fixture.example/"'
        $homepageHtml | Should -Match 'property="og:image" content="https://fixture.example/images/social.png"'
        $homepageHtml | Should -Not -Match 'og:image:(width|height)'
        (Read-SeoPage 'fallback/index.html') | Should -Match 'name="twitter:image" content="https://cdn.example/logo.png"'
        (Read-SeoPage 'absent/index.html') | Should -Not -Match '(property="og:image"|name="twitter:image")'
        $translated = Read-SeoPage 'configured/ja/guide/2025.1/index.html'
        $translated | Should -Match 'name="twitter:url" content="https://fixture.example/ja/guide/2025.1/"'
        $translated | Should -Match 'property="og:image" content="https://cdn.example/edition.png"'
    }
    It 'uses the existing version-filtered founding creators and preserves quoted names' {
        $current = Read-Schema (Read-SeoPage 'configured/guide/2025.1/index.html') 'CreativeWork'
        @($current.author).Count | Should -Be 2
        $current.author[0].name | Should -Be 'Creator "One"'
        $current.author[0].url | Should -Be 'https://github.com/creator-one'
        $current.author[1].PSObject.Properties.Name | Should -Not -Contain 'url'
        $current.publisher.logo.url | Should -Be 'https://fixture.example/images/brand.png'
        $older = Read-Schema (Read-SeoPage 'configured/guide/2024.1/index.html') 'CreativeWork'
        @($older.author).Count | Should -Be 1
        (Read-Schema (Read-SeoPage 'configured/unknown/2025.1/index.html') 'CreativeWork').PSObject.Properties.Name | Should -Not -Contain 'author'
    }
    It 'emits only explicit publication licensing and no fabricated edition ancestry' {
        $current = Read-SeoPage 'configured/guide/2025.1/index.html'
        (Read-Schema $current 'CreativeWork').license | Should -Be 'CC BY 4.0'
        $current | Should -Match 'name="license" content="CC BY 4.0"'
        $older = Read-SeoPage 'configured/guide/2024.1/index.html'
        (Read-Schema $older 'CreativeWork').PSObject.Properties.Name | Should -Not -Contain 'license'
        (Read-Schema $older 'TechArticle').PSObject.Properties.Name | Should -Not -Contain 'isBasedOn'
        $older | Should -Not -Match 'name="license"'
        $older | Should -Match '<title>Fixture guide \| January 2024 \| Fixture site</title>'
    }
}
