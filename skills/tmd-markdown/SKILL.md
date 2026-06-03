---
name: tmd-markdown
description: Use when an agent needs to present, open, preview, or ask the user to review a Markdown file in the terminal, especially plans, review notes, task summaries, or agent-written .md files. Prefer the local `tmd FILE` command so Markdown opens with glow, and in tmux it appears in a centered popup.
---

# TMD Markdown

Use `tmd FILE` as the default way to present a Markdown file to the user from the terminal.

Examples:

```sh
tmd PLAN.md
tmd notes/review.md
```

Inside tmux, `tmd` opens the file in a centered popup with `glow`. Outside tmux, it falls back to `glow -p`.

Use `tmd` when:

- The user asks to open, show, preview, or review a Markdown file.
- You create a Markdown plan or longer note and want the user to inspect it.
- Another agent writes `PLAN.md`, `plan.md`, or another `.md` artifact for user review.

Do not use `tmd` when:

- You only need to read or edit the file yourself.
- The user explicitly asks for the Markdown content in chat.
- A short summary in chat is more appropriate than opening a file.
