# Keep observer failures from replacing operation results

`captureResult` and `captureResultSync` preserve an original thrown
`DomainError`. They observe any other thrown object before mapping it to
a domain error; the mapped error does not trigger `onDomainError` again.

Observer failures are reported through optional `onObserverError`.
Failures of that handler are ignored without recursion, preserving the
operation result. Mapper failures propagate with their stack traces
instead of becoming a fallback domain error.

`captureResult` awaits the operation and its callbacks in order.
`captureResultSync` requires a synchronous mapper and observers. All observers,
including the failure reporter, return `Null`. Type checking rejects async
functions and direct `void` tear-offs. A synchronous `void` function can be
wrapped in a block returning null. This verifies return types; it cannot prevent
unawaited work inside a callback.

The synchronous operation stores its returned `T`, including a Future payload,
without awaiting it. Later failures of that future remain the caller's
responsibility. Use `captureResult` to capture asynchronous completion.

This deliberate 4.0 change replaces the unsupported async-observer behavior in
3.x. See [the public API decision](0004-result-composition.md) and
[the migration guide](../migration-4.0.md).

See the [implementation](../../lib/src/capture_result.dart) and
[routing and callback failure tests](../../test/capture_result_test.dart).
