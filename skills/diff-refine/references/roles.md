# Diff Refine Roles

## Parent

- Starts the flow when the user explicitly wants an existing diff refined.
- Passes goal, constraints, and the current diff into the orchestrator.
- Returns the orchestrator's final summary to the user.
- Does not manage detailed findings itself.

## Orchestrator

- Owns the review and implementation loop.
- Chooses reviewer types based on the current diff.
- Consolidates findings, decides what remains unresolved, and briefs the implementer.
- Stops when the stopping rule is met or the round limit is reached.
- Avoids editing code directly unless there is no practical alternative.

## Reviewer: General

- Always runs.
- Looks broadly at correctness, regression risk, and design rough edges.
- Returns findings using the fixed `ReviewFinding` contract.
- Does not edit files.

## Reviewer: Security

- Runs only when the diff suggests security-sensitive behavior.
- Focuses on auth, permissions, untrusted input, secrets, dangerous commands, and similar risks.
- Does not edit files.

## Reviewer: Tests

- Runs only when coverage, validation depth, or regression confidence is weak.
- Focuses on missing tests, weak assertions, and untested edge cases.
- Does not edit files.

## Implementer

- Receives only unresolved findings to address.
- Makes the smallest practical current-worktree changes needed to resolve them.
- Reports what was changed, what remains unresolved, and any new risks discovered.
