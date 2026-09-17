# SEO metadata

OGP renders shared metadata in its existing Hugo templates. No template override or extension framework is required for these settings.

| Setting | Behaviour |
| --- | --- |
| `params.seo_title` | Optional complete homepage title. Defaults to the site title, independently of the description. Language-specific site parameters can supply translated titles. Guide titles keep their existing guide-first edition format. |
| Page `og_image`, then `params.og_image`, then `params.logo_image` | Social image precedence. Hugo resolves relative image paths against the build's base URL; absolute URLs are preserved. Without an image, image tags are omitted. OGP does not guess image dimensions or image descriptions. |
| `params.logo_image` | Publisher logo in WebSite and CreativeWork structured data. Omitted when unconfigured. Use an existing asset or absolute image URL. |
| Page `guide_license` | Explicit publication licence text, also emitted in metadata and CreativeWork structured data with Markdown formatting removed. If absent, no licence is inferred from website copyright or another edition. |

Social page URLs use Hugo's page permalink. Configure the build base URL for the intended host. This does not change canonical URL policy.

CreativeWork authors use the same existing contributor discovery and `founder: true`, `role: creator` selection as the visible guide creators. Existing edition filtering is retained. A person's explicit URL takes precedence over their GitHub profile; a missing URL is omitted. If no creators are known, the author property is omitted.

OGP does not advertise a `/search?q=…` search endpoint. Its existing search interface is unchanged. Historical editions do not claim to be based on the latest edition. These changes introduce no new adaptation relationship configuration.

Publication discovery, reader templates, translation/PDF availability, routes, canonicals, sitemap/hreflang generation and XML/JSON feeds retain their existing behaviour.
