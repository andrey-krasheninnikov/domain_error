# Migrate from domain_error 3.x to 4.0

This guide describes the 3.x to 4.0 migration. For current names, continue with
[the 4.0 to 5.0 guide](migration-5.0.md).

Use `domain_error: ^4.0.0`. Keep the public import
`package:domain_error/domain_error.dart`. Dart >=3.0.0 <4.0.0 and Flutter 3.10.0
remain supported.

## Move Options fields into the capture call

Both Options classes are removed without aliases. Keep the operation as the
first positional argument. Pass `mapToDomainError` directly as a required named
parameter; `onDomainError`, `onRawError`, and `onObserverError` remain optional.

Before:

```dart
final result = await captureResult<int>(
  () async => 20,
  options: CaptureResultOptions(
    mapToDomainError: (error, trace) => SampleError(cause: error, stackTrace: trace),
  ),
);
```

After:

```dart
final result = await captureResult<int>(
  () async => 20,
  mapToDomainError: (error, trace) => SampleError(cause: error, stackTrace: trace),
);
```

Apply the same flattening to `CaptureResultSyncOptions`. Reuse mapping and
observation configuration through an application function when needed.

## Make synchronous observers explicit

All three observers in `captureResultSync` return `Null`. Async closures,
Future-returning tear-offs, and void tear-offs are rejected by type checking.
Wrap a synchronous void function:

```dart
final result = captureResultSync<int>(
  () => throw const SampleError(),
  mapToDomainError: (error, trace) => SampleError(cause: error, stackTrace: trace),
  onDomainError: (error, trace) {
    logError(error, trace);
    return null;
  },
);
```

Use this form for `onRawError` and `onObserverError` too. If an observer is async,
use `captureResult` and await the result. Its callbacks accept FutureOr and are
awaited in order. Do not start unawaited work inside a sync observer; return-type
checking cannot prevent internal side effects.

The synchronous operation stores its returned T unchanged. Returning a Future
produces a successful result containing that future, without waiting for it or
capturing later failures. To capture those failures, use `captureResult`.

## Replace nested folds with composition

- `map<R2>` transforms a success into a value of R2.
- `andThen<R2>` transforms a success into `Either<L, R2>`.
- `mapError<L2>` transforms an error into L2, preserving a success payload.
- `recover` handles an error and returns `Either<L, R>`. Return a success for a
  selected fallback or an error to preserve or replace the failure.

Only the selected branch runs, once per step. Null remains a valid error or
success payload. Use mapError when changing the error type; recovery preserves
both types.

```dart
final result = const Either<String, int>.error('missing').recover(
  (error) => error == 'missing' ? const Either.success(42) : Either.error(error),
);
assert(result.successValue == 42);
```

On Either, use `mapAsync`, `andThenAsync`, `mapErrorAsync`, or `recoverAsync`
for FutureOr callbacks. Each returns a Future<Either>.

On Future<Either>, use the corresponding unsuffixed methods. They await the
source and selected callback, so a chain needs only one final await:

```dart
final result = await captureResult<int>(
  () async => 20,
  mapToDomainError: (error, trace) => SampleError(cause: error, stackTrace: trace),
)
    .andThen((value) async => Either.success(value + 1))
    .map((value) => value * 2)
    .mapError((error) => error)
    .recover((error) => const Either.success(-1));
assert(result.successValue == 42);
```

Call fold after awaiting the completed chain. Existing constructors, concrete
branch classes, getters, fold, map, Result, and FutureResult remain available.

## Preserve exception and identity rules

Composition does not capture thrown exceptions. A transform or recovery
exception propagates with its original object and stack trace. A failed source
Future propagates too; recover handles an Either error payload. Wrap a throwing
operation in capture explicitly when it should produce a domain error.

Capture routing remains unchanged: an original DomainError is observed and
returned as the same object. A raw error is observed before mapping; the mapped
error does not trigger onDomainError again. Observer failures reach optional
onObserverError. Its absence or failure never replaces the operation result or
recurses. Mapper failures propagate.

Keep existing typeIdentifier strings and domain error equality rules. Diagnostic
cause and stackTrace remain outside equality. Composition preserves unchanged
payload references; do not depend on the identity of an Either wrapper.

Run [the complete example](https://github.com/andrey-krasheninnikov/domain_error/blob/v4.0.0/example/migration_v4.dart), which defines SampleError
and exercises capture, observation, chaining, translation, recovery, and null:

```sh
dart --enable-asserts run example/migration_v4.dart
```
