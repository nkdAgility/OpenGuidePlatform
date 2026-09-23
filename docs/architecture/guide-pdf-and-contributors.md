# Guide PDFs and contributor records

Status: platform part (actions 1 and 3, and section 5) implemented on branch `feature/guide-pdf-and-contributors`; consumer adoption (actions 2 and 4) not started. Section 9 records where the implementation differs from the original draft.

## 1. Purpose and scope

Every generated guide PDF gets a cover page with the title, edition, date, authors, contributors and translators, and every part of the PDF can be overridden per site, guide, edition and language. To make that possible, contributor and translator records move to one data format, and PDF settings move out of guide Markdown into a dedicated site folder.

The work is delivered as four actions:

1. Platform: new contributor record format (section 3).
2. Consumers: adopt the contributor format (section 7).
3. Platform: new PDF format (section 4).
4. Consumers: adopt the PDF format (section 7).

Actions 1 and 3 ship in one coordinated platform release so each consumer performs a single preview update and one adoption branch. Prepare validation (section 5) ships in the same release.

Out of scope: renaming guide identifiers or published PDF filenames, regenerating any PDF without an explicit `generated` declaration and visual review, translation quality, and Hugo module refactoring (E14).

## 2. Current state

Observed in KanbanGuides and ScrumGuide-ExpansionPack on 2026-09-23.

PDF generation (`PdfPublishing/Get-GuidePdfPlan.ps1`) runs Pandoc with XeLaTeX and Pandoc's default LaTeX template. It passes only `--pdf-engine`, `-interaction=nonstopmode`, `lang` and an empty `keywords`. Header files, Lua filters and font overrides are per-invocation parameters; nothing records a site's approved recipe. The shipped `templates/cover-page.tex` is not wired to any invocation and contains Kanban-specific fixed text. ScrumGuide-ExpansionPack still tracks its retired recipe in `scripts/` (`Create-GuidePDFs.ps1`, `callouts-latex.lua`, `callouts-header.tex`, `callouts.lua`, `cover-page.tex`); its cover is the same template with Scrum-specific fixed text.

PDF settings live in guide front matter: `mainfont`, `sansfont`, `monofont` and, for Persian, `dir`. Values are identical for every file of a language, with two exceptions in ScrumGuide-ExpansionPack: Japanese uses Times New Roman/Arial (no CJK glyphs), and `de` 2025.6 declares no fonts.

Contributors are recorded in three inconsistent places:

| Record | Location | Consumers |
|---|---|---|
| Authors | `author:` in every translation's front matter, and again as `role: creator` in `site/data/contributions/<guide>.yml` | JSON-LD `person.html`, Kanban home page |
| Contributors | `site/data/contributions/<guide>.yml` (`.yml` or `.yaml`) filtered by edition | `get-contributors.html` |
| Translators | `translators:` in some translations' front matter; names in body text for others; nothing for many | `guide-translators.html`, `community-translations2.html` |

Known data defects are listed per consumer in section 7.

## 3. Contributor records

### 3.1 Files

```
site/data/contributions/
├── <guide>.yml          ← guide source: creators, contributors, reviewers
└── <guide>.<lang>.yml   ← one translation team: translators, translation reviewers
```

`<lang>` is the content language code exactly as used in `index.<lang>.md`. New files use `.yml`. Hugo does not treat the language suffix in data specially; layouts read `hugo.Data.contributions` with the key `<guide>.<lang>`.

A subfolder per guide is not used because it would collide with the existing `<guide>.yml` key.

### 3.2 Record schema

Both files are YAML lists of records:

| Field | Required | Meaning |
|---|---|---|
| `name` | yes | Display name |
| `role` | yes | One of the roles in 3.3, lower case |
| `contributions` | yes | Edition identifiers (`"2025.7"`) this record applies to |
| `weight` | no | Sort order, ascending; default 100 |
| `localizedNames` | no | Map of language code to the name as displayed in that language |
| `githubUsername`, `gravatarHash`, `url`, `founder` | no | Unchanged from today |

Example `the-kanban-guide.yml` record with a Persian spelling, and `the-kanban-guide.fa.yml`:

```yaml
- name: John Coleman
  role: creator
  contributions: ["2020.7", "2020.12", "2025.5"]
  weight: 1
  localizedNames:
    fa: جان کولمن
```

```yaml
- name: Pedram Keshavarzi
  githubUsername: pedicurus
  url: https://www.agile-gap.com/p/pedram-keshavarzi
  role: translator
  contributions: ["2025.5"]
  weight: 6
```

Within a file a person appears once, identified by `githubUsername` when present, otherwise by `name`.

### 3.3 Roles

| File | Roles | Shown as |
|---|---|---|
| `<guide>.yml` | `creator` | Authors |
| | `contributor`, `reviewer`, `involved` | Contributors (which roles appear is decision D3) |
| `<guide>.<lang>.yml` | `translator` | Translators |
| | `reviewer` | Translation reviewers (decision D4) |

Existing values are normalised on adoption: `Translator` → `translator`, `Reviewer` and `translation reviewer` → `reviewer`. Other values are refused by validation.

### 3.4 Resolution for a page or PDF

For guide `g`, edition `e`, language `l`:

- Authors: records in `g.yml` with `role: creator` and `e` in `contributions`.
- Contributors: other records in `g.yml` for `e`, filtered by the roles selected.
- Translators: records in `g.l.yml` for `e`. Absent for the source language.
- Names: `localizedNames[l]` when present, otherwise `name`.
- Order: `weight`, then `name`.

### 3.5 Retired front matter

`translators:` is removed from all translation files and no longer read. `author:` is retired as well (decision D2). No platform layout reads guide `author` (the JSON-LD `person.html` reads `author` only on creator profile pages); the KanbanGuides home page (site-owned) reads it and is updated during adoption.

### 3.6 Platform changes

- Hugo module: `functions/get-translators.html` implements 3.4 for translation teams (data key matched case-insensitively, so `es-ES` files serve `es-es` pages); `guide-translators.html`, `community-translations2.html` (including PDF-only translations) and `get-participants.html` use it. `functions/localize-contributor.html` applies `localizedNames`, and `get-contributors.html` returns localised records. Language files join the existing all-guides list.
- `baseof.html` keeps the deprecated `.Language.LanguageDirection`: the platform supports Hugo 0.146+, and `.Language.Direction` only exists from 0.158.
- Core ContributorManagement: `New-GuideContributions` and `Update-GuideContributions` accept an optional language and address `<guide>.<lang>.yml`. Existing `.yaml` files remain addressable until renamed.
- Skill `guide.contributions`: documents language files and the role set.

## 4. PDF format

### 4.1 Location

Site-owned PDF configuration lives under `<site.source>/pdf/` (for current consumers, `site/pdf/`). It is outside `content/` so Hugo does not publish templates as page resources, and it follows `site.source` so no additional setting is needed.

### 4.2 Layering

Most specific wins:

| Level | Folder |
|---|---|
| Platform default | `system/OpenGuidePlatform.PowerShell.Core/PdfPublishing/templates/` |
| Site | `site/pdf/` |
| Guide | `site/pdf/<guide>/` |
| Edition | `site/pdf/<guide>/<edition>/` |

At every level a file may carry a language suffix (`cover.fa.tex`, `pdf.ja.yaml`). For a given level the language-suffixed file is applied after the unsuffixed one.

### 4.3 Files

| File | Part | Combination |
|---|---|---|
| `pdf.yaml` | Settings (4.4) | Merged key by key; lists replace |
| `cover.tex` | Cover page | Most specific file replaces |
| `page-header.tex`, `page-footer.tex` | Running header and footer | Most specific file replaces |
| `style.tex` | LaTeX preamble: colours, headings, spacing | Most specific file replaces |
| `licence.tex` | Licence and attribution page | Most specific file replaces |
| `back.tex` | Back page or colophon | Most specific file replaces |
| `filters/*.lua` | Pandoc Lua filters | Accumulate by filename; a same-named file at a more specific level replaces |
| `images/*` | Assets referenced by templates | Resource path, most specific first |

Two fixed platform files are not overridable: `body-start.tex`, added after the front parts so the body starts on page 1, and `rtl.tex`, added for right-to-left languages to define `\LR`/`\RL`, which Pandoc's babel setup for XeTeX omits. A filter's optional `filters/<name>.tex` is raw LaTeX included in the preamble with it.

The name `header.tex` is not used because Pandoc's `--include-in-header` means the preamble, not the running header.

### 4.4 `pdf.yaml` keys

```yaml
mainfont: Times New Roman
sansfont: Arial
monofont: Courier New
CJKmainfont: ""          # required for Japanese/Chinese/Korean line breaking; also CJKsansfont, CJKmonofont
papersize: a4            # a4 | letter
geometry: margin=2.2cm
fontsize: 11pt
toc: false
tocDepth: 2
watermark: ""            # e.g. set for preview translations
licence: ""              # licence page text; no licence page when empty
parts: [cover, licence, body, back]
cover:
  tagline: ""            # e.g. "Based on the Scrum Guide 2020"
  contributorRoles: [contributor, reviewer]
  translatorRoles: [translator]
downloads:               # edition level only
  - path: pdf/<file>.pdf
    handling: supplied   # supplied | protected | generated; default supplied
    papersize: letter    # per-download overrides: papersize, geometry, fontsize, watermark
```

Unknown keys are refused. `downloads` replaces the policy inventory removed during adoption and is the only place a PDF becomes eligible for generation.

When `cover.tagline` is empty and the edition's front matter has `forked_from`, the default cover shows "Based on" followed by the source guide's title and edition.

### 4.5 What is no longer read from front matter

`mainfont`, `sansfont`, `monofont` and `dir` are removed from guide front matter and not read. There is no front-matter override; a single translation that needs different settings gets `site/pdf/<guide>/<edition>/pdf.<lang>.yaml`.

Text direction comes from Hugo's `languages.<lang>.direction` (Hugo 0.158+; the older `languageDirection` key is deprecated but still honoured). Pandoc language metadata continues to come from the filename; `lang` stays out of front matter.

### 4.6 Cover data

Core writes a Pandoc metadata file per PDF and passes it with `--metadata-file`:

| Variable | Source |
|---|---|
| `title`, `short_title`, `date` | Translation front matter |
| `edition` | Edition folder name |
| `guide` | Guide identifier |
| `authors`, `contributors`, `translators` | Section 3.4; each item has `name`, `role` and, when known, `url` |
| `tagline` / `based_on` | `cover.tagline`, or `forked_from` resolved to title and edition |
| `labels.*` | Effective i18n catalogue for the language (4.7) |
| `logo` | `content/<guide>/images/<guide>-logo.png` when present |
| `licence`, `watermark` | `pdf.yaml` |
| `dir` | Set to `rtl` only for right-to-left languages (Pandoc loads bidi support whenever `dir` is set) |

In right-to-left documents, text values without any right-to-left characters (Latin names, untranslated labels) are wrapped in left-to-right spans so their word order and punctuation survive. Pandoc's own title block is suppressed (`title` and `author` are cleared on the command line); the cover replaces it, and `title-meta`/`author-meta` keep the PDF properties.

Templates use Pandoc template syntax, for example `$for(translators)$$translators.name$$sep$ · $endfor$`.

### 4.7 Labels

Labels come from the site i18n catalogue: platform English defaults, then the site catalogue for the source language, then the PDF language. Ids: `pdf_authors_label`, `pdf_contributors_label`, `pdf_translators_label`, `pdf_edition_label`, `pdf_based_on_label` and `pdf_callout_note`, `_tip`, `_important`, `_warning`, `_caution` (callout default titles). Prepare warns when a language with a generated PDF lacks any of them.

### 4.8 Platform defaults

The platform ships a complete default set: `pdf.yaml`, `labels.yaml`, `cover.tex`, `page-header.tex`, `page-footer.tex`, `style.tex`, `licence.tex`, `back.tex`, `filters/callouts.lua` with `filters/callouts.tex`, and `filters/hugo-images.lua`. The callouts filter and image handling come from ScrumGuide-ExpansionPack `scripts/`; review fixed three defects there: body text after the marker line became the title, titles were escaped incorrectly, and emoji icons are absent from the configured fonts (removed). Callout titles are translatable. Defaults contain no guide- or site-specific text. The old `templates/cover-page.tex` is removed.

### 4.9 Core changes

- `Get-GuidePdfPlan` resolves the layered files and settings itself. The per-invocation `HeaderPaths`, `LuaFilterPaths` and `FontOverrides` parameters are removed so the approved recipe is always the committed configuration (decision D6).
- The plan lists every resolved file with the level it came from, the merged settings and the generated metadata. All of these, the contributor data files and the i18n catalogue entries used are fingerprinted.
- Template parts are rendered first, each with its own Pandoc call (`--template <part> --metadata-file`), because Pandoc does not expand variables in included files. The main call then uses `--include-in-header` (rtl support, style, running header/footer, filter preambles), `--include-before-body` (cover, licence, body start) and `--include-after-body` (back page), one `--lua-filter` per resolved filter, `--metadata-file`, `-V` for settings and `--resource-path` for the edition folder and `images/` folders.
- Generation is refused when a required font is not installed, as today.

### 4.10 File naming for new PDFs

New generated downloads use `<edition>/pdf/<guide>.<edition>.<lang>.pdf`. Existing published filenames are preserved and declared explicitly in `downloads`.

## 5. Validation in Prepare

Prepare reports, and the build fails on:

- `translators`, `author`, `mainfont`, `sansfont`, `monofont` or `dir` in guide front matter;
- a contributor record without `name`, `role` or `contributions`, with an unknown role, or duplicated within a file;
- an edition in `contributions` that has no edition folder;
- a data file for a guide or language that does not exist;
- unknown `pdf.yaml` keys or a `downloads` path outside the edition;
- two data files for the same key differing only by `.yml`/`.yaml`.

Prepare warns on a web translation with no translator record and an edition with no creator (only when the site has a `data/contributions` folder), and on a missing PDF label translation for a language with a generated PDF. Findings use the existing assessment scopes: contributor files `guide`, missing creators `edition`, missing translators `translation`, PDF settings `download`, labels `wrapper`.

## 6. Rollout

1. Agree this document and the decisions in section 8.
2. Implement sections 3–5 in the platform with tests; ship one preview release.
3. For each consumer, on a review branch: `./build.ps1 Update -ring preview`, apply section 7, run the full build, compare `Get-GuidePdfPlan` output before and after for every existing download, and review the diff.
4. Generate only downloads declared `generated`; render representative pages including RTL and CJK and record visual approval.
5. KanbanGuides first, then ScrumGuide-ExpansionPack, then remaining consumers.

## 7. Consumer adoption

### 7.1 Common steps

- Move `translators:` into `<guide>.<lang>.yml`; move names recorded only in body text into records; keep the body acknowledgement sections.
- Add `localizedNames` where front matter `author` used a localised spelling; then remove `author:`.
- Normalise roles (3.3); rename `.yaml` data files to `.yml`.
- Create `site/pdf/pdf.yaml` and language files for fonts; remove `mainfont`, `sansfont`, `monofont` and `dir` from front matter.
- Declare `downloads` for every existing PDF (default `supplied`).
- Remove retired PDF scripts and templates.

### 7.2 KanbanGuides

- Minimal PDF configuration: `site/pdf/pdf.yaml` (Times New Roman, Arial, Courier New), `pdf.fa.yaml` (HMXRoya), `pdf.ja.yaml` (Noto Serif JP, Noto Sans JP). Removes 3–4 lines from each of 32 translation files.
- Translators: structured for `ja` and `fa` only. Body text only for `es-ES` and `pl` (2025 editions) and `fr` (open-guide-to-kanban 2025.7). None for `es-419` or any 2020 translation.
- `site/hugo.yaml` already uses the current `direction: rtl` key for `fa`; built Persian pages carry `dir="rtl"`.
- `site/layouts/index.html` shows `.Params.author` from the latest edition; switch it to `functions/get-contributors.html` creators before removing `author`.
- Remove `.agents/skills/guide.genpdfs/cover-page.tex` once the platform default replaces it.
- `min` is a test language; confirm it stays excluded from production.

### 7.3 ScrumGuide-ExpansionPack

- Retire `scripts/Create-GuidePDFs.ps1`, `GuidePdfLanguage.ps1` and its test, `callouts*.lua`, `callouts-header.tex` and `cover-page.tex` after the callouts recipe is in the platform defaults.
- `site/hugo.yaml` uses the deprecated `languageDirection` key for `fa` and `tlh`; rename to `direction`.
- `pdf.ja.yaml` must set CJK fonts; current Japanese PDFs would need them for any regeneration.
- `cover.tagline: Based on the Scrum Guide 2020` at site level replaces fixed cover text.
- Three filename conventions exist: `scrum-guide-expansion-pack.<lang>.pdf` (2025.6, does not match guide identifier `scrum-guide-expanded`, plus an `en-us` variant), `<guide>.<edition>.<lang>.pdf` (2026.1). All preserved via `downloads`.
- `strategy-as-an-empirical-capability/2026.1/pdf/strategy.2026.1.en.pdf` appears to be a stray duplicate; confirm before declaring it.
- Translators: structured for 2025.6 `es`, `fa`, `ja`, `ro`; body only for `pl`; none for `it` (six guides), `nl`, `pt`, `de`, `tlh`. `es` lists Marc Lluva twice. Roles include `contributor` and `translation reviewer`. Japanese translator names exist only in Japanese script.
- Authors: front matter and data disagree for `product-thinking` (three authors vs two creators and one contributor), `holistic-testing` (extra contributor) and `scrum-on-one-page` (no front-matter author). Author order differs between front matter and data; weights must reproduce the intended order.
- `planguage` has no contributions file.
- Three data files use `.yaml`.
- 2026.1 translations of `scrum-guide-expanded` other than `it` are empty and cannot produce a PDF.
- `tlh` is a test language with a published PDF; confirm production exclusion.
- The guide identifier `emergent-strategy-and-depoyment` is misspelt; it is part of live URLs and is not changed here.

## 8. Decisions

Recommendations were accepted when implementation was requested on 2026-09-23.

| # | Decision | Implemented |
|---|---|---|
| D1 | PDF configuration location | `<site.source>/pdf/` |
| D2 | Authors source | Data file `role: creator`; front-matter `author` retired |
| D3 | Roles shown as contributors on the cover | `contributor`, `reviewer`; `involved` excluded (configurable with `cover.contributorRoles`) |
| D4 | Translation reviewers on the cover | Not by default; `cover.translatorRoles: [translator, reviewer]` adds them to the translators list (see section 9) |
| D5 | Localised names | `localizedNames` per record, in whichever file holds the record |
| D6 | Keep per-invocation PDF overrides | No; committed configuration only |
| D7 | Paper-size variants | Per-download override in `downloads` |
| D8 | New PDF filename pattern | `<guide>.<edition>.<lang>.pdf` |
| D9 | Default part order | cover, licence, body, back |
| D10 | Licence page source | Platform default text parameterised by a `licence` key in `pdf.yaml`; body licence paragraphs unchanged |

## 9. Implementation notes

Differences from the original draft, found while implementing and checking real output (English, Persian and Japanese PDFs generated with Pandoc 3.10 and MiKTeX XeLaTeX and inspected page by page):

- Added `CJKmainfont`, `CJKsansfont` and `CJKmonofont`: without `CJKmainfont` Pandoc does not load xeCJK and Japanese lines do not break.
- Added the `licence` key (D10) and per-download `geometry`, `fontsize` and `watermark` overrides.
- The licence text appears on the licence page only, not on the cover and back page as first drafted.
- Removed the unused `pdf_page_label`; added translatable callout titles.
- Added the fixed `body-start.tex` and `rtl.tex` includes (section 4.3) and left-to-right wrapping of Latin text in right-to-left covers and headers; the running header mirrors for right-to-left documents.
- D4: translation reviewers are not a separate cover group. They can be listed with translators through `cover.translatorRoles`; the website still shows the whole translation team.
- Contributor warnings apply only to sites that keep `data/contributions`, so sites without contributor data are not asked for it.
- Missing fonts are reported together, each with the settings file that chose it and the `fontSources` entry saying where to get it; `Test-GuidePdfFonts` reports this for a whole site before generating.
- Right-to-left PDFs use babel `bidi=bidi-r` (the default XeTeX mode loses colour changes) and the `rtl-latin` filter, which marks Latin runs and Latin-only paragraphs as English; cover values use the same marking, including editions and dates.
- Contributors with equal weights keep the data file order, as on the website.
- Core exposes `Get-GuideCredits` (resolved credits) and `Get-GuidePdfDeclaredDownloads` (used by discovery). Discovery records `wrapper.languageDirections`, added to the site-policy schema.
