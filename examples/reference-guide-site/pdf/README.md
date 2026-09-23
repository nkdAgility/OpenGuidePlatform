# PDF configuration

Generated guide PDFs are configured here, outside `content/` so Hugo does not publish these files. Settings are layered; the most specific wins:

| Level | Folder |
|---|---|
| Platform default | OpenGuidePlatform Core `PdfPublishing/templates/` |
| Site | `pdf/` |
| Guide | `pdf/<guide>/` |
| Edition | `pdf/<guide>/<edition>/` |

Each folder may contain `pdf.yaml` (settings, merged key by key), `cover.tex`, `licence.tex`, `back.tex`, `page-header.tex`, `page-footer.tex` and `style.tex` (Pandoc templates, most specific file wins), `filters/*.lua` with an optional companion `filters/<name>.tex` preamble, and `images/`. Add `.<lang>` before the extension (`pdf.fa.yaml`, `cover.ja.tex`) for one language.

Only downloads declared in an edition's `pdf.yaml` with `handling: generated` are ever generated; every other PDF is preserved as supplied. Cover credits come from `data/contributions/<guide>.yml` (role `creator` = authors) and `data/contributions/<guide>.<lang>.yml` (translators). Do not put fonts, `dir`, `author` or `translators` in guide front matter.
