#!/usr/bin/env python3
"""Verify that every QA3 locale defines every visible localization key."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
LOCALIZATION_FILE = ROOT / "Localization.lua"
text = LOCALIZATION_FILE.read_text(encoding="utf-8-sig")

blocks = {}
for match in re.finditer(r"QuestAnnounce_L\.([A-Za-z0-9_]+)\s*=\s*\{", text):
    locale = match.group(1)
    next_match = re.search(r"\nQuestAnnounce_L\.[A-Za-z0-9_]+\s*=\s*\{|\n-- Fallback", text[match.end():])
    end = match.end() + next_match.start() if next_match else len(text)
    blocks[locale] = set(re.findall(r'\["([^"]+)"\]\s*=', text[match.start():end]))

base = blocks.get("enUS", set())
errors = []
for locale, keys in sorted(blocks.items()):
    if locale == "enUS":
        continue
    missing = sorted(base - keys)
    if missing:
        errors.append(f"{locale}: missing {len(missing)} keys")

if errors:
    print("QA3 localization completeness check FAILED:")
    for error in errors:
        print(f" - {error}")
    sys.exit(1)

print(f"QA3 localization completeness check passed ({len(blocks)} locales, {len(base)} keys).")
