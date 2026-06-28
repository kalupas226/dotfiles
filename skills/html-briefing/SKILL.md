---
name: html-briefing
description: Create a self-contained HTML briefing, report, review, explanation, comparison, or lightweight interactive artifact when structured HTML would help the user read, compare, review, or act on complex information better than chat or Markdown. Use for non-trivial implementation plans, PR reviews, code explanations, research summaries, decision notes, side-by-side comparisons, and small local HTML artifacts with optional inline CSS/JS.
---

# HTML Briefing

Create a focused, self-contained HTML page when the user needs a readable artifact rather than a long chat message.

## Output Principles

Build the page for the task rather than copying a full-page template. This skill intentionally does not provide a complete HTML template because templates tend to pull content toward the template's example structure. Start from a minimal HTML document, reuse only small snippets when they solve a specific problem, and let the user's information determine the sections, layout, visual aids, and controls.

HTML's expressive power is part of the value. Use layout, tables, callouts, diagrams, charts, metrics, collapsible details, copy buttons, filters, or small controls when they improve judgment or navigation. Avoid them when they only make the page look richer. Do not invent metrics, diagrams, UI panels, timelines, or labels that are not grounded in the user's information.

## Workflow

1. Choose the smallest recipe or custom structure that makes the content clearer.
2. Start with a minimal HTML document and add only the sections, styles, and components the content needs.
3. Keep the page self-contained: no external CDNs, remote scripts, web fonts, or external runtime dependencies. CSS stays inline in `<head>`. Inline JS is allowed for local reader affordances such as syntax highlighting, copy buttons, collapsible details, filters, toggles, and small controls.
4. Use a calm, document-oriented visual system by default: readable type, clear hierarchy, good spacing, restrained borders, and a light/paper background. Do not add automatic dark mode unless the user asks for it; code blocks may use a dark background for readability.
5. If the page contains code blocks, read `references/code-highlighter.html` and copy its inline CSS/JS snippet into the artifact. Do not include the snippet when there are no code blocks.
6. Write the result to a `.html` file, usually in the working directory or a temp path.
7. Open it for the user:
   ```sh
   open briefing.html
   ```
   `open` is macOS-only; this skill targets that environment.
8. If `open` cannot run (for example, command execution is blocked), do not retry or work around it. Instead, output the exact command for the user to run themselves, using the absolute path:
   ```sh
   open /absolute/path/to/briefing.html
   ```
9. Tell the user the file path and give a one-line summary in chat.

## Briefing Recipes

Use these as information-architecture recipes, not rigid templates. Rename, merge, or drop sections to match the task.

- **Implementation plan**: summary, context, approach, steps, files or components, verification, risks or open questions.
- **PR review**: verdict or TL;DR, findings by severity, evidence, review focus, test plan, follow-up questions.
- **Implementation explainer**: what changed, request/data flow, key snippets, edge cases, failure modes, how to verify.
- **Research/report**: question, sources or evidence, findings, comparison table, recommendation, uncertainty.
- **Decision note**: options, criteria, trade-offs, recommendation, non-goals, consequences.
- **Lightweight artifact**: input data, controls, output area, instructions only where necessary, export or copy affordances if useful.

## Tone and Labels

Write as a technical briefing. The document should read like a design note, PR review, incident analysis, implementation explainer, research memo, or decision note, not like a landing page, blog introduction, or conversational explainer.

Choose headings by the reader task they support. A heading should tell the reader what kind of judgment, evidence, boundary, risk, relationship, impact, or action the section contains. Avoid headings whose main role is to make the document feel friendly, dramatic, promotional, or easier to sell.

Prefer precise document functions over rhetorical summaries. When a section introduces the main point, label it by its role in the document. If a heading would feel out of place in an internal engineering document, rewrite it. Clarity should come from structure, evidence, and concrete relationships, not from casual phrasing or presentation copy.

## Document Components

Use ordinary document components when they help: headings, compact metadata, tables, callouts, details blocks, checklists, timelines, cards for repeated items, code blocks, copy buttons, filters, and small controls. Choose components by reader task, not by visual variety.

For longer briefings, add a compact table of contents or section navigation. Use it when the document has enough sections that readers may need to jump between summary, evidence, risks, decisions, code, or next actions. Do not add navigation to short artifacts where the headings are already visible within one or two screens.

Use cards for repeated peer items such as findings, candidates, or risks. Do not wrap a whole page section in a card just to make it look designed. Use tables for dense comparisons, file lists, findings, acceptance criteria, and trade-offs.

## Media and Sources

Use images when the reader needs to inspect an actual screen, product, artifact, chart, or visual state. Prefer inline SVG or embedded data URIs for self-contained artifacts. Avoid decorative stock-like images or atmospheric media that does not support a claim, comparison, or decision.

For source media such as talks, demos, recordings, or product videos, prefer links with titles, relevant time ranges, and the specific claims supported by the media. Do not embed remote media players by default. Use embedded images or video only when the media itself is necessary for inspection and the artifact can remain self-contained, or when the user explicitly accepts external assets.

## Diagrams

Add a figure only when it helps the reader understand structure that is hard to scan in prose. Do not use diagrams for simple linear sequences that can be read more clearly as a list, timeline, or table. A diagram should add structural information: branching, ownership boundaries, dependencies, state transitions, feedback loops, failure propagation, or interactions between multiple actors.

Use a diagram when the content would naturally fit a Mermaid flowchart, sequence diagram, state diagram, or dependency graph. Because the artifact must stay self-contained, implement the figure directly with HTML/CSS or inline SVG rather than depending on a Mermaid runtime or CDN. Avoid arrow-only chains where each node merely restates a step.

Every figure must explain its semantics:

- Add a title or caption that says exactly what the figure represents.
- If arrows appear, state what the arrows mean, such as data handoff, control flow, dependency, or sequence.
- If color, border, or emphasis carries meaning, state that meaning in adjacent text or a small legend. Do not rely on color alone.
- Do not leave orphan nodes, dangling arrows, or boxes whose relationship to the rest of the figure is unclear.
- If the relationship cannot be explained plainly, use a table or prose instead of a diagram.

Do not over-diagram. Use one or two visual aids only when they reduce reading effort; skip them when they repeat an already-clear sentence, list, or table.

## Code Blocks

Use code blocks when a snippet, diff, command, query, or configuration is evidence for the briefing. For PR reviews and implementation explainers, include the smallest relevant snippet when it materially clarifies a finding or change; do not paste large source files.

Every multiline code block must use a language class:

```html
<pre><code class="language-swift">final class ProductViewModel { ... }</code></pre>
```

Use the best known language identifier, such as `language-swift`, `language-sh`, `language-json`, `language-diff`, or `language-sql`. Do not emit bare `<pre><code>` blocks and rely on ad hoc CSS alone. If the language is unknown, use a `language-*` class anyway and let it degrade to plain readable code.

When any code block appears, read `references/code-highlighter.html` and copy its inline CSS/JS snippet into the artifact. The snippet includes best-effort syntax highlighting and copy buttons for `sh`, `json`, `js`, `ts`, `html`, `css`, `python`, `swift`, `sql`, and `diff`. Highlighting should preserve the original code text and escape inserted HTML safely; it is a readability aid, not a parser.

## Applicability Check

After the skill triggers, confirm that HTML still improves the answer. Continue when a structured artifact would make the content easier to read, compare, review, navigate, reuse, or act on.

Use chat or Markdown instead when the answer is short, the user asked for another format, the work is only private scratch space, or HTML would add ceremony without improving the user's ability to decide or act.

## References

- `references/code-highlighter.html`: optional inline CSS/JS snippet for artifacts that contain code blocks.
