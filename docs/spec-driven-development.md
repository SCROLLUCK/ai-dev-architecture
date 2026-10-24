# Spec-driven development (SDD) with OpenSpec

For a feature or a rule change, the spec is written, reviewed and approved **before** any agent
writes code. [OpenSpec](https://github.com/Fission-AI/OpenSpec) provides the structure; the
agent workflow supplies the discipline around it.

## Why

An agent given a vague request fills the gaps with its own reading. A written spec with testable
scenarios turns the PO's approval into something concrete, gives the agents a single plan
(`tasks.md`), and gives the reviewer a checklist (every scenario).

## Layout

```text
openspec/
  config.yaml            # schema, project context, per-artifact rules, per-operation guidance
  specs/<capability>/spec.md        # what the system does today (source of truth)
  changes/<name>/                   # one folder per proposed change
    proposal.md          # why, what changes, out of scope, impact, ends with "Approved: pending"
    specs/<capability>/spec.md      # deltas: ADDED / MODIFIED / REMOVED requirements + scenarios
    design.md            # context, goals/non-goals, decisions
    tasks.md             # the implementation plan, one checkbox per task
  changes/archive/YYYY-MM-DD-<name>/   # finished changes
```

## Lifecycle

1. **Brainstorm** the idea with the PO (a brainstorming skill from the Superpowers plugin), then
   `/opsx:propose` writes the change folder.
2. **PO approves the proposal.** Only then does the lead replace the last line `Approved: pending`
   with `Approved: YYYY-MM-DD`. A commit hook refuses code on the feature branch until that line is set.
3. **Branch + worktree** named after the change: change `x` is built on branch `feat/x` in worktree `.claude/worktrees/x`.
4. **Agents implement `tasks.md`**, test first, one task at a time. `tasks.md` is the only plan
   (no separate planning step). An agent that finds the change wrong or silent stops and reports.
5. **Review** checks every scenario of the deltas with evidence (test, screenshot, command output),
   and `openspec validate <name> --strict` passes.
6. **`/opsx:archive`** merges the deltas into `openspec/specs/` and moves the change to the archive,
   on the feature branch before the merge, so the updated spec and the code land together.

## Rules encoded in `config.yaml`

The config is where project-specific rules live, so agents see them without anyone repeating them:

- `proposal`: last line is `Approved: pending`; state what is out of scope; state the outcome of a legal/compliance screen when the change touches sensitive areas.
- `design`: name the docs and decision-log entries the change will update.
- `tasks`: each task names the files it touches **and how it is verified**; a reported bug fixed inside the change gets a failing test first; the last tasks update stale docs, the changelog and the decision log.
- `apply` guidance: work only on the feature branch in its worktree; `tasks.md` is the plan; run lint, tests and the docs check, then request a code review.
- `archive` guidance: archive on the feature branch before merge.

## Anonymized example

The shape below is modeled on a real archived change, with the product details replaced. The domain
(a catalogue of tags for listings) is invented for illustration.

**`proposal.md`** (abridged)

```markdown
# Proposal

## Why
Aliases in the tag catalogue do two jobs: spellings of the same tag ("nodejs" -> node.js) and
narrower tags folded into a broad word ("unit tests" -> tests). The broad tag then says nothing
and matches unrelated listings. Measured on the live catalogue: <table of broad terms with counts>.

## What Changes
- An alias is only another spelling. A narrower tag becomes its own catalogue term.
- Wrong folds are removed. Generic bare words stop being tags.
- Shipped as a reproducible data migration, then a re-tag run on the existing pool.
- The rule is written into the decision log.

Tradeoff the PO accepts: a profile that lists the broad word no longer matches a narrow tag.

## PO answer (2026-10-20)
Borderline broad words are disabled too: <list>.

## Out of scope
- No change to the matcher. - No admin guard yet. - Users' profiles are not rewritten.

## Capabilities
### Modified Capabilities
- `admin-panel`: the catalogue requirement gains the alias-is-a-spelling rule.

## Impact
Migration + its test; pool tags change after re-tag; docs and changelog.

## Legal screen
Passes: catalogue data, no personal data, no payment, no new scraping.

Approved: 2026-10-20
```

**`specs/admin-panel/spec.md`** (delta, abridged)

```markdown
## ADDED Requirements

### Requirement: Specific tag terms
A term's aliases SHALL only be other spellings of the same tag. A narrower tag SHALL be its own
term. A broad bare word MUST NOT be an enabled tag.

#### Scenario: A narrow tag keeps its name
- **WHEN** a listing asks for "unit tests and integration tests"
- **THEN** it is tagged `unit tests` and `integration tests`, and not `tests`

#### Scenario: A bare broad word tags nothing
- **WHEN** a listing says only "experience with tests"
- **THEN** it gets no `tests` tag

#### Scenario: A spelling is still an alias
- **WHEN** a listing asks for "NodeJS"
- **THEN** it is tagged `node.js`
```

**`tasks.md`** (abridged; note every task names files and a verification)

```markdown
## 1. Migration
- [x] 1.1 Write the data migration with SPLITS / DROPS / DISABLE tables (design section 1);
      verify forward and reverse both run on the dev database
- [x] 1.2 Add tests covering the spec scenarios and the reverse leaving staff-edited rows alone;
      verify it fails before 1.1 and passes after

## 2. Docs
- [x] 2.1 Update the flow note and the decision log; verify the docs check passes
- [x] 2.2 Add the changelog bullet under Unreleased; verify lint passes

## 3. Pool impact
- [x] 3.1 Dry-run the re-tag against a copy of the live catalogue; show per-area added/removed
      tags to the PO before release

## Workflow follow-up
- After deploy: dry run in prod, then apply with the PO's OK. Archive the change once shipped.
```

What to notice: scenarios are the acceptance tests; the PO's answer is recorded in the proposal;
tradeoffs and out-of-scope are explicit; each task has a verification; the PO also gets a
measured preview of the data impact before release.

## How agents use it

The goal in a brief becomes "implement task N.M of `openspec/changes/<name>/tasks.md`". The agent
reads proposal, deltas and design, builds only that task test-first against the scenarios, and stops
when the change is wrong or silent. The definition of done includes checking every scenario with evidence.
