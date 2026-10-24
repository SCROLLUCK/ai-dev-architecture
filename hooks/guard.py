#!/usr/bin/env python3
"""PreToolUse guard: turns the workflow's hard rules into checks the harness enforces.

- git add -A / . / -u / --all and git commit -a: denied (stage files by name)
- git push: asks the user (every push needs its own approval)
- Agent without an explicit model: denied (fork excepted, it always inherits)
- a new worktree past the cap: denied
"""
import json
import os
import shlex
import subprocess
import sys

WORKTREE_CAP = 5
SEPARATORS = {";", "&&", "||", "|", "&", "(", ")"}
GIT_OPTS_WITH_VALUE = {"-C", "-c", "--git-dir", "--work-tree", "--namespace"}
BROAD_PATHSPECS = {".", "./", ":/", ":.", "*", "-A", "--all", "-u", "--update"}


def decide(decision, reason):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": decision,
        "permissionDecisionReason": reason,
    }}))
    sys.exit(0)


def git_calls(command):
    """Yield (directory, subcommand, args) for each git call in a shell command."""
    lexer = shlex.shlex(command.replace("\n", " ; "), posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    try:
        tokens = list(lexer)
    except ValueError:
        return
    segment = []
    for token in tokens + [";"]:
        if token not in SEPARATORS:
            segment.append(token)
            continue
        names = [os.path.basename(t) for t in segment]
        if "git" in names:
            args = segment[names.index("git") + 1:]
            directory = None
            while args and args[0].startswith("-"):
                option = args.pop(0)
                if option in GIT_OPTS_WITH_VALUE and args:
                    value = args.pop(0)
                    if option == "-C":
                        directory = value
            if args:
                yield directory, args[0], args[1:]
        segment = []


def short_flags(args):
    return "".join(a[1:] for a in args if len(a) > 1 and a[0] == "-" and a[1] != "-")


def open_worktrees(cwd):
    out = subprocess.run(["git", "-C", cwd, "worktree", "list", "--porcelain"],
                         capture_output=True, text=True).stdout
    return max(out.count("worktree ") - 1, 0)


def check_worktree_cap(cwd):
    if cwd and open_worktrees(cwd) >= WORKTREE_CAP:
        decide("deny", f"Worktree cap reached ({WORKTREE_CAP} open). Merge or remove one first "
                       "(git worktree list).")


def check_bash(command, cwd):
    for directory, sub, args in git_calls(command):
        if sub == "add" and (BROAD_PATHSPECS & set(args) or set("Au") & set(short_flags(args))):
            decide("deny", "Stage files by name only: no git add -A / . / -u / --all.")
        if sub == "commit" and ("--all" in args or "a" in short_flags(args)):
            decide("deny", "No git commit -a: stage files by name, then commit.")
        if sub == "push" and not {"-n", "--dry-run"} & set(args):
            decide("ask", "git push needs the user's approval for this push.")
        if sub == "worktree" and args[:1] == ["add"]:
            check_worktree_cap(os.path.join(cwd or ".", directory) if directory else cwd)


def check_agent(tool_input, cwd):
    if tool_input.get("subagent_type") != "fork" and not tool_input.get("model"):
        decide("deny", "Pass an explicit model (haiku / sonnet / opus): subagents never "
                       "inherit the session model.")
    if tool_input.get("isolation") == "worktree":
        check_worktree_cap(cwd)


def main():
    payload = json.load(sys.stdin)
    tool, tool_input, cwd = payload.get("tool_name"), payload.get("tool_input", {}), payload.get("cwd")
    if tool == "Bash":
        check_bash(tool_input.get("command", ""), cwd)
    elif tool in ("Agent", "Task"):
        check_agent(tool_input, cwd)
    elif tool == "EnterWorktree":
        check_worktree_cap(cwd)


if __name__ == "__main__":
    main()
