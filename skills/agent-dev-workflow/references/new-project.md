# Setting this workflow up in a new repo

Create only what the project needs; the rules in SKILL.md work with nothing but git.

1. **Project CLAUDE.md** — a short section: "One branch per task", the approval rule
   ("never commit/push without asking"), the shared-tree rules (stage by name), and the
   project's hard invariants (runtime, i18n, component library, language of identifiers).
   Keep it to what the repo can't show.
2. **`.claude/worktrees/` in `.gitignore`**, and a note of the base branch for new
   worktrees. Also hide it from VS Code in `.vscode/settings.json` — otherwise every
   worktree is scanned (nested git repos, followed `node_modules` symlinks) and the
   extension host hangs:
   ```json
   "files.watcherExclude": { "**/.claude/worktrees/**": true },
   "files.exclude": { "**/.claude/worktrees": true },
   "search.exclude": { "**/.claude/worktrees": true },
   "git.repositoryScanIgnoredFolders": [".claude/worktrees", "node_modules"]
   ```
   Remove worktrees once their branch is merged (with approval) so they don't pile up.
3. **A project `git` skill** — branch naming, commit message voice, rebase/conflict
   handling, the approval question. Write one for the repo and adapt the voice.
4. **Docs that move with the code** (optional, recommended): a `docs/` vault with an
   index, a `changelog.md` with `## Unreleased`, a `decisions/` log, and
   `docs-map.txt` mapping code paths to notes; `docs-check.sh` plus a `PreToolUse` hook on
   `git commit` that refuses a commit whose code moved without its notes (see the
   `update-config` skill). Bypass is an explicit env var visible in the command.
5. **One lint/test entry point** (`lint.sh`) that the lead runs before asking to commit,
   and a helper that runs the same tools against a *worktree* (a throwaway container
   mounting it).
6. **Legal/compliance screen** if the product handles personal data, payments or
   scraping — a reference file the "understand" step runs first.
7. **Deploy skill** if there is prod: approvals, order (new in → verify → clean up),
   announce before restart, no deletion without asking.
8. **Memory** — first session: save who the PO is and any working preferences they state.

Global pieces already available everywhere: this skill, `maestri-manager`, `keep-awake`,
the budget/model rules in `~/.claude/CLAUDE.md`.
