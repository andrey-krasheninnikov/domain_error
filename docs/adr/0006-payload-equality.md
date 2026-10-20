# Keep symmetric payload equality in one place

## Status and problem

Accepted for [issue #11](https://github.com/andrey-krasheninnikov/domain_error/issues/11).
How can maintainers keep Result equality consistent between error and success
branches without changing the public interface or operation behavior?

The core has four flat modules. Both Result branches repeat the same two-way
payload comparison. Most other repetition expresses distinct synchronous and
asynchronous contracts already recorded in ADR 0002 and ADR 0004.

## Decision

Use one private `_payloadsEqual` function in the existing Result module. It
compares the first payload with the second, then compares the second with the
first only if the first comparison succeeds. Both `operator ==` implementations
call it after their existing identity, runtime type, and branch type checks.

Keep both directions: collection equality can depend on operand order, as the
public tests demonstrate for a List and a non-List Iterable. Keep hashing,
payload references, constructors, generic type distinctions, and wrong-branch
error messages unchanged. The helper is private; the public package import
remains the test seam. No new seam or adapter is needed for this in-process
policy.

## Alternatives and deletion test

- Keep the existing implementation: avoids a helper call, but leaves the same
  equality policy in two branch modules. The maintainer selected the small
  locality improvement after comparing this option with the extraction.
- Centralize payload equality: deleting the helper puts the two-way rule back
  in both callers. Its limited leverage is concentrating that rule, not reducing
  the public interface or adding behavior.
- Route composition through a common primitive: the current two-arm switches
  keep the selected callback and skipped branch together. A common primitive
  adds closures and indirection without a demonstrated locality benefit.
- Unify sync and async capture: their return types, observer types, waiting,
  and Future payload handling differ. Deleting `_observe` or `_observeSync`
  spreads observer/reporter isolation across callers. Retain both helpers.
- Merge domain specialization or diagnostic rendering into other modules:
  this increases generic Result's knowledge of DomainError or disperses message
  normalization. The existing modules already keep those responsibilities local.

## Trade-off and assumptions

The extraction adds one navigation step when reading equality. The expected
benefit is a single location for its non-obvious two-way rule. It does not make
Result deeper for callers. Revisit the helper if it acquires branch-specific
parameters or stops representing a shared policy.

Existing public-interface tests cover the affected behavior. Validate that
assumption with the unchanged equality tests before and after the extraction,
then the complete supported Dart and Flutter checks. Preserve the original
comparison order and short-circuit behavior by moving the expression intact.

## Not doing

No public capabilities, global renaming, SDK changes, dependencies, execution
engine, general equality framework, or new production test seams. Keep the
capture, composition, diagnostics, identity, and formatting contracts in
[ADR 0001](0001-domain-error-identity-and-diagnostics.md),
[ADR 0002](0002-capture-callback-failures.md),
[ADR 0004](0004-result-composition.md), and
[ADR 0005](0005-result-naming.md).

See the [Result implementation](../../lib/src/result.dart) and
[public equality tests](../../test/result_test.dart).
