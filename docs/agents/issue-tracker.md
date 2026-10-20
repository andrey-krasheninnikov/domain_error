# Issue tracker: GitHub

Issues and specifications live in
https://github.com/andrey-krasheninnikov/domain_error/issues.
Use the `gh` CLI. Specify `--repo andrey-krasheninnikov/domain_error`
for issue and pull request commands.

## Conventions

- Read an issue with `gh issue view <number> --comments`; inspect its labels too.
- List issues with `gh issue list`, using state and label filters as needed.
- Create an issue with `gh issue create --title "..." --body-file <path>`.
- Add a comment with `gh issue comment <number> --body-file <path>`.
- Apply or remove labels with `gh issue edit <number> --add-label "..."`
  or `--remove-label "..."`.
- Close an issue with `gh issue close <number>`.

Use files with actual newlines for multiline bodies. Review the exact
content before publication and read back the result afterward.
An available command does not authorize a write.

When a skill says "publish to the issue tracker", create a GitHub issue.
When it says "fetch the relevant ticket", read the issue body, comments,
and labels.

## Pull requests as a triage surface

**PRs as a request surface: no.**

When enabled, use the same triage roles for external pull requests.
For discovery, include authors with association `CONTRIBUTOR`,
`FIRST_TIME_CONTRIBUTOR`, or `NONE`. Read the PR body, comments, labels,
and diff. An explicitly requested PR can be inspected regardless of
author association.

Issues and pull requests share a number space. Resolve an ambiguous
number with `gh pr view <number>`, then `gh issue view <number>` if
it is not a pull request.

## Wayfinding operations

- The map is one issue labelled `wayfinder:map`, containing Notes,
  Decisions so far, and unresolved questions.
- Child tickets are GitHub sub-issues. If sub-issues are unavailable,
  use a task list in the map and `Part of #<map>` in each child.
  Use `wayfinder:research`, `wayfinder:prototype`,
  `wayfinder:grilling`, or `wayfinder:task` as appropriate.
- Record blockers through native issue dependencies. Use the blocker's
  numeric database ID, not its issue number or node ID. If dependencies
  are unavailable, write `Blocked by: #<number>` in the child.
- The frontier contains open, unassigned children with no open blockers,
  in map order.
- Claim an authorized ticket by assigning it to the current account.
- Resolve an authorized ticket with a comment and closure, then add
  a brief decision and a link to the map.
