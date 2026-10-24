# The docs vault — one convention for every project

The project's notes are an Obsidian vault. Small notes, one-line summaries, an index, a checker.

## Layout

- The vault is `docs/`. Obsidian opens `docs/`; `.obsidian/` lives there, not at the repo root.
- Exception: a project whose vault is the repo root by design (e.g. a content studio) may do
  so, as long as the project's docs say it.
- `docs/index.md` is the map: it links every note, one line each. A note not in the index
  does not exist.

## Notes

- Front matter on every note: `summary:` (one line: what the note holds) and `updated:`
  (`YYYY-MM-DD`, set whenever the note changes).
- Wikilinks must resolve (`[[note]]`, `[[note|alias]]`, `[[note#heading]]`, `![[image.png]]`).
- Keep notes small (~150 lines); split and add the new note to the index.

## How agents read it

1. `docs/index.md`, then the `summary:` lines (`grep -rh '^summary:' docs`).
2. Open only the notes the task touches.
3. Never read a big file whole: a changelog is read only at `## Unreleased`; a file over
   ~40KB is grepped or read by section.

## Drift check (optional)

`docs-map.txt` (default `docs/docs-map.txt`) maps code paths to the notes that describe them:

```
# code path prefix        notes under docs/, comma-separated, no .md
src/auth/                 authentication,routing-and-permissions
```

Longest prefix wins. A commit that changes a mapped path must also change one of its notes.
Bypass is explicit and visible: `DOCS_CHECK_SKIP_DRIFT=1` in the commit command, for a change
that alters nothing a note says.

## Local-only notes

A project may keep notes out of git on purpose (e.g. `notes/<channel>/` local, only
dashboards and templates committed). Allowed, but the project's docs must state it.

## Dataview and Graphify

- Dataview is optional. A dashboard queries only folders that exist.
- Graphify: not in use yet; evaluation pending.

## The checker

[`scripts/docs-check.sh`](../scripts/docs-check.sh) — bash + python3, no project paths.

```bash
bash docs-check.sh [docs_dir]           # default docs; vault checks + drift vs HEAD
bash docs-check.sh [docs_dir] --staged  # drift against the staged files (commit hook)
bash docs-check.sh [docs_dir] --vault   # structure only
```

It fails (exit 1, list on stderr) on: missing `summary:` / `updated:`, unresolved wikilinks,
notes missing from `index.md`, and (if the map exists) drift. Folders starting with `.` or `_`
(`_templates/`) are skipped. Copy it into the project (e.g.
`management-scripts/docs-check.sh`) so it is versioned with the repo.

### Wiring

Pre-commit (`.git/hooks/pre-commit` or the project's hook runner):

```bash
bash management-scripts/docs-check.sh docs --staged
```

Claude Code: a `PreToolUse` hook on `Bash` in `.claude/settings.json` calls a small wrapper
that reads the tool call JSON on stdin, returns early unless the command is a real
`git commit`, runs the check in the commit's tree, honours `DOCS_CHECK_SKIP_DRIFT=1` found in
the command, and answers with `permissionDecision: "deny"` plus the list when it fails:

```json
{ "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [
  { "type": "command", "command": "bash \"${CLAUDE_PROJECT_DIR:-.}\"/management-scripts/docs-check-hook.sh",
    "timeout": 60, "statusMessage": "docs-check: the vault must move with the code" } ] } ] } }
```

Reference implementation of the wrapper: job-matching's `management-scripts/docs-check-hook.sh`
(the `update-config` skill sets the hook up). Because the hook runs before the Bash command,
`git add` and `git commit` go in separate calls.
