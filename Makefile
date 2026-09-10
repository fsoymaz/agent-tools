# agent-tools ana Makefile'ı
#
# rtk + GitNexus + Caveman araçlarını kurar (hepsi fiilen sgoinfre altında
# yaşar, ~/.local/bin içine sadece ince sembolik linkler (symlink) konur)
# ve `scan` hedefi aracılığıyla, bu Makefile'ı hangi proje klasöründen
# çalıştırdıysan GitNexus'un repo indeksleme özelliğini ve Caveman'ın
# "explore" skill'ini o projeye uygular.
#
# Kullanım (HERHANGİ bir proje klasöründen, agent-tools'un içinden DEĞİL):
#   make -f ~/sgoinfre/agent-tools/Makefile all
#
# ya da README.md'deki alias'ı shell rc dosyana eklediysen:
#   amake all
#
# İşletim sistemine göre kurulum (rtk'yi o OS için derler/indirir, sonra
# gitnexus + caveman'ı kurar ve mevcut projeyi tarar):
#   make -f ~/sgoinfre/agent-tools/Makefile linux    # Linux için
#   make -f ~/sgoinfre/agent-tools/Makefile macos    # macOS için
#   make -f ~/sgoinfre/agent-tools/Makefile windows  # Windows için
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
#   make -f ~/sgoinfre/agent-tools/Makefile rtk        # sadece rtk (bu OS için)
#   make -f ~/sgoinfre/agent-tools/Makefile gitnexus   # sadece gitnexus
#   make -f ~/sgoinfre/agent-tools/Makefile caveman    # sadece caveman
#   make -f ~/sgoinfre/agent-tools/Makefile scan       # gitnexus+caveman'ı PROJECT_DIR'a uygula
#
# PROJECT_DIR varsayılan olarak CURDIR'dır, yani `make`'i nereden
# çalıştırdıysan orası. Gerekirse elle değiştirebilirsin:
#   make -f ~/sgoinfre/agent-tools/Makefile scan PROJECT_DIR=/baska/proje/yolu
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

export NPM_CONFIG_CACHE  := $(NPM_CACHE)
export NPM_CONFIG_PREFIX := $(NPM_PREFIX)

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
_rtk-os:
	mkdir -p $(LOCAL_BIN)
	$(MAKE) -C $(AGENT_TOOLS)/rtk $(RTK_OS)
	ln -sf $(AGENT_TOOLS)/rtk/dist/$(RTK_OS)/$(RTK_BIN) $(LOCAL_BIN)/$(RTK_BIN)
	@if [ "$(RTK_OS)" = "$(HOST_RTK_OS)" ]; then \
		echo "rtk hazır: $$($(LOCAL_BIN)/$(RTK_BIN) --version)"; \
	else \
		echo "rtk ($(RTK_OS)) indirildi -> $(LOCAL_BIN)/$(RTK_BIN)"; \
		echo "  (bu makine $(HOST_RTK_OS) çalıştırdığı için bu binary burada test edilemez)"; \
	fi

# --- gitnexus: agent-tools/npm-global altına npm ile kurulur, symlink'lenir
gitnexus:
	mkdir -p $(LOCAL_BIN)
	npm install -g gitnexus
	ln -sf $(NPM_PREFIX)/bin/gitnexus $(LOCAL_BIN)/gitnexus
	@echo "gitnexus hazır: $$($(LOCAL_BIN)/gitnexus --version)"

# --- caveman: skill dosyaları (global, tüm agent/projeler) + CLI --------
caveman:
	mkdir -p $(LOCAL_BIN)
	npx --yes skills add JuliusBrussee/caveman -g -a claude-code
	npm install -g @caveman-ai/cli
	ln -sf $(NPM_PREFIX)/bin/caveman $(LOCAL_BIN)/caveman
	@echo "caveman hazır: $$($(LOCAL_BIN)/caveman --version)"

# --- scan: gitnexus indekslemesini + caveman'ın explore skill'ini -------
# --- PROJECT_DIR'a uygular -----------------------------------------------
scan:
	@test -d "$(PROJECT_DIR)" || { echo "PROJECT_DIR bulunamadı: $(PROJECT_DIR)"; exit 1; }
	@if [ -d "$(PROJECT_DIR)/.git" ]; then \
		$(LOCAL_BIN)/gitnexus analyze "$(PROJECT_DIR)"; \
	else \
		echo "$(PROJECT_DIR) bir git deposu değil, --skip-git ile devam ediliyor"; \
		$(LOCAL_BIN)/gitnexus analyze --skip-git "$(PROJECT_DIR)"; \
	fi
	$(LOCAL_BIN)/caveman explore install --dir "$(PROJECT_DIR)"
	@echo "$(PROJECT_DIR) tarandı."

clean-npm-cache:
	rm -rf $(NPM_CACHE)/*
