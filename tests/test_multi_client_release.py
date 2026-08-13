#!/usr/bin/env python3
"""Verify that every supported WoW client package stays release-compatible."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
TOC_FILES = (
    "QuestAnnounce_Mainline.toc",
    "QuestAnnounce_Classic.toc",
    "QuestAnnounce_ClassicEra.toc",
    "QuestAnnounce_TBC.toc",
    "QuestAnnounce-Wrath.toc",
    "QuestAnnounce_Cataclysm.toc",
    "QuestAnnounce_MoP.toc",
    "QuestAnnounce_Hardcore.toc",
    "QuestAnnounce_Anniversary.toc",
    "QuestAnnounce_SeasonOfDiscovery.toc",
)
REQUIRED_LUA_FILES = (
    "Localization.lua",
    "QuestAnnounce.lua",
    "Config.lua",
    "Minimap.lua",
)

versions = {}
errors = []
for toc_name in TOC_FILES:
    path = ROOT / toc_name
    if not path.is_file():
        errors.append(f"missing TOC: {toc_name}")
        continue

    text = path.read_text(encoding="utf-8-sig")
    version = re.search(r"^## Version:\s*(.+)$", text, re.MULTILINE)
    if not version:
        errors.append(f"{toc_name}: missing version")
    else:
        versions[toc_name] = version.group(1).strip()

    for lua_name in REQUIRED_LUA_FILES:
        if re.search(rf"^{re.escape(lua_name)}$", text, re.MULTILINE) is None:
            errors.append(f"{toc_name}: missing shared file {lua_name}")

if len(set(versions.values())) != 1:
    errors.append(f"TOC version mismatch: {versions}")

if errors:
    print("QA3 multi-client release check FAILED:")
    for error in errors:
        print(f" - {error}")
    sys.exit(1)

version = next(iter(versions.values()))
print(f"QA3 multi-client release check passed ({len(TOC_FILES)} WoW variants, version {version}).")
