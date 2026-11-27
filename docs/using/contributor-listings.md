# Contributor listings and badges

Each guide site defines who appears in its listings. OGP supplies the filtering and badge behaviour. It supplies zero flag names and zero listing rules.

Add any flags your site uses to its contributor records in `<guide>/data/contributors.yml`. Then define the filters used by your templates in the site's `hugo.yaml`.

```yaml
params:
  contributorFilters:
    homepage: {}
    guideDetails:
      requireAnyRole: [creator, contributor]
```

This example shows everyone in scope on the homepage and limits guide details to the two named roles. An explicit empty filter, `{}`, selects everyone in scope. If a template requests a missing filter, the build reports its name and where to define it.

| Rule | Who appears |
| --- | --- |
| `requireAnyRole` | Contributors whose role is one of the listed roles. |
| `requireAllFlags` | Contributors who have every flag listed in this rule. |
| `requireAnyFlag` | Contributors who have at least one listed flag. |
| `excludeAnyFlag` | Contributors who have none of the listed flags. |

Each rule accepts a list of strings. A record must satisfy every populated rule in the filter. Omitted rules and empty lists leave that condition unrestricted.

## Filters requested by shared templates

| Filter | Where it is used |
| --- | --- |
| `homepage` | Contributor list on the shared homepage. |
| `guideDetails` | Contributor list on guide details pages. |
| `versionCard` | Contributor list on version cards. |
| `versionCardWithContributors` | Version cards for pages with a populated `contributors` parameter. |
| `creators` | Visible creator list. |
| `guideContributors` | Contributor list in a rendered guide. |
| `officialTranslation` | Contributor list on the official translation view. |
| `jsonLdAuthors` | CreativeWork author metadata for the applicable guide edition. |

Bespoke templates can request any site-defined name by passing `(dict "context" . "filter" "yourFilterName")` to the contributor partial. The site defines each filter requested by the templates it uses.

## Star badge

Set `params.contributorPresentation.starFlag` to a flag used in your site's contributor data if you want matching contributors to display a star. Leaving this setting out disables stars. The setting acts on contributors already selected for display and has no effect on listings or author metadata.

## Upgrade from OGP v2.0.0

Define each filter requested by your templates. Use your existing rendered selections as a comparison when you want to preserve them. Rename `roles` to `requireAnyRole`, `allFlags` to `requireAllFlags`, `anyFlags` to `requireAnyFlag`, and `excludeFlags` to `excludeAnyFlag`. If your site uses stars, add an explicit `starFlag` setting. On the same branch as the YAML migration, install OGP v2.1.0 using `./build.ps1 Update -Ring production -PlatformRelease v2.1.0`. Verify preview and production builds with the target OGP release before committing the migration.
