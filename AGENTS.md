# Repository guidance

`domain_error` is a Dart package. Use Dart 3.13.0 or later within Dart 3.
The public entry point is `package:domain_error/domain_error.dart`.

Keep changes focused. Preserve public contracts unless the task explicitly
requires changing them. Keep authorship and provenance neutral. Never add
tool attribution or invent authors, reviewers, or signatures.

For Dart changes, run `make deps`, `make check`, and
`dart run example/domain_error_example.dart`.
For documentation changes, check links and run `git diff --check`.
External writes require explicit task authorization.

## Agent skills

### Issue tracker

Track issues and specifications in GitHub Issues for
`andrey-krasheninnikov/domain_error`. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the five canonical triage labels. See `docs/agents/triage-labels.md`.

### Domain docs

Use a single-context layout with root `GLOSSARY.md` and `docs/adr/`.
See `docs/agents/domain.md`.
