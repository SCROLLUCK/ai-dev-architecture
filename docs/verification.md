# Verification: browser first, Figma first

The PO should never be the one who finds the defect. "Ready for acceptance" is the lead's claim,
made only after the checks below, performed by the lead and not by the developer agent.

## Definition of done

1. **Scope sweep independent of the brief.** Grep the whole repo for the concept (brand, field, rule, string) across every surface: web desktop and mobile, emails, PDFs, share cards, admin, agents, notes. The brief is a hypothesis; the sweep is the proof. (A logo swap was once "done" while an email template still drew the old logo.)
2. **A test that fails before and passes after**, and the area's suite green. Judge by exit code, not by grepping output.
3. **Lint, type-check and the docs check clean.**
4. **UI: screenshots** at desktop and mobile widths, light and dark, opened by the lead, plus the console and the network requests checked in a browser the lead drives.
5. **Adversarial review** by an agent that did not write the code, read-only: what is half-done, which edge case breaks, what does the deploy need.
6. **Every scenario of the spec change's deltas checked with evidence**, and `openspec validate <name> --strict` passes, when the project uses OpenSpec.
7. **Say what was verified and what was not.**

An agent's or recruit's report never becomes a fix, a commit or a deploy by itself. Anything that looks too clean gets one independent check.

## Adversarial checklist (before proposing a deploy)

Measure, do not reason:

- What controls each cache key, queue name or file path? Can an anonymous visitor inflate it?
- What invalidates each cached entry, and does it depend on a table other than the one that triggers invalidation?
- How does it behave **during writes** (a search, a harvest, a refresh storm), not only at rest?
- Anonymous vs logged-in boundary: plant a sentinel and prove it does not leak either way.
- Does it fit the host (RAM, CPU)?
- Does a new dependency create a silent coupling (a rate limit on the same cache that can fall)?
- Does the deploy need a manual step the automatic one does not do (a new service, a new env var)?
- A local-only change (env var, container): does production need the same?

## Browser first

For any task that touches UI or a reported bug, the lead opens the app in a browser itself.

- **At the start:** reproduce the bug or see the current screen, console and network **before** reading code or briefing an agent.
- **At the end:** before saying "done", handing over a preview or asking to merge, open the screen and check it, the console, and the network requests (status, payload, empty responses).
- Tool order: a Chrome extension MCP, else Playwright, else a browser pane on the agent canvas.
- UI work without a browser check is not done. A login wall is a blocker to solve (a logged-in profile, CDP), not a reason to skip.
- The lead never asks the PO "did it work?" for something a browser can show.

In practice the browser is one headed Chrome per project with a persistent, dedicated profile and a local-only debugging port;
agents attach with Playwright over CDP and keep the same window for the whole task, so the human can watch what the agent does.
The Project Hub opens a preview in that browser through an API call. Never the human's daily profile.

## Figma first

For any UI task with a Figma design, **at the start**, before writing code or briefing an agent:

1. Load the Figma design-to-code skill.
2. `get_metadata` to find every state node.
3. `get_design_context` and `get_screenshot` per node: normal, hover, edit, empty, error.

A screenshot alone is not a reading: values (texts, colors, spacing, sizes) come from the design context.
Before delivering, compare the built screen with those nodes element by element. Briefs tell agents to do the same.

## Skill-first for connectors

Before the first call to any connector or MCP tool, load its skill. When a connector covers the job,
use it the way its skill says, every time, instead of a workaround (a screenshot instead of the Figma MCP,
curl instead of the browser, asking the human to look).
