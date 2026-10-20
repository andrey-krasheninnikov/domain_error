# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [4.0.0] - 2026-10-20

### Changed

- Pass the mapper and optional observers directly to capture functions as named
  parameters. Remove `CaptureResultOptions` and `CaptureResultSyncOptions`.
- Require `Null` returns from synchronous observers, rejecting async callbacks
  and direct `void` tear-offs. Preserve observer isolation and error routing.

### Added

- Sequential composition with `andThen`, error transformation with `mapError`,
  and selective result-returning recovery with `recover`.
- Async equivalents on `Either` and composition methods on `Future<Either<L, R>>`.
- A migration guide, runnable migration example, compile-time callback checks,
  and extended minimum/stable Flutter consumer coverage.

## [3.1.0] - 2026-10-20

### Changed

- Lower the Dart SDK minimum to 3.0.0 and widen runtime dependency ranges for
  Flutter 3.10.0 compatibility, preserving the public API and behavior.
- Align development dependencies, callback test syntax, lint configuration, and
  formatting commands with the supported minimum SDK.

### Added

- A separate Flutter consumer with public-interface tests on Flutter 3.10.0 and
  current stable, including the lowest supported runtime dependencies.
- Minimum and stable SDK checks for Dart and Flutter in CI.

## [3.0.0] - 2026-09-13

### Changed

- Rename the capture functions and options to `captureResult`,
  `captureResultSync`, `CaptureResultOptions`, and `CaptureResultSyncOptions`.
- Use `Either.error` / `Either.success`, `EitherError` / `EitherSuccess`,
  `isError` / `isSuccess`, and `errorValue` throughout the API.
- Rename `DomainError.rawError` to `cause` and `mapRawErrorToDomain` to
  `mapToDomainError`. Previous public names are removed without aliases.
- Require matching concrete types and symmetric deep payload equality for
  `Either`; include the concrete type in hashing.
- Exclude causes and stack traces from `DomainError` equality. Subclasses can
  continue adding business fields through `props`.
- Preserve operation results when observers fail. Mapper failures still propagate.
- Normalize message and cause descriptions to one line and use `unknown` when
  a cause cannot be described.
- Make `format-check` read-only and simplify analyzer configuration while
  preserving applicable checks and strict type settings.

### Added

- Optional `onObserverError` handlers for synchronous and asynchronous capture.
  Handler failures are ignored without recursion.
- Regression tests for equality, callback ordering, delayed failures, immutable
  snapshots, and diagnostic formatting.
- Migration instructions and explicit synchronous callback requirements.
- Editable HTML/CSS diagram sources with a headless Chrome rendering command.
- CI checks for Dart 3.13.0 and the stable channel.

## [2.1.1] - 2026-08-30

### Added

- README diagrams for the error journey, the domain model, and the Result API.

## [2.1.0] - 2026-08-30

### Added

- `executeSafelySync` and `ExecuteSafelySyncOptions` for synchronous calls
  that return `Result<T>`.

## [2.0.0] - 2026-08-30

### Changed

- `ExecuteSafelyOptions`: `onError` is now `onDomainError`, `onThrown` is now
  `onRawError`, and `mapThrownToError` is now `mapRawErrorToDomain`.
  The options type is no longer generic and no longer extends `Equatable`.
- `DomainError.error` is now `rawError`.
- `Either` is sealed. The error branch is `isErr` / `errValue` / `Either.err`.
  The success branch is `isOk` / `successValue` / `Either.ok`.
- `fold` now takes `ifErr` and `ifOk`. `when` is removed. `map` maps the
  success value and leaves an error unchanged.
- `domainError` is available only on `Result<T>`, not on a generic `Either`.
- `executeSafely` now returns `Future<Result<T>>`. `FutureOrResult` is removed.

## [1.0.0] - 2026-08-30

### Added

- `DomainError` base type with a stable `typeIdentifier`, optional `message`,
  `error`, and `stackTrace`.
- `Either` with `failure` and `value` branches, plus `fold`, `when`, and `map`.
- `Result`, `FutureResult`, and `FutureOrResult` as `Either` aliases over
  `DomainError`.
- `executeSafely` to catch throws and return a `Result`.
- `ExecuteSafelyOptions` with `mapThrownToError`, `onError`, and `onThrown`.

[3.0.0]: https://github.com/pchkauu/domain_error/compare/v2.1.1...v3.0.0
[3.1.0]: https://github.com/pchkauu/domain_error/compare/v3.0.0...v3.1.0
[4.0.0]: https://github.com/andrey-krasheninnikov/domain_error/compare/v3.1.0...v4.0.0
[unreleased]: https://github.com/andrey-krasheninnikov/domain_error/compare/v4.0.0...HEAD
[2.1.1]: https://github.com/pchkauu/domain_error/compare/v2.1.0...v2.1.1
[2.1.0]: https://github.com/pchkauu/domain_error/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/pchkauu/domain_error/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/pchkauu/domain_error/releases/tag/v1.0.0
