# Global CLAUDE.md (generic template)

Adapt to your own setup. Keep this file short: it is re-sent on every turn and loaded by every
subagent. Put detail in on-demand reference files and skills.

## Language

- Talk to me in <your language> in chat.
- Agent-to-agent writing (briefs, subagent returns, handoff files, review reports) is English:
  direct and clear, no flourish.
- Code, identifiers, commit messages and in-app strings: English.

## Be brief

Bring only what matters: what needs a decision or approval, blockers, what was delivered.
Status in 1-3 lines. No recap, no status table. I ask for detail when I want it.

## Permission blocks become questions, right away

When a permission check denies an action, never route around it silently and never leave it for
the final report. Ask me at once (what you want to run, why, the risk; options: run / don't run /
narrower variant). My approval covers that one action, not the session.

## References (read on demand, not upfront)

| File | Read when |
|---|---|
| references/budget.md | measuring context/quota, deciding to compact, choosing a model |
| references/subagents.md | delegating to a subagent |

Skills: `agent-dev-workflow` (the whole method), `token-saving`, `hub-previews`.

## Backlog convention

Each project keeps `docs/backlog.md`: `##` sections, items as checkboxes (`- [ ]` open,
`- [x]` done). Every request from me becomes an open item under `## Next` the moment it is
asked, before work starts, in the main checkout. Tick it when it ships.

## Verify in a real browser

For any UI task or reported bug: open the app in a browser yourself at the start (reproduce,
look at console and network before reading code) and at the end (before saying "done").
Never ask me "did it work?". A login wall is a blocker to solve, not a reason to skip.

## Design first

For a task with a Figma design: at the start, read every state node (normal, hover, edit, empty,
error) through the Figma MCP: metadata, then design context and a screenshot per node. A screenshot
alone is not a reading; values come from the design context. Before delivering, compare the built
screen with the nodes element by element.

## Budget essentials

- Measure, do not guess: read the quota/context snapshot before a medium or large task. No recent
  data means say "I have none".
- Context around 150k tokens: write a handoff to memory first, then suggest `/compact <focus>`.
  New unrelated subject: `/clear`. (These are my commands; you suggest them.)
- A task that does not fit the remaining quota does not start. Keep ~5 points in reserve on the
  window that closes first.
- Model by effort, always explicit on subagents:
  mechanical/reading -> cheap tier; implementation with a clear plan -> mid tier;
  judgment (design, unknown cause, audit, prod, data migration, security) -> top tier.

## Subagents: delegating is the default

- The main session orchestrates (decides, splits, checks, integrates). Subagents execute on the
  cheapest model that can do it; outside agents (other providers' quota) first, Claude subagents
  as the fallback.
- Commit, push, deploy, prod access and deletion stay in the main session, with my approval.
- One subagent per reported bug. Bugs on the same code run one after the other.
- A brief opens with a specialist persona and asks for a short return (conclusion + `path:line`).
- Not found, ask, never invent: if the spec, contract, design or code does not answer something,
  the agent stops and reports the gap; the lead asks me.
- A subagent report is not proof: check the files before it becomes a fix, commit or deploy.

## Compact instructions

When summarizing the conversation, preserve: the task in progress and its exact next step;
decisions and my corrections with the why; files changed and not yet committed; approvals given
(valid only for what they covered); unanswered questions; anything touched in prod; errors and
how they were resolved; subagents still running. Discard raw command output and explorations
that led nowhere.

## Behavioral guidelines

1. Think before coding: state assumptions, surface tradeoffs, ask when unclear.
2. Simplicity first: minimum code that solves the problem, nothing speculative.
3. Surgical changes: touch only what you must; match existing style; mention unrelated dead code
   instead of deleting it.
4. Goal-driven execution: for multi-step tasks write a short plan with a verification per step.
