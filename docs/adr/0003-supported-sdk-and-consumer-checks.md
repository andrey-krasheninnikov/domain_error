# Support Dart 3.0 without a Flutter dependency

## Context

The public implementation uses Dart 3 class modifiers, patterns, and switch
expressions. Its interface does not require a newer language version or Flutter.
A Dart 3.13 minimum and runtime dependency floors above Flutter 3.10's pinned
versions unnecessarily exclude older applications.

## Decision

Use Dart 3.0 as the minimum language version, with an upper bound below Dart 4.
Allow collection 1.17.1, meta 1.9.1, and equatable 2.0.7 while retaining ranges
that permit newer compatible versions. Keep the existing public contracts.

Test the library on minimum and current stable Dart. Keep a separate,
non-publishable Flutter consumer with its own resolution and public-interface
tests on Flutter 3.10.0 and current stable. Its minimum-version downgrade checks
the runtime floors without the library test runner's development dependencies.
The library itself has no Flutter SDK dependency.

Use the Makefile's `--line-length=120` formatter argument with the Dart 3.0
language style. Do not rely on formatter configuration that requires a newer
language version.

## Alternatives and trade-offs

Changing only the SDK constraint leaves Flutter's pinned dependencies, newer
callback syntax, and development tooling incompatible. Raising the minimum to
avoid those changes excludes applications the existing interface can support.
Pinning old dependencies would unnecessarily restrict current applications.
A separate Flutter package would add a module without a distinct interface.

The selected approach retains one implementation and adds two SDK endpoints to
verification. The Flutter fixture is excluded from standalone library analysis and the
published archive, and checked separately with its owning Flutter SDK. Repository documentation
remains under `docs/` and is excluded from the archive because Pub expects the
singular `doc/` layout. README links point to those documents on GitHub.

## Revisit

Revisit the minimum when a required public capability cannot be implemented on
Dart 3.0. A newer local toolchain alone is not a reason to raise it. Prove a new
minimum and document its compatibility impact before changing the constraint.
