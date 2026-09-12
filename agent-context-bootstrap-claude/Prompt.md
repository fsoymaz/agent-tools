# Agent Context Bootstrap — Repository Setup (Claude Code)

You are setting up a token-efficient, progressive-disclosure context
architecture for Claude Code in this repository.

This is a tooling/documentation task.

Do NOT change application behavior, runtime source, database schema,
migrations, generated output, or business logic.

The goal is to make future Claude Code sessions understand this repository with
minimal repeated discovery and minimal prompt duplication.

---

## 0. What Claude Code Gives You

Before designing anything, know which mechanisms exist, because each one
replaces documentation you would otherwise have to write.

**Root `CLAUDE.md`** — loaded into every session automatically. This is the
router. Everything in it is paid for on every single task, so it must stay
small.

**Nested `CLAUDE.md`** — a `CLAUDE.md` in a subdirectory loads only when the
session touches that subtree. This is progressive disclosure with no protocol
to follow and no discipline required from the agent. Prefer it over a root
rule whenever a rule applies to one area.

**Skills** (`.claude/skills/<name>/SKILL.md`) — a procedure with a
`description`, loaded on demand when the description matches the task. Use for
repeatable multi-step procedures, not for facts.

**Subagents** (`.claude/agents/<name>.md`) — a role with its own context
window and its own tool allowlist. Only its final message returns to the main
session. Use for work that reads a lot and needs to report a little.

**Settings and hooks** (`.claude/settings.json`) — `permissions.deny`,
`permissions.ask`, and `PreToolUse` hooks. These *enforce*; documentation only
*asks*.

The central design question in this task is not "what should I write down?"
It is **"which layer owns this, and can a mechanism own it instead of prose?"**

---

## 1. Inspect Before Designing

First inspect the repository's existing agent/documentation structure.

Read:

- root `CLAUDE.md` and root `AGENTS.md`, if present
- any nested `CLAUDE.md` files already in the tree
- existing `.claude/` configuration: `settings.json`, `skills/`, `agents/`, hooks
- root/workspace configuration
- existing architecture/documentation indexes
- existing project-state or handoff documents, if any

Use repository graph/navigation tooling when available.

If GitNexus is available (MCP tools `mcp__gitnexus__*`):

- unknown concept/location → `query`
- known symbol/dependency/flow → `context`, `impact`, or `trace` as needed
- prefer graph navigation over broad recursive grep/tree scans

Graph results are navigation aids, not source-of-truth.

Verify important conclusions against targeted real source/config/schema/tests.

Do NOT broad-scan the entire repository unless targeted discovery cannot answer
a necessary architectural question. If wide discovery is genuinely required,
delegate it to a subagent so the reading stays out of this context.

---

## 2. Determine the Repository's Real Architecture

Identify only what is necessary to create reliable agent routing.

Determine:

- monorepo vs single-project layout
- applications/workspaces/packages/modules
- business/domain capability ownership
- reusable/shared technical layers
- module/package public APIs
- allowed dependency directions
- important cross-module/import boundaries
- runtime request/use-case flow
- persistence ownership
- database/schema/migration source-of-truth
- generated files that agents must not edit manually
- authentication / identity / tenant boundaries, if relevant
- canonical datasets/configuration sources, if relevant
- test/build/typecheck/lint/schema validation entrypoints
- active domains
- implemented domains
- materially discovered but not implemented domains
- scaffold-only or untouched domains
- current development focus
- existing durable architectural/product invariants

Do not invent conventions that source does not support.

If existing documentation conflicts with executable source, verify the
executable behavior and report the discrepancy.

---

## 3. Build a Progressive-Disclosure Context Model

Target future task startup flow:

```text
CLAUDE.md  (root router — always loaded)
    ↓
PROJECT_STATE.md
    ↓
nested CLAUDE.md / canonical architecture doc for the touched area
    ↓
task-relevant domain handoff
    ↓
repository graph/navigation
    ↓
targeted executable source/schema/tests
```

The repository should NOT require agents to reread a giant handbook or
rediscover the whole codebase for every task.

Each information type must have one clear owner.

### Information ownership

Root `CLAUDE.md`
→ global routing, hard invariants, scope discipline, validation protocol

Nested `CLAUDE.md`
→ rules that apply to exactly one subtree

Canonical architecture docs
→ structural rules, ownership, architecture rationale

`PROJECT_STATE.md`
→ current phase, focus, module/domain status, navigation

`DECISIONS.md`
→ durable accepted cross-task decisions

Domain handoffs
→ concise continuation state for an active domain

`.claude/settings.json` and hooks
→ invariants a tool can check

`.claude/skills/`
→ repeatable procedures

`.claude/agents/`
→ roles needing isolated context

Executable source/schema/tests
→ final implementation truth

Avoid duplicating the same information across these layers. A rule that lives
in `settings.json` does not also belong in prose, beyond a one-line pointer
saying the enforcement exists and must not be weakened.

---

## 4. Documentation Location

Adapt to the repository's existing documentation convention.

If the repository already uses something such as `Docs/`, `docs/`,
`documentation/`, or `architecture/`, reuse that structure.

Do NOT create a competing documentation tree just to match another project.

If no suitable structure exists, a reasonable default is:

```text
docs/
├── architecture/
│   ├── repository-layout.md
│   └── <only project-relevant architecture docs>
│
└── agent/
    ├── PROJECT_STATE.md
    ├── DECISIONS.md
    └── handoffs/
        └── <active-domain>.md
```

Do not blindly create documents such as identity-boundaries, persistence
architecture, module conventions, or backend architecture unless this
repository actually needs them.

---

## 5. Root CLAUDE.md

Create or refactor root `CLAUDE.md` into a concise routing document.

Target roughly 100–150 lines when practical. Do not optimize for line count at
the expense of semantic correctness.

Remember that every line here is loaded on every task, including tasks it has
nothing to do with. If a rule applies to one subtree, it belongs in a nested
`CLAUDE.md`, not here.

If the repository already has an `AGENTS.md`, do not maintain two routers.
Consolidate into `CLAUDE.md` and leave `AGENTS.md` as a short pointer, or
remove it — but preserve every still-valid invariant it contained.

It should normally contain:

### Source Priority

Define authority by concern rather than one misleading global ranking:

- workspace/build/deployment → executable workspace/config files
- persistence → executable schema/migrations
- runtime/domain behavior → owning runtime source
- regressions → targeted tests
- architecture conventions → canonical architecture docs
- continuation/navigation → agent state and handoffs

Explicit current-task user instructions and repository hard invariants remain
binding.

When documentation conflicts with executable source for the same concern,
executable source wins.

### Context Loading Protocol

At task start:

1. read `PROJECT_STATE`
2. read only the task-relevant canonical architecture documentation
3. read only the relevant domain handoff, if one exists
4. use repository graph/navigation when useful
5. verify only relevant executable source/config/schema/tests before editing

Nested `CLAUDE.md` files load on their own when their subtree is touched — do
not instruct the agent to go hunting for them.

Do not broad-scan by default.

Do not repeat discovery already answered by state + handoff + graph.

### Repository Graph

If GitNexus is available:

- unknown concept/location → `mcp__gitnexus__query`
- known symbol/dependency/flow → `context`, `impact`, or `trace` as needed
- prefer graph navigation over broad grep/tree scans
- use impact analysis for shared/public/high-blast-radius changes, not every
  trivial local edit
- verify relevant graph findings in source
- re-index only when the graph becomes stale after meaningful structural or
  dependency changes

Do not put GitNexus installation/configuration instructions into `CLAUDE.md`.

### Hard Invariants

Keep only truly global project-specific MUST / MUST NOT rules.

**First, classify each one.** If a tool can check it, it belongs in
`.claude/settings.json` or a `PreToolUse` hook, and `CLAUDE.md` gets at most a
one-line pointer. Only rules that need judgment stay as prose.

Enforceable, and therefore not prose:

- do not read secret files
- do not edit generated output
- do not run destructive git commands without confirmation
- do not run self-installing configuration commands automatically

Needs judgment, and therefore prose:

- capability ownership
- package/module boundaries
- public API/import rules
- identity boundaries
- tenant isolation
- persistence ownership
- lifecycle invariants
- canonical dataset ownership
- critical engine/runtime isolation rules

Move detailed explanation to canonical architecture docs.

### Scope Discipline

Require:

- only requested scope
- no unrelated refactors
- no speculative abstraction
- no architecture rewrite
- no unrelated schema redesign
- no mass cleanup/formatting
- preserve unrelated user worktree changes

### Validation

Reference only real repository commands. Verify each one exists before writing
it down.

Require validation proportional to risk:

- focused tests first
- relevant typecheck/build
- schema validation only when relevant
- `git diff --check`
- scoped diff review

Do not invent commands.

### Documentation Protocol

State clearly:

- handoff updates only for material continuation-state changes
- `PROJECT_STATE` only for material phase/focus/status changes
- `DECISIONS` only for accepted durable decisions
- architecture docs only for durable convention/architecture changes
- no documentation churn for trivial fixes

### Final Report

Require concise reporting of: changed areas, validation, boundaries/scope
preservation, blockers/gaps, material documentation changes.

---

## 6. Nested CLAUDE.md Files

Create a nested `CLAUDE.md` only for a subtree that has **its own real rules** —
rules that are wrong or meaningless outside it.

Good reasons:

- a package with import/boundary rules the rest of the repo does not share
- an area with its own test or build entrypoint
- a generated or vendored subtree with editing restrictions
- a domain with terminology that must be preserved exactly

Not reasons:

- the package exists
- the package is large
- symmetry with a sibling that has one

Keep each one short and specific to that subtree. Do not restate root rules.

---

## 7. PROJECT_STATE.md

Create a concise current-state/navigation index.

It should answer:

- What phase is the project in?
- What is currently being worked on?
- What domains/modules are scaffold / discovery / active / implemented / partial?
- What is the likely next work?
- Which handoff should a future session read?

Do NOT make it a changelog, implementation history, task archive, or source
dump. Keep it small.

---

## 8. DECISIONS.md

Create this only as a durable decision register.

Record decisions that future tasks would otherwise repeatedly rediscover or
debate: ownership choices, persistence/source-of-truth decisions, lifecycle
semantics, identity boundaries, contract strategy, architectural constraints.

Do NOT record ordinary implementation details or every completed task.

If there are currently no meaningful durable decisions beyond canonical
architecture, keep the file minimal.

---

## 9. Domain Handoffs

Create handoffs only for domains that are:

- implemented and likely to continue evolving
- actively being developed
- materially discovered with meaningful continuation state

Do NOT create handoffs merely because a module/folder exists. Do NOT create
handoffs for untouched scaffold-only domains.

Preferred structure:

```md
# <Domain> — Current State

## Status

## Architecture / Flow

## Key Files

## Important Decisions

## Dependencies

## Known Gaps

## Continue From Here
```

Use only headings that add value.

A handoff must be concise, current-state oriented, sufficient for a fresh
session to continue, and domain-terminology preserving.

A handoff must NOT be a changelog, completed-task archive, source-code copy,
schema dump, or verbose historical narrative.

Prefer roughly 40–100 lines when practical.

Note the division of labor with Claude Code's own mechanisms: automatic session
snapshots record *what changed* (branch, commits, dirty files). A handoff
records *what it means and what to do next*. Do not let the handoff degrade
into the former.

---

## 10. Canonical Architecture Docs

If the old router or existing docs contain detailed architecture information
that should survive, move it into a small set of project-specific canonical
documents.

Create only documents justified by the repository. Possible examples:
repository layout / ownership, module/package conventions, persistence
boundaries, identity/tenant boundaries, integration architecture, domain-engine
architecture.

Do not reproduce information already obvious from source unless future agents
genuinely need the rule or the rationale.

Each rule should have one canonical owner.

---

## 11. Claude Code Configuration

Only after the documentation layers are settled, consider the mechanisms.

### settings.json

Encode the invariants you classified as enforceable in section 5. Two rules:

- **Verify each pattern actually matches.** A `Bash(...)` permission entry
  matches the command as it will really be typed. An `ask` rule for
  `Bash(make scan:*)` does nothing if the documented invocation is
  `make -f <path>/Makefile scan`. Write the pattern for the real command, and
  check it against the invocation in your own documentation.
- **Do not weaken an existing entry.** If a deny list already exists, treat it
  as intentional. Extending it is in scope; relaxing it is not.

### Hooks

A `PreToolUse` hook can block what a permission pattern cannot express. If you
add one:

- fail **open** on unexpected input — the goal is to stop a known bad case, not
  to break the session on a parse error
- inspect only; never silently rewrite the user's command
- state the side effects in `CLAUDE.md`, including any legitimate action the
  hook will also block

Never install a hook that prefixes or rewrites every command with a binary that
may not resolve in the harness's non-interactive `PATH`. Confirm resolution in
a plain, non-interactive shell first.

### Skills

Create a skill only for a procedure that is (a) multi-step, (b) actually
repeated, and (c) easy to get wrong from memory. Write the `description` for
matching — it is the only part loaded until the skill fires, so it must say
when to use the skill, not what the skill contains.

Do not create a skill for a fact. Facts belong in documentation.

### Subagents

Create a subagent only for a role that reads much more than it reports:
discovery, review, triage, verification. Give each one the narrowest tool set
that lets it finish — a reviewer that cannot write cannot accidentally "fix"
anything.

Do not create a subagent for work the main session handles fine. Each one
starts cold and re-derives context.

---

## 12. Existing Documentation Audit

During this setup, identify material stale documentation such as removed
modules/packages, obsolete architecture, renamed concepts, old service counts,
invalid commands, stale paths, retired runtime engines, outdated persistence
assumptions, or reference DB docs lagging executable schema.

Correct stale material only when it directly affects the new canonical context
architecture.

Do not turn this into a general documentation cleanup task.

Report notable discrepancies.

---

## 13. Persistence Source-of-Truth

Determine the repository's real persistence workflow, and clearly document
which artifacts own executable truth — Prisma schema + migrations, Drizzle
schema + migrations, Mongoose schemas, SQL migrations, ORM entities, and so on.

If DBML, SQL snapshots, diagrams, or design documents coexist, mark them as
reference/design artifacts when appropriate.

Do NOT modify schema or migrations in this task.

---

## 14. Tooling Assumptions

If already installed:

- GitNexus → repository graph/navigation
- rtk → compressed shell/tool output
- Caveman → concise agent output and local measurement

Do not reinstall or reconfigure them unless explicitly requested. Check before
installing: a tool may already be on `PATH` from a package manager, and a
second copy that loses the `PATH` race is worse than none.

Do not make tooling itself the center of `CLAUDE.md`.

The objective is fewer unnecessary tokens and less repeated discovery, not more
mandatory tool calls.

---

## 15. Preservation Rules

Do NOT:

- change application/runtime behavior
- change schema or migrations
- edit generated files
- invent architecture
- copy another project's domain rules
- create handoffs for every folder
- create a nested `CLAUDE.md` for every package
- create a skill or subagent for every procedure
- create a giant replacement handbook
- duplicate the same invariant in multiple files
- weaken an existing permission or hook
- weaken project-specific terminology merely to shorten documents
- perform unrelated cleanup

Preserve all still-valid project-specific invariants from an existing router.

If validity is uncertain, verify before moving or removing the rule.

---

## 16. Validation

Before finishing:

- verify all referenced paths exist
- verify referenced commands/scripts exist
- verify important architecture claims against targeted source/config/schema
- verify each new `settings.json` pattern matches the command form your own
  documentation tells people to type
- check documentation links
- run `git diff --check`
- review scoped diff

Do not run expensive full application validation for documentation-only changes
unless necessary to validate a specific claim.

---

## 17. Final Report

Report concisely:

1. root router before/after lines and words
2. created/updated canonical architecture docs
3. created nested `CLAUDE.md` files and why each subtree qualified
4. created agent-state/decision files
5. created handoffs and why each qualified
6. domains intentionally left without handoffs and why
7. invariants moved from prose into `settings.json` or hooks
8. skills/subagents created and why each was not just documentation
9. important stale/conflicting documentation found
10. established source-of-truth boundaries
11. validation performed
12. any operational/documentation gaps discovered

Do not claim exact token savings.

Finish after the context architecture is established.

Do not implement application features.
