# Message Contracts

Use Markdown with the exact section headings below. Keep responses concise and structured.

## DiffBrief

```md
## Goal
...

## Constraints
...

## Allowed Scope
...

## Disallowed Scope
...

## Review Focus
...
```

## ReviewFindings

```md
## Summary
...

## Findings
### [Severity] Short title
- Evidence: ...
- Recommended change: ...

### [Severity] Another title
- Evidence: ...
- Recommended change: ...

## Follow-up
...
```

Severity must be one of `high`, `medium`, or `low`.

## ImplementationResult

```md
## Resolved
- Finding: ...
- Change: ...

## Unresolved
- Finding: ...
- Reason: ...

## New Risks
- ...
```

## FinalSummary

```md
## Outcome
...

## Resolved Risks
- ...

## Remaining Risks
- ...

## Notes
...
```
