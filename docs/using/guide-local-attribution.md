# Guide-local attribution in OGP v2.2.0

Each guide owns its credits under its declared `contentRoot`:

```text
content/<guide>/
  _index.md
  data/
    contributors.yml
    translators.fa.yml
    translators.es-ES.yml
  <edition>/
    index.md
```

`contributors.yml` holds creators, contributors, reviewers and involved people.
Each `translators.<language>.yml` holds that language's translation team, including
reviewers. Keep each record's `contributions` list of edition identifiers, roles,
profiles, flags, ordering and localized names. There is no record schema change.
Existing `.yaml` extensions remain supported; do not keep both extensions for
the same guide and language. An unqualified `translators.yml` is invalid.

## Adopt v2.2.0

On the consumer's adoption branch, move `data/contributions/<guide>.yml` to that
guide's `contentRoot/data/contributors.yml`. Move each
`data/contributions/<guide>.<language>.yml` to
`contentRoot/data/translators.<language>.yml`. Preserve the file contents and
remove the retired `data/contributions` directory. Prepare reports the retired
directory as a blocker so an unmigrated site cannot silently lose its credits.
Guide-wide `protectSource` and explicit `protectedPaths` still apply: attribution
inside a protected guide remains read-only to the contributor commands. Have
the maintainer handle approved changes through the existing protection policy;
do not remove protections as part of this migration.

Update bespoke templates that read `hugo.Data.contributions` to use the shared
contributor and translator partials. Validate preview and production with the
selected v2.2.0 platform before publishing. Consumer adoption is separate work;
this platform change does not edit or deploy consumer repositories.

Core resolves paths from the policy's `contentRoot`, not the guide identifier.
Prepare adds a generated Hugo asset mount for each declared guide's data
folder, preserving the site's effective mounts. Templates unmarshal those YAML
assets; asset filenames retain language suffixes even on Hugo 0.146. This also
supports implicit guide sections and externally mounted content, without
relying on a section source file or changing consumer configuration. Ordinary
builds and Serve use the same generated overlay. A direct Hugo diagnostic must
supply equivalent mounts to `assets/ogp-attribution/<guide-id>`.
Site-wide lists
aggregate source and translation records across guide sections, applying the
existing filters and deduplication. Website metadata and generated PDF credits
retain their existing role, edition and language selection.

## Acceptance evidence

| Requirement | Owner | Evidence |
| --- | --- | --- |
| Resolve attribution inside the declared guide, even when its directory differs from its id | Core ContributorManagement | GuideCredits and Contributors tests |
| Preserve roles, editions, localization, ordering, profiles and safe updates | Core ContributorManagement | Existing contributor regression tests, using guide-local fixtures |
| Preserve PDF credits and source fingerprints | Core PdfPublishing | GuidePdfRecipe tests |
| Preserve guide displays, site-wide aggregation and author metadata | Hugo attribution partials | HugoGuideRendering and HugoSeoMetadata tests |
| Detect ambiguous files and require explicit legacy migration | Core assessment and Hugo loader | Attribution regression tests |
| Keep sample multilingual behavior and production exclusions | Reference guide site | Platform build and both sample target builds |

Release versions are supplied by the existing tag/build process. This change
targets v2.2.0; it does not create a release tag or publish a package.
