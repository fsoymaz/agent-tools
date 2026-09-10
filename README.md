# agent-tools

A local toolkit for AI coding agents: **rtk** (compressed terminal output),
**GitNexus** (repository knowledge graph), and **Caveman** (concise agent
responses + a local compression proxy). Everything here lives on the
`sgoinfre` network share, not on the small `/home` partition, because rtk's
Rust toolchain, GitNexus's `tree-sitter` grammars, and Caveman's proxy add
up to several hundred MB — more than `/home` had free.

## Layout

```
agent-tools/
├── Makefile          ← master orchestrator (this is what you actually run)
├── rtk/               ← rtk source clone + its own cross-platform Makefile
│   ├── Makefile        (make linux / mac / windows / all)
│   └── dist/<os>/rtk   ← built or fetched binaries land here
├── GitNexus/           ← GitNexus source clone (reference; the working
│                          install is the npm package below, not this clone)
├── handoffs/           ← domain handoff notes (see Agent-Context-Bootstrap-v1/Prompt.md)
├── npm-cache/          ← isolated npm cache (keeps installs off /home)
├── npm-global/         ← npm --prefix target: gitnexus + caveman live here
└── bin/                ← the actual rtk binary in use lives here
```

`~/.local/bin/rtk`, `~/.local/bin/gitnexus`, and `~/.local/bin/caveman` are
**symlinks** into the paths above. `~/.local/bin` is on PATH in a normal
interactive terminal; keep using it as the stable entry point rather than
typing the long sgoinfre paths.

## One-time convenience alias

Add to `~/.zshrc` (a real, interactive terminal — not needed inside this
harness, which resolves `~/.local/bin` directly):

```bash
alias amake='make -f $HOME/sgoinfre/agent-tools/Makefile'
```

Then, from **any project directory**:

```bash
amake all      # install/update rtk + gitnexus + caveman, then scan this project
amake rtk      # just (re)build/fetch rtk for this OS
amake gitnexus # just (re)install gitnexus
amake caveman  # just (re)install caveman
amake scan     # just re-run the two project-scoped steps below
```

Without the alias, spell it out: `make -f ~/sgoinfre/agent-tools/Makefile all`.

`PROJECT_DIR` defaults to wherever you ran `make` from (`$CURDIR`). Override
it if you want to scan a different repo without `cd`-ing there first:

```bash
make -f ~/sgoinfre/agent-tools/Makefile scan PROJECT_DIR=/path/to/other/repo
```

## What each target actually does

- **`rtk`** — `rtk/Makefile`'s `linux` or `mac` target for whichever OS you
  ran `make` on (never `windows` here — that's cross-platform output only,
  see below), then symlinks the result into `~/.local/bin/rtk`.
- **`gitnexus`** — `npm install -g gitnexus` (isolated cache/prefix under
  this folder), symlinked into `~/.local/bin/gitnexus`.
- **`caveman`** — installs the 20 Caveman Claude Code skills globally
  (`npx skills add JuliusBrussee/caveman -g -a claude-code`) *and* the
  `@caveman-ai/cli` proxy binary, symlinked into `~/.local/bin/caveman`.
- **`scan`** — the only target that touches `PROJECT_DIR`:
  - `gitnexus analyze <PROJECT_DIR>` — indexes that repo into a local
    knowledge graph, writing/updating `AGENTS.md` and `CLAUDE.md` there.
  - `caveman explore install --dir <PROJECT_DIR>` — installs Caveman's
    `explore` skill scoped to that one project (not globally).

## Cross-compiling rtk for other platforms

`rtk/Makefile` produces a binary for any of the three OSes regardless of
which one you're running on:

```bash
cd ~/sgoinfre/agent-tools/rtk
make linux    # dist/linux/rtk
make mac      # dist/mac/rtk        (arch auto-detected: arm64 vs x86_64)
make windows  # dist/windows/rtk.exe
make all      # all three
```

It is **not** a real cross-compiler: this machine has an old Rust toolchain
(1.75, rtk needs 1.91+) and no macOS SDK / MSVC toolchain, so true
cross-compilation from source isn't realistic here. Instead:

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

- `/home/<user>` on this machine is a small (~5GB) partition; it filled up
  twice while building this. Everything heavier than a symlink goes in
  `sgoinfre` (network share, terabytes free) for that reason.
- `npm-cache/` and `npm-global/` can be deleted and rebuilt any time via
  `make gitnexus` / `make caveman` again — nothing there is hand-edited.
