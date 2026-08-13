#!/usr/bin/env python3
"""Static isolation regression checks for Quest Announce 3.

The checks intentionally focus on shared Blizzard UI/API state. QA3 may create and
modify its own frames, but it must not patch globally shared Blizzard frames,
tooltips, dropdown lists, or API tables.
"""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
LUA_FILES = sorted(ROOT.glob("*.lua"))

# Patterns that represent writes/hooks against shared Blizzard UI internals.
FORBIDDEN = {
    "shared DropDownList access": re.compile(r'_G\s*\[\s*["\']DropDownList'),
    "global ToggleDropDownMenu hook": re.compile(r'hooksecurefunc\s*\(\s*["\']ToggleDropDownMenu["\']'),
    "direct GameTooltip mutation": re.compile(r'\bGameTooltip\s*:\s*(?:Set|HookScript|Hide|Show|Clear)'),
    "direct WorldMapFrame mutation": re.compile(r'\bWorldMapFrame\s*:\s*(?:Set|HookScript|Hide|Show|Clear)'),
    "direct QuestFrame mutation": re.compile(r'\bQuestFrame\s*:\s*(?:Set|HookScript|Hide|Show|Clear)'),
    "C_QuestLog table write": re.compile(r'\bC_QuestLog\s*\.\s*[A-Za-z_][A-Za-z0-9_]*\s*='),
    "C_QuestLog compatibility alias": re.compile(r'local\s+QA_QuestLog\s*=\s*C_QuestLog\s+or\s+\{\}'),
    "unnamespaced leave-channel popup": re.compile(r'["\']CONFIRM_LEAVE_CHANNEL["\']'),
    "unnamespaced missing-channel popup": re.compile(r'["\']MISSING_CHANNEL_NAME["\']'),
}

# Named addon-owned tooltip frames are allowed and expected.
OWNED_TOOLTIP_NAMES = {"QuestAnnounceTooltip", "QuestAnnounceConfigTooltip"}

errors = []
for path in LUA_FILES:
    text = path.read_text(encoding="utf-8")
    for label, pattern in FORBIDDEN.items():
        for match in pattern.finditer(text):
            line = text.count("\n", 0, match.start()) + 1
            errors.append(f"{path.name}:{line}: {label}: {match.group(0)!r}")

    # Catch named GameTooltip instances that are not explicitly QA3-owned.
    for match in re.finditer(
        r'CreateFrame\s*\(\s*["\']GameTooltip["\']\s*,\s*["\']([^"\']+)["\']',
        text,
    ):
        name = match.group(1)
        if name not in OWNED_TOOLTIP_NAMES:
            line = text.count("\n", 0, match.start()) + 1
            errors.append(
                f"{path.name}:{line}: non-QA3 named tooltip frame {name!r}"
            )

if errors:
    print("QA3 taint/isolation regression check FAILED:\n")
    for error in errors:
        print(f" - {error}")
    sys.exit(1)

print(f"QA3 taint/isolation regression check passed ({len(LUA_FILES)} Lua files scanned).")
