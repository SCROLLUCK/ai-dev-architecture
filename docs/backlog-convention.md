# Backlog convention

One convention for every project: `docs/backlog.md`.

```markdown
# Backlog

## Next
- [ ] Add dark mode to the settings page
- [ ] Export the report as CSV

## Done
- [x] Rate-limit the search endpoint
```

## Rules

- `##` sections group items (Next, Done, or any theme); each item is a Markdown checkbox, `- [ ]` open and `- [x]` done.
- **Every request from the PO becomes an open item the moment it is asked, before work starts.** One item per thing asked, in the PO's own words, under `## Next`.
- It is written in the **main checkout**, not a worktree, so tooling sees it immediately, and left uncommitted there.
- The task branch never touches `docs/backlog.md`, so the merge cannot conflict with it.
- After the merge, the lead ticks the item and commits `docs/backlog.md` on the trunk, named in the same approval as the merge.
- Tick the item when it ships, or move it to the changelog where the project has one.
- A project without the file gets one.

## Why

A request that only lives in chat is lost at the next `/clear` or compaction. The file survives, is diffable, and any agent can read it.
It also lets the Project Hub (see [tooling](tooling.md#project-hub)) show the backlog per project and let the PO edit it in the browser.
