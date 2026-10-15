# Agent integration

Distributed integration assets for Codex, Claude and GitHub Copilot. This component owns skills, agent definitions, client workflows/commands, hooks, shared instructions and configuration templates as they are implemented.

Current contents:

- `skills/`: the seven publishing skills, usage instructions, license and provenance. Installation places these in the consumer's `.agents/skills/` directory.
- `instructions/guide-site.md`: canonical distributed contributor instructions. Installation uses these for `.agents/agents.md`, the root instruction symlinks and Copilot instructions.
- [Contributor guide](contributor-guide/README.md): shared human-facing task pages and accessible SVG diagrams, included in the GuideSite package.

Future agent definitions, Claude workflows/commands, client hook adapters and configuration templates belong here in clearly named directories. They are not implemented or enabled by this rename.

Executable validation belongs in `OpenGuidePlatform.PowerShell.AgentControls`. Hooks must be thin calls to those PowerShell operations. Skills and workflows call the appropriate publishing/build module rather than duplicate its implementation. Consumer configuration remains reviewed through installation/update; adding this component does not change agent permissions.

## Maintaining contributor documentation

Keep the beginner explanations and expert command references on the same supported workflow. Reusable explanations belong here; consumer sites retain local policy and link to the installed release's source revision. No consumer update or deployment is implied by changing these sources.

Run the platform root `./build.ps1 -Version 0.0.0-local`. Core tests check page presence, local links/heading anchors and accessible SVG structure, including rejection of missing references. Package validation runs the same checker against extracted release bytes; normal packaging includes this component recursively. Packaged sample acceptance exercises preview/production builds and disposable human-operated content and site-language workflows.

Render and visually inspect all four SVGs after diagram edits, including a narrow viewport. Check command examples against the matching Core contracts and independently review the manual and assistant journeys. Technical checks do not establish beginner usability: ask a new contributor to complete setup, first assessment, a selected change and review using only the docs, recording help required and revising confusing steps. Retain source revision, installed version, artifacts and results with review evidence. Do not claim that walkthrough happened unless it did.
