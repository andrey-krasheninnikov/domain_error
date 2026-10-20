# Shared rules for 3.x, 4.x, and 5.x

## Error identity and diagnostics

A feature error root can extend `DomainError` in its own library. It can be
sealed when the project uses a closed feature hierarchy; do not seal the
package's base class or impose a hierarchy on an unrelated flow.

Keep `typeIdentifier` stable across class renames and obfuscation. Use error
types or structured business fields for decisions. `message`, arbitrary cause
text, and `toString()` are not a stable business protocol.

Equality includes concrete type, identifier, and message. Diagnostic `cause`
and `stackTrace` are excluded. Add business fields with
`[...super.props, businessField]` when they define identity. Keep equality fields
immutable. Result payloads are retained by reference and compared deeply;
copy mutable data explicitly when a stable snapshot is required.

A cause may contain transport errors, nested domain errors, credentials, or
personal data. A one-line `toString()` is still untrusted diagnostic text.
Report an allowlisted identifier and approved structured fields through the
project's reporting boundary. Redact before sending; do not publish arbitrary
messages, causes, stack traces, or request bodies by default.

## Capture routing

Choose the exception boundary already responsible for converting thrown
failures into operation outcomes. Do not make every layer catch and remap the
same error, or convert an existing result/expected state into a throw just to
use capture.

- Success produces the success branch and runs no error callbacks.
- An original thrown `DomainError` runs `onDomainError`, then returns the same
  error instance. It does not run the raw observer or mapper.
- Any other thrown object runs `onRawError` before `mapToDomainError`. The
  mapped domain error is returned without a second `onDomainError` notification.
- A failing observer reaches optional `onObserverError`. With no reporter, that
  failure is ignored. Reporter failures are also ignored without recursion.
  Neither failure replaces the operation result.
- Mapper failures propagate with their original object and stack trace. They
  do not become fallback domain errors or observer failures.

The mapper and every observer, including `onObserverError`, receive two
arguments: the error object and a `StackTrace`. Preserve both parameters when
writing callbacks, even when one is unused.

Use observers for diagnostics, not recovery, authorization, validation, or a
business decision whose failure must affect the operation. Put such work in
the operation or the existing owning layer. Use `onObserverError` when failed
reporting needs a separate diagnostic path; keep that path safe too.

## Completion and result handling

`captureResult` awaits the operation, selected observer, failure reporter, and
mapper in order. `captureResultSync` does not await returned work. Its callback
requirements differ between majors; read the selected version reference.

A synchronous operation can return a Future as its payload. Capture succeeds
with that Future; a later failed completion is the caller's responsibility.
Use asynchronous capture around the awaited operation when that completion
belongs inside the boundary. Unawaited work inside a callback is not made safe
by its declared return type.

Returning a Stream captures its creation, not errors emitted during later
subscription. Handle late errors at the subscription/transform boundary, or
await the intended finite consumption inside async capture. Preserve streaming
semantics rather than collecting an unbounded stream to make capture work.

Use `fold`, predicates, or the installed branch types to select a result branch.
The opposite getter throws; nullable payloads are valid and do not indicate a
missing branch. `map` transforms success only. In 4.x/5.x, composition selects
one branch, once, in order. Callbacks and failed source futures propagate their
exceptions; `recover` handles error payloads, not failed futures. Capture remains
an explicit exception boundary. Do not invent retries or cancellation policy.

Run checks in the affected package. A successful local example does not prove
remote reporting, physical-device behavior, or selection in another client.
