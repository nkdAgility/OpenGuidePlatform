# OpenGuidePlatform current system

This describes the implementation based on repository commit `2a178e6618c2b55c4ff55913e4e7965454ea19c1`, including the Hugo catalogue changes proposed in PR #52 as of 18 September 2026. Each section links to the implementation or schema that supports its claims. The [execution plan](open-guide-platform-execution-plan.md) records acceptance status; this page describes behavior in source, not PR approval, merge status or a completed consumer rollout.

## Components and ownership

| Component | Current responsibility |
|---|---|
| [`OpenGuidePlatform.Hugo.Guides`](../../system/OpenGuidePlatform.Hugo.Guides/layouts/guide/single.html) | Hugo guide templates and reusable presentation partials. Consumer wrappers may have their own layouts and overrides; see the [architecture proposal](open-guide-platform-proposal.md#5-hugo-architecture-and-extension-compatibility) for the ownership boundary. |
| [`OpenGuidePlatform.PowerShell.Core`](../../system/OpenGuidePlatform.PowerShell.Core/OpenGuidePlatform.PowerShell.Core.psm1) | Policy import, guide assessment, publishing operations and PDF operations. |
| [`OpenGuidePlatform.PowerShell.GuideSiteBuild`](../../system/OpenGuidePlatform.PowerShell.GuideSiteBuild/GuideSiteBuild/Invoke-GuideSiteBuild.ps1) | Source discovery and the guide-site Prepare, Build, Validate, Deploy and Verify operations. |
| [`OpenGuidePlatform.PowerShell.GuideSiteAdoption`](../../system/OpenGuidePlatform.PowerShell.GuideSiteAdoption/OpenGuidePlatform.PowerShell.GuideSiteAdoption.psm1) | Installation, update and selected-package restoration. |
| [`OpenGuidePlatform.PowerShell.PlatformBuild`](../../system/OpenGuidePlatform.PowerShell.PlatformBuild/OpenGuidePlatform.PowerShell.PlatformBuild.psm1) | Platform testing, packaging, candidate sample acceptance and release operations. The [distribution package](../../system/OpenGuidePlatform.PowerShell.PlatformBuild/Packaging/Package-OpenGuidePlatform.ps1) keeps this separate from GuideSite. |
| [`OpenGuidePlatform.Agents.Integration`](../../system/OpenGuidePlatform.Agents.Integration/README.md) and [`OpenGuidePlatform.PowerShell.AgentControls`](../../system/OpenGuidePlatform.PowerShell.AgentControls/README.md) | Contributor skills/instructions and a repository governance evaluator. The [AgentControls README](../../system/OpenGuidePlatform.PowerShell.AgentControls/README.md) distinguishes repository code from independently installed enforcement. |

The root [`build.ps1`](../../build.ps1) selects the platform or guide-site operation. The [installed launcher](../../system/OpenGuidePlatform.PowerShell.GuideSiteAdoption/build.ps1) resolves its installed package and calls [`Invoke-GuideSiteBuild`](../../system/OpenGuidePlatform.PowerShell.GuideSiteBuild/GuideSiteBuild/Invoke-GuideSiteBuild.ps1). PlatformBuild packages and tests the candidate GuideSite distribution. The [build instructions](../platform-development.md) define the supported acceptance commands.

## Source and discovery

The [settings reader](../../system/OpenGuidePlatform.PowerShell.GuideSiteAdoption/Resolve-OpenGuidePlatform.ps1) reads `site.source` from `.OpenGuidePlatform/settings.yaml`. [`Build-GuideSite.ps1`](../../system/OpenGuidePlatform.PowerShell.GuideSiteBuild/GuideSiteBuild/Build-GuideSite.ps1) imports a supplied `-PolicyPath`, or calls `New-GuideSiteDiscovery` and saves its result as `discovered-site.json` under that run's `.processing/` directory. The generated file is passed to the same subsequent policy import and assessment code. Installed sites do not have to maintain a separate guide inventory. [Implementation: build entry point](../../system/OpenGuidePlatform.PowerShell.GuideSiteBuild/GuideSiteBuild/Build-GuideSite.ps1).

### How the source list is populated

The **PowerShell filesystem walk**, not `hugo list all`, creates the `guides`, `editions`, `translations` and `downloads` entries. [`New-GuideSiteDiscovery`](../../system/OpenGuidePlatform.PowerShell.GuideSiteBuild/Discovery/New-GuideSiteDiscovery.ps1) obtains the effective default language and content directory, then applies these rules:

| Entry | Exact current recognition rule |
|---|---|
| Guide | Recursively find `_index.md` under the configured content directory; keep a directory when that file's front matter has `type: guide` and `layout: root` and at least one accepted edition. Guide `id` is its path relative to the content directory. |
| Edition/version | Inspect immediate child directories of the guide. Keep one when it contains `index.md`, its layout is not `translations`, `history`, `root` or `details`, and its front matter has either `type: guide` or a `version` field. Use the `version` field as edition `id` when present; otherwise use the directory name. |
| Language | Collect languages from edition-root `index*.md` filenames and from recognised PDF suffixes. `index.md` means the configured default language; `index.<tag>.md` supplies `<tag>`. |
| PDF/download | Find `*.pdf` recursively inside the edition. A filename ending `.<language>.pdf` is assigned to that language; a PDF without a recognised suffix is assigned to the configured default language. Store its path relative to the edition and mark its inferred handling `supplied`. |

For each collected language, the code reads the corresponding `index.md` or `index.<language>.md` body and infers `web` when populated, `pdf-only` when the body is empty but a matching PDF exists, `web` for the empty default-language source, or `fallback` to the default language otherwise. It also records required guide-root, history and translations wrapper files for active guide languages. These are the rules in the [source walk and entry construction](../../system/OpenGuidePlatform.PowerShell.GuideSiteBuild/Discovery/New-GuideSiteDiscovery.ps1); they describe what the code currently recognises, not a proposed content format.

### What the Hugo source listing contributes

Separately, [`Get-GuideSourcePages`](../../system/OpenGuidePlatform.PowerShell.GuideSiteBuild/Discovery/Get-GuideSourcePages.ps1) runs `hugo list all` with the selected configuration and environment. It filters pages according to the effective draft, future and expiry settings and returns page paths and permalinks. Discovery uses those observations to derive page routes, PDF `publicationRoots`, and evidence for environment exclusions; it derives some additional required routes from aliases and output configuration. It does **not** use that listing to enumerate guide directories, edition directories, translation files or PDF files. [Use of `$pages` and route construction in discovery](../../system/OpenGuidePlatform.PowerShell.GuideSiteBuild/Discovery/New-GuideSiteDiscovery.ps1).

An explicit policy is the other supported input. Its [v1 schema](../../system/OpenGuidePlatform.PowerShell.Core/Contracts/site-policy.schema.json) permits reviewed publication intent, protected paths, download handling and wrapper obligations. Discovery returns the same top-level shape but infers values from files; an inferred `web` or `pdf-only` state is not an editorial judgement about translation quality. [Discovery output](../../system/OpenGuidePlatform.PowerShell.GuideSiteBuild/Discovery/New-GuideSiteDiscovery.ps1), [Core inventory](../../system/OpenGuidePlatform.PowerShell.Core/GuideInventory/Get-GuideInventory.ps1).

## Site-policy-shaped inventory format

The [v1 site-policy schema](../../system/OpenGuidePlatform.PowerShell.Core/Contracts/site-policy.schema.json) requires `schemaVersion`, `siteId`, `wrapper`, `guides`, `publication` and `protectedPaths`, and rejects additional properties. It defines repository-relative paths, with edition and download paths relative to their parent entries. Core's path resolver also checks filesystem containment; see [path handling](../../system/OpenGuidePlatform.PowerShell.Core/Internal/Paths.ps1).

| Field | Meaning |
|---|---|
| `wrapper.sourcePath` | Hugo site directory. Wrapper requirements can include `requiredFiles`, `requiredRoutes`, `requiredI18nKeys`, `integrationPoints`, `requiredPageContent`, `runtimeAnchors`, JSON index expectations and recorded legacy aliases. `wrapper.discovery: source` marks generated discovery evidence. |
| `guides[]` | Any number of guides, each with `id`, `contentRoot`, `relationship`, `protectSource` and one or more `editions`. Optional `artifactPrefixes` identify known public paths for exclusions. |
| `editions[]` | Edition `id`, directory `path`, `sourceLanguage` and `translations`. |
| `translations[]` | Language, `intent`, optional `fallbackLanguage` and `downloads`. Intents are `web`, `pdf-only`, `fallback`, `scaffold` and `excluded`. Intent is a declaration or inference, not proof of translation quality. |
| `downloads[]` | PDF path relative to the edition and `handling`: `supplied`, `generated` or `protected`. Explicit policies can record `publishedPaths` and generated-PDF `generationReceipt`; discovery can retain `publicationRoots` for later artifact observation. Source and public paths are distinct. |
| `publication` | Target environments with excluded languages/guides and permanent exclusions for language, guide or edition. |
| `protectedPaths` | Repository paths that publishing operations must preserve. |

The [schema](../../system/OpenGuidePlatform.PowerShell.Core/Contracts/site-policy.schema.json) checks structure. [Core assessment](../../system/OpenGuidePlatform.PowerShell.Core/Assessment/Get-GuideAssessment.ps1) checks declared relationships and source readiness; [Build](../../system/OpenGuidePlatform.PowerShell.GuideSiteBuild/GuideSiteBuild/Build-GuideSite.ps1) separately observes effective Hugo configuration and validates the artifact. The [trusted-policy decision](decisions/004-trusted-policy-authority.md) explains why a candidate-controlled repository file cannot approve its own changes.

## Prepare, assessment and build evidence

The [Prepare branch](../../system/OpenGuidePlatform.PowerShell.GuideSiteBuild/GuideSiteBuild/Build-GuideSite.ps1) resolves the Hugo module, generates or loads the site-policy-shaped input and records source/tool evidence. [`Prepare-GuideSite.ps1`](../../system/OpenGuidePlatform.PowerShell.GuideSiteBuild/GuideSiteBuild/Prepare-GuideSite.ps1) reads effective Hugo configuration and calls [`Get-GuideAssessment`](../../system/OpenGuidePlatform.PowerShell.Core/Assessment/Get-GuideAssessment.ps1). Core [inventory](../../system/OpenGuidePlatform.PowerShell.Core/GuideInventory/Get-GuideInventory.ps1) observes each declared edition/translation body as `populated`, `empty` or `missing`; [translation readiness](../../system/OpenGuidePlatform.PowerShell.Core/TranslationReadiness/Get-GuideTranslationState.ps1) returns `web`, `pdf-only`, `fallback`, `scaffold`, `excluded` or `unknown`. The inventory follows declared fallback chains to populated web content and does not require a web body for PDF-only intent. None of these source checks establishes translation quality.

[`Prepare-GuideSite.ps1`](../../system/OpenGuidePlatform.PowerShell.GuideSiteBuild/GuideSiteBuild/Prepare-GuideSite.ps1) checks downloads, declared generated-PDF receipts, legacy/latest aliases and source translation catalogues, then writes `prepare/assessment.json` and a Markdown report. The [assessment v1 schema](../../system/OpenGuidePlatform.PowerShell.Core/Contracts/assessment.schema.json) defines `sourceCommit`, `platformVersion`, `policyDigest`, `target`, `stage`, `outcome`, `findings` and observed `inventory`. Findings include a code, severity, scope, subject, message, remediation and evidence. The schema permits `pass`, `fail` and `blocked`; Prepare throws unless the assessment passes.

The [build-stage script](../../system/OpenGuidePlatform.PowerShell.GuideSiteBuild/GuideSiteBuild/Build-GuideSite.ps1) saves prepared inputs and tool evidence. Both Build and Validate recheck the prepared inputs, commit, target and policy digest; Build additionally checks the tool hash before invoking Hugo and writing an artifact identity. Validate checks routes/resources, PDF publication, links, JSON indexes and runtime anchors against the built artifact. [`Invoke-GuideSiteBuild`](../../system/OpenGuidePlatform.PowerShell.GuideSiteBuild/GuideSiteBuild/Invoke-GuideSiteBuild.ps1) calls Deploy and Verify when explicitly requested; an ordinary `All` run stops after Validate.

## PDF evidence and preservation

[`Get-GuidePdfPlan` and `New-GuidePdf`](../../system/OpenGuidePlatform.PowerShell.Core/PdfPublishing/Get-GuidePdfPlan.ps1) select only a download declared `generated`, read `index.md` or `index.<language>.md`, and pass language to Pandoc as metadata. They check tools/fonts, render in staging and check the PDF header before publishing. Replacement requires the existing output's expected SHA256. Supplied and protected downloads cannot be selected for generation. [`Get-GuideAssessment`](../../system/OpenGuidePlatform.PowerShell.Core/Assessment/Get-GuideAssessment.ps1) flags `lang` in Hugo front matter as deprecated.

[`New-GuidePdf`](../../system/OpenGuidePlatform.PowerShell.Core/PdfPublishing/Get-GuidePdfPlan.ps1) returns a v1 receipt with guide, edition, language, input/output hashes, configuration hash, toolchain, environment digest and optional cache key. [`Save-GuidePdfReceipt` and `Get-GuidePdfReceipts`](../../system/OpenGuidePlatform.PowerShell.Core/PdfPublishing/Get-GuidePdfReceipts.ps1) save and validate declared receipts; Prepare calls the latter without rerunning Pandoc. [`Test-GuidePdfCache`](../../system/OpenGuidePlatform.PowerShell.Core/PdfPublishing/Test-GuidePdfCache.ps1) uses content/recipe/tool/environment evidence rather than timestamps. The returned PDF result says visual review is required; neither receipt validation nor source discovery assesses translation quality.

At Validate, [`Get-GuideDownloadRequirements`](../../system/OpenGuidePlatform.PowerShell.Core/PublicationPolicy/Get-GuideDownloadRequirements.ps1) uses explicit `publishedPaths` when present. For inferred discovery it considers recorded `publicationRoots` and published JSON `PathPdf` entries, accepts matching artifact paths only when their SHA256 equals the source PDF, and checks excluded PDFs by path, hash and filename across the artifact. [`Get-GuidePublishedDownloads`](../../system/OpenGuidePlatform.PowerShell.GuideSiteBuild/ArtifactValidation/Get-GuidePublishedDownloads.ps1) reads the JSON entries.

## Settings, installation and release files

| File | Owner and current role |
|---|---|
| `.OpenGuidePlatform/settings.yaml` | The [settings reader](../../system/OpenGuidePlatform.PowerShell.GuideSiteAdoption/Resolve-OpenGuidePlatform.ps1) accepts `platform.version`, `platform.ring`, `site.source` and `delivery`; version selection can be exact or a major/minor family. See the [user README](../../readme.md#platform-settings-and-updates) for an example. |
| `.OpenGuidePlatform/installation.json` | The [adoption module](../../system/OpenGuidePlatform.PowerShell.GuideSiteAdoption/OpenGuidePlatform.PowerShell.GuideSiteAdoption.psm1) writes the v1 installation record, including release, native dependency and managed-file hashes. The [installed launcher](../../system/OpenGuidePlatform.PowerShell.GuideSiteAdoption/build.ps1) reads it. |
| `release-manifest.json` | The [packager](../../system/OpenGuidePlatform.PowerShell.PlatformBuild/Packaging/Package-OpenGuidePlatform.ps1) writes schema version 2 with package ZIP names, hashes, component versions, one source commit and PlatformBuild's exact GuideSite dependency. |
| `platform.json` | The same [packager](../../system/OpenGuidePlatform.PowerShell.PlatformBuild/Packaging/Package-OpenGuidePlatform.ps1) writes version, source commit, channel, native Hugo module, workflow and tool requirements into the GuideSite package. |
| `.processing/...` | [`Build-GuideSite.ps1`](../../system/OpenGuidePlatform.PowerShell.GuideSiteBuild/GuideSiteBuild/Build-GuideSite.ps1) writes per-run discovery, prepared inputs, tool evidence and validation results there. |

The [adoption resolver](../../system/OpenGuidePlatform.PowerShell.GuideSiteAdoption/Resolve-OpenGuidePlatform.ps1) validates selected release/package identity; the [adoption module](../../system/OpenGuidePlatform.PowerShell.GuideSiteAdoption/OpenGuidePlatform.PowerShell.GuideSiteAdoption.psm1) handles installation conflicts and the coordinated native Hugo dependency. A run records its selected package for subsequent stages. The generated release manifest and the [platform-lock v1 schema](../../system/OpenGuidePlatform.PowerShell.Core/Contracts/platform-lock.schema.json) are distinct formats.

## Presentation and current limits

Hugo dynamically discovers guides, editions, translations and PDF resources through [capability partials and their contracts](hugo-guide-catalogue.md). The [shared catalogue](../../system/OpenGuidePlatform.Hugo.Guides/layouts/_partials/openguide/guides/get-guide-catalogue.html) retains Hugo Page and Resource objects; the [compatibility adapter](../../system/OpenGuidePlatform.Hugo.Guides/layouts/_partials/functions/get-guide-translations-catalogue.html) projects the existing public JSON fields. Neither reads `discovered-site.json` or `assessment.json`.

The [guide rendering template](../../system/OpenGuidePlatform.Hugo.Guides/layouts/_partials/components/guide/render-guide.html) uses capability functions for PDF lookup and same-path translation fallback. It retains presentation and its existing content-availability rules. The original [execution plan](open-guide-platform-execution-plan.md#16a-e14--refactor-hugo-module-contents-last) defers broader Hugo refactoring until consumer adoption; the catalogue work in PR #52 does not establish that those wider gates have passed.

The [execution plan](open-guide-platform-execution-plan.md#current-acceptance-status) records the remaining consumer adoption, independently administered enforcement, named-release verification and later Hugo work. The presence of a schema or test fixture is not evidence that one of those gates passed.
