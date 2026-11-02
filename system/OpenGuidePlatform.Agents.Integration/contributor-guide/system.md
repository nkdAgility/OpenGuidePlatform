# How the work fits together

The guide site owns the words and publication decisions. OpenGuidePlatform (OGP) supplies shared tools and instructions. Your agent follows the skills installed for that site.

## Work with an agent

Start with [setup](setup.md) if the agent cannot access the site. Then ask:

> Use this site's installed **guide.transstatus** skill to inspect our chosen language without changing files. Explain which work belongs to the website, which belongs to the guide, and what needs a maintainer or language reviewer. Identify the installed version and actual report used. If you cannot inspect them, say so rather than guessing.

This uses [guide.transstatus](../skills/guide.transstatus/SKILL.md). **You should receive:** a map of the actual work and who can help, not a demand that you learn the site's software architecture.

![OGP supplies skills and tools; your team proposes words; the site team reviews the submission and decides publication.](diagrams/ownership.svg)

The agent can handle supported file operations; you and the language reviewers assess meaning. A maintainer handles site access and review arrangements. Ask them for missing access or capabilities instead of accepting an invented workaround.

**Next:** [your first translation](first-translation.md). The extra background below is for people who want to understand or operate the files themselves.

## I do not have an agent and want to do this manually

You can perform the same operations with the installed commands. [Manual setup](setup.md#i-do-not-have-an-agent-and-want-to-do-this-manually) teaches the tools first. This background explains who owns the files and decisions; it does not grant permission to publish.

OpenGuidePlatform (OGP) supplies shared building and publishing tools. A guide site owns its content, design choices and publication decisions. Your computer holds a working copy of that site's repository, called a clone.

![OGP supplies tools to the local clone; reviewed site changes travel through a pull request to the site repository.](diagrams/ownership.svg)

In words: the installed OGP package supplies commands and matching instructions. You use those commands against the local site files. You submit the reviewed changes to the site's repository through a pull request. Site maintainers decide when those changes reach readers.

| Owner | What belongs there |
|---|---|
| OGP | Reusable procedures, commands, validation, shared templates and these diagrams |
| Guide site | Guide content, wrapper design, editorial rules, guardian contacts and delivery configuration |
| Translation team | Proposed text, glossary decisions and review findings |

The wrapper is the website around a guide: homepages, navigation, buttons, history and translation listings. Translating a guide body alone does not translate that experience. A site may have any number of guides and editions.

Build output goes under `.processing` and is temporary. Do not commit it or edit downloaded platform files. Platform fixes belong in OGP; maintainers adopt a released fix through the coordinated update procedure.

**Next:** [set up your computer](setup.md), or [choose a task](README.md).
