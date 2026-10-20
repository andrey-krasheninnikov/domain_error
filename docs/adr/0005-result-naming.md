# Use one result vocabulary

## Status and problem

Accepted before implementation in [issue #10](https://github.com/andrey-krasheninnikov/domain_error/issues/10#issuecomment-6299209534).
How can new Dart and Flutter callers read capture, branch access, and composition
with one vocabulary while existing users can migrate without changing behavior?

The maintainer selected Result plus DomainResult, full error/success words,
success-first type arguments, short error/value getters, the existing sync/async
scheme, and a 5.0.0 release without compatibility aliases. This supersedes only
the naming in [the composition decision](0004-result-composition.md).

## Alternatives on the same caller scenarios

| Vocabulary | Capture | Branch access | Composition | Trade-off |
| --- | --- | --- | --- | --- |
| Existing Either | Result is a domain alias | Either.error/success | Either.map/andThen/mapError/recover | Least migration; two terms for one outcome model |
| Result plus DomainResult | captureResult returns DomainResult | Result.error/success, error/value | Result and Future<Result> use the same verbs | One model; requires a major source migration |
| Outcome plus Result | captureResult returns Result | Outcome.error/success | Outcome uses the same verbs | Preserves the domain alias but introduces another outcome term |
| Left/right | Capture selects the error side | Left/right getters | Left/right mapping | Familiar algebraic vocabulary; hides which side is an error |
| Attempt | Capture runs an attempt | Attempt.error/success | Attempt chaining | Emphasizes execution although the object is a completed value |

The selected model is concise without introducing ok/err alongside DomainError,
raw errors, and observer errors. Dart naming remains UpperCamelCase for types
and extensions, lowerCamelCase for members, and lowercase_with_underscores for
files. Standard T/E and U/F type parameters express value/error roles.

## Complete naming inventory

| Meaning and consumers | Current name | Decision | Reason and migration |
| --- | --- | --- | --- |
| Generic outcome; all library and consumer code | Either<L, R> | Result<T, E> | Result describes error/success; put former R first and former L second |
| Constructors and pattern types | Either(), Either.error/success, EitherError/L,R and EitherSuccess/L,R | Result(), Result.error/success, ResultError<T,E> and ResultSuccess<T,E> | One type family; reorder explicit type arguments |
| Domain outcome annotations and capture signatures | Result<T> | DomainResult<T> = Result<T, DomainError> | Distinguish the specialization from generic Result |
| Asynchronous domain annotations | FutureResult<T> | FutureDomainResult<T> | State which result specialization the future carries |
| Branch fields, patterns, callback parameter names | errorValue, successValue | error, value | The receiver already identifies the result; update named object patterns too |
| Domain getter extension and explicit extension overrides | ResultDomainError<T> | DomainResultError<T> | Match the receiver's DomainResult name; domainError stays |
| Future composition extension and explicit overrides | FutureEitherOperations<L,R> | FutureResult<T,E> | The receiver supplies the execution context; no Operations suffix |
| Value and error transforms | R2, L2; fold's T | U, F; fold's U | Keep generic roles distinct without shadowing Result's T |
| Stored cause formatting | local error in DomainError._displayDetail | cause | Distinguish stored diagnostic context from a caught error |
| Library modules and corresponding tests | either.dart; current result.dart | result.dart; domain_result.dart | Match the declared type families; rename either_* tests to result_* and current result_test to domain_result_test |
| Runnable composition and migration sample | migration_v4.dart | composition_example.dart | Current API example is independent of release numbering; update CI and links |
| Public package and entry point | domain_error; package:domain_error/domain_error.dart | Keep | Package/import identity is stable |
| Error model and equality surface | DomainError, typeIdentifier, message, cause, stackTrace, props, toString | Keep | Existing names express domain meaning; keep every identifier value and error message |
| Result predicates and domain getter | isError, isSuccess, domainError | Keep | Clear positive predicates and a meaningful domain getter |
| Composition and folding | fold, map, andThen, mapError, recover and Async variants | Keep | Existing verbs distinguish value mapping, chaining, error mapping, and recovery |
| Capture and callback interface | captureResult, captureResultSync, operation, mapToDomainError, onDomainError, onRawError, onObserverError, onError, onSuccess, transform | Keep | Names already distinguish execution, conversion, observation, and branching |
| Shared private implementation | _payloadEquality, _observe, _observeSync, _displayDetail, _firstLine, observer, observerError, observerStackTrace, stackTrace, domainError | Keep | Names describe their actual scope and meaning |
| Test fixtures, sample error types and remaining local names | Existing test/sample types, loop variables, error/success objects, traces, payloads and expected values | Keep | Scope and types provide context; no clearer replacement is demonstrated |
| Remaining files, directories and configuration | domain_error.dart, capture_result.dart, domain_error.dart model, tests/fixtures, assets, tool, docs, CI and Make targets | Keep | Existing names follow their language and project conventions |
| Current documentation and diagram labels | Either and domain Result vocabulary | Apply this inventory | Update glossary, README, metadata, current diagrams and rendered PNGs together |
| Historical documentation and literals | Prior release tables, migration-4.0, original getter StateError strings, typeIdentifier values | Keep versioned text or exact literal | Link old runnable source at v4.0.0; distinguish intentional old names from stale references |

The inventory covers every tracked library, test, example, Flutter fixture,
configuration, tool, asset, documentation file, and directory. It introduces no
other identifier renames. The public migration table records every breaking
rename, including extension names, object-pattern fields and generic ordering.

## Contracts, assumptions and checks

Keep error-first fold arguments, callback ordering, selected-branch execution,
nullable and void payloads, diagnostic formatting, identity and equality/hash
rules. Capture remains the exception boundary. Its sync observers still return
Null; asynchronous composition still uses Async on a Result and unsuffixed
methods on a Future. Generic error payloads remain unrestricted.

The bet is that a value-first Result plus an explicit domain specialization is
clearer for readers familiar with C, Go, or Rust. Validate the chosen vocabulary
through the same capture, pattern matching, and composition scenarios using only
the public package import. Keep the behavior assertions, minimum/stable Dart
checks, and independently resolved Flutter consumer. Preserve stable diagnostic
identifiers even when a class has a different source name.

## Not doing

No aliases, new capabilities, dependencies, SDK changes, effect framework,
architecture restructuring, package rename, or README redesign. Keep historical
release descriptions accurate. Revisit the vocabulary only with a concrete
caller ambiguity that outweighs another migration.
