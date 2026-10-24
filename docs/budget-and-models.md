# Budget and models

Quota and context are the scarce resources of agent-heavy work. The rule is to **measure, not guess**,
and to put every task on the cheapest model and effort that can do it.

## Measuring

- **Quota:** a statusline snapshot (the harness hands the statusline script current plan usage as JSON) is written
  to a file; a small script reads it and prints every quota: the Claude 5-hour and weekly windows, Codex, and Antigravity.
  Run it before accepting a medium or large task and when closing stages. With no recent data, say "I have none"; do not estimate.
  (These helper scripts are personal and not included; see [skills/README.md](../skills/README.md).)
- **Context:** the real number is the session's token count, not the transcript file size. Auto-compact is set to a 150k window.

## Context gate (about 150k)

- Past ~150k: write a **handoff to memory first** (task, decisions, files changed, approvals, pending questions), then suggest `/compact <focus>`. The human runs it; the lead does not.
- A new subject: `/clear`.
- A compaction summary keeps: the task and exact next step, decisions and corrections with the why, uncommitted files (and which are not from this session), approvals given and for what, unanswered questions, what was touched in prod, errors and fixes, subagents still running. It drops raw output and anything re-readable.

## Quota gates

- Keep about 5 points in reserve on the window that closes first.
- 5h window at 90% or more: only what finishes in minutes.
- Weekly at 85% or more: small tasks only. Weekly at 70% or more: drop one model tier.
- A task that does not fit does not start; say so and propose the smaller version.

## Models by effort

| Work | Model tier |
|---|---|
| Mechanical, reading sweeps, formatting, i18n, changelog | Smallest (Haiku-class) |
| Implementation with a clear plan, tests, routine review | Mid (Sonnet-class) |
| Judgment: design, unknown cause, audit, prod, data migration, security | Largest (Opus-class) |
| Top experimental tier | Only on request |

Rules: every subagent gets an **explicit** model, never "inherit" (the session model is usually the biggest).
If the session itself runs above what the task needs, warn once and suggest switching.
Adversarial review runs on the mid tier with a lean prompt; a bigger model reading a long prompt costs more than the bug it finds.
Outside agents (Antigravity/Gemini, Codex) take work first when their quota has room, to spend it before the Claude quota.

## Lessons from a usage report

A usage report on one heavy week found that most usage (about 80%) came from sessions that ran many subagents, because
each subagent carries its own context and repeats reads. Consequences:

- Brief agents with exact files and a narrow goal so they do not rediscover the repo.
- Cap parallel agents (recruits: at most 2 working at once).
- Ask for short returns (conclusion plus `path:line`), not file dumps.
- Do not re-delegate what the lead can do in two tool calls.

## Saving tokens in daily use

Detail is in [skills/token-saving](../skills/token-saving/SKILL.md). In short: a CLI proxy (rtk) that filters shell output;
terse replies; read only the part of a file needed; cheap agents for trivial writing; outside agents first;
the layout orchestrator, then tech lead, then devs, so context stays small at the top; `/clear` between subjects;
trim MCP servers and skills that load into every session.
