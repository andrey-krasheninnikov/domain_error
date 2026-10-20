# Migrate from domain_error 4.x to 5.0

Use `domain_error: ^5.0.0`. Keep the public import
`package:domain_error/domain_error.dart`. Dart >=3.0.0 <4.0.0 and Flutter 3.10.0
remain supported. This release changes names and generic argument order, with
no compatibility aliases or new result behavior.

## Rename the result family

| 4.x API | 5.0 API |
| --- | --- |
| `Either<L, R>`, including its unnamed constructor | `Result<R, L>`, conventionally written `Result<T, E>` |
| Either.error / Either.success | Result.error / Result.success |
| `EitherError<L, R>` / `EitherSuccess<L, R>` | `ResultError<R, L>` / `ResultSuccess<R, L>` |
| `Result<T>` | `DomainResult<T>` = `Result<T, DomainError>` |
| `FutureResult<T>` type alias | `FutureDomainResult<T>` = Future<`DomainResult<T>`> |
| errorValue / successValue getters and branch fields | error / value |
| `ResultDomainError<T>` extension | `DomainResultError<T>` extension |
| `FutureEitherOperations<L, R>` extension | `FutureResult<R, L>` extension |
| lib/src/either.dart | lib/src/result.dart |
| Former domain aliases in lib/src/result.dart | lib/src/domain_result.dart |
| example/migration_v4.dart | example/composition_example.dart |

Use the public import rather than importing src files. The internal path rows
help locate moved code; those paths are not a separate supported entry point.
The generic Future<Result<T, E>> has no new typedef. FutureResult is now an
extension name, so it cannot replace a FutureDomainResult type annotation.

Put the success type first. Replacing only the type name is insufficient:

```dart
// 4.x
const success = Either<String, int>.success(7);
const error = Either<String, int>.error('missing');
Result<int> load() => captureResultSync(
  () => 7,
  mapToDomainError: (error, trace) => SampleError(cause: error, stackTrace: trace),
);
```

```dart
// 5.0
const success = Result<int, String>.success(7);
const error = Result<int, String>.error('missing');
DomainResult<int> load() => captureResultSync(
  () => 7,
  mapToDomainError: (error, trace) => SampleError(cause: error, stackTrace: trace),
);
```

DomainResult.success/error and ResultSuccess/ResultError constructors remain
const. Keep explicit type arguments in the new T, E order for both branch types.
The same rule applies inside collections, Future, function signatures, bounds,
casts, and type tests. Use U for a transformed success and F for a transformed
error; those mnemonic names do not change call syntax.

## Update getters, patterns, and extension names

```dart
final description = switch (result) {
  ResultError(:final error) => 'error: $error',
  ResultSuccess(:final value) => 'value: $value',
};
```

Read result.error or result.value after checking isError/isSuccess, or use fold.
The domainError getter remains on DomainResult. Explicit extension overrides
and show/hide clauses need the renamed extension as well:

```dart
final error = DomainResultError<int>(domainResult).domainError;
final next = FutureResult<int, DomainError>(pending).map((value) => value * 2);
```

These snippets assume domainResult is DomainResult<int> and pending is
FutureDomainResult<int>. Prefer ordinary instance syntax when no extension
ambiguity exists. Callback parameter names errorValue/successValue become
error/value in the declarations; those parameters are positional.

## Compose with the same contracts

```dart
FutureDomainResult<int> compose() => captureResult<int>(
      () async => 20,
      mapToDomainError: (error, trace) => SampleError(cause: error, stackTrace: trace),
    )
        .andThen((value) async => Result.success(value + 1))
        .map((value) => value * 2)
        .mapError((error) => error)
        .recover((error) => const Result.success(-1));
```

The [runnable composition example](../example/composition_example.dart) defines
SampleError and covers synchronous capture, observation, nullable recovery,
generic error translation, and asynchronous composition. Run it with:

```sh
dart --enable-asserts run example/composition_example.dart
```

Keep fold's error callback first and success callback second. map<U> and
andThen<U> change T; mapError<F> changes E; recover preserves both types. Result
uses mapAsync, andThenAsync, mapErrorAsync, and recoverAsync for FutureOr
callbacks. Future<Result<T, E>> uses the corresponding unsuffixed methods.
Only the selected callback runs. Exceptions and failed source futures propagate;
recover handles an error payload, not a failed future.

## Preserve diagnostic identity and behavior

Keep all typeIdentifier strings, messages, diagnostic causes and stack traces.
Do not derive an identifier from a renamed Dart class. The example
EmptyOrderIdError still reports OrderIdEmptyError. DomainError equality still
excludes diagnostic context. Result equality still requires the same concrete
branch and type arguments plus deep payload equality. Payloads remain stored by
reference, with null and void payloads supported as before.

The two wrong-branch StateError messages remain exactly
`Either.success has no errorValue` and `Either.error has no successValue`.
Their historical names are intentional diagnostic text, not compatibility APIs.
A concrete result's runtimeType now reflects ResultError or ResultSuccess;
do not persist runtimeType names or hashCode values as diagnostic identifiers.

Capture function names, arguments and routing remain unchanged. The async
capture awaits its operation and callbacks in order. Sync observers still
return Null; a sync Future payload is stored without awaiting it. Observer
failures cannot replace the operation result, reporter failures do not recurse,
and mapper failures propagate with their original object and stack trace.

The [4.0 migration guide](migration-4.0.md) retains its historical vocabulary.
For the rationale, retained-name inventory and alternatives, see
[ADR 0005](adr/0005-result-naming.md).
