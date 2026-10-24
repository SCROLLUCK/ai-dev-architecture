# Delegation — what, to whom, and how to brief

## What goes to an agent

| Work | Agent type / model | Notes |
|---|---|---|
| Reading, sweeps, investigation | `Explore` or `general-purpose`, **haiku** (sonnet if it needs reasoning) | independent ones in parallel, one per agent, in one message |
| Implementation with a clear plan | `general-purpose`, **sonnet**, on its own branch/worktree | the lead verifies and merges |
| Design, unknown cause, audit, prod, data migration, security | **opus** (or the lead itself) | judgment work |
| Adversarial review | an agent that did **not** write the code, **opus**, read-only | see definition-of-done |
| Long job (test suite, build, monitoring) | background; keep working | |
| Mechanical work when the Claude quota is tight | `antigravity` (Google quota) | needs a complete brief; it has no conversation |

Model is always explicit — never inherit the session's. Fable only on request.

## What stays with the lead

- A surgical edit of a few lines with the context already loaded.
- Verification that needs the running environment (containers and dev servers mount the
  main tree, not the worktree): delegate the writing, verify here.
- Commit, push, tag, deploy, prod, deletion — the PO's approval happens in the lead.
- Any decision that needs the PO.

## The brief

Open with the specialist persona (1–2 sentences) — it is what makes the agent act like one:
*"You are a senior frontend engineer (React/TS) who follows best practices and always
reads the docs and the decision log before coding."* Then:

1. **Goal** in the PO's terms and the observable result wanted. When the project uses
   OpenSpec, the goal is "implement task N.M of `openspec/changes/<name>/tasks.md`": the
   agent reads the proposal, the deltas and the design, builds only that task (test
   first) against the deltas' scenarios, and stops and reports when the change is wrong
   or silent — it never fills the gap with its own reading of the request.
2. **Branch + worktree path.** "Work and commit only there. Never touch master or the
   main tree. Do not push."
3. **Files and notes to read first** (exact paths) and the project rules that apply
   (i18n, component library, runtime invariants, language of identifiers).
4. **Done-criterion**: the commands that must pass (tests, lint, type-check), and the
   doc/changelog entries the change needs.
5. **Out of scope**: no unrelated refactors, no new abstractions, no deleting dead code.
6. **Return**: the conclusion plus `path:line` — not a dump. State what was verified and
   what was not.

## Mind the environment

- A worktree has no running stack. Give the agent the command that runs tools against its
  worktree (e.g. a throwaway container mounting `worktree/frontend` over the image's
  `node_modules`), or tell it which checks the lead will run.
- Never symlink or install `node_modules` (or a venv) inside a worktree under
  `.claude/worktrees/`: the editor follows the links, and six worktrees pointing at one
  `node_modules` put ~1M files in the workspace — VS Code's extension host hangs and no
  extension works. Run tools through the throwaway container above instead — for Node
  repos, `<path-to>/wt-run.sh <worktree> <cmd...>` (mounts the main checkout's
  `node_modules`; `WT_IMAGE` picks the image). The repo's
  `.vscode/settings.json` must exclude `.claude/worktrees` (see
  [new-project.md](new-project.md)).
- At most 5 open worktrees per repo (`git worktree list` before adding one). Dozens of
  forgotten worktrees crash the editor even without links; clean up after each merge.
- An agent that can't run something must say so, not guess it passed.
- Don't remove a subagent's worktree while it may still run, or while its branch is
  unmerged or dirty. Root-owned leftovers from containers need approval, then a throwaway
  container to remove them.

## Maestri recruits (when the session runs under Maestri)

Only the VS Code/main session orchestrates; a session running inside Maestri
(`$MAESTRI_TERMINAL_ID` set) does not. Run `maestri list` before recruiting — reuse a
teammate whose role fits. Recruits get a film-persona name and a specialist role
(`maestri role create`), an explicit model, and the same brief as above. Details: the
`maestri-manager` skill.
