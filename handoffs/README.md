# Domain Handoffs

Concise continuation-state files for active domains, per the format defined in
`Agent-Context-Bootstrap-v1/Prompt.md` (see "Preferred structure"). Create one
file per actively-evolving domain — not for every folder, not for scaffold-only
code.

In that prompt's information-ownership model, a domain handoff is the layer
between global routing (`AGENTS.md`) and the executable source: it carries
current state for one domain, and nothing that another layer already owns.

These are hand-written and intentional. The mechanical per-session snapshots
a hook drops in `.claude/handoffs/` are a different thing: they record commit
and branch state, not intent.

The **live story both agents continue from** is root `PROGRESS.md`, not
this folder. Update `PROGRESS.md` every session; add a domain file here
only when a subtree has durable state that does not belong in the live
story.

Template:

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

Keep each handoff ~40-100 lines: current-state oriented, not a changelog or
source dump.
