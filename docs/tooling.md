# Tooling

| Tool | Role | Link |
|---|---|---|
| Claude Code | The CLI agent that runs the lead and its subagents; hooks, skills, memory | https://docs.claude.com/en/docs/claude-code |
| OpenSpec | Spec-driven change folders (proposal, deltas, design, tasks) | https://github.com/Fission-AI/OpenSpec |
| Superpowers | Plugin of process skills (brainstorming, TDD, debugging, review, plans) | https://github.com/obra/superpowers |
| Antigravity (`agy`) | Outside agent on a Google quota, used for mechanical work and read-only second opinions | https://antigravity.google |
| Codex | Outside agent on an OpenAI quota | https://github.com/openai/codex |
| Maestri | Canvas of agent terminals; recruits with personas and roles | https://www.maestri.app |
| rtk | CLI proxy that filters shell output to save tokens | https://github.com/rtk-ai/rtk |
| Pinokio | 1-click launchers (optional) | https://pinokio.computer |
| ui-ux-pro-max | Third-party UI/UX design skill, via https://www.skills.sh/ | https://www.skills.sh/ |
| Project Hub | Personal dashboard (below) | [project-hub-public](https://github.com/SCROLLUCK/project-hub-public) |

## Hooks used

- **PreToolUse (Bash):** rewrites shell commands through `rtk`, transparently.
- **SessionStart:** injects the note that authorizes subagents for implementation, sweeps, reviews and long checks.
- **Commit hook (per project):** refuses code on a `feat/<name>` branch until the OpenSpec proposal is approved, and refuses a commit whose code moved without its docs.
- **Statusline:** writes a usage snapshot that the quota script reads.

## Project Hub

A small personal web app, run as a Docker container, that surfaces status for all projects. It does not maintain projects; each project fixes itself.

- **Previews:** an API starts a project's or worktree's dev server and returns a URL; the hub shows the diff next to the running preview.
- **Browser helper:** opens a preview in one persistent headed Chrome per project over CDP so agents and the human share the same window.
- **Showcase:** a home grid of projects with a stable local deploy.
- **Backlog:** reads and edits each project's `docs/backlog.md`.
- **Docs viewer:** renders project notes.
- **Quota widget:** Claude, Codex and Antigravity usage.
- **Development tab:** sessions and subagents.
- **Pipelines** status.

The skill [hub-previews](../skills/hub-previews/SKILL.md) is how agents use it.

## Other pieces

- [keep-awake](../skills/keep-awake/SKILL.md): holds off suspend during long unattended work and restores settings after.
- Memory: short notes kept by the agent about the PO and the project, loaded each session.
