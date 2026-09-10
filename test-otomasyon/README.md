# test-otomasyon

Bu klasör, Playwright tabanlı UI + API test otomasyon sistemi için
**örnek/taslak** subagent tanımlarını içeriyor. Gerçek otomasyon kodu
(test dosyaları, Playwright config, CI workflow'ları) ayrı bir repoda
yazılacak — burası sadece o repoya taşınacak `.claude/agents/` iskeleti.

## İçerik

```
.claude/agents/
├── test-writer.md     — yeni Playwright test yazar (UI + API)
├── flaky-triage.md     — kararsız/flaky testlerin kök nedenini bulur
└── test-reviewer.md    — test PR'larını hız/izolasyon/flakiness açısından review eder
```

## Nasıl devreye alınır

1. Bu `.claude/agents/` klasörünü gerçek otomasyon repo'sunun köküne
   kopyala.
2. İçindeki tier limitleri, dizin yolları (`tests/ui/`, `tests/api/`) ve
   kuralları o repo'nun gerçek yapısına göre güncelle.
3. Claude Code o repoda çalışırken, ilgili görev geldiğinde bu subagent'lar
   otomatik devreye girer (`description` alanına göre eşleşir) — elle
   `subagent_type` belirtmene gerek yok, ama istersen açıkça da
   çağırabilirsin.

## Henüz karara bağlanmamış konular

Ana konuşmadan (agent-tools repo'sundaki sohbet geçmişi) taşınan, hâlâ
netleşmemiş iki karar:

- **Test seçim stratejisi**: `@smoke` / `@regression` tag'leriyle mi
  gidilecek, yoksa değişen dosya/alana göre otomatik test seçimi
  (impact-based selection) mi kurulacak?
- **Repo-arası gate mimarisi**: ürün repo'sunun deploy pipeline'ı bu
  otomasyon repo'sunu nasıl tetikleyecek — reusable GitHub Actions
  workflow (`workflow_call`) mu, `repository_dispatch` mı?

Bu ikisi netleşince, `test-writer.md`'deki tier kuralları ve CI entegrasyon
detayları buna göre güncellenmeli.
