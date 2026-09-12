# AGENTS.md — Cursor + Claude Code ortak yönlendirici

Bu dosya **her iki ajan** için giriş noktasıdır. Claude Code ayrıca
`CLAUDE.md` yükler (tam kurallar orada). Cursor `AGENTS.md` + `.cursorrules`
+ `.cursor/rules/` yükler.

## Oturum protokolü (hafıza)

1. **Başla:** kök `PROGRESS.md` oku. Repo’yu tarama ile yeniden keşfetme.
2. **İş bitince / token bitmeden / kullanıcı kaydet-devret deyince:**
   `PROGRESS.md` güncelle (başlıkları koru). Skill: `/progress`.
3. Niyet notu isteğe bağlı: `.claude/handoffs/<utc>-note.md`.
4. Mekanik `*-auto.md` snapshot’larına dokunma; hikaye orada değil.

## Bu kutu nedir

`$AGENT_TOOLS` — varsayılan: makinedeki `agent-tools` dizini.
Giriş: kök `Makefile`. İnsan dokümanı: `README.md`.

```bash
export AGENT_TOOLS="${AGENT_TOOLS:-$HOME/Desktop/agent-tools}"
alias amake='make -f "$AGENT_TOOLS/Makefile"'
```

Herhangi bir proje klasöründen:

| Hedef | Ne yapar |
|---|---|
| `amake rtk` | rtk kur/atla |
| `amake gitnexus` | gitnexus kur/atla |
| `amake caveman` | caveman kur/atla |
| `amake scan` | **yıkıcı** — hedef `CLAUDE.md`/`AGENTS.md` ezebilir |
| `amake all` | kur + scan |

Bu repoda grafiği tazelemek için scan değil:

```bash
gitnexus analyze . --index-only
```

`gitnexus setup` / `caveman setup --install` **onaysız çalıştırma**.

## Araçları nasıl çağır

| Araç | Claude Code | Cursor |
|---|---|---|
| Repo grafiği | GitNexus **MCP** (`query`, `context`, `impact`, `trace`) | aynı MCP (`user-gitnexus`) |
| Grafik CLI | yalnız MCP yoksa `gitnexus query` | aynı |
| Terminal sıkıştırma | global rtk hook çoğu `cat/ls/grep` çevirir; pipe’ta `rtk read` | hook yok — `rtk read` / `rtk ls` **elle** |
| Kısa yanıt | caveman skill’leri | isteğe bağlı; zorunlu değil |

rtk hook boşlukları: pipe, döngü, `find`. Ölç: `rtk hook check "<komut>"`.

## Sert sınırlar

- Sır dosyalarına dokunma — `CLAUDE.md` bölüm 0.
- Vendor (`GitNexus/`, `rtk/`, `Agent-Context-Bootstrap-v1/`) edit yok.
- Üretilen `npm-cache/`, `npm-global/`, `rtk/dist/`, `bin/` elle edit yok.
- Commit/push kullanıcı istemeden yok.
