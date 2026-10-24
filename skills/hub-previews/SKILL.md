---
name: hub-previews
description: Use the local Project Hub (http://project-hub.local:4380) from any project — start/list/stop live previews of a project or worktree and hand the user a clickable URL, register a project (roots, devCommand) and put a deployed project in the hub's Showcase home grid. Use when work on a branch/worktree is ready for the user to see running, when the user asks for a preview, before asking to merge UI work, when a project is missing from the hub, or when a project gets a local deploy.
---

# Hub previews

The Project Hub (`<path-to>/project-hub`) runs in a Docker container
(`project-hub`, API and UI on the same port **4380**). It runs every project's dev server on a
free port and lists all running servers at **http://project-hub.local:4380/previews** (tiles, one
click opens the app). Agents use its API instead of starting dev servers by hand, so the user
always finds previews in one place.

## 1. Is the hub up?

```bash
curl -sf http://127.0.0.1:4380/api/projects >/dev/null && echo up || echo down
```

Down → `<path-to>/project-hub/deploy/up.sh` (builds and starts the container,
`restart: unless-stopped`). Logs: `docker logs project-hub`. Never stop or rebuild the hub while
another session has previews running (they die with it). `npm run dev` (4310/4311) is only for
developing the hub itself.

## 2. Find the project id and worktree path

```bash
curl -s http://127.0.0.1:4380/api/projects | jq -r '.[] | "\(.id)\t\(.path)"'
curl -s http://127.0.0.1:4380/api/projects/<id>/worktrees | jq -r '.[] | "\(.branch)\t\(.path)"'
```

Project id = folder name. The worktree path must be one the hub lists (a worktree created
with `git worktree add` shows up on its own).

**Project missing?** The hub lists every directory under a configured root (up to
`scanDepth`, default 2) that has a `.git` **directory**. If the repo lives outside the roots,
add its parent as a root (section "Config" below) or ask the user to add it in Settings.

## 3. Start the preview

```bash
curl -s -X POST http://127.0.0.1:4380/api/previews \
  -H 'content-type: application/json' \
  -d '{"projectId":"<id>","worktreePath":"<abs worktree path>"}'
```

Returns `{ id, port, url, status }`. Status goes `installing` (npm install, only in a main
checkout with no devCommand and no node_modules) → `starting` → `running` | `failed`. In a
worktree the Hub never installs: set the project's devCommand to run through
`<path-to>/wt-run.sh . <cmd>` (main checkout's node_modules mounted in a container).
devCommand placeholders: `{port}`, `{worktree}`, `{cwd}`, `{main}`. Poll until running:

```bash
curl -s http://127.0.0.1:4380/api/previews | jq '.[] | select(.id=="<preview id>") | {status,url}'
```

Logs (SSE): `curl -sN http://127.0.0.1:4380/api/previews/<preview id>/logs`.

**422 `no_dev_command`** → the hub found no `dev` script in `.`, `frontend/`, `web/` or
`client/`. Set `devCommand` (and `devCwd` if not the repo root) for the project (section
"Config" below; there is no UI field for it):

```json
"projects": { "<id>": { "devCommand": "npm run dev -- --port {port} --host 127.0.0.1", "devCwd": "frontend" } }
```

`{port}` is replaced by the free port; `PORT` is also set in the env. The command runs inside
the hub container (Ubuntu 24.04, Node 24, python3, git, docker CLI, host network, `$HOME` at the
same path): a toolchain not in the image needs a `devCommand` that goes through `docker compose`.

## 4. Hand it to the user

Give both links:
- the app: the `url` from the preview;
- the hub page with diff + preview: `http://project-hub.local:4380/p/<id>/worktrees/<urlencoded worktree path>`
  (or just `http://project-hub.local:4380/previews`).

## Drive the preview in a browser (Playwright over CDP)

Use one headed Chrome per project, with a persistent profile (logins survive across previews
and worktrees) and CDP on 127.0.0.1 only. Reuse the open browser for the whole task: attach,
navigate, check, keep it open — don't launch a fresh browser per check. The user can watch the
same window. Never use the user's daily Chrome profile.

Preferred: ask the Hub (it opens the preview in the project's Chrome, new tab if already open;
can take ~20 s cold). Needs a running preview id from `GET /api/previews`:

```bash
CDP=$(curl -s -X POST http://127.0.0.1:4380/api/previews/<id>/browser | jq -r .cdpUrl)
```

Then `chromium.connectOverCDP($CDP)`. If the API returns 503 `browser_helper_unavailable`, use the
manual launch below.

Fallback (manual launch):

```bash
P=~/.local/state/project-hub/browser-profiles/<project id>; mkdir -p "$P"
# reuse if alive: Chrome writes its CDP port to $P/DevToolsActivePort
CDP_PORT=$(head -1 "$P/DevToolsActivePort" 2>/dev/null)
if ! curl -sf "http://127.0.0.1:$CDP_PORT/json/version" >/dev/null 2>&1; then
  rm -f "$P/DevToolsActivePort"
  google-chrome --user-data-dir="$P" --remote-debugging-port=0 --remote-debugging-address=127.0.0.1 \
    --no-first-run --new-window "<preview url>" >/dev/null 2>&1 &
  until [ -s "$P/DevToolsActivePort" ]; do sleep 0.5; done
  CDP_PORT=$(head -1 "$P/DevToolsActivePort")
fi
echo "http://127.0.0.1:$CDP_PORT"
```

Attach with `chromium.connectOverCDP("http://127.0.0.1:<port>")` and use
`browser.contexts()[0].pages()` (the window the user sees); open your own page with
`context.newPage()` for inspection-only work. Disconnect with `browser.close()` on a CDP
connection only detaches — the window stays. Two previews of the same project share this
browser (one profile can't run twice): open the second preview as a new tab.
This is phase 0 of `docs/proposal-playwright-previews.md` in the project-hub repo.

## 5. Stop it

```bash
curl -s -X DELETE http://127.0.0.1:4380/api/previews/<preview id>
```

Stop your preview when the branch is merged or abandoned. Previews die when the hub server
stops; they are not persisted.

## Running servers the hub did not start

`GET /api/running` lists hub previews **and** docker compose stacks (and dev servers) already
listening inside a known project. Check it before starting a second server for the same
worktree. Dev servers started outside docker may be missing from it (the container cannot see
their process owner).

## Showcase (deployed projects)

The hub home page (http://project-hub.local:4380/) is a grid of live tiles for projects that
have a local deploy and answer (HTTP status < 500, checked every 30 s). When a project gets a
stable local deploy (e.g. `docker compose up` behind `http://<project>.local:<port>`), register
it: set `projects["<id>"].showcaseUrl` (section "Config"), or the user adds it in
Settings → Showcase. Check with `curl -s http://127.0.0.1:4380/api/showcase`. A `.local` name
needs its line in `/etc/hosts` (convention: `127.0.0.1 <project>.local`; needs sudo, so the
user runs it). Remove the entry when the deploy goes away.

## Config

`~/.config/project-hub/config.json` (read on every request, no restart):
`roots`, `scanDepth`, `pinned`, `hidden`, `projects` — per id:
`devCommand`, `devCwd`, `showcaseUrl`. Change it through the API; `PUT /api/settings` replaces
each key you send whole (`projects`, `roots`), so read, merge, write:

```bash
H=http://127.0.0.1:4380/api/settings
curl -s $H | jq '{projects: (.projects + {"<id>": ((.projects["<id>"] // {}) + {"showcaseUrl": "http://<id>.local:8080"})})}' \
  | curl -s -X PUT $H -H 'content-type: application/json' -d @- >/dev/null
# add a root: jq '{roots: (.roots + ["~/code/clients"] | unique)}'
```

Other things the hub reads from a project, no
setup needed: `docs/backlog.md` (global backlog convention), an Obsidian vault (`.obsidian` in
the root or `docs/`), CI runs, and
Claude Code sessions.
