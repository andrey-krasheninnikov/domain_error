# Compose results with explicit synchronous and asynchronous contracts

## Problem

How can Dart and Flutter callers compose result-returning operations without
nested folds, while keeping completion, error routing, and diagnostics explicit?

## Decision

The maintainer selected named capture parameters, `Null` sync observers, and
result-returning recovery before implementation. The comparison and agreement
are recorded in [issue #9](https://github.com/andrey-krasheninnikov/domain_error/issues/9#issuecomment-6298227997).

Keep `captureResult` and `captureResultSync`, requiring the mapper and making
observers optional. Remove both Options classes. Keep one implementation and
public import, with Dart 3.0 and Flutter 3.10 compatibility.

Add `andThen`, `mapError`, and `recover` alongside `map` and `fold` on Either.
`andThen` preserves L and changes R; `mapError` preserves R and changes L;
`recover` preserves both and returns another Either. Error and success payloads
may be null. Preserve unchanged payload references, not wrapper identity.

On Either, the four composition methods have explicit Async variants accepting
FutureOr callbacks and returning Future<Either>. FutureEitherOperations provides
the unsuffixed four methods on Future<Either>, awaiting the source and selected
callback. Only the selected branch runs, once per step, in sequence. Failed
futures and callback exceptions propagate with their objects and stack traces;
recovery handles error payloads. Capture remains the explicit exception boundary.

Sync observers return Null, including the observer failure reporter. Async
functions and void tear-offs fail type checking; wrap a synchronous void
function in a block returning null. Keep observer failure isolation, reporter
non-recursion, original domain error identity, and raw-observer-before-mapper
ordering. Mapper failures propagate. The sync operation stores any T, including
a Future, without awaiting its completion.

## Alternatives and trade-offs

A configured capture object can hold the mapper and observers for reuse, then
run operations through object methods. Capture, chaining, error translation,
recovery, and async composition otherwise require the same result operations.
Named parameters avoid adding configuration types to the common single-call
case. Applications can reuse configuration through an ordinary function.

Factories on result types complicate async capture; extensions on operation
functions make discovery harder. A pipeline builder introduces another execution
model without a required capability. Keep the existing result representation.

Null callbacks trade direct void tear-offs for static async rejection. Runtime
Future detection would need rules for already-started work and delayed failure.
Checking return types cannot detect unawaited work started inside a callback.
Recovery preserves L to keep Result inference predictable; use mapError to change
error vocabulary. New wrappers may be needed when type arguments change.

## Assumptions and validation

Callers need sequential composition, not parallel execution. Validate order,
short-circuiting, selected recovery, nullable/void payloads, type inference,
identity, delayed completion, and exception/trace propagation through the public
import. Compile positive and negative sync-observer consumers on minimum and
stable Dart. Exercise migration examples and an independent Flutter consumer,
including minimum runtime dependency versions.

## Not doing

Global naming harmonization and internal architecture restructuring belong to
subsequent issues. Do not add aliases, a general effect framework, collection
operators, retries, cancellation, streams, or a Flutter library dependency.
