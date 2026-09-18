# Hugo guide catalogue contract

The Hugo catalogue is derived from the current Hugo site, its pages and page resources. It is not loaded from the PowerShell discovery or assessment files. PowerShell's source assessment remains a separate build responsibility; see [current system](current-system.md).

## Ownership and naming

Capability partials live directly below `layouts/_partials/openguide/{guides,editions,translations,pdfs,history}/`. The folder names describe guide publishing capabilities. There is no nested `functions/` folder. HTML presentation stays under `components/`; the existing `functions/get-...` entry points remain compatibility adapters.

The paths in the following table are relative to [`openguide/`](../../system/OpenGuidePlatform.Hugo.Guides/layouts/_partials/openguide/). Inputs are Hugo template values, not JSON.

| Partial | Input | Result and responsibility |
|---|---|---|
| `guides/discover-guides.html` | Page | Current site's sections of type `guide`, deduplicated by relative permalink and ordered by weight. |
| `guides/get-guide-catalogue.html` | Page | `SiteLanguage`, `Guides[]`; aggregates editions, translations and PDF resources. |
| `editions/discover-guide-editions.html` | Dict: `Page`, `Scope`, optional `Order` | `Version`, `Page` records in descending date order, or original page order with `Order: source`. `children` uses the page's children; `section` uses the site's regular pages in the page's section. Both filter type `guide` and require a version in the URL. |
| `editions/get-edition-version.html` | Page | First permalink segment matching `YYYY.number`, or an empty string. |
| `editions/select-latest-guide-edition.html` | Page | `Version`, `Page`; date-first selection with the existing lexical URL fallback. |
| `editions/get-guide-version-options.html` | Page | Existing `version`, `url`, `title`, `date`, `page`, `isLatest` records. Latest links to the section root. |
| `translations/discover-edition-translations.html` | Edition Page | Union of `AllTranslations` languages and language suffixes found in edition PDFs. Each record retains pages and resources. |
| `translations/select-preferred-guide-translations.html` | Guide section Page | Public translation rows with `Version`. Orders editions numerically by year/month; an older readable translation takes precedence over a newer PDF-only translation. Preserves the legacy per-edition override hook. |
| `translations/project-legacy-translation.html` | Discovered translation record | The existing public translation fields, including availability and status. This operation reads `.Plain`. |
| `translations/resolve-translation-fallback.html` | Page | Same-path page in the first Hugo language site, preserving the existing fallback lookup. |
| `pdfs/discover-edition-pdfs.html` | Dict: `Page`, optional `Pattern` | All matching `Name`, `Language`, `Resource` records. Default pattern: `pdf/*.*.pdf`. Language is the penultimate dot-separated filename component. |
| `pdfs/select-translation-pdfs.html` | Dict: `PDFs`, `Language` | Case-insensitive language filter over discovered records, preserving order. |
| `pdfs/select-first-edition-pdf.html` | Dict: `Page`, `Pattern` | First matching resource, or `false`; preserves the rendering templates' previous `GetMatch` selection. |
| `history/get-guide-history-chain.html` | Page | Existing `current`, `history`, `forkSource`, `forkHistory` structure containing Hugo pages; preserves explicit fork edition and fallback behavior. |

## Internal structure

`get-guide-catalogue` returns this **in-memory shape**. The names below illustrate a Kanban guide; they are not configuration or a maintained inventory. All entries are discovered.

```text
SiteLanguage: "en"
Guides:
  - Id: "the-kanban-guide"            # Hugo section identifier
    Page: <Hugo section Page>
    Title: "The Kanban Guide"
    LatestVersion: "2025.5"
    Versions:
      - Version: "2025.5"
        Page: <Hugo edition Page>
        Translations:
          - Language: "en"
            Page: <Hugo translated Page, or false if absent>
            EditionPage: <calling edition Page>
            PDFs:
              - Name: "pdf/kanban-guide.en.pdf"
                Language: "en"
                Resource: <Hugo Resource>
            LegacyPDF: <selected Resource, or false>
```

An empty translated page remains a page. A PDF-only language without a page has `Page: false`; no translated page or URL is invented. Multiple matching PDFs remain in `PDFs`. `LegacyPDF` preserves the old single-download choice: last matching edition resource, or first matching translated-page resource when the edition has no match. Resource enumeration follows Hugo's `Resources.Match` order.

Raw discovery and catalogue aggregation do not read `.Content` or `.Plain`. They can be used from rendering without eagerly rendering every translation. Availability projection and preferred-translation selection do read `.Plain` and should not be invoked recursively from a shortcode that is itself being evaluated for that projection. No global cache is introduced; each call retains its language-site context.

## Public compatibility

[`functions/get-guide-translations-catalogue.html`](../../system/OpenGuidePlatform.Hugo.Guides/layouts/_partials/functions/get-guide-translations-catalogue.html) explicitly projects the internal catalogue into the existing JSON-compatible shape. Hugo Page and Resource objects must not be passed directly to `jsonify`. `index.translations.json` continues to use this adapter.

Public guide records retain `Title`, `Path`, `RelPermalink`, `Section`, `Type`, `Weight`, `Description`, `Versions`, `LatestVersion`. Edition records retain `Version`, `Title`, `Date`, `RelPermalink`, `Path`, `Description`, `Latest`, `Translations`.

Translation records retain exactly `Date`, `Language`, `LanguageName`, `Path`, `PathPdf`, `ReadOnline`, `ReadOnlineStub`, `ReadPDF`, `RelPermalink`, `Status`, `Title`, `VersionPath`, `Weight`. The preferred-language list additionally includes `Version`. `ReadOnlineStub` means a page exists, not that it has readable content. `ReadOnline` preserves the existing greater-than-ten-space-separated-words rule. Status remains `published`, `online-only`, `pdf-only` or `site-only`.

The rendering components retain their separate greater-than-500-character content rule and production draft checks. Their PDF patterns and first-match policy remain unchanged. Consolidating these differing availability rules would change behavior and is outside this refactor.

The six existing entry points for catalogue, edition translations, preferred translations, version options, latest version and history remain callable. The catalogue adapter and preferred selection continue calling the legacy per-edition translation hook. Catalogue projection and version options retain the legacy latest-version hook; history retains the legacy version-options hook. Their default implementations delegate to capability partials without recursion. These deliberate extension points preserve existing consumer overrides; raw catalogue discovery still describes the Hugo objects themselves. Consumer adoption must check any additional site-specific overrides.

## Verification

[`HugoCatalogue.Tests.ps1`](../../tests/Core/HugoCatalogue.Tests.ps1) builds multilingual fixtures with several guides, dated editions, empty translations, PDF-only languages, regional language tags, multiple PDFs, fork ancestry, equal-date ordering, consumer overrides and production language exclusion. Existing rendering and SEO tests cover their public output. Acceptance also requires the root platform build and both reference-site targets described in [platform development](../platform-development.md).

These checks establish local platform behavior. They do not establish consumer adoption or deployment approval.
