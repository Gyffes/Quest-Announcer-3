#!/usr/bin/env python3
"""Guard explicit QA3 sound-channel routing against accidental Master fallback."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
CORE_FILE = ROOT / "QuestAnnounce.lua"
text = CORE_FILE.read_text(encoding="utf-8")

errors = []
if 'function QuestAnnounce:GetPlaybackChannelForSound(_, channel)' not in text:
    errors.append("explicit sound-channel pass-through helper is missing")

master_override = re.compile(
    r'GetPlaybackChannelForSound\s*\([^)]*\).*?'
    r'(?:soundID|\bid\b).*?==\s*8959.*?return\s+["\']Master["\']',
    re.DOTALL,
)
if master_override.search(text):
    errors.append("sound ID 8959 still forces playback through Master")

for channel in ("SFX", "Ambience", "Dialog", "Music"):
    if f'["{channel}"]' not in text:
        errors.append(f"sound channel mapping missing: {channel}")

if errors:
    print("QA3 sound-channel routing check FAILED:")
    for error in errors:
        print(f" - {error}")
    sys.exit(1)

print("QA3 sound-channel routing check passed.")
