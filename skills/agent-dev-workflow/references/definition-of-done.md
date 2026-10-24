# Definition of done — nothing half-finished reaches the PO

The PO should never be the one who finds the defect. "Ready for acceptance" is the lead's
claim, made only after all of this, verified by the lead and not by the developer agent.

1. **Scope sweep independent of the brief.** Grep the whole repo for the concept (brand,
   field, rule, string) across every surface — web desktop and mobile, emails, PDFs,
   share cards, admin, agents, notes. The brief is a hypothesis; the sweep is the proof.
   (A logo swap was once "done" while the email template still drew the old one.)
2. **A test that fails before and passes after**, and the area's suite green. Judge by the
   exit code, not by grepping the output (`-q` output may have no summary line).
3. **Lint, type-check and the docs check clean.**
4. **UI: screenshots** at desktop and mobile widths, light and dark, opened by the lead,
   plus the console and the network requests checked in a browser the lead drives
   (Claude in Chrome, else Playwright). The PO is never asked "did it work?".
5. **Adversarial review** by an agent that didn't write the code (opus, read-only): "what
   is half-done, which edge case breaks, what does the deploy need".
6. **Every scenario of the OpenSpec change's deltas checked with evidence** (test,
   screenshot, command output), when the project uses OpenSpec; `openspec validate
   <name> --strict` passes.
7. **Say what was verified and what was not.**

## Adversarial checklist (before proposing a deploy)

Measure, don't reason:
- What controls each cache key / queue name / file path? Can an anonymous visitor
  inflate it?
- What invalidates each cached entry, and does it depend on a table other than the one
  that triggers the invalidation?
- How does it behave **during writes** (a search, a harvest, a refresh storm), not only
  at rest?
- Anonymous/logged-in boundary: plant a sentinel and prove it doesn't leak either way.
- Does it fit the host (RAM, CPU)? Check the infra note before choosing limits.
- Does the new dependency create a silent coupling (rate limit on the same cache that can fall)?
- Does the deploy need a manual step the automatic one doesn't do (a new service, a new env var)?
- A local-only change (env var, container) — does prod need the same?

## Reports

An agent's or recruit's report never becomes a fix, a commit or a deploy by itself:
open the files. Anything that looks too clean gets one independent check.
