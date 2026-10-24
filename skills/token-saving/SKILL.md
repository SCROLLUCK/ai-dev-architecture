---
name: token-saving
description: How to spend fewer tokens and less quota in every session — rtk for shell output, terse replies, subagents on the cheapest model and effort that can do the job, cheap agents for trivial writing (i18n files, changelog), outside agents (agy/Gemini, Codex), the orchestrator → tech lead → devs layout, context hygiene (/clear, /compact, MCP and skills overhead). Use before delegating work, before starting a medium or large task, when context or quota is high, when an answer is getting long, or when the user mentions tokens, cost or quota.
---

# Token saving

> Machine-specific paths, habits and notes: read `~/.claude/skills-local/token-saving.md` if it exists.
> It lives outside this repo and is never versioned; this file stays generic.

Every turn re-sends the whole context, so the cost is **context size × number of turns**.
Saving means: keep the context small, take noisy work out of it, and give each piece of work
to the cheapest worker that can do it well. Measure first (`~/.claude/quota.sh`,
`~/.claude/references/budget.md`); never guess a percentage.

## 1. Keep command output small — rtk

- A hook rewrites shell commands to `rtk <cmd>` (60–90% less output). Don't fight it.
- Debug with the raw output only when the filtered one hides the problem: `rtk proxy <cmd>`.
- Prefer quiet flags and narrow queries: `git log --oneline -n 10`, `grep -n`, `tail -n 30`,
  `--quiet`. A noisy command whose output I don't need to read goes to a subagent or to a
  file I then grep.
- `rtk gain` shows what was saved; `rtk discover` lists commands that missed the hook.

## 2. Don't be chatty

- Chat replies: result, decision needed, blocker. 1–3 lines for status. No recap, no status
  table, no explaining internal mechanism, no restating the question.
- Tool calls: no narration between calls when nothing changed. Parallelise independent calls
  (one message, several tools).
- Read only what is needed: `offset`/`limit` for big files, `@file` over exploring, don't
  re-read a file I just edited, don't re-derive facts already established.
- Edit, don't rewrite: `Edit` over `Write` for partial changes.
- One question to the user only when it blocks; use the options form, not prose.

## 3. Delegate to the cheapest worker that can do it

Model and effort are chosen **explicitly** on every subagent — never inherit the session's.

| Work | Model | Effort |
|---|---|---|
| Mechanical: sweeps, reading, rename, translation keys, changelog/note from a finished diff, metrics reads | Haiku 4.5 | low |
| Implementation with a clear plan: scoped feature, tests, fix with known cause, UI following an existing pattern | Sonnet 5.5 | medium |
| Judgment: design, unknown-cause bug, pre-deploy audit, prod, data migration, security | Opus 5.5 | high (only here) |

- `effort` is set only when the task or the user calls for it; default is the agent's own.
- Adversarial review in Sonnet with a lean prompt (diff + touched files), not "read the folder".
- A subagent starts cold: the brief must be complete and short (persona line, goal, exact
  files and notes, done-criteria, return = conclusion + `path:line`). A vague brief costs a
  second round-trip, which is more than doing it myself.
- **Every implementation brief says, in these words:** "Change existing files with `Edit`,
  only the hunk that changes — never `Write` a whole existing file." And the mechanical part
  (i18n keys, changelog bullet, note edits) is split off to a Haiku subagent, not left in the
  Sonnet/Opus brief.
- Don't strip indentation to "save tokens": whitespace runs are cheap tokens, and a later
  formatter makes the file differ from what was written, so the next `Edit` needs a re-read.
- Stay in the main session for: a few-line surgical edit with context already loaded, checks
  that need the running environment, commit/push/deploy/deletion, decisions needing the user.
- A subagent report is not proof — check the files before it becomes a fix, commit or deploy.

### Trivial writing goes to the basics

Translation files (locale-file keys), changelog bullets, doc-note edits from a
finished diff, fixtures, renames, boilerplate: a **Haiku** subagent (or `agy`) with the exact
keys and wording given. Opus/Sonnet in the main session should not spend context typing them.
Conferring the result is a `git diff`, not a re-read.

## 4. Outside agents spend someone else's quota — use them first

Claude is the orchestrator; its quota is the scarcest. **Execution goes to an outside agent
first** (agy/Gemini, Codex) whenever it can do the job; a Claude subagent (Haiku/Sonnet) is the
fallback when the outside quota is tight, the tool is unavailable, or the task needs this
conversation's context. What stays on Claude regardless: orchestration, judgment (design,
unknown cause, audit, security, data migration), and commit/push/deploy/prod/deletion.

- **`antigravity` subagent (`agy`, Gemini)** — Google quota, not Claude's. Default worker for
  mechanical or well-specified work, and for a read-only second opinion. Full brief
  (it can't see this conversation); check the diff it prints before bringing it in. Details:
  `~/.claude/references/subagents.md`.
- **Codex (ChatGPT quota)** — recruited through Maestri, only from the VSCode session, never
  from inside Maestri. Read `~/.claude/references/maestri.md` before any `maestri` command.
- Quotas are separate: check `~/.claude/quota.sh` (reads Claude, Codex and agy) and spend the outside
  quotas down before Claude's; when one is tight and another has room, move the work before
  cutting scope.

## 5. Orchestrator → tech lead → devs

- **Orchestrator (the VSCode session)** decides, splits, checks and integrates; it keeps a
  small context and does not type bulk code.
- **Tech lead** (an Opus/Sonnet recruit or subagent) owns one front: reads the notes, plans,
  hands slices to devs, reviews their diffs.
- **Devs** (Sonnet/Haiku, or agy/Codex) implement closed slices, each on its own
  branch/worktree, and return short reports.
- Rules that keep it cheap: at most 2 recruits working at once; a new recruit per front;
  delivered and integrated → dismiss; a pause means STATUS.md + dismiss, never an idle
  session (an idle one loses its cache and re-reads everything at full price).
- Full flow (roles, branch+worktree per task, brief, definition of done): skill
  `agent-dev-workflow`.

### Agent-to-agent language: English, direct

All writing and conversation between agents is **in English**: briefs, subagent returns,
Maestri messages, STATUS.md handoffs, review reports. Direct and clear — facts, decisions,
`path:line`, next step. No flourish, no prose, no greetings, no restating the task. (Chat
with the user stays in the user's own language.)

## 6. Context hygiene

- New unrelated subject → `/clear` (rename first so `/resume` finds it). Same task, context
  near ~150k → save the handoff to memory, then suggest `/compact <focus>`. Closing a big
  stage → compact early. These commands are the user's; I only say which and with what focus.
- **Spot sessions over 150k.** Read the statusline snapshot, never the `.jsonl` size (not a
  proxy): `~/.claude/state/usage/<session_id>.json` (or `latest.json`), field
  `context.used_percentage` × `context.context_window_size`. Check own session, recruits and
  subagent sessions before a long task and at each stage close. Snapshot missing or older
  than 30 min (the VSCode extension has no statusline) → say "no data", don't guess.
  Over 150k: handoff to memory, then tell the user `/compact <focus>` (same task) or
  `/clear` (new subject); a recruit gets STATUS.md and is dismissed, then re-recruited fresh.
- Pick model and effort **at the start** — changing either mid-session can bust the prompt
  cache. Cheap work moves to subagents instead of switching the main model.
- Standing overhead is re-sent every turn: CLAUDE.md, MCP tool definitions, skill
  descriptions. Keep CLAUDE.md short and put detail in on-demand references; prune MCP
  servers the session doesn't need (`/mcp`); keep skill descriptions tight. `/context` in a
  fresh session shows what is preloaded.
- Keep long outputs out of the context: logs and test runs to a file, then `grep`/`tail`.
- Plan before implementing on non-trivial work — rework costs more than the plan.
- Don't trim what later steps depend on (complex debugging, decisions that constrain what
  follows): drop context that doesn't affect the next step, not context that does.

## 7. Quota gates (details in budget.md)

Measure with `~/.claude/quota.sh` before a medium/large task and at the end of each stage.
Keep ~5 points in reserve on the window that closes first. 5h ≥ 90% → only what finishes in
minutes; weekly ≥ 85% → small tasks only; weekly ≥ 70% → drop one model tier where quality
allows. A task that won't fit doesn't start: say what's left, when it resets, and the options
(smaller cut, wait, cheaper model, other provider).

## Sources for the external tips

[Anthropic: maximizing the value of your Claude Code sessions](https://claude.com/blog/maximizing-the-value-of-your-claude-code-sessions) (official: `/clear` between tasks, `@file`, quiet commands, model/effort set up front, `/context`); third-party guides, figures unverified: [Composio](https://composio.dev/blog/ways-to-cut-token-consumption-in-claude-code), [KDnuggets](https://kdnuggets.com/7-practical-ways-to-reduce-claude-code-token-usage), [wmedia](https://wmedia.es/en/tips/claude-code-save-tokens-10-habits) (MCP overhead, short CLAUDE.md, `# Compact instructions`, tightly scoped subagent prompts with output caps).
