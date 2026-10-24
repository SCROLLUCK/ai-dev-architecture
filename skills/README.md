# Skills

Sanitized copies of my own Claude Code skills, published as reusable templates.

| Skill | What it does |
|---|---|
| [agent-dev-workflow](agent-dev-workflow/SKILL.md) | The whole method: PO / lead / agents, branch + worktree per task, brief, definition of done, preview before merge |
| [hub-previews](hub-previews/SKILL.md) | How agents use the Project Hub API to start live previews and drive them in a browser |
| [token-saving](token-saving/SKILL.md) | Spend fewer tokens: rtk, terse replies, cheapest capable worker, context hygiene |
| [keep-awake](keep-awake/SKILL.md) | Keep a Linux laptop from suspending while agents work (lease + watchdog) |

Notes for reuse:

- Install by copying a folder to `~/.claude/skills/` (user level) or `<repo>/.claude/skills/` (project level).
- Keep the skill files generic and put what is yours (paths, ports, project names, habits,
  incident notes) in `~/.claude/skills-local/<skill>.md`, outside any repo; every skill reads it
  when it exists. You can update the skills from this repo without touching it, and it can never
  be pushed by mistake.
  How you install them (copy, symlink, a sync script) is up to you.
- Some skills mention helper scripts that are personal and **not included** here: a quota reader
  (`quota.sh`), a status-line snapshot writer, a worktree command runner (`wt-run.sh`) and the
  Antigravity wrapper (`agy-run.sh`). The docs describe what each one does so you can write your own.
- Third-party skills I also use (Maestri skills, `ui-ux-pro-max`, Pinokio) are not copied; see [docs/tooling.md](../docs/tooling.md).
