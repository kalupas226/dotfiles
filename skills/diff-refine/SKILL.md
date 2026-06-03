---
name: diff-refine
description: Refine an existing code or config diff through iterative reviewer and implementer passes. Use when there is already a current-worktree diff and the goal is to converge it by reviewing risks, applying targeted fixes, and repeating until unresolved high/medium findings are cleared or the loop stops.
---

# Diff Refine

## Overview

Launch an orchestrated review-and-fix loop for an existing diff. If the host supports subagents, treat the invoking agent as a parent launcher: start a dedicated orchestrator subagent, pass the current diff and constraints to it, and let that subagent manage reviewer and implementer workers. If subagents are not available, run the same reviewer and implementer passes in the current agent using the contracts in `references/contracts.md`.

## Workflow

1. Confirm there is already a meaningful diff in the current worktree.
2. If strong rollback matters, tell the user to create a baseline commit before starting. Do not require it.
3. Start an orchestrator subagent when available, or run an orchestrator pass in the current agent, and give it:
   - the current task goal
   - any constraints or non-goals
   - any known concerns
   - the current diff as the refinement target
4. Have the orchestrator run:
   - `reviewer:general` every round
   - `reviewer:security` when the diff touches auth, secrets, permissions, untrusted input, dangerous commands, or similarly sensitive behavior
   - `reviewer:tests` when test coverage, validation depth, or regression confidence looks weak
   - `implementer` after findings are triaged
5. Repeat until there are no unresolved `high` or `medium` findings, or the round limit is reached.
6. Return a concise final summary to the parent agent with:
   - what changed
   - what risks were resolved
   - what remains unresolved or intentionally accepted

## Boundaries

- Default input is the current worktree diff.
- Operate directly in the current worktree.
- Do not require file-backed run state; use the message contracts in `references/contracts.md`.
- Do not create branches or worktrees as part of v1.
- Do not require rollback support. If the user wants a strong checkpoint, rely on a baseline commit they make before the loop starts.

## References

- `references/workflow.md`: execution flow, round rules, and stopping conditions
- `references/roles.md`: responsibilities and guardrails for each review or implementation role
- `references/contracts.md`: fixed Markdown message formats to pass between roles
- `references/prompts.md`: reusable prompt templates for orchestrator, reviewers, and implementer
