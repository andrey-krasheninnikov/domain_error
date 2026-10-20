# domain_error

[![domain_error: model expected failures and capture thrown errors as explicit success or error results](https://raw.githubusercontent.com/andrey-krasheninnikov/domain_error/abfbda92ffa6a77dd1f9a4536b462702d6a1e8c2/assets/cover.png)](https://raw.githubusercontent.com/andrey-krasheninnikov/domain_error/abfbda92ffa6a77dd1f9a4536b462702d6a1e8c2/assets/cover.png)

[![pub.dev version](https://img.shields.io/pub/v/domain_error.svg)](https://pub.dev/packages/domain_error)
[![Dart and Flutter checks](https://github.com/andrey-krasheninnikov/domain_error/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/andrey-krasheninnikov/domain_error/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/andrey-krasheninnikov/domain_error/blob/main/LICENSE)

Domain errors and explicit operation results for Dart and Flutter. Model an
expected failure with `DomainError`, capture a throwing operation at its boundary,
and handle or compose its `Result` without nested `try`/`catch` blocks.

The package is pure Dart. It has no Flutter SDK dependency and does not choose
state management, logging or application layers for you.

## Contents

- [When to use it](#when-to-use-it)
- [Install](#install)
- [Quick start](#quick-start)
- [Model domain errors](#model-domain-errors)
- [Capture operations](#capture-operations)
  - [Synchronous capture and observation](#synchronous-capture-and-observation)
  - [Asynchronous capture](#asynchronous-capture)
- [Handle results](#handle-results)
- [Compose operations](#compose-operations)
  - [Map and chain successful values](#map-and-chain-successful-values)
  - [Translate errors and recover](#translate-errors-and-recover)
  - [Compose asynchronous work](#compose-asynchronous-work)
- [Exceptions and asynchronous boundaries](#exceptions-and-asynchronous-boundaries)
  - [Callback failures and failed futures](#callback-failures-and-failed-futures)
  - [Late Future and Stream errors](#late-future-and-stream-errors)
- [Equality and mutable payloads](#equality-and-mutable-payloads)
- [Diagnostics and reporting](#diagnostics-and-reporting)
- [API map](#api-map)
- [Compatibility](#compatibility)
- [Migrate to 5.x](#migrate-to-5x)
- [Package skill](#package-skill)
- [Development](#development)
- [License](#license)

## When to use it

Use a domain error when a caller needs to distinguish an expected application
outcome, such as an empty order ID, an unavailable order or a rejected order.
A feature-specific error hierarchy lets the caller make that decision without
parsing exception messages.

Use `Result<T, E>` when an operation returns either a value of `T` or an error of
`E`. The error can be any type. `DomainResult<T>` specializes it to `DomainError`;
`FutureDomainResult<T>` is `Future<DomainResult<T>>`.

Use capture at a boundary where a throwing operation should become a domain
result. Map other thrown objects into your vocabulary there. Keep that mapping
selective so programming failures are not silently presented as expected outcomes.
An ordinary return value or exception remains appropriate when the caller does
not need a result value to inspect or compose.

Capture handles an operation and its returned future. Composition transforms
existing result values. The package supplies no retries, cancellation, parallel
execution, stream operator, logger or reporting integration.

## Install

```sh
dart pub add domain_error
# In a Flutter project:
flutter pub add domain_error
```

Or add this dependency:

```yaml
dependencies:
  domain_error: ^5.0.0
```

Import `package:domain_error/domain_error.dart`. Use the public import for all
types and extensions; internal `src` paths are not separate supported entry points.
Requires Dart `>=3.0.0 <4.0.0`. See [compatibility](#compatibility) for the tested
Dart and Flutter endpoints.

## Quick start

Every Dart block in this README is an independent program. Save one as
`bin/example.dart` in a project with the dependency, then run
`dart --enable-asserts run bin/example.dart`. This program prints `Order 42`.

```dart
import 'package:domain_error/domain_error.dart';

/// Converts an unavailable order into the application's error vocabulary.
final class OrderUnavailableError extends DomainError {
  const OrderUnavailableError({
    super.cause,
    super.stackTrace,
  });

  @override
  String get typeIdentifier {
    return 'OrderUnavailableError';
  }
}

Future<void> main() async {
  final result = await captureResult<int>(
    () async {
      return 42;
    },
    mapToDomainError: (error, trace) {
      return OrderUnavailableError(
        cause: error,
        stackTrace: trace,
      );
    },
  );

  final description = result.fold(
    (error) {
      return error.typeIdentifier;
    },
    (value) {
      return 'Order $value';
    },
  );

  assert(description == 'Order 42');
  print(description);
}
```

[`example/domain_error_example.dart`](https://github.com/andrey-krasheninnikov/domain_error/blob/main/example/domain_error_example.dart)
contains a larger order-loading example with success, domain errors, timeouts
and other thrown objects.

## Model domain errors

[![DomainError separates comparable business fields from diagnostic cause and stack trace, with one error hierarchy per feature](https://raw.githubusercontent.com/andrey-krasheninnikov/domain_error/abfbda92ffa6a77dd1f9a4536b462702d6a1e8c2/assets/flow.png)](https://raw.githubusercontent.com/andrey-krasheninnikov/domain_error/abfbda92ffa6a77dd1f9a4536b462702d6a1e8c2/assets/flow.png)

Extend `DomainError` in your own library. A sealed feature root groups related
outcomes while allowing exhaustive handling within your application's model.
Set `typeIdentifier` explicitly. Preserve the string when renaming the Dart class;
for example, `EmptyOrderIdError` can retain the identifier `OrderIdEmptyError`.
Runtime type names and hash codes are not stable identifiers.

By default, equality includes the concrete error type, `typeIdentifier` and
`message`. Diagnostic `cause` and `stackTrace` do not participate. Include business
fields through `props`, preserving `super.props`:

```dart
import 'package:domain_error/domain_error.dart';

/// Groups order failures without prescribing an application architecture.
sealed class OrderError extends DomainError {
  const OrderError({
    super.message,
    super.cause,
    super.stackTrace,
  });
}

/// The rejection reason is business data and participates in equality.
final class OrderRejectedError extends OrderError {
  final String reason;

  const OrderRejectedError({
    required this.reason,
    super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  String get typeIdentifier {
    return 'OrderRejectedError';
  }

  @override
  List<Object?> get props {
    return [
      ...super.props,
      reason,
    ];
  }
}

void main() {
  const first = OrderRejectedError(reason: 'closed');
  final diagnosticCopy = OrderRejectedError(
    reason: 'closed',
    cause: StateError('warehouse unavailable'),
    stackTrace: StackTrace.current,
  );
  const different = OrderRejectedError(reason: 'invalid quantity');

  assert(first == diagnosticCopy);
  assert(first.hashCode == diagnosticCopy.hashCode);
  assert(first != different);
}
```

Keep business fields and their nested collections immutable. A changing field
in `props` can change the error's equality and hash while it is stored in a set
or used as a map key.

## Capture operations

[![Capture returns success for a value, preserves a thrown DomainError, and observes other thrown objects before mapping them](https://raw.githubusercontent.com/andrey-krasheninnikov/domain_error/abfbda92ffa6a77dd1f9a4536b462702d6a1e8c2/assets/overview.png)](https://raw.githubusercontent.com/andrey-krasheninnikov/domain_error/abfbda92ffa6a77dd1f9a4536b462702d6a1e8c2/assets/overview.png)

Both capture functions take the operation as the first positional argument and
require the named `mapToDomainError` callback. Observers are optional.

| Operation outcome | Order | Returned result |
| --- | --- | --- |
| Value | No observer or mapper | `Result.success(value)` |
| Thrown `DomainError` | `onDomainError` | `Result.error` holding the same error instance |
| Other thrown object | `onRawError`, then `mapToDomainError` | `Result.error` holding the mapped error |

The mapped error does not trigger `onDomainError` again. Observers receive the
caught stack trace. Stored diagnostic fields remain the mapper's responsibility;
capture preserves an existing domain error without filling or replacing its fields.

### Synchronous capture and observation

`captureResultSync<T>` returns `DomainResult<T>` immediately. The operation and
mapper are synchronous. All three observers return `Null`: an async function or
a `void` tear-off does not match the required type. Wrap a synchronous `void`
function in a block ending with `return null`, as below.

Observer failures reach optional `onObserverError`. Its absence or its own failure
never replaces the operation result, and it is not called recursively. A mapper
failure propagates; it is not an observer failure.

```dart
import 'package:domain_error/domain_error.dart';

/// Keeps a technical cause without making it part of error equality.
final class OrderUnavailableError extends DomainError {
  const OrderUnavailableError({
    super.cause,
    super.stackTrace,
  });

  @override
  String get typeIdentifier {
    return 'OrderUnavailableError';
  }
}

void main() {
  final events = <String>[];
  final trace = StackTrace.fromString('order.load');
  const original = OrderUnavailableError();
  final raw = StateError('warehouse unavailable');

  /// Uses the same boundary to demonstrate both error routes.
  DomainResult<int> capture(Object failure) {
    return captureResultSync<int>(
      () {
        Error.throwWithStackTrace(failure, trace);
      },
      mapToDomainError: (error, stackTrace) {
        events.add('map');
        return OrderUnavailableError(
          cause: error,
          stackTrace: stackTrace,
        );
      },
      onDomainError: (error, stackTrace) {
        events.add('domain');
        throw StateError('observer failed');
      },
      onRawError: (error, stackTrace) {
        events.add('raw');
        return null;
      },
      onObserverError: (error, stackTrace) {
        events.add('report');
        throw StateError('reporting failed');
      },
    );
  }

  final preserved = capture(original);
  final mapped = capture(raw);

  assert(identical(preserved.domainError, original));
  assert(identical(mapped.domainError.cause, raw));
  assert(identical(mapped.domainError.stackTrace, trace));
  assert(events.join(',') == 'domain,report,raw,map');
}
```

Return-type checks cannot prevent a synchronous observer from starting unawaited
work internally. Use asynchronous capture when observation must await work.

### Asynchronous capture

`captureResult<T>` returns `Future<DomainResult<T>>`. It accepts `FutureOr`
callbacks and awaits the operation, selected observer, observer failure reporter
and mapper in order. This example verifies that reporting completes before mapping.

```dart
import 'package:domain_error/domain_error.dart';

/// Stores the original failure and trace supplied to the mapper.
final class OrderUnavailableError extends DomainError {
  const OrderUnavailableError({
    super.cause,
    super.stackTrace,
  });

  @override
  String get typeIdentifier {
    return 'OrderUnavailableError';
  }
}

Future<void> main() async {
  final events = <String>[];
  final raw = StateError('warehouse unavailable');

  final result = await captureResult<int>(
    () async {
      await Future<void>.delayed(Duration.zero);
      throw raw;
    },
    onRawError: (error, trace) async {
      await Future<void>.delayed(Duration.zero);
      events.add('raw');
      throw StateError('observer failed');
    },
    onObserverError: (error, trace) async {
      await Future<void>.delayed(Duration.zero);
      events.add('report');
    },
    mapToDomainError: (error, trace) async {
      await Future<void>.delayed(Duration.zero);
      events.add('map');
      return OrderUnavailableError(
        cause: error,
        stackTrace: trace,
      );
    },
  );

  assert(result.isError);
  assert(identical(result.domainError.cause, raw));
  assert(events.join(',') == 'raw,report,map');
}
```

## Handle results

[![Sync and async capture return domain results with error and success branches; fold handles both and map changes only success](https://raw.githubusercontent.com/andrey-krasheninnikov/domain_error/abfbda92ffa6a77dd1f9a4536b462702d6a1e8c2/assets/fold.png)](https://raw.githubusercontent.com/andrey-krasheninnikov/domain_error/abfbda92ffa6a77dd1f9a4536b462702d6a1e8c2/assets/fold.png)

`Result<T, E>` is sealed, with `ResultSuccess<T, E>` and `ResultError<T, E>`
branches. Construct them with `Result.success` / `Result.error` or the concrete
branch constructors. These constructors are const when their payload is const.
The success type comes first.

Use `fold(onError, onSuccess)` or a switch to handle both branches. Only the
selected callback runs. `isSuccess` and `isError` test the branch. Reading
`value` from an error, or `error` from a success, throws `StateError`.
`domainError` is the error getter on `DomainResult<T>` and also throws on success.

A null payload is a valid success or error; branch identity does not depend on
whether the payload is null. A `Result<void, E>` can represent successful
completion without a useful value.

```dart
import 'package:domain_error/domain_error.dart';

/// Matches the public concrete branches with Dart 3 object patterns.
String describe(Result<int, String> result) {
  switch (result) {
    case ResultError(:final error):
      return 'Error: $error';
    case ResultSuccess(:final value):
      return 'Order $value';
  }
}

void main() {
  const success = Result<int, String>.success(42);
  const error = Result<int, String>.error('missing');
  const nullableSuccess = ResultSuccess<int?, String?>(null);
  const nullableError = ResultError<int?, String?>(null);
  const completed = Result<void, String>.success(null);

  final folded = success.fold(
    (error) {
      return 'Error: $error';
    },
    (value) {
      return 'Order $value';
    },
  );

  assert(folded == describe(success));
  assert(describe(error) == 'Error: missing');
  assert(success.isSuccess && success.value == 42);
  assert(error.isError && error.error == 'missing');
  assert(nullableSuccess.isSuccess && nullableSuccess.value == null);
  assert(nullableError.isError && nullableError.error == null);
  assert(nullableSuccess != nullableError);
  assert(completed.isSuccess);
}
```

## Compose operations

Composition selects one branch at each step. Skipped callbacks do not run;
selected steps run once, in order. Unchanged payloads retain their references;
wrapper identity is not a contract. Composition does not capture exceptions.

### Map and chain successful values

`map<U>` turns a successful value into a value of `U`. `andThen<U>` runs an
operation returning `Result<U, E>`, so it can choose success or error. Both skip
an existing error and preserve its payload.

```dart
import 'package:domain_error/domain_error.dart';

void main() {
  final events = <String>[];

  final total = const Result<int, String>.success(2).map(
    (quantity) {
      events.add('price');
      return quantity * 20;
    },
  ).andThen(
    (subtotal) {
      events.add('limit');
      if (subtotal > 100) {
        return const Result<int, String>.error('limit exceeded');
      }
      return Result<int, String>.success(subtotal);
    },
  );

  final skipped = const Result<int, String>.error('sold out').andThen(
    (quantity) {
      events.add('unexpected');
      return Result<int, String>.success(quantity);
    },
  );

  assert(total.value == 40);
  assert(skipped.error == 'sold out');
  assert(events.join(',') == 'price,limit');
}
```

### Translate errors and recover

`mapError<F>` changes the error type from `E` to `F`, preserving a success.
`recover` runs only for an error and returns another `Result<T, E>`. Return a
success for a selected fallback or an error to preserve or replace the failure.
Recovery preserves both type arguments; use `mapError` to change error vocabulary.

```dart
import 'package:domain_error/domain_error.dart';

/// A small application vocabulary for a boundary's numeric error codes.
enum OrderFailure {
  missing,
  unavailable,
}

void main() {
  final translated = const Result<int, int>.error(404).mapError<OrderFailure>(
    (code) {
      if (code == 404) {
        return OrderFailure.missing;
      }
      return OrderFailure.unavailable;
    },
  );

  final recovered = translated.recover(
    (error) {
      if (error == OrderFailure.missing) {
        return const Result<int, OrderFailure>.success(0);
      }
      return Result<int, OrderFailure>.error(error);
    },
  );

  var called = false;
  final unchanged = const Result<int, OrderFailure>.success(42).recover(
    (error) {
      called = true;
      return Result<int, OrderFailure>.error(error);
    },
  );

  assert(translated.error == OrderFailure.missing);
  assert(recovered.value == 0);
  assert(unchanged.value == 42 && !called);
}
```

### Compose asynchronous work

| Receiver | Methods | Callback completion | Return |
| --- | --- | --- | --- |
| `Result<T, E>` | `map`, `andThen`, `mapError`, `recover` | Synchronous | `Result` |
| `Result<T, E>` | `mapAsync`, `andThenAsync`, `mapErrorAsync`, `recoverAsync` | Awaited `FutureOr` | `Future<Result>` |
| `Future<Result<T, E>>` | `map`, `andThen`, `mapError`, `recover` | Source and selected `FutureOr` callback awaited | `Future<Result>` |

On a future, the unsuffixed methods come from the public `FutureResult<T, E>`
extension. A chain needs one final `await`; call `fold` on the completed result.
The generic future has no `FutureResult` typedef. Use `FutureDomainResult<T>`
for the domain specialization or `Future<Result<T, E>>` for other error types.

```dart
import 'package:domain_error/domain_error.dart';

Future<void> main() async {
  final mapped = await const Result<int, String>.success(20).mapAsync(
    (value) async {
      return value + 1;
    },
  );
  final chained = await mapped.andThenAsync(
    (value) async {
      return Result<int, String>.success(value * 2);
    },
  );
  final translated = await const Result<int, int>.error(404).mapErrorAsync(
    (code) async {
      return 'HTTP $code';
    },
  );
  final recovered = await translated.recoverAsync(
    (error) async {
      return const Result<int, String>.success(0);
    },
  );

  final events = <String>[];
  final pipeline = await Future<Result<int, String>>.value(
    const Result.success(20),
  ).andThen(
    (value) async {
      events.add('chain');
      return Result<int, String>.success(value + 1);
    },
  ).map(
    (value) {
      events.add('map');
      return value * 2;
    },
  ).mapError(
    (error) {
      events.add('unexpected translation');
      return error;
    },
  ).recover(
    (error) async {
      events.add('unexpected recovery');
      return const Result<int, String>.success(-1);
    },
  );

  assert(chained.value == 42);
  assert(translated.error == 'HTTP 404');
  assert(recovered.value == 0);
  assert(pipeline.value == 42);
  assert(events.join(',') == 'chain,map');
}
```

The maintained
[composition example](https://github.com/andrey-krasheninnikov/domain_error/blob/main/example/composition_example.dart)
also combines capture, observation, nullable recovery and chaining.

## Exceptions and asynchronous boundaries

### Callback failures and failed futures

Observer failure isolation belongs to capture. Mapper failures propagate with
their original objects and stack traces. A thrown transform or recovery failure
also propagates. `recover` handles an error payload inside a result; it does not
handle a failed source future. Capture a throwing operation explicitly when its
failure should become a domain error.

```dart
import 'package:domain_error/domain_error.dart';

Future<void> main() async {
  final failure = StateError('callback failed');
  final trace = StackTrace.fromString('original callback trace');
  var recovered = false;
  var propagated = 0;

  try {
    captureResultSync<int>(
      () {
        throw StateError('operation failed');
      },
      mapToDomainError: (error, stackTrace) {
        Error.throwWithStackTrace(failure, trace);
      },
    );
  } on Object catch (error, stackTrace) {
    assert(identical(error, failure));
    assert(identical(stackTrace, trace));
    propagated++;
  }

  try {
    const Result<int, String>.success(42).map<int>(
      (value) {
        Error.throwWithStackTrace(failure, trace);
      },
    );
  } on Object catch (error, stackTrace) {
    assert(identical(error, failure));
    assert(identical(stackTrace, trace));
    propagated++;
  }

  try {
    await Future<Result<int, String>>.error(failure, trace).recover(
      (error) {
        recovered = true;
        return const Result<int, String>.success(0);
      },
    );
  } on Object catch (error, stackTrace) {
    assert(identical(error, failure));
    assert(identical(stackTrace, trace));
    propagated++;
  }

  assert(propagated == 3);
  assert(!recovered);
}
```

### Late Future and Stream errors

`captureResultSync<T>` stores its returned `T` unchanged. If `T` is a `Future`
or `Stream`, later errors occur outside that synchronous call. Likewise,
capturing the creation of a stream does not observe subscription errors.
Await the future or consume the stream inside an asynchronous capture boundary:

```dart
import 'package:domain_error/domain_error.dart';

/// Represents a failure observed while awaiting or consuming work.
final class OrderUnavailableError extends DomainError {
  const OrderUnavailableError({
    super.cause,
    super.stackTrace,
  });

  @override
  String get typeIdentifier {
    return 'OrderUnavailableError';
  }
}

Future<void> main() async {
  final failure = StateError('late failure');
  final trace = StackTrace.fromString('asynchronous operation');

  final pending = captureResultSync<Future<int>>(
    () {
      return Future<int>.error(failure, trace);
    },
    mapToDomainError: (error, stackTrace) {
      return OrderUnavailableError(
        cause: error,
        stackTrace: stackTrace,
      );
    },
  );

  final awaited = await captureResult<int>(
    () {
      return pending.value;
    },
    mapToDomainError: (error, stackTrace) {
      return OrderUnavailableError(
        cause: error,
        stackTrace: stackTrace,
      );
    },
  );
  final consumed = await captureResult<int>(
    () async {
      return await Stream<int>.error(failure, trace).first;
    },
    mapToDomainError: (error, stackTrace) {
      return OrderUnavailableError(
        cause: error,
        stackTrace: stackTrace,
      );
    },
  );

  assert(pending.isSuccess);
  assert(identical(awaited.domainError.cause, failure));
  assert(identical(consumed.domainError.cause, failure));
}
```

For a long-lived stream subscription, own error handling and cancellation at the
subscription boundary. Capture is not a stream transformer or a zone-wide handler.

## Equality and mutable payloads

Result equality requires the same concrete branch and both type arguments,
plus deeply equal payloads. The payload comparison checks both directions.
For example, `Result<int, String>.success(7)` differs from
`Result<num, String>.success(7)`, even though the numeric values compare equal.
Hashing includes the concrete result type and deep payload hash.

`Result` stores payloads by reference without copying them. Mutating a payload
can change equality and hashing and make an existing map key or set element
unfindable. An unmodifiable outer collection does not protect nested mutable
collections. Snapshot every mutable layer you own:

```dart
import 'package:domain_error/domain_error.dart';

void main() {
  final source = <String, List<int>>{
    'items': [1, 2],
  };
  final snapshot = Map<String, List<int>>.unmodifiable({
    for (final entry in source.entries) entry.key: List<int>.unmodifiable(entry.value),
  });
  final result = Result<Map<String, List<int>>, String>.success(snapshot);
  final results = {result};

  source['items']!.add(3);

  assert(identical(result.value, snapshot));
  assert(result.value['items']!.length == 2);
  assert(results.contains(result));
  assert(
    result ==
        Result<Map<String, List<int>>, String>.success({
          'items': [1, 2],
        }),
  );
  assert(
    const Result<int, String>.success(7) != const Result<num, String>.success(7),
  );
}
```

The same immutability discipline applies to domain error business fields in
`props`. Diagnostic fields excluded from equality do not make mutable business
payloads safe as keys.

## Diagnostics and reporting

`DomainError.toString()` uses `typeIdentifier` and the first non-empty description:
`message`, then `cause`. It trims whitespace and keeps the first line, recognizing
LF, CRLF and CR. A nested domain error contributes its identifier. An empty,
opaque or throwing cause description becomes `unknown`; without a description,
only the identifier remains. The original fields remain available.

This is display formatting, not redaction. Messages, causes, stack traces and
`toString()` output can contain private data. Define an allowlist for remote
reporting, and prepare user-facing messages separately from technical causes.
The package does not send reports or decide which fields are safe.

```dart
import 'package:domain_error/domain_error.dart';

/// Keeps the display message separate from technical diagnostic context.
final class OrderUnavailableError extends DomainError {
  const OrderUnavailableError({
    super.message,
    super.cause,
    super.stackTrace,
  });

  @override
  String get typeIdentifier {
    return 'OrderUnavailableError';
  }
}

void main() {
  final error = OrderUnavailableError(
    message: '  Try again later\nAdditional internal detail',
    cause: StateError('private diagnostic context'),
    stackTrace: StackTrace.current,
  );

  /// Only explicitly selected fields cross the reporting boundary.
  final report = <String, String>{
    'type': error.typeIdentifier,
    'operation': 'order.load',
  };

  assert(error.toString() == 'OrderUnavailableError(Try again later)');
  assert(error.message!.contains('Additional internal detail'));
  assert(report.length == 2);
  assert(report['type'] == 'OrderUnavailableError');
}
```

## API map

All entries are exported from `package:domain_error/domain_error.dart`.

| Public interface | Purpose and constraints |
| --- | --- |
| `DomainError` | Abstract `Exception` model; const constructor with optional `message`, `cause`, `stackTrace` |
| `typeIdentifier`, `message`, `cause`, `stackTrace` | Stable error vocabulary, description and diagnostic context |
| `props`, equality, `hashCode`, `toString()` | Business identity and diagnostic display; see the sections above |
| `Result<T, E>` | Sealed generic outcome, success type first; its unnamed base constructor is not directly instantiable |
| `Result.success(value)`, `Result.error(error)` | Const factories for the two branches |
| `ResultSuccess<T, E>`, `ResultError<T, E>` | Const concrete constructors and object-pattern types; public `value` / `error` fields |
| `isSuccess`, `isError`, `value`, `error` | Branch predicates and checked branch access |
| `fold<U>(onError, onSuccess)` | Error callback first; returns the selected callback's `U` |
| `map<U>`, `andThen<U>` | Change the success type; preserve `E` |
| `mapError<F>` | Change the error type; preserve `T` |
| `recover` | Return another result on error; preserve `T` and `E` |
| `mapAsync`, `andThenAsync`, `mapErrorAsync`, `recoverAsync` | Await a selected `FutureOr` callback on an existing result |
| `FutureResult<T, E>` | Extension with unsuffixed composition methods on `Future<Result<T, E>>` |
| `DomainResult<T>` | Type alias for `Result<T, DomainError>` |
| `FutureDomainResult<T>` | Type alias for `Future<DomainResult<T>>` |
| `DomainResultError<T>.domainError` | Extension getter for the error of a domain result |
| `captureResult<T>` | Await an operation and callbacks; return `Future<DomainResult<T>>` |
| `captureResultSync<T>` | Run synchronous work; return `DomainResult<T>` without awaiting a future payload |
| `operation`, `mapToDomainError` | Required positional operation and required named mapper |
| `onDomainError`, `onRawError`, `onObserverError` | Optional domain/raw observers and isolated observer failure reporter |

Extension names matter for explicit extension overrides and `show`/`hide`
imports; ordinary instance syntax is usually sufficient. Read the
[published API reference](https://pub.dev/documentation/domain_error/latest/domain_error/)
for full signatures.

## Compatibility

The package declares Dart `>=3.0.0 <4.0.0` and no Flutter SDK constraint. Dart 3
syntax is required by its class modifiers and patterns. A separate Flutter
consumer resolves the library without dependency overrides.

| Environment | Verification |
| --- | --- |
| Dart 3.0.0 | Minimum SDK: library checks, examples and README programs |
| Current stable Dart | Library checks, examples and README programs |
| Flutter 3.10.0 / Dart 3.0.0 | Consumer analysis/tests with normal and lowest runtime dependency resolution |
| Current stable Flutter | Consumer analysis/tests with its independent resolution |

The [CI workflow](https://github.com/andrey-krasheninnikov/domain_error/blob/main/.github/workflows/ci.yml)
checks these endpoints. Flutter 3.10.0 resolves `collection` 1.17.1 and `meta`
1.9.1; its downgrade check also selects `equatable` 2.0.7. Intermediate SDK
versions are not each tested by this matrix. Platform declarations describe a
pure Dart library and are not physical-device test results.

The current API guide is for 5.x. The portable skill also maintains separate
3.x and 4.x contracts. Historical migrations below do not imply that every old
package version was tested with every current SDK.

## Migrate to 5.x

Keep the package name and public import. The table maps legacy spelling to the
current interface; choose the rows for your starting version. There are no
compatibility aliases.

| Starting API | Current 5.x API |
| --- | --- |
| 2.x `Either<L, R>`, `Either.err` / `Either.ok` | `Result<R, L>`, `Result.error` / `Result.success` |
| 2.x `EitherErr<L, R>` / `EitherOk<L, R>` | `ResultError<R, L>` / `ResultSuccess<R, L>` |
| 2.x `isErr` / `isOk`, `errValue` | `isError` / `isSuccess`, `error` |
| 2.x `DomainError.rawError`, including constructor forwarding | `cause`, including `super.cause` |
| 2.x `executeSafely` / `executeSafelySync` | `captureResult` / `captureResultSync` |
| 2.x `ExecuteSafelyOptions` / `ExecuteSafelySyncOptions` | Move fields directly into named capture arguments; Options classes are removed |
| 2.x `mapRawErrorToDomain` | `mapToDomainError` |
| 2.x positional `method`, fold parameters `ifErr` / `ifOk` | `operation`, `onError` / `onSuccess`; positional call syntax stays the same |
| 3.x `CaptureResultOptions` / `CaptureResultSyncOptions` | Move fields directly into named capture arguments |
| 3.x / 4.x `Either<L, R>`, `Either.error` / `Either.success` | `Result<R, L>`, `Result.error` / `Result.success` |
| 3.x / 4.x `EitherError<L, R>` / `EitherSuccess<L, R>` | `ResultError<R, L>` / `ResultSuccess<R, L>` |
| 2.x / 3.x / 4.x domain `Result<T>` / `FutureResult<T>` aliases | `DomainResult<T>` / `FutureDomainResult<T>` |
| 2.x / 3.x / 4.x `successValue`; 3.x / 4.x `errorValue` | `value`; `error`, including named pattern fields |
| 2.x / 3.x / 4.x `ResultDomainError<T>` | `DomainResultError<T>`; `domainError` remains |
| 4.x `FutureEitherOperations<L, R>` | `FutureResult<R, L>` extension; it is not a typedef |

Reorder both generic arguments, including inside collections, futures, bounds,
casts, type tests, branch constructors and explicit extension overrides.

Review behavior as well as names:

- Upgrading from 2.x: observer failures are isolated, optional `onObserverError`
  receives them, and a failure in that reporter does not recurse. Diagnostics
  no longer affect default domain error equality. Different concrete generic
  result types compare unequal; payload comparison is symmetric. Description
  formatting consistently uses one line and tolerates failing causes.
- Upgrading from 3.x or earlier: synchronous observers return `Null`. Wrap
  synchronous `void` functions; choose async capture for asynchronous observers.
  Composition provides explicit Async methods on a result and unsuffixed methods
  on a result future. Recovery returns another result with the same types.
- Upgrading from 4.x: 5.0 changes names and generic ordering while retaining
  capture and composition behavior, nullable/void payloads, stable identifiers
  and the SDK minimums.

Keep `typeIdentifier` strings, messages and diagnostic context when renaming
classes. Do not use runtime type names or hash codes as persisted identity.
The two historical wrong-branch `StateError` messages remain
`Either.success has no errorValue` and `Either.error has no successValue`;
these strings are diagnostic text, not compatibility APIs.

For historical detail, see the
[3.0 changelog](https://github.com/andrey-krasheninnikov/domain_error/blob/main/CHANGELOG.md#300---2026-09-13),
[3.x to 4.0 guide](https://github.com/andrey-krasheninnikov/domain_error/blob/main/docs/migration-4.0.md)
and [4.x to 5.0 guide](https://github.com/andrey-krasheninnikov/domain_error/blob/main/docs/migration-5.0.md).
The [4.0 migration program](https://github.com/andrey-krasheninnikov/domain_error/blob/v4.0.0/example/migration_v4.dart)
uses its historical API; run current examples against 5.x.

## Package skill

Install the portable `flutter-domain-errors` guidance:

```sh
npx skills add andrey-krasheninnikov/domain_error --skill flutter-domain-errors
```

Installation is project-local by default. Add `--agent codex claude-code` to
select those clients or `--global` for user-wide installation. The existing
[skills CLI](https://github.com/vercel-labs/skills) needs a compatible Node.js
installation; there is no separate npm package to install.

The [skill](https://github.com/andrey-krasheninnikov/domain_error/tree/main/skills/flutter-domain-errors)
covers pure Dart and Flutter with separate 3.x, 4.x and 5.x references. It checks
the applicable package's direct dependency and resolved API, including path/Git
sources, before choosing rules. Older, newer or unresolved APIs require source
inspection. It does not silently upgrade dependencies, migrate untouched code
or impose application architecture.

Automatic selection depends on client support and task relevance. Installation
alone does not establish selection. The
[validation notes](https://github.com/andrey-krasheninnikov/domain_error/blob/main/skills/flutter-domain-errors/references/validation.md)
name the exercised client versions, scenarios and limits.

## Development

From a checkout with the selected Dart SDK on `PATH`:

```sh
make deps
make check
dart run example/domain_error_example.dart
dart --enable-asserts run example/composition_example.dart
python3 -B -m unittest discover -s tool/readme_checks
python3 -B tool/readme_checks/check.py
make publish-dry-run
```

`make check` runs formatting checks, analysis and tests without rewriting source.
Use `make format` to apply the Dart 3.0 language style at a line length of 120.
The README checker requires Python 3.9 or later and uses its standard library.
It extracts every Dart block into a temporary package, analyzes and formats-checks
the programs, then runs them with assertions against this checkout. It also
checks local files, image descriptions and heading anchors. The Dart CI matrix
runs these checks on minimum and stable SDKs.

With Flutter 3.10.0 or current stable on `PATH`, run `make flutter-deps`, then
`make flutter-check`. To test the lowest runtime dependencies, run
`flutter pub downgrade` inside `tool/flutter_consumer` and repeat
`make flutter-check` from the root. This consumer has its own dependency
resolution and does not add Flutter to the published library.

Check portable skill examples with:

```sh
python3 -B -m unittest discover -s tool/skill_checks
python3 -B tool/skill_checks/check.py
```

Editable artwork lives in `assets/cover.html`, `assets/overview.html`,
`assets/flow.html` and `assets/fold.html`, sharing `assets/readme-art.css`.
Run `make diagrams` to export a 1600×640 cover and three 1600×900 diagrams.
The renderer uses isolated temporary Chrome profiles and local resources;
set `CHROME_BIN` to select Chrome or Chromium. The want dark artwork uses bundled
[IBM Plex](https://github.com/andrey-krasheninnikov/domain_error/blob/abfbda92ffa6a77dd1f9a4536b462702d6a1e8c2/assets/fonts/OFL.txt)
and [Pixelify Sans](https://github.com/andrey-krasheninnikov/domain_error/blob/abfbda92ffa6a77dd1f9a4536b462702d6a1e8c2/assets/fonts/OFL-PixelifySans.txt)
fonts under their SIL Open Font Licenses.

Use [GitHub Issues](https://github.com/andrey-krasheninnikov/domain_error/issues)
for defects or proposals. Public contract changes need tests and migration
notes. Project vocabulary is in the
[glossary](https://github.com/andrey-krasheninnikov/domain_error/blob/main/GLOSSARY.md);
[architecture decisions](https://github.com/andrey-krasheninnikov/domain_error/tree/main/docs/adr)
record the reasoning behind identity, capture, composition and compatibility.

## License

[MIT](https://github.com/andrey-krasheninnikov/domain_error/blob/main/LICENSE).
