# Workflow: branch and worktree per task

Nothing is developed on the trunk. Every task gets its own branch and its own git worktree, so
agents work in parallel without touching each other, the trunk or the human's checkout.

## The loop

1. **Understand.** Read the project's notes for the area (not the whole folder). Surface assumptions
   and alternatives; ask the PO only if the answer changes what you build. If the project uses OpenSpec, a feature
   or rule change starts as a spec change that the PO approves (see [spec-driven-development](spec-driven-development.md)).
2. **Branch + worktree:** `git worktree add -b feat/<name> .claude/worktrees/<name> <base>`.
   The base is the branch that already holds the work this one builds on (local trunk when earlier tasks are merged
   locally and not pushed; basing on the remote trunk would silently drop them).
3. **Delegate or do it:** persona brief, explicit model, the branch and worktree path, a done criterion, a short return.
4. **Verify** (see [verification](verification.md)). An agent's report is a hypothesis; files, exit codes and the running app are the proof.
5. **Show the PO the result running, before merge.**
6. **Ask approval** with a structured question ("commit and merge locally?") that names the files. One approval covers one action.
7. **Integrate** by merging the branch (never by copying files into the main tree), restore the preview, ask to remove the merged worktree and branch, and report in 1-3 lines what shipped and what is open.

## Worktree rules

- **At most 5 open worktrees per repo.** Run `git worktree list` before adding one; at the cap, remove a merged one first (with approval) or wait. Dozens of forgotten worktrees crash the editor.
- **No `node_modules` or venv symlinks inside a worktree.** The editor follows the links; six worktrees pointing at one `node_modules` put about a million files in the workspace and the extension host hangs. Run tools through a throwaway container that mounts the worktree over the main checkout's dependencies.
- **Hide worktrees from the editor:** `.claude/worktrees/` in `.gitignore` and excluded in the editor's watcher, files and search settings.
- **A worktree has no running stack.** Give the agent the command that runs tools against its worktree, or tell it which checks the lead will run.
- **Do not remove a worktree** while its agent may still run, or while the branch is unmerged or dirty.
- Remove each worktree and branch right after its merge, in the same step as the integration.

## Standing rules around git

- Approvals are per action: commit, push, tag, deploy, prod commands, deletion.
- Stage by name; never `-A`/`.`/`-u`/`commit -a`; no `stash`, `reset --hard`, `clean`, `checkout .` without approval.
- Docs move with the code in the same commit when the project keeps notes or a changelog; a commit hook can enforce it.
- Local, untracked changes (an `.env` edit, a container started for testing) are mentioned to the PO with how to undo them.

## Preview before merge

The PO approves what they have seen, and work in a worktree is invisible to them. Options, cheapest first:

1. Screenshots from a headless browser against the worktree build.
2. A live preview of the worktree. Today this is done through the [Project Hub](tooling.md#project-hub): one API call starts the worktree's dev server on a free port and returns a URL; the hub page shows the diff next to the running preview.
   (Earlier, the same was done by swapping the shared dev server for a container on the same port mounting the worktree, announced first, and restored after the verdict.)
3. For backend-only changes: the test run plus a request/response against a throwaway instance, or a behavior diff on real data.

Protocol: tell the PO the URL, the page and what to look at; keep it up while they iterate; after the verdict, commit, merge, restore the original setup and confirm it is healthy. If they refuse, restore too.

## New repo checklist

A project CLAUDE.md section (one branch per task, approvals, stage by name, the project's hard invariants);
`.claude/worktrees/` ignored and hidden from the editor; a project git skill (branch naming, commit voice, the approval question);
docs that move with the code (index, changelog, decision log, optionally a hook that refuses a commit whose code moved without its notes);
one lint/test entry point plus a helper that runs it against a worktree; a legal/compliance screen if the product handles personal data or payments; a deploy skill if there is prod; memory for who the PO is.
See [skills/agent-dev-workflow/references/new-project.md](../skills/agent-dev-workflow/references/new-project.md).
