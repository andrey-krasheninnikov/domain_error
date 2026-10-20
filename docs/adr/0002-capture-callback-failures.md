# Keep observer failures from replacing operation results

`captureResult` and `captureResultSync` preserve an original thrown
`DomainError`. They observe any other thrown object before mapping it to
a domain error; the mapped error does not trigger `onDomainError` again.

Observer failures are reported through optional `onObserverError`.
Failures of that handler are ignored without recursion, preserving the
operation result. Mapper failures propagate with their stack traces
instead of becoming a fallback domain error.

`captureResult` awaits the operation and its callbacks in order.
`captureResultSync` requires synchronous callbacks, including observers:
an async callback passed to a `void` observer is unsupported, and its
future and asynchronous errors are not handled by the synchronous API.
There is no static or runtime rejection of such a callback.

See the [implementation](../../lib/src/capture_result.dart) and
[routing and callback failure tests](../../test/capture_result_test.dart).
