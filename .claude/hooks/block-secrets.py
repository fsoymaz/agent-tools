#!/usr/bin/env python3
"""PreToolUse hook: sir dosyalarina (.env vb.) her turlu erisimi engeller.

Tasarim notu: bu hook komutu ASLA yeniden yazmaz, sadece inceler. Beklenmedik
her durumda exit 0 ile gecer (fail-open) -- amac calismayi kirmak degil, bilinen
sir dosyalarini durdurmak. Bkz. CLAUDE.md bolum 0 ve 4.
"""
import json
import re
import sys

# .env.example / .env.sample / .env.template serbest; geri kalan her sey yasak.
SAFE = re.compile(r"\.env[\w.-]*\.(example|sample|template|dist)\b", re.I)

PATTERNS = [
    r"(^|[^\w-])\.env($|[^\w-])",
    r"(^|[^\w-])\.env\.[\w.-]+",
    r"\.envrc\b",
    r"\bid_rsa\b", r"\bid_ed25519\b",
    r"\.git-credentials\b",
    r"\.npmrc\b",
    r"\bsecrets\.json\b",
    r"\.(pem|p12|pfx)\b",
]
RX = [re.compile(p, re.I) for p in PATTERNS]

def hits(text: str) -> bool:
    if not text:
        return False
    scrubbed = SAFE.sub(" ", text)
    return any(r.search(scrubbed) for r in RX)

def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0  # fail-open

    ti = payload.get("tool_input") or {}
    if not isinstance(ti, dict):
        return 0

    # Bash: komut metni. Dosya araclari: file_path / path / notebook_path.
    candidates = [
        ti.get("command"), ti.get("file_path"), ti.get("path"),
        ti.get("notebook_path"), ti.get("pattern"),
    ]
    for c in candidates:
        if isinstance(c, str) and hits(c):
            print(
                "ENGELLENDI: sir dosyasi erisimi (.env / anahtar / kimlik bilgisi). "
                "CLAUDE.md bolum 0 bunu kosulsuz yasaklar. Sablon gerekiyorsa "
                ".env.example dosyasini oku, degisken degeri gerekiyorsa kullaniciya sor. "
                "Bu kontrolu atlatmaya calisma.",
                file=sys.stderr,
            )
            return 2  # 2 = arac cagrisini blokla, stderr Claude'a gider
    return 0

if __name__ == "__main__":
    sys.exit(main())
