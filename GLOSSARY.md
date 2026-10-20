# domain_error

This context describes expected application errors and operation outcomes.
Its vocabulary distinguishes those outcomes from failures in diagnostics
or error conversion.

## Language

**Domain error**:
An expected domain or application error that an operation can report as
its outcome.

**Feature error root**:
The common category for a feature's related domain errors.

**Type identifier**:
A stable name for a kind of domain error, used in logs and error reporting.

**Cause**:
The optional technical context attached to a domain error, including
another domain error.
_Avoid_: Raw error when referring to stored diagnostic context.

**Result**:
An operation outcome containing either an error value or a success value.
The error value need not be a domain error.

**Domain result**:
A result whose error value is a domain error.

**Error value**:
The error held by an unsuccessful result. It is distinct from a thrown raw
error or a failure in an observer or mapper.

**Success value**:
The value produced by an operation that completes successfully.

**Raw error**:
A thrown object that is not already a domain error.

**Mapped domain error**:
A domain error produced by converting a raw error.

**Observer failure**:
A failure in a callback that observes an operation's error.

**Mapper failure**:
A failure while converting a raw error into a domain error.
