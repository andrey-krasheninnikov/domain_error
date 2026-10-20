# Domain documentation

This repository has one domain context: `domain_error`.

## Before exploring

Read the root `GLOSSARY.md` and relevant decisions in `docs/adr/`.
If either is absent, continue without treating its absence as a blocker.
Create documentation when a concrete term or decision needs recording.

## Layout

- `GLOSSARY.md`: project vocabulary.
- `docs/adr/NNNN-short-title.md`: sequentially numbered decisions.

Use glossary terms consistently in issues, specifications, tests, and
documentation. Keep implementation details out of the glossary.
Verify new terms against the current source before adding them.

If a proposed change conflicts with an ADR, identify the conflict
explicitly before revisiting the decision.
