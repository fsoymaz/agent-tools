#!/usr/bin/env python3
"""Stop hook: oturum kapanirken PROGRESS.md hatirlatmasi.

Komutu yeniden yazmaz, durmayi bloklamaz. stop_hook_active ise sessiz cikar
(dongu yok). Hikayeyi bu script yazamaz; onu model PROGRESS.md'ye yazar.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path


def main() -> int:
    raw = sys.stdin.read()
    try:
        payload = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        return 0

    if payload.get("stop_hook_active"):
        return 0

    root = Path(os.environ.get("CLAUDE_PROJECT_DIR") or payload.get("cwd") or ".")
    progress = root / "PROGRESS.md"
    if not progress.is_file():
        return 0

    json.dump(
        {
            "systemMessage": (
                "Oturum duruyor. PROGRESS.md guncel mi bak: tamamlanan, yarim, "
                "siradaki, tuzaklar. Degilse kapanmadan once yaz. Kullanici "
                "istemedikce commit yok."
            )
        },
        sys.stdout,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
