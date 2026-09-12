# PROGRESS — canlı hikaye

> Cursor ve Claude Code **aynı dosyayı** okur ve yazar. Oturum başında
> burayı aç; oturum sonunda veya kullanıcı “kaydet / devret / /progress”
> dediğinde güncelle. Şablonu silme. Git’ten okunabilen şeyi kopyalama.
>
> Araç kullanımı: `AGENTS.md`. Repo kuralları: `CLAUDE.md`.
> Alan notları: `handoffs/`. Mekanik snapshot: `.claude/handoffs/`.

**Son güncelleme:** 2026-09-12  
**Ajan:** Cursor  
**Durum:** çift-ajan okuma katmanı eklendi

## Tamamlanan

- `rtk`, GitNexus, Caveman Makefile ile kurulabilir (`amake all`).
- `scan` kasıtlı olarak CLAUDE.md üzerine yazabilir — bu repoda
  `gitnexus analyze --index-only` kullanılmalı.
- Claude Code için `CLAUDE.md` + `block-secrets` kancası var.
- `AGENTS.md`, `.cursorrules`, `PROGRESS.md`, `/progress` skill, Stop
  hatırlatması — Cursor ve Claude aynı hikayeyi görür.

## Yarım kalan

- Yok.

## Sıradaki

1. Yeni oturumda `PROGRESS.md` ile devam et — protokolü canlı tut.
2. Hook/MCP (`gitnexus setup` vb.) hâlâ onaysız kurulmaz.

## Tuzaklar

- `make scan` hedef repodaki `CLAUDE.md` / `AGENTS.md` dosyalarını ezer.
- rtk hook’u PATH’te çözülmezse her Bash kırılır; kurmadan önce `which rtk`.
- Vendor: `GitNexus/`, `rtk/`, `Agent-Context-Bootstrap-v1/` elle edit yok.
- Bash komut metninde yasak dosya adları kancayı düşürür; doküman için
  Edit/Write kullan.

## Açık sorular

- Yok.
