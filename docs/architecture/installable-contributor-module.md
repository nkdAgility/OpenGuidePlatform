# Installable contributor module

Approved in the module-delivery chat on 2 November 2026. The earlier proposal's
no-required-Gallery-installation v1 boundary is extended by this requirement.
Existing ZIP-based build and adoption contracts remain supported.
Martin subsequently confirmed that CurrentUser module installation is explicitly
disabled on his computer. Installation instructions and actual install checks
must use AllUsers with the required administrator rights; do not bypass this
policy by relocating a user installation. Isolated Save-Module verification is
separate evidence, not an actual Install-Module success claim.
Local dependency installers also default to AllUsers. Hosted runner adapters
select CurrentUser explicitly for their disposable runner accounts; this is not
the local installation procedure. GuideSite Dependencies installs its requested
scope before parsing site settings, so a fresh runner cannot trigger the
settings reader's local AllUsers fallback first.

## Requirements and acceptance

| Requirement | Owner | Preserved contract | Acceptance evidence required |
|---|---|---|---|
| Install with Install-Module | Contributor manifest; PlatformBuild packaging/release | Coordinated release identity, preview/stable separation | Actual feed installation in isolated verification; manifest/version checks |
| Understandable task commands | PowerShell.Contributor | Core owns discovery, translation, credits, PDF and policy operations | Beginner walkthrough, command help and contributor task execution |
| Hide loading and discovery | Contributor context | Site installation selects runtime; installing commands does not upgrade it | Different command/runtime versions, missing capability and stale draft checks |
| Preserve reviewed inputs | Contributor drafts; Core writers | Source/target hashes, protected content and production exclusions | Stale source/target and changed runtime rejection; WhatIf preserves site files |
| Share human and agent operations | Core and installed Agents.Integration skills | Site language before separately selected bodies; existing credits/PDFs | Packaged site/contributor workflows and documentation review |
| Deliver working platform changes | PlatformBuild | Existing root acceptance entry point | Full root build, package install and independent engineering review |

## Design

The proposed Gallery package is named `OpenGuidePlatform`. Its source owner is
`system/OpenGuidePlatform.PowerShell.Contributor`. It supplies task orchestration,
help and draft receipts, never replacement business rules. Its bundled resolver
uses the existing coordinated installation record. Core and GuideSiteBuild are
loaded from that selected runtime, not from whichever module is newest on the
machine. A missing supported operation fails with an update instruction; no
fallback to a different Core implementation is allowed.

Each operation runs Prepare with fresh evidence. Valid discovery from a failing
assessment remains available for repair; the failed assessment is explicitly
reported. Drafts retain workspace, runtime identity, source and target hashes.
Saving checks the retained evidence and calls the owning Core writer. Draft
files are local work products, not publication approval or a security boundary.

Gallery distribution adds a version-stamped module package to platform output.
Publication must consume the validated package and requires a Gallery API key.
No package name, remote availability, successful publication, or hosted CI result
is established merely by this design. GitHub ZIP release publication remains
compatible; no consumer site is changed by platform development.
