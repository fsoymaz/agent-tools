---
name: progress
description: >
  PROGRESS.md canlı hikayeyi güncelle. Kullanıcı /progress, kaydet, devret,
  oturumu kapat, token bitiyor dediğinde, uzun sıkıştırma öncesi veya iş
  parçası başka oturuma geçecekse.
---

# PROGRESS.md güncelle

Kod tabanını yeniden keşfetme. Git’ten okunabilen şeyi yazma.

1. Kök `PROGRESS.md` yoksa aşağıdaki şablonla oluştur.
2. Varsa **aynı başlıkları koruyarak** güncelle; 80 satırı geçme.
3. `Son güncelleme` tarihini ve ajan adını (Claude Code / Cursor) yaz.
4. Kullanıcı açıkça istemedikçe commit yok.
5. İsteğe bağlı niyet notu: `.claude/handoffs/YYYY-MM-DDTHH-MM-SS-note.md`
   (UTC). Mekanik `*-auto.md` dosyalarına dokunma.

## Şablon

```markdown
# PROGRESS — canlı hikaye

**Son güncelleme:** YYYY-MM-DD
**Ajan:** Claude Code | Cursor
**Durum:** bir cümle

## Tamamlanan
- …

## Yarım kalan
- dosya:satır ve tam olarak nerede kesildi

## Sıradaki
1. tek, somut adım

## Tuzaklar
- denenip vazgeçilen veya yanıltıcı varsayım

## Açık sorular
- …
```
