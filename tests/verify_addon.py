"""Portable verification and optional RC packaging; no PowerShell dependency."""
import argparse
import ast
import hashlib
import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CORE_FILES = ("Localization.lua", "QuestAnnounce.lua", "Config.lua", "Minimap.lua")
LOCALES = ("enUS", "deDE", "esES", "esMX", "frFR", "koKR", "ptBR", "ruRU", "zhCN", "zhTW")


def read(name):
    return (ROOT / name).read_text(encoding="utf-8-sig")


def require(condition, message):
    if not condition:
        raise ValueError(message)


def verify_metadata(matrix):
    expected = {"QuestAnnounce.toc"}
    base = read("QuestAnnounce.toc")
    for client in matrix["clients"]:
        interfaces = client.get("interfaces", [client["interface"]])
        interface_text = ", ".join(map(str, interfaces))
        for filename in [client["toc"], *client["aliases"]]:
            require(filename not in expected, f"Duplicate TOC in client matrix: {filename}")
            expected.add(filename)
            lines = read(filename).splitlines()
            require(f"## Interface: {interface_text}" in lines, f"Wrong interfaces: {filename}")
            require(f"## X-Interface: {client['interface']}" in lines, f"Wrong current interface: {filename}")
        flavor = "Vanilla" if client["id"] == "Classic" else client["id"]
        require(f"## Interface-{flavor}: {interface_text}" in base.splitlines(), f"Missing universal flavor: {flavor}")
    require(expected == {p.name for p in ROOT.glob("*.toc")}, "TOC list differs from complete client matrix")
    for filename in expected:
        lines = read(filename).splitlines()
        loaded = tuple(line for line in lines if line.strip() and not line.startswith("#"))
        require(loaded == CORE_FILES, f"Changed core load order: {filename}")
        require("## SavedVariables: QuestAnnounceDB" in lines, f"Changed SavedVariables: {filename}")
        require(f"## Version: {matrix['addonVersion']}" in lines, f"Changed addon version: {filename}")
    print(f"Client metadata passed: {len(expected)} TOCs, complete aliases and canonical flavors.")


def verify_localizations(sources):
    values, locale = {}, None
    for line in sources["Localization.lua"].splitlines():
        match = re.match(r"^QuestAnnounce_L\.([A-Za-z]{4})\s*=\s*\{", line)
        if match:
            locale = match[1]
            require(locale not in values, f"Duplicate locale table: {locale}")
            values[locale] = {}
        match = re.match(r'^\s*\["(.*)"\]\s*=\s*"(.*)"\s*,?\s*\}?\s*$', line)
        if match and locale:
            key, value = match.groups()
            require(key not in values[locale], f"Duplicate key in {locale}: {key}")
            values[locale][key] = value
    require(set(values) == set(LOCALES), "Locale table list differs from supported locales")
    base = values["enUS"]
    tokens = re.compile(r"(?<!%)%(?:\d+\$)?[-+0 #]*\d*(?:\.\d+)?[cdeEfgGiouqsxX]")
    for locale in LOCALES:
        require(values[locale].keys() == base.keys(), f"Missing or extra keys: {locale}")
        for key, value in base.items():
            require(sorted(tokens.findall(value)) == sorted(tokens.findall(values[locale][key])),
                    f"Different format placeholders: {locale}, {key}")
    used = set()
    for name in ("QuestAnnounce.lua", "Config.lua", "Minimap.lua"):
        used.update(re.findall(r'(?<![A-Za-z0-9_])L\["([^"\r\n]+)"\]', sources[name]))
    require(used <= base.keys(), f"Undefined localization keys: {used - base.keys()}")
    require("setmetatable(localeTable, { __index = fallback })" in sources["Localization.lua"],
            "The enUS runtime fallback is missing")
    print(f"Localizations passed: {len(values)} locales, {len(base)} keys each, matching placeholders.")


def verify_source_contracts(sources, matrix):
    core = sources["QuestAnnounce.lua"]
    contexts = {"core": core, "config": sources["Config.lua"],
                "allAddonCode": core + "\n" + sources["Config.lua"]}
    sections = {
        "restrictionSection": ("IsChatSendRestricted(chatType)", "GetChannelNameSafe(channelName)"),
        "queueSection": ("QueuePendingCombatChatMessage(msg)", "FlushPendingCombatChatMessage()"),
        "flushSection": ("FlushPendingCombatChatMessage()", "DispatchChatOutputs(msg, allowCombatQueue)"),
        "dispatchSection": ("DispatchChatOutputs(msg, allowCombatQueue)", "SendMsg(msg, isComplete, soundOverrideEvent)"),
    }
    for name, (start, end) in sections.items():
        pattern = r"function QuestAnnounce:" + re.escape(start) + r".*?(?=function QuestAnnounce:" + re.escape(end) + ")"
        match = re.search(pattern, core, re.S)
        require(match is not None, f"Missing function section: {name}")
        contexts[name] = match[0]
    contracts = json.loads(read("tests/source_contracts.json"))
    for contract in contracts:
        matched = bool(re.search(contract["pattern"], contexts[contract["source"]], re.S))
        require(matched == contract["present"], contract["message"])
    production = "\n".join(sources.values())
    require(not re.search(r"FOR_TAINT_TEST|diagnosticMode|linkHandlerMode|cinematic taint A/B test|^\s*--\s*(?:TODO|FIXME|HACK|XXX)\b",
                          production, re.M), "Temporary diagnostics or unfinished maintenance comments remain")
    require(not re.search(r"^\s*--\s*(?:local\s+)?function\s+QuestAnnounce[:.]", production, re.M),
            "Commented-out QuestAnnounce functions remain")
    for helper in ("GetTooltipFontPath", "GetTooltipFontSelection", "GetTooltipFontChoices", "ApplyTooltipLineFont"):
        require(len(re.findall(r"function QuestAnnounce:" + helper + r"\(", core)) == 1,
                f"Missing or duplicate shared font helper: {helper}")
    for name in ("Config.lua", "Minimap.lua"):
        require(not re.search(r"ResolveTooltipFontPath|ResolveTooltipFontLabel|Fonts\\\\|STANDARD_TEXT_FONT", sources[name])
                and ":ApplyTooltipLineFont(" in sources[name], f"Shared font policy bypassed: {name}")
    require(matrix["releaseTag"] in read("README.md"), "README is missing the RC tag")
    header = f"v{matrix['addonVersion']} Multi (RC1) - 03-10-2026"
    require(header in read("CHANGELOG.txt").splitlines(), "Changelog is missing the RC header")
    for filename in (ROOT / "tests").glob("*.py"):
        ast.parse(filename.read_text(encoding="utf-8-sig"), filename=str(filename))
    print(f"Source contracts passed: {len(contracts)} quest/chat/taint safety assertions and shared font policy.")


def package_files():
    files = [ROOT / name for name in (*CORE_FILES, "CHANGELOG.txt", "README.md", "CLIENT_VERSIONS.md",
                                     "COMMUNITY_FIX_PLAN.md", "RELEASE_NOTES_V9.3.0.10-RC1.md")]
    return sorted([*files, *ROOT.glob("*.toc"), *(p for p in (ROOT / "Media").rglob("*") if p.is_file())])


def verify_archive(archive_path):
    expected = {p.relative_to(ROOT).as_posix(): p for p in package_files()}
    with zipfile.ZipFile(archive_path) as archive:
        actual = []
        for entry in archive.infolist():
            name = entry.filename.replace("\\", "/")
            require(name.startswith("QuestAnnounce/") and ".." not in name.split("/") and ":" not in name,
                    f"Unsafe or wrong addon root: {name}")
            if entry.is_dir():
                continue
            relative = name[len("QuestAnnounce/"):]
            actual.append(relative)
            require(relative in expected, f"Unexpected package entry: {relative}")
            require(archive.read(entry) == expected[relative].read_bytes(), f"Archive differs from source: {relative}")
        require(sorted(actual) == sorted(expected), "Incomplete or duplicate archive entries")
    digest = hashlib.sha256(archive_path.read_bytes()).hexdigest()
    checksum = Path(str(archive_path) + ".sha256").read_text(encoding="ascii").strip()
    require(checksum == f"{digest}  {archive_path.name}", "Invalid release checksum")
    print(f"RC archive passed: {len(expected)} source-identical files, correct root and SHA256; no test tools.")


def build_package(matrix):
    dist = (ROOT / "dist").resolve()
    require(dist.is_relative_to(ROOT), "Release directory is outside the repository")
    archive_path = dist / f"QuestAnnounce-3-{matrix['releaseTag']}.zip"
    checksum_path = Path(str(archive_path) + ".sha256")
    require(not archive_path.exists() and not checksum_path.exists(), "Existing RC outputs will not be overwritten")
    dist.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive_path, "x", compression=zipfile.ZIP_DEFLATED) as archive:
        for filename in package_files():
            archive.write(filename, "QuestAnnounce/" + filename.relative_to(ROOT).as_posix())
    digest = hashlib.sha256(archive_path.read_bytes()).hexdigest()
    with checksum_path.open("x", encoding="ascii") as checksum:
        checksum.write(f"{digest}  {archive_path.name}\n")
    verify_archive(archive_path)
    print(f"RC package: {archive_path}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", action="store_true", help="Build a new RC ZIP and checksum after verification")
    parser.add_argument("--verify-archive", type=Path, help="Check an existing ZIP against current sources")
    args = parser.parse_args()
    matrix = json.loads(read("tests/client_matrix.json"))
    sources = {name: read(name) for name in CORE_FILES}
    verify_metadata(matrix)
    verify_localizations(sources)
    verify_source_contracts(sources, matrix)
    subprocess.run([sys.executable, str(ROOT / "tests/run_lua_tests.py")], check=True)
    if args.package:
        build_package(matrix)
    if args.verify_archive:
        verify_archive(args.verify_archive.resolve())
    print("Verification passed. Real-client loading, API and glyph tests remain separate.")


if __name__ == "__main__":
    main()
