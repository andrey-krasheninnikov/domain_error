# domain_error

![Capture an operation result, observe errors, and fold the outcome](assets/overview.png)

Turn thrown errors into values you can fold.

A `DomainError` represents an expected domain or application error.
`Result<T>` is `Either<DomainError, T>`; `FutureResult<T>` is `Future<Result<T>>`.
Use `captureResult` for asynchronous work and `captureResultSync` for synchronous work.

## Install

```yaml
dependencies:
  domain_error: ^3.0.0
```

Requires Dart 3.13.0 or later within Dart 3.

## Model errors

![Domain error fields, feature hierarchy, and stable identifiers](assets/flow.png)

Keep one sealed error root per feature. Set `typeIdentifier` explicitly and
preserve its value when renaming classes. It remains readable after obfuscation.

```dart
import 'package:domain_error/domain_error.dart';

sealed class OrderError extends DomainError {
  const OrderError({super.message, super.cause, super.stackTrace});
}

final class EmptyOrderIdError extends OrderError {
  const EmptyOrderIdError();

  // Preserve the existing identifier after the class rename.
  @override
  String get typeIdentifier => 'OrderIdEmptyError';
}

final class OrderUnavailableError extends OrderError {
  const OrderUnavailableError({super.cause, super.stackTrace});

  @override
  String get typeIdentifier => 'OrderUnavailableError';
}
```

Errors compare by their concrete type, `typeIdentifier`, and `message`.
Diagnostic `cause` and `stackTrace` do not participate in equality or hashing.
Subclasses can include business fields in `props`:

```dart
final class OrderRejectedError extends OrderError {
  final String reason;

  const OrderRejectedError(this.reason, {super.message, super.cause, super.stackTrace});

  @override
  String get typeIdentifier => 'OrderRejectedError';

  @override
  List<Object?> get props => [...super.props, reason];
}
```

`toString()` uses the identifier and the first non-empty description source:
`message`, then `cause`. It trims whitespace and takes the first line, recognizing
LF, CRLF, and CR. A nested `DomainError` contributes its identifier. An empty,
opaque, or throwing cause description becomes `unknown`. Without a message or
cause, only the identifier is returned. The full fields remain available.

## Capture and fold

![Async and sync capture, Either branches, fold, and map](assets/fold.png)

```dart
final result = await captureResult<Order>(
  () => loadOrder(id: id),
  options: CaptureResultOptions(
    mapToDomainError: (rawError, stackTrace) {
      return OrderUnavailableError(cause: rawError, stackTrace: stackTrace);
    },
    onDomainError: (domainError, stackTrace) {
      print('${domainError.typeIdentifier}: $stackTrace');
    },
    onRawError: (rawError, stackTrace) {
      print('$rawError: $stackTrace');
    },
    onObserverError: (observerError, stackTrace) {
      print('Observer failed: $observerError: $stackTrace');
    },
  ),
);

result.fold(
  (domainError) => print(domainError.typeIdentifier),
  (successValue) => print(successValue.title),
);

final syncResult = captureResultSync<Order>(
  () => loadOrder(id: id),
  options: CaptureResultSyncOptions(
    mapToDomainError: (rawError, stackTrace) {
      return OrderUnavailableError(cause: rawError, stackTrace: stackTrace);
    },
  ),
);
```

Runnable sample, including `Order`, `loadOrder`, and timeout mapping:
[`example/domain_error_example.dart`](example/domain_error_example.dart).

The handling order is explicit:

1. A successful operation returns `Either.success`; no callbacks run.
2. A thrown `DomainError` triggers `onDomainError`, then returns `Either.error`
   containing the same error object.
3. Any other thrown object triggers `onRawError`, then `mapToDomainError`.
   The mapped error is returned without triggering `onDomainError` again.
4. An observer failure triggers `onObserverError` with that failure and its trace.
   Without the handler, the observer failure is ignored. Failures of the handler
   itself are also ignored without recursion, preserving the operation result.
5. Mapper failures propagate unchanged with their stack traces. They are not
   observer failures and do not become a fallback `DomainError`.

`captureResult` awaits the operation, observers, observer error handler, and mapper.
`captureResultSync` requires **every callback to be synchronous**. Dart allows an
async function in a `void` observer slot, but this is unsupported: its future is
not awaited and its asynchronous failures are not captured. There is no static
or runtime rejection. Use `captureResult` whenever any callback is asynchronous.

## Work with Either

`Either<L, R>` also supports error values that are not `DomainError` instances.

```dart
const success = Either<String, int>.success(7);
const error = Either<String, int>.error('missing');

final doubled = success.map((value) => value * 2);
assert(doubled.successValue == 14);
assert(error.isError);
assert(success.isSuccess);
assert(error.errorValue == 'missing');
```

`map` transforms only the success value. It preserves the error payload without
calling the transform. Accessing the wrong branch getter throws `StateError`;
use `fold` or pattern matching to handle both branches. `domainError` is available
only on `Result<T>` and also throws on a successful result. Nullable payloads
remain valid values of their respective branches.

Equality requires the same concrete result type, including both type arguments
and the branch, plus deeply equal payloads. Equality is checked in both directions.
The hash includes the result type and the deep payload hash.

### Keep payloads immutable

`Either` stores its payload by reference and does not copy it. A mutable payload
can change equality and hashing, making an existing map key or set element
unfindable. Keep nested collections immutable too. Take explicit snapshots with
standard collections when necessary:

```dart
final source = <String, List<int>>{'items': [1, 2]};
final snapshot = Map<String, List<int>>.unmodifiable({
  for (final entry in source.entries)
    entry.key: List<int>.unmodifiable(entry.value),
});
final result = Either<String, Map<String, List<int>>>.success(snapshot);
final results = {result};

source['items']!.add(3);
assert(result.successValue['items']!.length == 2);
assert(results.contains(result));
```

Copy every mutable layer you own. An unmodifiable outer collection alone does
not protect mutable elements or nested collections.

## Migrate from 2.x to 3.0.0

Version 3.0.0 removes the previous names without compatibility aliases.
The package name and public import `package:domain_error/domain_error.dart` stay the same.

| Previous API | Version 3.0.0 |
| --- | --- |
| `Either.err` / `Either.ok` | `Either.error` / `Either.success` |
| `EitherErr` / `EitherOk` | `EitherError` / `EitherSuccess` |
| `isErr` / `isOk` | `isError` / `isSuccess` |
| `errValue` | `errorValue` |
| `DomainError.rawError`, including constructor arguments | `DomainError.cause` |
| `executeSafely` / `executeSafelySync` | `captureResult` / `captureResultSync` |
| `ExecuteSafelyOptions` / `ExecuteSafelySyncOptions` | `CaptureResultOptions` / `CaptureResultSyncOptions` |
| `mapRawErrorToDomain` | `mapToDomainError` |
| Positional parameter `method` | `operation` |
| `fold` parameters `ifErr` / `ifOk` | `onError` / `onSuccess` |

Update subclass forwarding parameters to `super.cause`. Keep the existing
`typeIdentifier` strings even when a class name changes. Positional parameter
renames do not change call syntax.

Review behavior changes as well as names: observer failures no longer escape,
`onObserverError` is optional, diagnostics no longer affect `DomainError` equality,
and different concrete generic result types compare unequal in both directions.
String descriptions now consistently use one line and tolerate failing causes.
Applications that need observer diagnostics should supply `onObserverError`.

`DomainError`, `Either`, `Result`, `FutureResult`, `domainError`, `successValue`,
`fold`, `map`, `typeIdentifier`, `message`, `stackTrace`, `onDomainError`, and
`onRawError` retain their names.

## Project documentation

- [Domain glossary](GLOSSARY.md)
- [Architecture decisions](docs/adr/)
- [Repository guidance](AGENTS.md)
- Workflow configuration: [issue tracker](docs/agents/issue-tracker.md),
  [triage labels](docs/agents/triage-labels.md), and
  [domain documentation](docs/agents/domain.md).

## Development

Run `make deps`, then `make check`. The check target does not rewrite source files.
Use `make format` to apply formatting and `make publish-dry-run` to validate the package.
CI checks Dart 3.13.0 and the stable channel on pull requests and pushes to `main`.

Editable diagrams live in `assets/overview.html`, `assets/flow.html`, and
`assets/fold.html`, with shared `assets/readme-art.css`. Run `make diagrams` to
render the three 1600×900 PNGs with headless Chrome. Set `CHROME_BIN` to override
the Chrome or Chromium executable. All diagram resources are local.
The bundled IBM Plex fonts use the [SIL Open Font License](assets/fonts/OFL.txt).

## License

MIT. Issues: https://github.com/pchkauu/domain_error/issues
