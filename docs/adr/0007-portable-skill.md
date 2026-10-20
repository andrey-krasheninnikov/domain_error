# Publish version-aware package guidance as a portable skill

## Status and problem

Accepted for issue #12. Projects need package guidance that follows their
resolved domain_error API without importing personal application conventions.
Installation, automatic selection, and correct behavior need separate evidence.

## Decision

Publish flutter-domain-errors under skills/ using the portable SKILL.md format
and the existing skills CLI. Keep a short entry point, shared rules, separate
3.x, 4.x, and 5.x references with executable examples, and migration guidance.
Allow implicit invocation for relevant work in a package with a direct runtime
or development dependency. Resolve the applicable package and actual API before
applying version-specific instructions. A transitive dependency, comment, or
unrelated sibling package is insufficient.

Use lockfiles, overrides, package configuration, and dependency source as
needed. Path and Git dependencies can differ from a hosted version. Unsupported
or unresolved versions require source inspection; installation grants no
permission to upgrade dependencies or migrate untouched code.

Preserve each application's architecture, naming, state management, and return
conventions. Separate domain decisions from diagnostics and redact context
before reporting it. Keep the library's public API and SDK requirements unchanged.

## Alternatives and trade-offs

- One large entry point is easier to package but loads incompatible examples
  together. Version references keep discovery cheap and the selected API clear.
- A dependency-detection script can inspect manifests but cannot force client
  selection. Use instructions and realistic client checks without adding a CLI.
- Separate client skills duplicate contracts. Keep one portable source and
  optional client policy metadata.
- Hooks or an npm installer add a maintenance and permission surface outside
  this task. Use the existing installer and clients' own selection mechanisms.

Description-based selection depends on the client and task context. Confirm it
with requests that do not name the skill. Report installation, selection, and
example execution separately; do not promise a forced universal trigger.

## Assumptions and validation

Validate public examples against 3.0.0, 3.1.0, 4.0.0, and the current 5.x
candidate. Keep executable Markdown examples as the single source and run them
in isolated temporary packages. Maintain deterministic checks in CI.

Exercise matching and non-matching requests in Codex and Claude Code, including
hosted, path, Git, development dependencies, monorepo boundaries, legacy and
unknown versions. Use project-local installations. Test optional global scope
on a disposable CI runner, preserving a control skill. Never change the user's
personal skills or copy credentials into test projects.

The maintainer requested a 5.0.2 documentation release in addition to GitHub
skill distribution. Release only after the rules have been validated and merge
is explicitly allowed. Keep the task worktree after delivery.

## Not doing

No package API change, npm package, custom installer, forced selection hook,
2.x behavioral support, automatic dependency upgrade, application redesign,
global user installation, or README overhaul. README restructuring remains #13.

See [error identity](0001-domain-error-identity-and-diagnostics.md),
[capture behavior](0002-capture-callback-failures.md),
[composition](0004-result-composition.md), and [5.x naming](0005-result-naming.md).
