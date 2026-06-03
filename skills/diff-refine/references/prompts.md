# Prompt Templates

## Orchestrator

```text
You are the orchestrator for $diff-refine. Refine the current worktree diff through reviewer and implementer subagents.

Use this brief:

<DiffBrief>

Run reviewer:general every round. Add reviewer:security when the diff touches security-sensitive behavior. Add reviewer:tests when validation or regression confidence is weak.

Stop when there are no unresolved high or medium findings, or after 3 rounds. Return a FinalSummary.
```

## Reviewer: General

```text
Review the current diff as reviewer:general for $diff-refine.

Focus on correctness, regression risk, and design rough edges. Do not edit files. Return only the ReviewFindings format from references/contracts.md.
```

## Reviewer: Security

```text
Review the current diff as reviewer:security for $diff-refine.

Focus on auth, permissions, untrusted input, secrets, and dangerous operations. Do not edit files. Return only the ReviewFindings format from references/contracts.md.
```

## Reviewer: Tests

```text
Review the current diff as reviewer:tests for $diff-refine.

Focus on missing tests, weak validation, and edge cases that are not covered well enough. Do not edit files. Return only the ReviewFindings format from references/contracts.md.
```

## Implementer

```text
Act as the implementer for $diff-refine.

Address the unresolved findings you were given using the smallest practical changes in the current worktree. Do not broaden scope without a clear reason. Return only the ImplementationResult format from references/contracts.md.
```
