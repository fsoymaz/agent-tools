# rtk cross-platform build/fetch Makefile
#
# Strategy per target:
#   - If we are natively ON that OS *and* have a Rust toolchain that meets
#     the crate's rust-version (see Cargo.toml), build from source with cargo.
#   - Otherwise (cross-building, or no usable toolchain), download the
#     official prebuilt release asset from GitHub and verify it against
#     the published checksums.txt before using it. This is the same method
#     used to install rtk on this machine originally.
#
# Usage:
#   make linux     # produce dist/linux/rtk
#   make mac       # produce dist/mac/rtk        (arch auto-detected: arm64/x86_64)
#   make windows   # produce dist/windows/rtk.exe (always fetched: no cross MSVC toolchain here)
#   make all       # all three
#   make clean

VERSION      := 0.48.0
REPO         := rtk-ai/rtk
RELEASE_URL  := https://github.com/$(REPO)/releases/download/v$(VERSION)
DIST         := dist
UNAME_S      := $(shell uname -s)
UNAME_M      := $(shell uname -m)

# Minimum cargo/rustc version this crate declares (Cargo.toml: rust-version)
MIN_RUST     := $(shell grep '^rust-version' Cargo.toml | sed -E 's/.*"([0-9.]+)".*/\1/')

.PHONY: all linux mac windows clean check-checksum

all: linux mac windows

# --- Linux -------------------------------------------------------------
linux: $(DIST)/linux/rtk

$(DIST)/linux/rtk:
	mkdir -p $(DIST)/linux
ifeq ($(UNAME_S),Linux)
	@$(MAKE) --no-print-directory _try-cargo-build TARGET_DIR=$(DIST)/linux || \
		$(MAKE) --no-print-directory _fetch ASSET=rtk-x86_64-unknown-linux-musl.tar.gz OUT=$(DIST)/linux BIN=rtk
else
	@$(MAKE) --no-print-directory _fetch ASSET=rtk-x86_64-unknown-linux-musl.tar.gz OUT=$(DIST)/linux BIN=rtk
endif

# --- macOS ---------------------------------------------------------------
mac: $(DIST)/mac/rtk

$(DIST)/mac/rtk:
	mkdir -p $(DIST)/mac
ifeq ($(UNAME_S),Darwin)
	@$(MAKE) --no-print-directory _try-cargo-build TARGET_DIR=$(DIST)/mac || \
		$(MAKE) --no-print-directory _fetch-mac
else
	@$(MAKE) --no-print-directory _fetch-mac
endif

_fetch-mac:
ifeq ($(UNAME_M),arm64)
	@$(MAKE) --no-print-directory _fetch ASSET=rtk-aarch64-apple-darwin.tar.gz OUT=$(DIST)/mac BIN=rtk
else
	@$(MAKE) --no-print-directory _fetch ASSET=rtk-x86_64-apple-darwin.tar.gz OUT=$(DIST)/mac BIN=rtk
endif

# --- Windows -------------------------------------------------------------
# No mingw/MSVC cross toolchain is assumed to be present, so this always
# fetches the official prebuilt binary rather than attempting a cross build.
windows: $(DIST)/windows/rtk.exe

$(DIST)/windows/rtk.exe:
	mkdir -p $(DIST)/windows
	@$(MAKE) --no-print-directory _fetch ASSET=rtk-x86_64-pc-windows-msvc.zip OUT=$(DIST)/windows BIN=rtk.exe ZIP=1

# --- shared helpers --------------------------------------------------------

# Attempts a native cargo build; fails loudly (non-zero) if cargo is missing
# or older than the crate's declared rust-version, so the caller can fall
# back to _fetch.
_try-cargo-build:
	@command -v cargo >/dev/null 2>&1 || { echo "no cargo found"; exit 1; }
	@cur=$$(cargo --version | sed -E 's/cargo ([0-9.]+).*/\1/'); \
	 lowest=$$(printf '%s\n%s\n' "$$cur" "$(MIN_RUST)" | sort -V | head -1); \
	 if [ "$$lowest" != "$(MIN_RUST)" ]; then \
	   echo "cargo $$cur is older than required $(MIN_RUST), skipping source build"; exit 1; \
	 fi
	cargo build --release
	mkdir -p $(TARGET_DIR)
	cp target/release/rtk $(TARGET_DIR)/rtk

# Downloads + checksum-verifies an official release asset, extracts the
# single binary into OUT/BIN. ZIP=1 selects unzip instead of tar.
_fetch:
	@echo "Fetching $(ASSET) (rtk v$(VERSION)) ..."
	mkdir -p $(OUT)
	curl -sL -o /tmp/$(ASSET) $(RELEASE_URL)/$(ASSET)
	curl -sL -o /tmp/rtk-checksums.txt $(RELEASE_URL)/checksums.txt
	@expected=$$(grep " $(ASSET)$$" /tmp/rtk-checksums.txt | awk '{print $$1}'); \
	 actual=$$(sha256sum /tmp/$(ASSET) | awk '{print $$1}'); \
	 if [ "$$expected" != "$$actual" ]; then \
	   echo "CHECKSUM MISMATCH for $(ASSET): expected $$expected got $$actual"; exit 1; \
	 fi; \
	 echo "checksum OK"
ifdef ZIP
	unzip -o -q /tmp/$(ASSET) -d $(OUT)
else
	tar xzf /tmp/$(ASSET) -C $(OUT)
endif
	chmod +x $(OUT)/$(BIN)
	rm -f /tmp/$(ASSET) /tmp/rtk-checksums.txt

clean:
	rm -rf $(DIST)
