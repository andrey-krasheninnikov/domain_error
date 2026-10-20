---
name: flutter-domain-errors
description: Implement, review, or migrate error handling in Dart and Flutter packages that directly depend on domain_error. Verify the applicable pubspec and resolved API before applying version-specific rules. Use for relevant error work, not transitive-only dependencies, textual mentions, or unrelated tasks.
---

# Flutter domain errors

Use the installed package's contract while preserving the project's architecture.
This skill covers pure Dart as well as Flutter; Flutter is not required.

## Establish applicability and version

1. Find the nearest applicable `pubspec.yaml` for each file or package being
   changed. In a monorepo, evaluate each package separately. A dependency in a
   sibling or workspace root does not establish a member's direct dependency.
2. Read the YAML structure. Require `domain_error` in that package's
   `dependencies` or, for relevant development/test work, `dev_dependencies`.
   A comment, textual mention, override alone, or transitive dependency is
   insufficient. For unrelated work, continue without applying these rules.
3. Confirm the resolved version from the applicable `pubspec.lock` and
   `.dart_tool/package_config.json`; account for workspace resolution,
   `dependency_overrides`, and `pubspec_overrides.yaml`. Do not infer the
   installed major from a version range alone.
4. For path/Git dependencies, overrides, missing resolution, or conflicting
   evidence, inspect the selected dependency's `pubspec.yaml`, public exports,
   and implementation. Its actual API takes precedence over a hosted version
   assumption. Do not install or upgrade dependencies merely to use this skill.
5. Load [shared rules](references/rules.md) and only the matching contract:
   [3.x](references/v3.md), [4.x](references/v4.md), or [5.x](references/v5.md).
   For older, newer, or unresolved versions, state the limitation and inspect
   source before recommending version-dependent code. Do not apply another
   major's example or silently migrate the project.

## Apply to the requested work

Trace the changed operation through its existing callers and error boundary.
Use the public import `package:domain_error/domain_error.dart`. Preserve existing
return conventions, naming, state management, and logging ownership. Apply
rules to new or semantically changed flows; leave unrelated legacy code alone.

Use the selected reference's runnable example for capture and branch handling.
For an explicitly requested migration, read [migration](references/migration.md)
and update affected consumers together. Installation alone authorizes no migration.

Check the behavior that changed through the public interface with the project's
SDK and commands. Separate installation success, observed automatic selection,
example execution, and runtime reporting evidence. Client selection is based on
relevance and client support; this skill does not install a forced trigger.

For installation and selection evidence, read [validation](references/validation.md).
