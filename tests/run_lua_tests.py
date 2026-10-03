"""Execute addon Lua under Lua 5.1 mocks; this does not emulate WoW rendering."""
import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".test-tools" / "python"))
try:
    from lupa.lua51 import LuaRuntime
except ImportError as exc:
    raise SystemExit("Lua tests require Python and: pip install -r tests/requirements.txt") from exc

os.chdir(ROOT)
matrix = json.loads((ROOT / "tests/client_matrix.json").read_text(encoding="utf-8"))
locales = ("enUS", "deDE", "esES", "esMX", "frFR", "koKR", "ptBR", "ruRU", "zhCN", "zhTW")
files = ("Localization.lua", "QuestAnnounce.lua", "Config.lua", "Minimap.lua")
checks = 0
for client in matrix["clients"]:
    for locale in locales:
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.globals().TEST_LOCALE = locale
        lua.globals().TEST_CLIENT = client["id"]
        lua.globals().TEST_INTERFACE = client["interface"]
        lua.execute((ROOT / "tests/mock_wow.lua").read_text(encoding="utf-8"))
        for filename in files:
            lua.execute((ROOT / filename).read_text(encoding="utf-8"), name=filename)
        lua.execute((ROOT / "tests/test_tooltip_fonts.lua").read_text(encoding="utf-8"))
        lua.execute((ROOT / "tests/test_quest_safety.lua").read_text(encoding="utf-8"))
        checks += 1
print(f"Lua 5.1 runtime tests passed: {checks} client-family/locale combinations, font fallbacks, UI callbacks, profiles, quest events and combat replay. Glyph rendering and real client APIs require in-game tests.")
