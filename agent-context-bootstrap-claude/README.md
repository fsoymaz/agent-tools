# Agent Context Bootstrap — Claude Code edition

A bootstrap prompt for building a **token-efficient, progressive-disclosure
context architecture** in a repository, adapted for **Claude Code**.

The bootstrap prompt lives in [`Prompt.md`](./Prompt.md).

This is an adaptation of [`Ifmai/Agent-Context-Bootstrap-v1`](https://github.com/Ifmai/Agent-Context-Bootstrap-v1),
vendored in this repo at `../Agent-Context-Bootstrap-v1/`. That version targets
**Codex CLI**. This one targets Claude Code and drops the Codex-specific parts.
Read the next section before assuming the two are interchangeable — the core
idea survives, but several layers move from prose into mechanism.

---

## What changes vs. the Codex version

The upstream prompt has to describe the whole architecture *in documentation*,
because Codex has no structural place to put it. Claude Code does. Most of the
adaptation is moving a rule from "a paragraph the agent should remember" into
"a mechanism the harness enforces."

| Upstream (Codex) | Claude Code |
|---|---|
| `AGENTS.md` as root router | `CLAUDE.md` — auto-loaded into **every** session |
| One flat doc tree, agent reads what it should | **Nested `CLAUDE.md`** — a subdirectory's file loads only when that subtree is touched |
| Procedures written into the router | **Skills** (`.claude/skills/`) — the model loads one by `description` match, on demand |
| "Discovery session → close → fresh session" | **Subagents** (`.claude/agents/`) — isolated context in the *same* session; only the final report returns |
| "Do NOT edit X" as prose | `.claude/settings.json` → `permissions.deny` / `ask`, plus `PreToolUse` hooks |
| GitNexus CLI (`gitnexus query …`) | GitNexus **MCP tools** (`mcp__gitnexus__query`, `context`, `impact`, `trace`) |
| `rtk init -g --codex` | rtk as a Claude Code hook (command rewriting) |
| Bundled `caveman-codex/` skills | Upstream Caveman skills in `~/.claude/skills/` |
| Handoff written by hand at session end | `/handoff` skill, plus automatic session snapshots |

Three of these are not cosmetic:

**Nested `CLAUDE.md` is progressive disclosure, for free.** The upstream prompt
spends effort teaching the agent *when* to read which architecture doc. In
Claude Code, a `CLAUDE.md` in `packages/billing/` loads when — and only when —
the agent touches that subtree. Rules that apply to one area belong there, not
in the root router. This is the single biggest structural difference, and the
adapted prompt leans on it heavily.

**Subagents replace the session boundary.** Upstream's core workflow is
*discovery session → write handoff → close session → fresh implementation
session*, because a bloated context can only be escaped by ending it. A subagent
gets its own context window and returns only its final message, so discovery can
be isolated without stopping work. The handoff is still worth writing — but as a
durable artifact for *later* sessions, not as an escape hatch from this one.

**An invariant that can be enforced should not be documentation.** Upstream can
only write "do not edit generated files." Claude Code can deny the write. Prose
invariants are for things a tool cannot check; everything else belongs in
`settings.json` or a hook. The adapted prompt asks you to classify each
invariant rather than write them all into the router.

---

## The architecture

The target startup flow for any future task:

```text
CLAUDE.md  (root router — always loaded)
    ↓
PROJECT_STATE.md  (what is happening now)
    ↓
nested CLAUDE.md / architecture doc for the touched area
    ↓
domain handoff for that domain, if one exists
    ↓
repository graph (GitNexus MCP)
    ↓
targeted source / schema / tests
```

Each information type gets exactly one owner:

| Layer | Owns |
|---|---|
| Root `CLAUDE.md` | global routing, hard invariants, scope discipline, validation protocol |
| Nested `CLAUDE.md` | rules scoped to one subtree |
| Architecture docs | structural rules, ownership, rationale |
| `PROJECT_STATE.md` | current phase, focus, domain status, navigation |
| `DECISIONS.md` | durable accepted decisions |
| Domain handoffs | continuation state for one active domain |
| `.claude/settings.json` + hooks | mechanically enforceable invariants |
| `.claude/skills/` | repeatable procedures, loaded on demand |
| `.claude/agents/` | isolated-context roles (discovery, review, triage) |
| Source / schema / tests | final truth |

The same rule must not appear in two layers.

---

## What the bootstrap creates

Adapted to the repository, not copied blindly. A typical result:

```text
CLAUDE.md                      ← compact root router (~100-150 lines)

docs/
├── architecture/
│   ├── repository-layout.md
│   └── <only project-relevant docs>
└── agent/
    ├── PROJECT_STATE.md
    ├── DECISIONS.md
    └── handoffs/
        └── <active-domain>.md

packages/<area>/CLAUDE.md      ← only where an area has its own real rules

.claude/
├── settings.json              ← enforceable invariants
├── skills/                    ← only for genuinely repeated procedures
└── agents/                    ← only for roles that need isolated context
```

`.claude/skills/` and `.claude/agents/` are **opt-in**. Creating a skill for a
procedure used once is the same mistake as creating a handoff for every folder.

---

## Setup

1. Install the tooling you want (all optional — see below).
2. Open Claude Code at the target repository root, in a fresh session.
3. Give it the contents of [`Prompt.md`](./Prompt.md).
4. Review the diff before committing. The bootstrap writes documentation and
   agent configuration; it must not touch runtime behavior.

If the repository already has a `CLAUDE.md`, the bootstrap refactors it rather
than replacing it, and preserves every still-valid project-specific invariant.

### Tooling

None of these are required. The progressive-disclosure architecture works
without them; they reduce different kinds of waste.

**GitNexus** — repository graph, so the agent navigates instead of grepping.

```bash
npm install -g gitnexus        # or: it may already be on your PATH
gitnexus analyze .             # index the repo
gitnexus doctor                # verify
gitnexus setup                 # register the MCP server — read what it writes first
```

In Claude Code the graph is reached through MCP tools (`mcp__gitnexus__query`,
`context`, `impact`, `trace`), not the CLI. Keep the local `.gitnexus/` index
out of Git. The graph is a **navigation aid, never source-of-truth** — verify
conclusions against real source.

**rtk** — compresses terminal/tool output before it reaches context.

```bash
brew install rtk               # macOS
```

rtk wires into Claude Code as a hook that rewrites Bash commands. Inspect the
generated hook's `command` field and confirm it resolves in a **plain,
non-interactive** shell before trusting it — a bare, unresolvable `rtk` prefix
will break every shell command in the session.

**Caveman** — response compression and local usage measurement.

```bash
npx skills add JuliusBrussee/caveman -g -a claude-code   # skills
npm install -g @caveman-ai/cli                           # CLI
caveman setup --install                                  # native binaries
```

Use the upstream Claude Code skills. Do **not** copy
`../Agent-Context-Bootstrap-v1/caveman-codex/` into `~/.claude/skills/` — that
bundle is Codex-shaped (`$caveman-stats-codex`, `agents/openai.yaml`) and is
the Codex substitute for the very skills you already have.

In this repo, `make caveman` does the first two steps and skips them if
Caveman is already on `PATH`.

---

## After bootstrap

Task prompts get much smaller, because the repository now explains itself:

```text
Implement <task>.

Follow the Context Loading Protocol in CLAUDE.md. Load only the relevant
state, handoff, and targeted source. Do not broad-scan the repository.

<task-specific requirements>
```

For work that needs wide discovery, send a subagent rather than widening the
main context, and have it report findings — not file dumps.

---

## What not to do

The failure mode of this approach is producing *more* documentation, which is
the problem it exists to solve. Specifically, do not:

- write a handoff for every folder
- write a nested `CLAUDE.md` for every package
- turn a one-off procedure into a skill
- create a subagent for work the main session handles fine
- replace the root router with a giant handbook
- copy another repository's domain rules
- restate an enforceable rule in prose *and* in `settings.json`
- update `PROJECT_STATE`, handoffs, and decisions after every small change

More context is not better context. Correctly-owned context is.
