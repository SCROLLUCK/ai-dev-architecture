# Show the result before the merge

The PO approves what they have seen. Work in a worktree is invisible to them, so before
asking "commit and merge?", put it in front of them — and say how to look at it.

## Options, cheapest first

1. **Project Hub preview** (preferred for UI): one call starts the worktree's dev server on a
   free port and returns a URL; the hub page shows the diff next to it. See the
   `hub-previews` skill. Nothing shared is stopped, so nothing has to be restored.
2. **Screenshots** from a headless browser against the worktree build (always possible).
3. **Swap the dev server** (fallback when the app only works on its usual origin): stop the shared dev frontend and start a
   container on the *same port* mounting the worktree, so origin/CORS and the backend
   keep working. Announce it first — other sessions lose that screen meanwhile — and ask
   (the permission check may block it; that block becomes an `AskUserQuestion`).
   ```bash
   docker stop <main-frontend>
   docker run -d --name preview --rm -p <same-port>:<inner-port> \
     -e VITE_API_URL=<same-as-main> \
     -v <worktree>/frontend:/app -v <node_modules volume of the main container>:/app/node_modules \
     -w /app <frontend-image> npm run dev -- --host
   ```
   Find the node_modules volume with `docker inspect <main-frontend>`. Wait for HTTP 200.
4. **Another port** only if the backend's CORS/allowed-hosts can take it without a restart
   (a backend restart kills in-flight work).
5. **Backend-only changes**: show the test run plus a request/response against a throwaway
   instance, or the diff of the behaviour with real data.

## Protocol

- Tell the PO the URL, the page, and what to look at. Keep the preview up while they iterate;
  each change they ask for is made in the worktree and is visible on reload.
- After the verdict: commit on the branch, merge, stop the hub preview. If the dev server
  was swapped, **restore** it (`docker stop preview && docker start <main-frontend>`),
  confirm HTTP 200, and say so — also when they refuse.
- Tools against a worktree (tsc, eslint, vitest) run in a throwaway container mounting
  the worktree (see the project's helper); the project's own lint script usually checks
  only the main tree.
