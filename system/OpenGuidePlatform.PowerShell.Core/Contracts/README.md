# Platform contracts — version 1

These contracts belong to Core because they describe publishing intent and observations. They do not introduce new Hugo rendering inputs. Build, GitHub reporting, filesystem discovery, PDF generation and agent integrations adapt to these contracts.

| Contract | Responsibility |
|---|---|
| site-policy.schema.json | Bespoke wrapper requirements, guide/edition structure, translation intent, download handling and environment exclusions |
| assessment.schema.json | Observed wrapper/guide readiness, findings, evidence, remediation and stage outcome |
| platform-lock.schema.json | Exact coordinated package, module, workflow, component and toolchain identities |

The version-1 JSON Schemas are draft-07 and self-contained. Unknown fields and unsupported schema versions fail validation. A future incompatible contract needs a new schemaVersion and an explicit migration; tools must never silently reinterpret it. See the [current-system reference](../../../docs/architecture/current-system.md) for how these formats are produced and consumed today.

`tests/Contracts/fixtures` contains representative shapes, not installable consumer policies. The one-, two- and fifteen-guide examples use discovered guide names and editions, but their wrapper requirements and translation selections are deliberately incomplete. They must not be injected into deployed sites. The lock has synthetic hashes and an example.invalid package URL, not a release reservation.

Run `pwsh -File .build/Test-PlatformContracts.ps1` locally. The thin Platform contracts workflow runs the same assertions without secrets. E04 incorporates this check into the root build entry point.

## Meaning and ownership

- Consumers own their wrapper requirements and content. There is no universal wrapper file list.
- `intent` declares web, PDF-only, fallback, scaffold or excluded publication. The separate observed state may be unknown. A populated file is not evidence of a reviewed translation.
- Paths in site policy are repository-relative except edition.path (relative to guide.contentRoot) and download.path (relative to its edition). All use forward slashes. Future adapters must resolve and verify containment, including links/reparse points; lexical schema checks are insufficient.
- Permanent exclusions are checked against production configuration even when the requested build targets preview. Kanban's Minionese prohibition is a permanent rule; Scrum's current Klingon exclusion is environment configuration, not an invented permanent prohibition.
- Protected paths and supplied/protected downloads are preservation constraints. Build cannot infer permission to regenerate or edit them.
- A candidate JSON file cannot grant maintainer authority. Trusted policy ownership and reviewer decisions live outside candidate-controlled input. Unknown authority fails closed at the enforcement adapter.
- Findings carry a stable code, affected scope/subject, explanation, remediation and evidence. A pass with a blocker is structurally invalid. Missing/dependent checks yield blocked, not pass.
- Source-language fallback and extension relationships name their targets explicitly. Schema validation checks shape; it cannot establish whether those targets exist.

## Current semantic checks and separate acceptance boundaries

Core checks guide/edition/language relationships, translation fallback and download intent, protected writes and source paths. Build checks effective Hugo configuration, source/assessment freshness, published resources, routes and artifact identity. Adoption and packaging validate release/package checksums and coordinated component identity. These checks have different inputs and should not be described as schema validation alone. The [execution plan](../../../docs/architecture/open-guide-platform-execution-plan.md) records which consumer, release and independent enforcement acceptance gates remain open.

Passing structural or local tests is not evidence that independent enforcement or a consumer deployment has been accepted. Hugo does not load these schemas or fixtures; the GuideSite build loads or generates a policy-shaped inventory and records a separate assessment.

## Download publication paths

A download's `path` locates the source relative to its edition. `publishedPaths` records one or more existing file paths relative to the built site, without a leading slash. Source paths and public paths are deliberately separate because Hugo mounts, language behaviour and wrapper routes vary by consumer. Explicit policies require reviewed public mappings. Inferred source inventories retain owning edition resource roots and defer public-path and byte checks until Validate receives the actual artifact. Prepare still requires the supplied source file; consumers do not maintain public PDF mappings.

Artifact validation requires each eligible mapped file with the same source bytes. PDF-only and declared fallback resources remain valid. Excluded downloads are checked at their declared paths and by source hash/filename throughout the artifact, including outside language prefixes. Shared fallback bytes are allowed only at an explicitly eligible mapped path. Validate passes forbidden public paths to post-deployment verification.
