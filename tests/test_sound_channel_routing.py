#!/usr/bin/env python3
"""Guard explicit QA3 sound-channel routing against accidental Master fallback."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
CORE_FILE = ROOT / "QuestAnnounce.lua"
CONFIG_FILE = ROOT / "Config.lua"
LOCALIZATION_FILE = ROOT / "Localization.lua"
text = CORE_FILE.read_text(encoding="utf-8")
config_text = CONFIG_FILE.read_text(encoding="utf-8")
localization_text = LOCALIZATION_FILE.read_text(encoding="utf-8-sig")

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

if "local RAID_WARNING_FILE_DATA_ID = 567397" not in text:
    errors.append("raid warning FileDataID mapping is missing")

if "PlaySoundFile(RAID_WARNING_FILE_DATA_ID, playbackChannel)" not in text:
    errors.append("raid warning does not use channel-aware file playback")

if 'if playbackChannel ~= "Master"' not in text:
    errors.append("raid warning may fall back to Master on a non-Master channel")

if "QuestAnnounce:PlaySoundOnSelectedChannel(soundID, channel)" not in text:
    errors.append("sound playback is not centralised through the channel-aware helper")

for channel in ("SFX", "Ambience", "Dialog", "Music"):
    if f'["{channel}"]' not in text:
        errors.append(f"sound channel mapping missing: {channel}")

for key in (
    "Music channel requirement",
    "Progress sound 8959 master channel note",
):
    if f'L["{key}"]' not in config_text:
        errors.append(f"sound UI hint is not used: {key}")
    for locale in ("enUS", "deDE", "esMX", "esES", "frFR", "koKR", "ruRU", "zhCN", "zhTW", "ptBR"):
        locale_start = localization_text.find(f"QuestAnnounce_L.{locale} = {{")
        locale_end = localization_text.find("\nQuestAnnounce_L.", locale_start + 1)
        if locale_end < 0:
            locale_end = localization_text.find("\n-- Fallback", locale_start + 1)
        locale_block = localization_text[locale_start:locale_end]
        if f'["{key}"]' not in locale_block:
            errors.append(f"{locale}: missing sound UI hint {key!r}")

if errors:
    print("QA3 sound-channel routing check FAILED:")
    for error in errors:
        print(f" - {error}")
    sys.exit(1)

print("QA3 sound-channel routing check passed.")
