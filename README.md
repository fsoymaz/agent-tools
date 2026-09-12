# agent-tools

A local toolkit for AI coding agents: **rtk** (compressed terminal output),
**GitNexus** (repository knowledge graph), and **Caveman** (concise agent
responses + a local compression proxy), plus reusable `.claude/agents/`
scaffolds to drop into project repos.

## Where this folder lives

**Anywhere.** The `Makefile` derives its own location, so nothing here
depends on a fixed path. Pick a spot, then point one environment variable
at it — the rest of this README refers to that variable rather than to a
hardcoded path, so the same checkout works on every machine.

Add to your shell rc (`~/.zshrc`):

```bash
export AGENT_TOOLS="$HOME/Desktop/agent-tools"   # wherever you keep it
alias amake='make -f "$AGENT_TOOLS/Makefile"'
```

Everything heavier than a symlink stays inside `$AGENT_TOOLS` (npm cache,
npm prefix, rtk build output). On a machine with a small or quota'd home
partition — a 42 school box, for instance — put the checkout on the big
volume (`sgoinfre`) and point `AGENT_TOOLS` there; no file in this repo
needs to change.

`~/.local/bin/rtk`, `~/.local/bin/gitnexus`, and `~/.local/bin/caveman` are
**symlinks** into `$AGENT_TOOLS`, created only when the Makefile actually
installs a tool (see the next section).

## For coding agents (Claude Code and Cursor)

Both agents must read the **same** files — do not keep a second copy of
the story in chat.

| File | Who loads it | Owns |
|---|---|---|
| `PROGRESS.md` | both, on purpose | live story (done / leftover / next) |
| `AGENTS.md` | Cursor auto; Claude via `CLAUDE.md` pointer | how to call tools |
| `CLAUDE.md` | Claude Code every session | hard invariants |
| `.cursorrules` + `.cursor/rules/` | Cursor | same invariants, short |

**How to invoke the tools**

- From any project: `make -f "$AGENT_TOOLS/Makefile" <target>` (`amake`).
- Knowledge graph: GitNexus **MCP** in both UIs. Refresh this repo with
  `gitnexus analyze . --index-only`. Do **not** run `make scan` here — it
  overwrites `CLAUDE.md` / `AGENTS.md`.
- Terminal compression: Claude Code may rewrite `cat`/`ls` via an rtk
  hook. Cursor does not — call `rtk read` / `rtk ls` yourself. Pipes are
  never rewritten; use `rtk read FILE --max-lines N`.
- Persist story: `/progress`, or the user saying kaydet / devret. A Stop
  hook only *reminds*; it cannot write the narrative.

Do not run `gitnexus setup` or `caveman setup --install` without explicit
approval.

## Layout

```
$AGENT_TOOLS/
├── Makefile          ← master orchestrator (this is what you actually run)
├── PROGRESS.md       ← live story for both agents
├── AGENTS.md         ← dual-agent router (tool invocation)
├── .cursorrules      ← Cursor short rules (mirrors CLAUDE.md invariants)
├── .cursor/rules/    ← always-on Cursor rule (PROGRESS + tools)
├── CLAUDE.md         ← rules for Claude Code working *in this repo*
│   ├── Makefile        (make linux / mac / windows / all)
│   └── dist/<os>/rtk   ← built or fetched binaries land here
├── GitNexus/           ← GitNexus source copy (reference only; the working
│                          install is the npm/brew package, not this copy)
├── Agent-Context-Bootstrap-v1/  ← upstream clone (own .git, nested repo):
│                          the Codex-targeted bootstrap prompt that defines
│                          this repo's agent-context layering and the
│                          domain-handoff format
├── agent-context-bootstrap-claude/  ← the same workflow adapted to Claude
│                          Code (nested CLAUDE.md, skills, subagents, hooks).
│                          Written here so the upstream clone stays pristine.
├── test-otomasyon/     ← draft Playwright subagents, to be copied into the
│                          real test-automation repo (see its README)
├── handoffs/           ← hand-written domain state notes (see handoffs/README.md)
├── CLAUDE.md           ← rules for Claude Code working *in this repo*
├── .claude/
│   ├── settings.json   ← permission deny/ask lists
│   ├── hooks/          ← block-secrets.py (PreToolUse guard)
│   └── handoffs/       ← mechanical session snapshots written by a hook
├── npm-cache/          ← isolated npm cache (gitignored)
├── npm-global/         ← npm --prefix target: gitnexus + caveman (gitignored)
└── bin/                ← older hand-built binary copy (gitignored)
```

## Already-installed tools are skipped

The `rtk`, `gitnexus`, and `caveman` targets first check whether the tool is
already on `PATH`. If it is, they print the existing version and **skip the
install** rather than laying down a symlink in `~/.local/bin` that a
higher-priority `PATH` entry would silently shadow.

This matters on macOS, where Homebrew's `/opt/homebrew/bin` usually comes
before `~/.local/bin`: without the check, `make rtk` would happily build and
link a binary you would then never actually run.

For `rtk` the check also confirms the binary is the right one — it runs
`rtk gain`, which only the real rtk supports. A `PATH` entry named `rtk`
that fails that probe is almost certainly `reachingforthejack/rtk` (Rust
Type Kit), so the Makefile warns and installs this repo's copy anyway.

To install regardless:

```bash
amake all FORCE_INSTALL=1
```

If a forced install ends up shadowed by another `PATH` entry, the Makefile
says so and names the winner.

## Usage

From **any project directory**:

```bash
amake all      # install/update rtk + gitnexus + caveman, then scan this project
amake rtk      # just (re)build/fetch rtk for this OS
amake gitnexus # just (re)install gitnexus
amake caveman  # just (re)install caveman
amake scan     # just re-run the two project-scoped steps below
```

Without the alias, spell it out: `make -f "$AGENT_TOOLS/Makefile" all`.

`PROJECT_DIR` defaults to wherever you ran `make` from (`$CURDIR`). Override
it if you want to scan a different repo without `cd`-ing there first:

```bash
amake scan PROJECT_DIR=/path/to/other/repo
```

## What each target actually does

- **`rtk`** — `rtk/Makefile`'s `linux` or `mac` target for whichever OS you
  ran `make` on (never `windows` here — that's cross-platform output only,
  see below), then symlinks the result into `~/.local/bin/rtk`.
- **`gitnexus`** — `npm install -g gitnexus` (isolated cache/prefix under
  this folder), symlinked into `~/.local/bin/gitnexus`.
- **`caveman`** — installs the Caveman Claude Code skills globally
  (`npx skills add JuliusBrussee/caveman -g -a claude-code`, landing in
  `~/.claude/skills/`) *and* the `@caveman-ai/cli` package under
  `npm-global/`, symlinked into `~/.local/bin/caveman`. The native proxy
  binaries are a separate, manual step — `caveman setup --install` puts
  ~177 MB into `~/.caveman/bin/`, outside this repo. It installs binaries
  only; wiring Caveman into an agent config is `caveman setup --install`'s
  sibling commands (`caveman tools hooks`, `caveman tools mcp`), which fall
  under the Hooks/MCP rule below.
- **`scan`** — the only target that touches `PROJECT_DIR`, and the only one
  that never skips:
  - `gitnexus analyze <PROJECT_DIR>` — indexes that repo into a local
    knowledge graph, writing/updating `AGENTS.md` and `CLAUDE.md` there.
  - `caveman explore install --dir <PROJECT_DIR>` — installs Caveman's
    `explore` skill scoped to that one project (not globally).

`scan` resolves `gitnexus` and `caveman` from `PATH`, falling back to
`~/.local/bin`, so it uses the right binary whether the install ran or was
skipped.

## Cross-compiling rtk for other platforms

`rtk/Makefile` produces a binary for any of the three OSes regardless of
which one you're running on:

```bash
cd "$AGENT_TOOLS/rtk"
make linux    # dist/linux/rtk
make mac      # dist/mac/rtk        (arch auto-detected: arm64 vs x86_64)
make windows  # dist/windows/rtk.exe
make all      # all three
```

The skip-if-installed check does **not** apply when the target OS differs
from the host: producing `dist/windows/rtk.exe` isn't an install, so an
`rtk` already on `PATH` is no reason to skip it.

It is **not** a real cross-compiler. Building from source needs a current
Rust toolchain (rtk needs 1.91+) for the host OS, plus a matching SDK —
which generally isn't available for the other two. So:

- If you run `make linux` **on Linux** with a new-enough `cargo`, it
  actually builds from source.
- If you run `make mac` **on macOS** with a new-enough `cargo`, same thing.
- In every other case (including always, for `windows`, since there's no
  cross MSVC toolchain) it downloads the official prebuilt release asset
  from `github.com/rtk-ai/rtk/releases` and verifies it against the
  published `checksums.txt` before use — the same method used to install
  rtk on this machine in the first place.

If you copy `rtk/` to an actual Mac or Windows box with a current Rust
toolchain, the matching target will build from source there instead.

## Hooks / MCP — deliberately NOT automated

`gitnexus setup` registers MCP servers for your editor/agent, and
`caveman setup --install` wires Caveman's proxy into your agent's config.
Neither is called by `all` or `scan`. Run them yourself once you've read
what they write:

```bash
gitnexus setup          # MCP config for Claude Code / Cursor / etc.
caveman setup --install # caveman's own hook/proxy install
```

This project previously hit a real problem where an auto-installed rtk
hook rewrote every Bash command to be prefixed with a bare `rtk`, which
wasn't resolvable in this environment's actual command-execution PATH —
it broke every shell command until the hook was removed. Always inspect
a generated hook's `command` field and confirm it resolves (`which <cmd>`
in a **plain, non-interactive** shell, not just your normal terminal)
before trusting an automatic installer to wire itself into Claude Code.

## Disk notes

- `npm-cache/` and `npm-global/` can be deleted and rebuilt any time via
  `make gitnexus` / `make caveman` again — nothing there is hand-edited.
  `make clean-npm-cache` empties the cache alone.
- On a host with a small home partition, keep the checkout on the roomy
  volume and set `AGENT_TOOLS` accordingly — the npm cache and rtk's Rust
  build tree are the two things that grow.
