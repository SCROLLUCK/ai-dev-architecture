# Orchestration and subagents

## Roles

| Role | Who | Owns |
|---|---|---|
| **PO** | the human | product direction, money and price, production risk, every approval (commit, merge to a shared branch, push, tag, deploy, deletion) |
| **Lead** | the main session | splitting the work, briefs, branches, verification, integration, the questions to the PO. Decides the operational; asks only what is the PO's |
| **Agents** | subagents (Claude Code `Agent` tool) or recruits (full sessions in Maestri) | one closed task on one branch, on the cheapest model that can do it |

The lead is not the typist and not the bottleneck: small context on the lead, cheap models doing the typing.
A subagent starts cold, so for a two-line edit with the context already loaded the lead does it itself.

For a larger front the layout is orchestrator -> tech lead -> devs: the orchestrator (the editor
session) decides and integrates; a tech lead (a mid- or top-tier recruit or subagent) owns one front,
plans, hands slices to devs and reviews diffs; devs implement closed slices on their own branch and return short reports.

## What gets delegated

| Work | Worker | Notes |
|---|---|---|
| Reading, sweeps, investigation | `Explore` / general-purpose, cheap tier (mid if it needs reasoning) | independent ones run in parallel, one per agent, in one message |
| Implementation with a clear plan | general-purpose, mid tier, own branch + worktree | the lead verifies and merges |
| Design, unknown-cause bug, audit, prod, data migration, security | top tier (or the lead) | judgment work |
| Adversarial review | an agent that did **not** write the code, read-only | mid tier with a lean prompt (diff + touched files); top tier only for prod data migration or security |
| Long job (test suite, build, monitoring) | background | the lead keeps working |
| Mechanical work when Claude quota is tight | outside agent (Antigravity) | needs a complete brief; it cannot see the conversation |

The model is always set explicitly on the subagent; it never inherits the session's.

## What stays with the lead

- A surgical edit of a few lines with the context already loaded.
- Verification that needs the running environment (containers and dev servers mount the main tree, not the worktree): delegate the writing, verify in the lead.
- Commit, push, tag, deploy, production access and deletion. The approval is the PO's and happens in the lead session.
- Any decision that needs a conversation with the PO.

Agents are told in their brief not to commit, push, deploy or touch prod.

## The brief

Full template: [templates/subagent-brief.md](../templates/subagent-brief.md). The shape:

1. **Specialist persona** in one or two sentences. This is what makes the agent act like a specialist.
2. **Goal** in the PO's terms. With a spec-driven project the goal is "implement task N.M of the change's `tasks.md`".
3. **Branch and worktree path**: work and commit only there, never the trunk, no push.
4. **Files and notes to read first**, exact paths, plus the project rules that apply.
5. **Done criterion**: the commands that must pass.
6. **Out of scope**: no unrelated refactors, no new abstractions.
7. **Return**: conclusion plus `path:line`, what was verified and what was not. Not a dump.

Two rules go in every implementation brief: change existing files by editing only the hunk that changes
(never rewrite a whole file), and **if the spec, contract, design or code does not answer a question, stop and
report the gap instead of guessing**. The lead then asks the PO. Any assumption in a report becomes a question before it ships.

Agent-to-agent text is in English: briefs, returns, handoff files, review reports. Direct, with facts and
`path:line`, no greetings or restating the task.

## One agent per reported bug

Each bug report gets its own subagent. Bugs on the same branch share its worktree; bugs touching the same code run one after the other.

## Outside agents: spend other quotas first

Claude's quota is the scarcest, so execution goes to an outside agent first when it can do the job.
Claude subagents are the fallback when the outside quota is tight, the tool is unavailable, or the task needs the conversation's context.

- **Antigravity (`agy`, Gemini models, the Google quota).** Wrapped as a Claude Code subagent (`antigravity`): a
  thin cheap-tier dispatcher that writes the brief to a file, runs it through a wrapper script and reports back.
  Read tasks run as-is; write tasks run in a throwaway git worktree of HEAD and print the diff, which the lead reviews before
  bringing anything in. Its shell is limited to a read-only allow-list, so tests and builds do not run inside it. It
  never commits, pushes, deploys or deletes. Its report is not proof either.
- **Codex (ChatGPT quota).** Recruited as a full session through Maestri, always with explicit model and reasoning
  effort per task tier (never the expensive default), fast mode off for devs after four devs in fast mode burned half a 5-hour window in about 35 minutes.

What stays on Claude regardless: orchestration, judgment, and commit/push/deploy/prod/deletion.

## Recruits (Maestri)

For a long front with its own conversation (a whole feature, a batch of similar tasks) a recruit is a full session
with its own context that the lead can consult without inflating its own. Rules that came out of measured usage:

- Only the editor session orchestrates. A session already running inside Maestri does its task and returns; it does not recruit.
- Every recruit is born with a specialist role (not a vanilla session) and a persona name that matches the specialty
  (for example a frontend specialist, a security specialist, an adversarial reviewer). The role carries the team rules: stay isolated, test first, docs in the same change, no git, no deploy.
- At most 2 recruits working at once; the rest queue. A new recruit per front; delivered and integrated means dismissed.
- A pause means: the recruit writes a `STATUS.md`, the lead dismisses it, and a fresh recruit resumes from that file.
  An idle session loses its cache and re-reads everything at full price.
- Reads and test runs are auto-approved; git, docker beyond the test runner, network that sends data, deleting outside the floor, and anything on a server go to the human.

## Standing rules

- **Stage by name** (`git add path/a path/b`), never `-A`, `.`, `-u` or `commit -a`; several sessions may share a tree. No `stash`, `reset --hard`, `clean` or `checkout .` without approval.
- **A blocked command becomes a question at once**: what it runs, why, the risk, and options. The approval covers that one action; do not rephrase the command to get around the block.
- **Surface warnings**, do not swallow them.
- **Report briefly**, announce long background tasks when they start and end.
- **Keep the machine awake** while agents work (see the `keep-awake` skill); release the lease in the same turn the last agent ends.

## Hook-injected authorization

A `SessionStart` hook injects a short note into every session stating that the user explicitly authorizes
and expects use of the Agent tool for implementation, reading sweeps, reviews and long checks. This keeps delegation as the default
even in sessions where the model would otherwise be cautious about spawning agents. A `PreToolUse` hook on Bash rewrites commands through `rtk` (see [tooling](tooling.md)).
