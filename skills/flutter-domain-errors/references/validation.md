# Validation

Installation, automatic selection, and example behavior are checked separately.
A successful install does not establish selection. A request that names a skill
establishes explicit use only.

The deterministic CI job checks local/global installation through skills CLI
1.7.4, preservation of an unrelated control skill, portable references, and
runnable examples against 3.0.0, 3.1.0, 4.0.0, and the current 5.x source.
Global installation runs only on a disposable runner. The package has no custom
installer and installation never upgrades domain_error.

Selection checks use fresh projects and sessions, with requests that do not
name the skill. Positive evidence requires actual loading and correct API
selection; a self-reported choice is insufficient. Negative cases must not
apply these rules. Inspect invocation/loading evidence separately from the
correctness of the final recommendation.

The matrix includes direct hosted 3.x/4.x/5.x, path, Git, development dependency,
monorepo scoping, no dependency, a comment-only mention, transitive-only,
unrelated sibling and unrelated task, plus unsupported and unresolved versions.
The latter require an explicit limitation and source inspection, never an
upgrade or an incompatible example.

## Observed client checks

On 2026-10-20, Codex CLI 0.163.0 and Claude Code 2.1.304 each completed 16
read-only cases without the skill name in the request:

| Cases per client | Observed behavior |
| --- | --- |
| Hosted 3.1.0, 4.0.0, 5.0.1; path; Git; development dependency; 3.x declaration overridden to 5.x; mixed 3.x/5.x monorepo | Skill loaded; contract selected from the applicable resolved source. |
| No dependency; comment only; transitive only; unrelated sibling; unrelated task | Skill was not invoked or loaded. |
| Legacy 2.1.1; unresolved version; path override to an unknown 99.x API | Applicability checked; unsupported/unresolved API identified; no 3.x/4.x/5.x example was applied blindly and no dependency changed. |

Codex used per-run overrides to disable unrelated catalog entries. Its initial
full personal catalog exceeded the client's skill-description budget. A skill
whose description is unavailable cannot rely on automatic selection. User
configuration was not edited. Claude used project settings, read-only tools,
and no external integrations. Both used fresh projects and sessions with the
same entry point, shared rules, executable examples, and dependency fixtures.

These checks establish observed loading, version routing, and exclusion behavior.
The runnable Markdown assertions establish example behavior separately.
Proposed application changes still need their own compilation and tests.
No claim is made for other clients, versions, prompt variations, remote reporting,
or a forced trigger on every request.
