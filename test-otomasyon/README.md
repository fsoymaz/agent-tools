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

---

## Durum: devreye alındı (2026-09-12)

Bu taslaklar `~/Desktop/bimasraf-e2e/.claude/agents/` altına **uyarlanarak**
taşındı. Kopya değil — gerçek mimariye göre yeniden yazıldı:

| Buradaki taslak | Oradaki karşılığı | Başlıca fark |
|---|---|---|
| `test-writer.md` | `test-yazar.md` | Gherkin-önce sıra; `data-testid` yerine `formcontrolname` |
| `flaky-triage.md` | `flaky-dedektif.md` | Yaşanmış üç SPA tuzağı eklendi |
| `test-reviewer.md` | `test-gozden-gecirici.md` | Katman disiplini + gezinme bloğu + sır güvenliği kontrolleri |

**Kurallar oradan yönetilir, buradan değil.** Claude Code ajan ve kural
dosyalarını çalıştığı proje dizininden yükler; `bimasraf-e2e` içinde
çalışırken bu klasör devrede değildir. Buradaki dosyalar artık tarihsel
taslaktır — değiştirilmesi otomasyon repo'sunu etkilemez.

`test-writer.md`'deki "`data-testid` kullan" kuralı bu uygulama için
**yanlış çıktı**: panel Angular + PrimeNG ve `data-testid` taşımıyor.
Doğrusu `formcontrolname`. Başka bir repoya kopyalamadan önce o kuralı
hedef uygulamaya göre doğrula.

Ayrıca README'nin "henüz karara bağlanmamış" iki konusundan biri kapandı:
test seçimi **etiket tabanlı** (`@smoke` / `@regresyon` / `@kritik`).
Repo-arası gate mimarisi hâlâ açık.
