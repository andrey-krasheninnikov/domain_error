# A practical guide to domain_error

## Problem statement

How can a Dart or Flutter developer understand domain_error quickly, run a
complete example, and find the precise behavior needed for production code?

## Recommended direction

Use a compact technical cover in the existing dark and mint palette, followed
by an executable quick start and a guide organized by scenarios. An API map and
working table of contents give returning readers a shorter path to details.
Keep the full practical guide in the README, with supporting links for history.

Each Dart block is a standalone program with its imports, entry point, types
and assertions. Prefer block bodies, trailing commas, visible grouping and
explanatory Dartdoc. Consolidate upgrades from 2.x, 3.x and 4.x into the current
5.x vocabulary and explain behavior changes as well as renamed symbols.

## Key assumptions to validate

- [ ] The existing public interface supports every documented scenario. Check
  exports and contract tests, then analyze and run the exact README programs.
- [ ] Independent programs remain navigable despite repeated setup. Review the
  rendered guide with its table of contents and compact API map.
- [ ] Images, anchors and tables work in both target environments. Review GitHub
  and a named pub.dev-equivalent preview before release, then the live page.
- [ ] Compatibility claims match the tested SDKs. Check minimum and stable Dart
  and Flutter, keeping dependency resolution independent for the consumer.

## MVP scope

Deliver the complete English README, original cover, accurate diagrams and
badges, runnable examples, API map, compatibility evidence, limitations,
migration, development guidance and the published skill installation command.
Add a small documentation check to the existing Dart CI matrix. Release 5.0.3
through a reviewed PR to main, an annotated tag and pub.dev publication.

## Not doing

- A documentation site or demo: the README is the requested publication surface.
- A new API, dependency or SDK floor: this release documents existing behavior.
- Talker branding or copied visuals: use its presentation as a reference only.
- Coverage or integration claims: show only services that can be verified.
- Forcing an application style through the skill: preserve its current policy.

## Open questions

No product decisions remain. The maintainer selected the technical cover,
scenario-based navigation, direct migration to 5.x, independent programs and
both this concept and an [ADR](../adr/0008-readme-guide.md).
