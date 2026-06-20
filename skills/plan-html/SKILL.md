---
name: plan-html
description: Present an implementation or task plan to the user as a single self-contained HTML page with a consistent layout, then open it in the browser. Use when an agent has a non-trivial plan, proposal, or design to show for review and a styled page is clearer than raw chat or Markdown. Prefer this over dumping a long plan into chat or writing a plain .md file.
---

# Plan HTML

Present a plan as a styled, self-contained HTML page instead of raw Markdown or a wall of chat text.

## Overview

When you have a plan worth reviewing, render it into a single `.html` file using `references/template.html` as the base, then open it in the user's browser. The template gives a consistent look; you fill in the content. Slight variation is fine — the goal is a readable, predictable format, not a rigid schema.

## Workflow

1. Start from `references/template.html` (copy it, do not edit the reference in place).
2. Fill in the plan content. Keep the page self-contained: no external CDNs, scripts, or web fonts — CSS stays inline in `<head>`.
3. Write the result to a `.html` file (e.g. `plan.html` in the working directory or a temp path).
4. Open it for the user:
   ```sh
   open plan.html
   ```
   `open` is macOS-only; this skill targets that environment.
5. If `open` cannot run (e.g. a sandboxed environment where command execution is blocked or fails), do not retry or work around it. Instead, output the exact command for the user to run themselves, using the absolute path:
   ```sh
   open /absolute/path/to/plan.html
   ```
6. Tell the user the file path and give a one-line summary in chat.

## Suggested structure

Use these sections as a default; add, drop, or rename them to fit the plan. Consistency across plans matters more than hitting every section.

- **Title** — what this plan is
- **Context** — why this change is being made; the problem or need
- **Approach** — the recommended approach in a few sentences
- **Steps** — ordered, concrete actions
- **Files** — files/areas to be changed (paths)
- **Verification** — how to confirm it works (commands, tests, manual checks)
- **Risks / Open questions** — trade-offs, unknowns, things to confirm

## Diagrams

Add a simple figure only when it genuinely helps the reader understand flow, structure, or relationships — not for decoration. Keep it minimal and not flashy. Stay self-contained: no external libraries (e.g. no Mermaid/CDN). The template provides two reusable patterns:

- **CSS flow** (`.flow` with `.node` / `.arrow`) — for short left-to-right pipelines or step flows.
- **Inline SVG** (`.diagram`) — for boxes, arrows, and relationships that need more structure.

Reuse the template's colors so diagrams match the page in both light and dark mode.

Do not over-diagram. The default is no figure: most plans read fine with prose, lists, and a table. Add one only where text alone is genuinely hard to follow, and use at most one or two per plan. If a sentence or list is clearer than a figure, skip the figure. Never add a diagram just to fill space or make the page look richer.

## When to use

- You produced a non-trivial plan, design, or proposal and want the user to review it.
- A long plan would be hard to read in chat.

## When not to use

- You only need to read or reason about the plan yourself.
- The user explicitly asked for the plan inline in chat.
- A short summary in chat is enough.

## References

- `references/template.html`: self-contained HTML base (inline CSS) to copy and fill in.
