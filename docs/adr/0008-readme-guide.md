# Keep the README executable and complete

## Problem and audience

How can new Dart and Flutter users evaluate domain_error and run their first
capture, while existing users find every public operation and its limits in
one guide? The current README mixes current usage with a sequence of migrations,
and several examples depend on declarations outside their code blocks.

## Decision

Rebuild the English README around scenarios: model errors, capture operations,
handle results, compose work, and understand diagnostics and value semantics.
Place a compact technical cover, truthful badges, navigation, installation and
a runnable quick start before the guide. Finish with an API map, compatibility,
a consolidated migration to 5.x, skill installation, development and license.

Keep every Dart code block a standalone program. Extract the exact Markdown
contents into temporary Dart files, analyze them and run their assertions
against the current package on minimum and stable Dart. Migration tables use
inline historical identifiers rather than executable code from old releases.
Check local links and navigation anchors without requiring network access in CI.
Verify external targets and rendered output separately before publication.

Use the existing dark palette, mint accent and bundled IBM Plex fonts. Keep
editable local artwork and PNG exports together. Publish artwork before final
README links, then use absolute raw URLs pinned to that immutable resource
commit. Both GitHub and pub.dev can load the same reviewed bytes without
relying on a disposable branch or a future release tag.

## Alternatives and trade-offs

A showcase gives new visitors a quick introduction but cannot replace the full
guide requested in issue #13. An API-first reference helps experienced users
but makes the first successful operation harder to find. Scenario-based
navigation plus a compact API map supports both audiences.

Short snippets linked to full examples reduce repetition but need a second
source and a consistency check. Standalone programs make the README longer;
they let readers run each example and let CI test the published text directly.
Avoid a new documentation framework, generated site or runtime dependency.

A moving main-branch image URL is simpler, but can change an older release's
illustrations. A future tag is unavailable during review. An immutable resource
commit adds a publication checkpoint and keeps preview and release identical.

## Assumptions and validation

The public 5.x interface already covers every requested scenario. Confirm the
API map against public exports and existing contract tests; preserve library
source, dependencies, stable identifiers and SDK constraints. Run the complete
public examples and Dart checks, plus the independent Flutter consumer at both
SDK endpoints and its minimum runtime dependency resolution.

The guide must work in GitHub and pub.dev Markdown. Use ordinary headings,
tables, fenced code and absolute image links with descriptive alt text. Review
the candidate at desktop and narrow widths before merging. A pub.dev-equivalent
preview does not establish live publication; verify the actual page and archive
after the requested 5.0.3 release.

## Boundaries

No API changes, new capabilities, documentation website, hosted demo, coverage
claims, integrations, application architecture rules or copied Talker assets.
Keep the package identity and MIT license. The separate
[concept](../ideas/readme-guide.md) records the agreed presentation choices.
