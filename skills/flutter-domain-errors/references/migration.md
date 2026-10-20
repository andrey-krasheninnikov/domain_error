# Migration only when requested

Inspect the installed source first, including overrides and path/Git forks.
Preserve stable identifier strings and application behavior. Map the complete
public dependency closure and update the affected package's callers and tests
together. Leave untouched legacy code outside the requested migration alone.

| From | To | Required source changes |
| --- | --- | --- |
| 2.x | 3.x | Outside behavioral support here. Inspect both APIs and the package's migration guide before proposing changes; do not reuse 3.x examples unchanged. |
| 3.x | 4.x | Move Options fields to named capture arguments; remove Options construction. Sync observers, including the reporter, return `Null`. Wrap synchronous `void` functions in a block returning null; use async capture for async observers. Composition becomes available. |
| 4.x | 5.x | Replace `Either<L, R>` with `Result<R, L>`; reorder explicit generic arguments. Replace domain `Result<T>` with `DomainResult<T>` and the `FutureResult<T>` alias with `FutureDomainResult<T>`. |

In 5.x, use `ResultError<T, E>` and `ResultSuccess<T, E>` patterns with `error`
and `value`. Replace `errorValue`/`successValue` getters with `error`/`value`.
`domainError` remains available on domain results. `FutureResult` in 5.x is the
Future composition extension, not the old domain alias.

Capture function names and routing remain the same across 3.x through 5.x.
Composition verbs introduced in 4.x retain their behavior in 5.x. Do not add
compatibility aliases or string heuristics to hide a mismatched interface.

For 3.0.0, respect its Dart 3.13 SDK requirement; 3.1.0 lowers the floor to Dart
3.0. A skill installation does not change either constraint.

Read the destination contract and runnable example before editing:
[3.x](v3.md), [4.x](v4.md), [5.x](v5.md). Verify caller behavior, callback order,
mapper propagation, and the applicable synchronous contract after migration.
