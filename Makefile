# agent-tools ana Makefile'ı
#
# rtk + GitNexus + Caveman araçlarını kurar ve `scan` hedefi aracılığıyla,
# bu Makefile'ı hangi proje klasöründen çalıştırdıysan GitNexus'un repo
# indeksleme özelliğini ve Caveman'ın "explore" skill'ini o projeye uygular.
#
# KONUM: Bu Makefile kendi bulunduğu dizini otomatik türetir (AGENT_TOOLS),
# yani agent-tools klasörünü nereye koyduğun önemli değil. Kolaylık olsun
# diye shell rc dosyanda bir kez tanımla (bkz. README.md):
#
#   export AGENT_TOOLS="$HOME/Desktop/agent-tools"   # kendi yolun
#   alias amake='make -f "$AGENT_TOOLS/Makefile"'
#
# Kullanım (HERHANGİ bir proje klasöründen, agent-tools'un içinden DEĞİL):
#   amake all                       # ya da: make -f "$AGENT_TOOLS/Makefile" all
#
# İşletim sistemine göre kurulum (rtk'yi o OS için derler/indirir, sonra
# gitnexus + caveman'ı kurar ve mevcut projeyi tarar):
#   amake linux      # Linux için
#   amake macos      # macOS için
#   amake windows    # Windows için
#
# Not: Hangi işletim sisteminden çalıştırırsan çalıştır, `linux`/`macos`/
# `windows` hedefleri o OS'a ait rtk binary'sini hedefler. Kendi işletim
# sistemin için derleme yapılabiliyorsa (native toolchain varsa) kaynak
# koddan derlenir; başka bir OS hedefleniyorsa (ör. Linux makineden
# `make windows`) GitHub'daki resmi, checksum doğrulamalı hazır binary
# indirilir (bkz. rtk/Makefile). `all` hedefi, çalıştığın makinenin OS'unu
# otomatik algılar ve ona göre kurar.
#
# Tek tek parçalar da çalıştırılabilir:
#   amake rtk        # sadece rtk (bu OS için)
#   amake gitnexus   # sadece gitnexus
#   amake caveman    # sadece caveman
#   amake scan       # gitnexus+caveman'ı PROJECT_DIR'a uygula
#
# ZATEN KURULU ARAÇLAR: rtk / gitnexus / caveman hedefleri, araç PATH'te
# zaten bulunuyorsa (ör. macOS'ta Homebrew ile kurulmuşsa) kurulumu ATLAR
# ve mevcut sürümü bildirir. Böylece PATH'te öncelikli olan bir kurulumu
# gölgeleyen, sessizce ölü kalan symlink'ler oluşmaz. Bu kontrolü devre
# dışı bırakıp bu repodaki kopyayı zorla kurmak için:
#   amake all FORCE_INSTALL=1
#
# PROJECT_DIR varsayılan olarak CURDIR'dır, yani `make`'i nereden
# çalıştırdıysan orası. Gerekirse elle değiştirebilirsin:
#   amake scan PROJECT_DIR=/baska/proje/yolu
#
# ÖNEMLİ: `scan`, PROJECT_DIR içine dosya yazar (AGENTS.md / CLAUDE.md,
# .claude/skills/, GitNexus'un yerel index veritabanı) ama kendi başına
# hiçbir Claude Code hook'u veya MCP sunucusu kaydetmez. `gitnexus setup`
# ve `caveman setup --install` bunu yapar ve bilerek `scan`'in altında,
# ayrı ve elle çalıştırılan adımlar olarak bırakılmıştır — ne yazdıklarını
# inceleyene kadar (bkz. README.md, "Hooks/MCP" bölümü) `all` hedefine
# DAHİL DEĞİLLER, kendin çalıştırman gerekiyor.

AGENT_TOOLS := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
LOCAL_BIN   := $(HOME)/.local/bin
NPM_CACHE   := $(AGENT_TOOLS)/npm-cache
NPM_PREFIX  := $(AGENT_TOOLS)/npm-global
PROJECT_DIR ?= $(CURDIR)

# Boş bırakılırsa zaten kurulu araçlar atlanır; FORCE_INSTALL=1 zorla kurar.
FORCE_INSTALL ?=

export NPM_CONFIG_CACHE  := $(NPM_CACHE)
export NPM_CONFIG_PREFIX := $(NPM_PREFIX)

# `scan` hangi binary'yi çağıracağını PATH'ten çözer; bulunamazsa kurulumun
# symlink'leyeceği yere düşer. Bu sayede araç zaten kuruluysa (ve kurulum
# adımı atlandıysa) scan yine de doğru binary'yi kullanır.
GITNEXUS := $(shell command -v gitnexus 2>/dev/null || echo $(LOCAL_BIN)/gitnexus)
CAVEMAN  := $(shell command -v caveman  2>/dev/null || echo $(LOCAL_BIN)/caveman)

UNAME_S := $(shell uname -s)

# Bu makinenin fiilen çalıştığı OS'u rtk'nin dist/ klasör adlarıyla
# (linux / mac / windows) eşleştiriyoruz. Git Bash / MSYS2 gibi Windows
# üzerindeki POSIX katmanları uname'de MINGW*/MSYS* döndürür.
ifeq ($(UNAME_S),Darwin)
HOST_RTK_OS := mac
else ifneq (,$(findstring MINGW,$(UNAME_S)))
HOST_RTK_OS := windows
else ifneq (,$(findstring MSYS,$(UNAME_S)))
HOST_RTK_OS := windows
else
HOST_RTK_OS := linux
endif

.PHONY: all linux macos windows rtk gitnexus caveman scan clean-npm-cache _rtk-os

# --- all: bu makinenin OS'unu otomatik algılayıp her şeyi kurar ---------
all: rtk gitnexus caveman scan

# --- OS'a özel kurulum hedefleri: rtk'yi o OS için hazırlar, sonra ------
# --- gitnexus + caveman'ı kurar ve PROJECT_DIR'ı tarar -------------------
linux: RTK_OS  := linux
linux: RTK_BIN := rtk
linux: _rtk-os gitnexus caveman scan
	@echo "Linux kurulumu tamamlandı."

macos: RTK_OS  := mac
macos: RTK_BIN := rtk
macos: _rtk-os gitnexus caveman scan
	@echo "macOS kurulumu tamamlandı."

windows: RTK_OS  := windows
windows: RTK_BIN := rtk.exe
windows: _rtk-os gitnexus caveman scan
	@echo "Windows kurulumu tamamlandı."

# --- rtk: bu Makefile'ı çalıştıran OS için derler/indirir ---------------
rtk: RTK_OS  := $(HOST_RTK_OS)
rtk: RTK_BIN := $(if $(filter windows,$(HOST_RTK_OS)),rtk.exe,rtk)
rtk: _rtk-os

# --- _rtk-os: RTK_OS / RTK_BIN parametreleriyle çağrılan asıl iş --------
# (linux/macos/windows/rtk hedeflerinin hepsi bunu kullanır, tekrar yok)
#
# Atlama kontrolü SADECE hedef OS bu makineninkiyle aynıysa çalışır: başka
# bir OS için binary üretmek (cross) bir "kurulum" değil, dist/ çıktısıdır,
# dolayısıyla PATH'te rtk olması onu atlamak için gerekçe değildir.
_rtk-os:
	mkdir -p $(LOCAL_BIN)
	@if [ -z "$(FORCE_INSTALL)" ] && [ "$(RTK_OS)" = "$(HOST_RTK_OS)" ] && command -v rtk >/dev/null 2>&1; then \
		if rtk gain >/dev/null 2>&1; then \
			echo "rtk zaten kurulu, atlanıyor: $$(command -v rtk) ($$(rtk --version))"; \
			echo "  (bu repodaki kopyayı yine de kurmak için: FORCE_INSTALL=1)"; \
			exit 0; \
		fi; \
		echo "UYARI: PATH'te bir 'rtk' var ($$(command -v rtk)) ama 'rtk gain' çalışmadı."; \
		echo "       Bu muhtemelen farklı bir araç (reachingforthejack/rtk - Rust Type Kit);"; \
		echo "       bu repodaki kopya kuruluyor."; \
	fi; \
	$(MAKE) -C $(AGENT_TOOLS)/rtk $(RTK_OS) && \
	ln -sf $(AGENT_TOOLS)/rtk/dist/$(RTK_OS)/$(RTK_BIN) $(LOCAL_BIN)/$(RTK_BIN) && \
	if [ "$(RTK_OS)" != "$(HOST_RTK_OS)" ]; then \
		echo "rtk ($(RTK_OS)) indirildi -> $(LOCAL_BIN)/$(RTK_BIN)"; \
		echo "  (bu makine $(HOST_RTK_OS) çalıştırdığı için bu binary burada test edilemez)"; \
	else \
		echo "rtk hazır: $$($(LOCAL_BIN)/$(RTK_BIN) --version)"; \
		RESOLVED="$$(command -v $(RTK_BIN) 2>/dev/null || true)"; \
		if [ -n "$$RESOLVED" ] && [ "$$RESOLVED" != "$(LOCAL_BIN)/$(RTK_BIN)" ]; then \
			echo "  UYARI: PATH'te önce $$RESOLVED geliyor, bu symlink gölgede kalıyor."; \
			echo "         Kurduğunu kullanmak için PATH'te $(LOCAL_BIN) önde olmalı."; \
		fi; \
	fi

# --- gitnexus: agent-tools/npm-global altına npm ile kurulur, symlink'lenir
gitnexus:
	mkdir -p $(LOCAL_BIN)
	@if [ -z "$(FORCE_INSTALL)" ] && command -v gitnexus >/dev/null 2>&1; then \
		echo "gitnexus zaten kurulu, atlanıyor: $$(command -v gitnexus) ($$(gitnexus --version))"; \
		echo "  (bu repodaki kopyayı yine de kurmak için: FORCE_INSTALL=1)"; \
	else \
		npm install -g gitnexus && \
		ln -sf $(NPM_PREFIX)/bin/gitnexus $(LOCAL_BIN)/gitnexus && \
		echo "gitnexus hazır: $$($(LOCAL_BIN)/gitnexus --version)"; \
	fi

# --- caveman: skill dosyaları (global, tüm agent/projeler) + CLI --------
caveman:
	mkdir -p $(LOCAL_BIN)
	@if [ -z "$(FORCE_INSTALL)" ] && command -v caveman >/dev/null 2>&1; then \
		echo "caveman zaten kurulu, atlanıyor: $$(command -v caveman) ($$(caveman --version))"; \
		echo "  (skill'leri tazelemek / bu kopyayı kurmak için: FORCE_INSTALL=1)"; \
	else \
		npx --yes skills add JuliusBrussee/caveman -g -a claude-code && \
		npm install -g @caveman-ai/cli && \
		ln -sf $(NPM_PREFIX)/bin/caveman $(LOCAL_BIN)/caveman && \
		echo "caveman hazır: $$($(LOCAL_BIN)/caveman --version)"; \
	fi

# --- scan: gitnexus indekslemesini + caveman'ın explore skill'ini -------
# --- PROJECT_DIR'a uygular -----------------------------------------------
scan:
	@test -d "$(PROJECT_DIR)" || { echo "PROJECT_DIR bulunamadı: $(PROJECT_DIR)"; exit 1; }
	@if [ -d "$(PROJECT_DIR)/.git" ]; then \
		$(GITNEXUS) analyze "$(PROJECT_DIR)"; \
	else \
		echo "$(PROJECT_DIR) bir git deposu değil, --skip-git ile devam ediliyor"; \
		$(GITNEXUS) analyze --skip-git "$(PROJECT_DIR)"; \
	fi
	$(CAVEMAN) explore install --dir "$(PROJECT_DIR)"
	@echo "$(PROJECT_DIR) tarandı."

clean-npm-cache:
	rm -rf $(NPM_CACHE)/*
