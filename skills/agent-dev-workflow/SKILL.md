---
name: agent-dev-workflow
description: The orchestrator + subagents way of developing software, portable to any repo — the main session is the tech lead and the user is the PO; every task gets its own branch and worktree; subagents implement on a cheap model from a persona brief and never touch master; the lead verifies (a report is not proof), shows the result running before merging, and asks approval for commit, push and deploy. Use when starting a task the user hands over, delegating to a subagent or Maestri recruit, reviewing an agent's work, showing the user a worktree's result before merge, setting this workflow up in a new project, or when the user says "our agent workflow", "como trabalhamos com agents".
---

# Agent-driven development — lead, agents, PO

> Machine-specific paths, habits and notes: read `local.md` next to this file if it exists.
> It is yours and never versioned; this file stays generic.

The roles are fixed; the project only supplies the
commands. Setting it up in a new repo: [references/new-project.md](references/new-project.md).

## The three roles

| Role | Who | Owns |
|---|---|---|
| **PO** | the user | product direction, money and price, prod risk, and every approval (commit, merge to a shared branch, push, tag, deploy, deletion) |
| **Lead** | the main session | splitting the work, briefs, branches, verification, integration, the questions to the PO. Does not wait for orders: decides the operational, asks only what is the PO's |
| **Agents** | subagents (`Agent` tool) or Maestri recruits | executing one closed task on one branch, on the cheapest model that can do it |

The lead orchestrates, it does not become the bottleneck or the typist: small context
on the lead, cheap models on the typing. A subagent starts cold, so for a two-line edit
with the context already here, the lead does it itself.

## The loop for every task

1. **Understand.** Read the project's notes/docs for the area first (not the whole
   folder). Surface assumptions and alternatives; ask the PO only if the answer changes
   what you build. Run the project's legal/compliance screen if it has one.
   **Spec first** when the project uses OpenSpec (`openspec/`): a feature or a rule
   change is an OpenSpec change `openspec/changes/<name>/` (proposal, spec deltas,
   design, tasks), written from a Superpowers brainstorm via `/opsx:propose`. The PO
   approves it before any agent codes; only then does the lead set the proposal's last
   line to `Approved: YYYY-MM-DD`. Agents implement `tasks.md` (the only plan — no
   `writing-plans`), the review checks every scenario of the deltas, and `/opsx:archive`
   merges the deltas into `openspec/specs/` on the branch before the merge.
2. **Branch + worktree** — nothing is developed on the trunk:
   `git worktree add -b feat/<name> .claude/worktrees/<name> <base>`. Base = the branch
   that already holds the work this one builds on (local `master` when earlier tasks are
   merged locally and not pushed — basing on `origin/master` silently drops them).
   No `node_modules`/venv symlinks inside the worktree, and `.vscode/settings.json`
   excludes `.claude/worktrees` — otherwise VS Code's extension host hangs
   ([references/delegation.md](references/delegation.md#mind-the-environment)).
   **At most 5 open worktrees per repo**: run `git worktree list` before adding one; at
   the cap, remove a merged one first (with approval) or wait. Remove each worktree and
   its branch right after its merge, in the same step as the integration (step 7).
3. **Delegate or do it** ([references/delegation.md](references/delegation.md)): persona
   brief, explicit model, the branch and worktree path, a done-criterion, a short return.
4. **Verify** ([references/definition-of-done.md](references/definition-of-done.md)). An
   agent's report is a hypothesis; the files, the exit codes and the running app are the proof.
   Browser first, not last: open the app at the start of the task (reproduce before reading
   code or briefing) and again here. Open the running app in a browser yourself (Claude in Chrome, else Playwright via Bash, else
   maestri-portal) and check the screen, the console and the network requests. Never ask the
   PO "did it work?" for something a browser can show you.
5. **Show the PO the result running, before merge**
   ([references/preview-before-merge.md](references/preview-before-merge.md)). The PO can't
   judge a diff in a worktree they never see; give them the URL or the screenshots.
6. **Ask approval** with `AskUserQuestion` ("commit and merge locally?"), naming the
   files. One approval covers one action.
7. **Integrate** by merging the branch (never by copying files into the main tree), put
   the preview back, ask to remove the merged worktree and branch, then report in 1–3 lines what shipped and what is still open.

## Standing rules

- **Approvals are per action and never inherited.** Commit, push, tag, deploy, prod
  commands, deletion (files, images, branches, worktrees) — ask each time, in the PO's
  language, through `AskUserQuestion`, never as a loose question in prose.
- **A blocked command becomes a question at once** (what it runs, why, the risk), not a
  line in the final report. The approval is for that action alone; do not rephrase the
  command to get around the block.
- **Stage by name** (`git add path/a path/b`) — never `-A`, `.`, `-u`, `commit -a`;
  several sessions may share the tree. Never `stash`, `reset --hard`, `clean`,
  `checkout .` without approval. A failed edit means the file moved: re-read, redo.
- **Docs move with the code**, in the same commit, when the project keeps a notes
  vault/changelog (and a hook can enforce it). If the commit hook runs before the Bash
  command, `git add` and `git commit` go in separate calls.
- **Report often and briefly.** Close each stage with a short paragraph; announce a long
  background task when it starts and when it ends. Silence reads as a hang.
- **Surface warnings, don't swallow them** — a warning you saw is told to the PO, with an
  offer to fix it.
- **Real data over generic advice** — "this field exists in 62% of postings", measured.
- **Local, untracked changes** (an `.env` edit, a container you started) are mentioned
  to the PO, with how to undo them.

## Keep the machine awake while agents work

A suspended PC freezes every subagent, build and test run mid-task (and kills the
network sessions they hold). While any agent or subagent is developing, the PC must not
suspend, hibernate or sit idle into a sleep.

- **Before launching the first agent** of a task, take a lease with the global
  `keep-awake` skill: `<skills-dir>/keep-awake/keep-awake.sh on <task-name> <hours>`
  (honest estimate with slack; one holder per task, several can overlap).
- **Renew** it with `on` again at each stage if the work runs past the estimate.
- **Release it** (`off <task-name>`) in the same turn the last agent finishes, fails or
  is stopped — also on failure. The last release restores the power settings; a watchdog
  does the same when a lease expires, so a dead session never leaves the PC awake forever.
- **Never edit the power settings by hand** while a lease is live.
- Tell the PO in one line when the lease starts and when it ends.
- The screen lock is not a problem for the processes (they keep running); only suspend
  is. If the PO also wants no lock while agents work, say so: `keep-awake` does not
  touch the screensaver lock today.

## Where the detail lives

- [references/delegation.md](references/delegation.md) — what to delegate, model by effort, the brief template, Maestri recruits
- [references/definition-of-done.md](references/definition-of-done.md) — what "ready for acceptance" means and the adversarial checklist
- [references/preview-before-merge.md](references/preview-before-merge.md) — putting a worktree in front of the PO
- [references/new-project.md](references/new-project.md) — the pieces to create in a new repo
