# Guard hooks

Prose rules are advisory; a model under pressure skips them. `guard.py` is a Claude Code
`PreToolUse` hook that enforces the few rules whose violation is costly or hard to undo:

| Tool call | Decision |
|---|---|
| `git add -A` / `.` / `-u` / `--all` / `:/` | deny: stage files by name |
| `git commit -a` / `-am` / `--all` | deny |
| `git push` (except `--dry-run`) | ask: the user approves each push in the permission prompt |
| `Agent` without `model` (fork excepted) | deny: subagents never inherit the session model |
| `git worktree add`, `EnterWorktree`, `Agent` with `isolation: worktree` at 5 open worktrees | deny |

It parses each git call in a shell command (chains, `-C`, `rtk git …`), ignores git inside
quoted strings, and fails open on a command it cannot parse.

## Install

Merge [settings-snippet.json](settings-snippet.json) into `~/.claude/settings.json` (keep
your existing hooks), replacing `<repo>` with this checkout's path. Then open `/hooks` once
or restart the session.

## Test

```sh
echo '{"tool_name":"Bash","cwd":".","tool_input":{"command":"git add -A"}}' | python3 hooks/guard.py
# {"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", ...}}
```

The worktree cap lives in `WORKTREE_CAP`.
