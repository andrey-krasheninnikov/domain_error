# Keep domain error identity separate from diagnostics

`DomainError` equality includes the concrete type, `typeIdentifier`, and
`message`; subclasses can add business fields through `props`.
Diagnostic `cause` and `stackTrace` do not participate, so the same
application error remains equal when its diagnostic context differs.

Preserve `typeIdentifier` strings when renaming classes so logs and error
reporting keep stable identifiers after renames and obfuscation.

See the [implementation](../../lib/src/domain_error.dart) and
[identity and diagnostic tests](../../test/domain_error_test.dart).
