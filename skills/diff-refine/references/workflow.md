# Diff Refine Workflow

## Start Conditions

- There is already a meaningful diff in the current worktree.
- The user wants to refine that diff rather than start implementation from scratch.
- If strong rollback matters, recommend creating a baseline commit before the loop starts.

## Parent Handoff

The invoking agent should:

- summarize the user's goal and constraints
- start an orchestrator subagent
- pass the current diff as the refinement target
- ask the orchestrator to return only a concise final summary plus any unresolved risks

## Round Flow

1. Review the current diff and decide which reviewer types are needed.
2. Run `reviewer:general`.
3. Add `reviewer:security` when the diff touches security-sensitive behavior.
4. Add `reviewer:tests` when validation or regression confidence looks weak.
5. Triage findings and forward unresolved work to the implementer.
6. Re-review if the implementer made meaningful changes or unresolved high/medium findings remain.

## Stopping Rule

Stop when either condition is met:

- there are no unresolved `high` or `medium` findings
- the loop reaches 3 rounds

`low` findings do not block completion. Include them in the final summary when still relevant.

## Retry Guidance

- If a reviewer returns shallow findings for a broad diff, add a specialized reviewer or rerun with a tighter brief.
- If the implementer does not fully address a finding, keep it unresolved and feed it back into the next round.
- If the diff keeps expanding without reducing risk, stop and report that explicitly instead of looping further.
