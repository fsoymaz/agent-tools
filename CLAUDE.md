# agent-tools — Claude Code kuralları

## 0. Sır dosyaları — MUTLAK YASAK

`.env` ve türevleri **hiçbir koşulda okunmaz, yazılmaz, kopyalanmaz, listelenmez.**

- Yasak yollar: `.env`, `.env.local`, `.env.development`, `.env.production`,
  `.env.test`, `.env.*.local`, ayrıca `*.pem`, `*.key`, `id_rsa*`,
  `.npmrc`, `.git-credentials`, `credentials`, `secrets.json`, `*.p12`.
- **`secrets/` klasörü ve içeriği** — her projede. Özellikle
  `secrets/*.user.txt`, `secrets/*.password.txt` gibi kimlik bilgisi
  dosyaları. Klasörün varlığını doğrulamak serbesttir (`test -d secrets`),
  içeriğini okumak veya listelemek değildir. **Boş** placeholder dosya
  oluşturmak serbest, içine **değer** yazmak yasak — boş dosya sır taşımaz.
- **`playwright/.auth/*.json`** — geçerli oturum token'ı taşır; bir saldırgan
  için şifreden farkı yoktur, aynı muameleyi görür.
- Bu yasak **araçtan bağımsızdır**: `Read` kadar `cat`, `head`, `tail`, `sed`,
  `grep`, `less`, `cp`, `source`, `env`, `printenv`, `xargs`, Python/Node script'i
  veya bir subagent üzerinden de yapılamaz. Dolaylı yol aramak da yasağa dahildir.
- Kullanıcı oturum içinde "oku" dese bile okunmaz. Yasağın kalkması için
  kullanıcının bu dosyadaki kuralı kendi elleriyle değiştirmesi gerekir.
- Sadece `.env.example`, `.env.sample`, `.env.template` okunabilir — bunlar
  şablondur, sır içermez.
- Bir değişkenin varlığını doğrulaman gerekiyorsa `.env.example`'a bak veya
  kullanıcıya sor; `.env`'i "sadece anahtar isimlerini görmek için" bile açma.
- Yanlışlıkla bir sır ekrana düşerse: değeri cevabında **tekrarlama**, dosyaya
  yazma, commit etme; kullanıcıyı uyar ve rotasyon öner.

**Zorlayıcı katman iki parçalıdır** ve ikisi de sadece kullanıcının isteğiyle
değişir — zayıflatma, devre dışı bırakma, "geçici olarak" kaldırma yok:

1. `.claude/settings.json` → `permissions.deny` (araç seviyesi ön kesme).
2. `.claude/hooks/block-secrets.py` → `PreToolUse` hook'u. Her `Bash`, `Read`,
   `Edit`, `Write`, `Glob`, `Grep` çağrısını inceler; komut metninde veya dosya
   yolunda sır kalıbı görürse çağrıyı exit 2 ile durdurur. Komutu yeniden
   yazmaz, beklenmedik girdide fail-open davranır (bkz. bölüm 4).

Yan etki: **Bash komut metninin içinde** bu dosya adlarını yazamazsın
(dokümantasyon yazarken bile). Böyle bir metin gerekiyorsa `Edit`/`Write`
aracını kullan — hook dosya *içeriğine* değil, yola ve komut metnine bakar.

## Devir ve hafıza

Cursor aynı yönlendirmeyi `AGENTS.md` + `.cursorrules` ile alır.

- **Başlangıç:** kök `PROGRESS.md` oku; vendor ve `npm-*` altına tarama.
- **Bitiş / “kaydet” / “devret” / `/progress`:** `PROGRESS.md` güncelle
  (Tamamlanan, Yarım kalan, Sıradaki, Tuzaklar). Skill:
  `.claude/skills/progress/SKILL.md`. `Stop` kancası hatırlatır, yazmaz.
- Alan notu: `handoffs/`. Mekanik snapshot: `.claude/handoffs/*-auto.md`.
- Araç çağrısı: `AGENTS.md` (Claude MCP vs Cursor; rtk hook boşlukları).

## 1. Bu repo nedir

AI coding agent'ları için yerel araç kutusu: **rtk** (terminal çıktısı sıkıştırma),
**GitNexus** (repo bilgi grafiği), **Caveman** (kısa yanıt + sıkıştırma proxy'si).
Giriş noktası kök `Makefile`'dır; ayrıntı için `README.md`.

## 2. Üretilen dizinler — elle düzenleme yok

`npm-cache/`, `npm-global/`, `rtk/dist/`, `rtk/target/`, `bin/` tamamen
Makefile üretimidir ve `.gitignore`'dadır. Buralara dosya yazma, buradaki
dosyaları düzeltme, commit'e dahil etme. Bozulduysa ilgili `make` hedefini
yeniden çalıştır.

## 3. Vendor klasörleri

`GitNexus/`, `rtk/`, `Agent-Context-Bootstrap-v1/` upstream klonlarıdır
(`Agent-Context-Bootstrap-v1/` kendi `.git`'ine sahip — iç içe repo).

- Bu klasörlerin içinde, kullanıcı açıkça istemedikçe kaynak kodu değiştirme.
- Kök dizinden `git add -A` / `git commit -a` çalıştırma; iç içe repo ve
  büyük vendor ağaçları yüzünden istenmeyen dosyaları yakalar. Yolları tek tek ver.
- Vendor içindeki `.claude/`, `.cursorrules`, `AGENTS.md`, `CLAUDE.md`
  dosyaları upstream'e aittir; bu repo adına onları düzenleme.

## 4. Hook / MCP kurulumu — otomatik ASLA

`gitnexus setup`, `caveman setup --install`, rtk hook kurucuları ve benzeri
"kendini agent yapılandırmana yazan" komutlar **açık onay olmadan çalıştırılmaz**
(`make all` / `make scan` de bunları bilerek çağırmaz).

Daha önce otomatik kurulan bir rtk hook'u her Bash komutunun başına PATH'te
çözülmeyen bir `rtk` ekledi ve tüm shell'i kırdı. Bu yüzden:

- Üretilen her hook'un `command` alanını kur**madan önce** oku.
- Komutu **etkileşimsiz** bir shell'de doğrula (`which <cmd>`), sadece kendi
  terminalinde değil.
- Yapılandırma dosyasını değiştirmeden önce yedekle.

## 5. `make scan` yıkıcıdır

`make scan` hedef repoda `gitnexus analyze` çalıştırır ve oradaki `CLAUDE.md`
ile `AGENTS.md` dosyalarını **üzerine yazar**. Çalıştırmadan önce:

- `PROJECT_DIR`'ın hangi dizin olduğunu kullanıcıya doğrulat (varsayılan `$CURDIR`).
- Hedefte mevcut `CLAUDE.md`/`AGENTS.md` varsa uyar; bu dosya da dahil.

Sadece grafiği kurmak istiyorsan `make scan`'i atla ve doğrudan çağır:

```bash
gitnexus analyze . --index-only     # hiçbir dosyaya dokunmaz
```

`--index-only` AGENTS.md / CLAUDE.md yazımını ve `.claude/skills/` kurulumunu
birlikte kapatır; `--skip-agents-md` sadece ilkini kapatır. Bu repoda doğru
olan `--index-only` — elle yazılmış bir CLAUDE.md var.

Kapsam `.gitnexusignore` ile daraltılır (`.gitignore` sözdizimi, negasyon
destekli). Bu repoda vendor klonları oradan dışlanmıştır; yoksa tek başına
`GitNexus/` 251M ile grafiği hiç dokunmayacağımız kodla doldurur.

## 6. Disk

`/home` küçük bir bölüm (~5GB) ve bu proje kurulurken iki kez doldu. Ağır
her şey `agent-tools/` altında kalır. Varsayılan npm global prefix'ine kurulum
yapma; npm çağrılarında repo içindeki `npm-cache/` + `npm-global/` kullan
(Makefile bunu `NPM_CONFIG_*` ile zaten ayarlıyor).

## 7. Git

- Kullanıcı istemedikçe commit/push yok.
- `main` üzerindeyken önce branch aç.
- `git push --force`, `reset --hard`, `clean -fdx` açık onay ister.
- `.claude/handoffs/` otomatik üretilir; elle düzenleme.

## 8. Üslup

- Makefile ve `.gitignore` yorumları Türkçe, `README.md` İngilizce. Bir dosyayı
  düzenlerken **o dosyanın** dilini sürdür.
- Shell script'lerde `set -euo pipefail`; `$AGENT_TOOLS` gibi yollar tırnak içinde.
- Kabuk komutlarının çıktısı `rtk` ile sıkıştırılır (global `RTK.md`); bir hedefin
  ham çıktısı lazımsa `rtk proxy <cmd>`.

## 9. rtk — hook'un kapsamı ve boşlukları

Global `PreToolUse` hook'u (`rtk hook claude`) Bash komutlarını otomatik yeniden
yazar. Hangi komutun dönüştüğü **rtk binary'sinin içinde** gömülüdür;
`~/.claude/settings.json`'da düzenlenecek bir komut listesi yoktur. Bir komutun
dönüşüp dönüşmediğini tahmin etme, ölç:

```bash
rtk hook check "<komut>"
```

Yakalananlar: `cat` / `head` / `tail` (→ `rtk read`), `ls`, `grep`, `wc`, `du`,
`git`. `&&` ve `;` ile zincirlenmiş komutları da taşır.

Üç yerde düşer — buralarda rtk'yi **elle** çağır:

- **Pipe**: `cat X | head -20` dönüşmez. Yerine `rtk read X --max-lines 20`.
- **Döngü / subshell**: `for f in *.md; do cat $f; done` dönüşmez.
- **`find`**: rtk'nin `find` alt komutu var ama hook tanımıyor; doğrudan
  `rtk find` yaz.

Heredoc'lar (`cat > dosya <<'EOF'`) bilerek dönüşmez — onlar yazma işlemidir,
olduğu gibi bırak. `python3`, `caveman`, `gitnexus`, `command -v` gibi rtk'nin
kapsamadığı binary'ler de normaldir.

Ölçüm notu: `rtk discover`'ın "missed savings" tablosu son 30 günü tarar, ama
global hook 2026-09-12'de kuruldu. O tarihten önceki satırlar geçmiş kayıptır,
mevcut bir sızıntı değil — kapsam boşluğu sanıp hook'u "düzeltmeye" kalkma.
Temiz adopsiyon oranı için `rtk gain --reset` sonrası ölç; proje bazlı görünüm
`rtk gain -p`, oturum bazlı adopsiyon `rtk session`.
