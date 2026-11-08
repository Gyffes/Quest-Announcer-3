# Quest Announce 3 (QuestAnnounce 3 / QA3)

**World of Warcraft quest announcement addon for Retail and Classic.** Quest Announce 3 announces quest progress and completion through configurable chat channels, local notices and sounds. Standalone: no Ace or other addon dependency.

**World-of-Warcraft-Quest-Addon für Retail und Classic.** Quest Announce 3 meldet Questfortschritt und Questabschluss über einstellbare Chatkanäle, lokale Hinweise und Sounds. Eigenständig: keine Abhängigkeit von Ace oder anderen Addons.

[GitHub source / Quellcode](https://github.com/Gyffes/Quest-Announcer-3) · [Latest release / Aktuelles Release](https://github.com/Gyffes/Quest-Announcer-3/releases/latest) · [CurseForge](https://www.curseforge.com/wow/addons/quest-announce-3) · [WoWInterface](https://www.wowinterface.com/downloads/info11002-QuestAnnounce3.html) · [Feedback](https://github.com/Gyffes/Quest-Announcer-3/issues)

## Aktuelle Version / Current version

**9.3.0.11 Multi — 08.11.2026**

GitHub-Tag: **V9.3.0.11-Multi**. Reguläres Release ohne RC-Zusatz / Regular release without an RC suffix. Diagnosebuild / Diagnostic build: **20261007-1**; beide Testpartner verwenden dieselbe Addonversion / both peers should use the same addon version.

DE: Enthält die Tooltip-/Sprachkorrekturen, kanalabhängigen Chatversand, die integrierte Chatdiagnose und den aktuellen Client-Metadatenabgleich. Der Release-Status bedeutet nicht, dass jede Region, Schrift oder Client-API live getestet wurde. Bekannte Einschränkungen bleiben unten dokumentiert.

EN: Includes locale-aware tooltip fixes, channel-aware chat routing, integrated chat diagnostics and the current client metadata check. Release status does not mean every region, font or client API was tested live. Known limitations remain documented below.

## Installation / WowUp

DE: Das installierbare Release-ZIP entpackt direkt nach `Interface/AddOns/QuestAnnounce/`. Nicht GitHubs automatisch erzeugtes „Source code (zip)“ installieren. Beim Aktualisieren den bestehenden Addonordner ersetzen; die persönlichen Einstellungen unter `WTF` behalten.

EN: Extract the installable release ZIP directly to `Interface/AddOns/QuestAnnounce/`. Do not install GitHub's automatically generated “Source code (zip)”. Replace the existing addon folder when updating; preserve personal settings under `WTF`.

DE: In WowUp „Get Addons“ → per URL installieren und die Repository-URL `https://github.com/Gyffes/Quest-Announcer-3` verwenden. GitHub stellt ein Multi-ZIP und `release.json` zur eindeutigen Client-Zuordnung bereit. Ein direkt importierter ZIP-Link hat dagegen keinen automatischen Updatekanal. Vorhandene Provider-IDs: CurseForge `3607`, WoWInterface `11002`.

EN: In WowUp, open Get Addons → install from URL using the repository URL `https://github.com/Gyffes/Quest-Announcer-3`. GitHub supplies a Multi ZIP and `release.json` for explicit client matching. Importing a direct ZIP link does not provide an automatic update channel. Provider IDs: CurseForge `3607`, WoWInterface `11002`.

## Funktionen (DE)

- Questfortschritt/-abschluss, optionale Questtypfilter und einstellbare Meldungsabstände.
- Chatziele: SAY, YELL, EMOTE, PARTY, RAID, RAID_WARNING, INSTANCE_CHAT, GUILD, OFFICER, WHISPER, CHANNEL und Fokus-Flüstern, soweit der Client diese erlaubt.
- Lokales Chatfenster, eigenes Raid-Hinweisfenster und UI-Fehleranzeige; unabhängig vom Chatversand.
- Sounds für Fortschritt, Abschluss, Annahme und Abgabe, mit Sound-ID, Kanal, Test und Zurücksetzen. Auto-Turn-In-Sound ist separat und standardmäßig aus.
- Profile speichern, laden, kopieren, überschreiben und löschen; bestehende Profile bleiben erhalten.
- Questlinks: Linksklick öffnet das Questlog, Rechtsklick den Wowhead-Kopierdialog, Shift-Klick fügt einen Questlink ein.
- Minimap: links an/aus, mittig Pause, rechts Optionen; Position verschiebbar.
- Sprachgerechte Tooltip-Schrift, Größe und Farben. Automatische Schrift aus Client-Fontobjekten; native Auswahl für Koreanisch, Chinesisch und Russisch. Keine globale Änderung von Blizzard-Schriften.
- Zehn Sprachen: enUS, deDE, esES, esMX, frFR, koKR, ptBR, ruRU, zhCN und zhTW; Fallback auf enUS.
- Integrierte, standardmäßig ausgeschaltete Chatdiagnose; Einzel-/Partnertests nur nach ausdrücklichem Start.

## Features (EN)

- Quest progress/completion, optional quest-type filters and configurable announcement intervals.
- Chat destinations: SAY, YELL, EMOTE, PARTY, RAID, RAID_WARNING, INSTANCE_CHAT, GUILD, OFFICER, WHISPER, CHANNEL and focus whisper, where permitted by the client.
- Local chat frame, addon-owned raid notice and UI error display, independent of chat transmission.
- Progress, completion, acceptance and turn-in sounds with configurable ID, channel, test and reset. Auto-turn-in sound is separate and off by default.
- Save, load, copy, overwrite and delete profiles; preserve existing profiles.
- Quest links: left-click opens the quest log, right-click opens the Wowhead copy dialog, Shift-click inserts a quest link.
- Minimap: left-click toggles, middle-click pauses, right-click opens options; draggable position.
- Locale-aware tooltip font, size and colors. Automatic font from client font objects, with native Korean, Chinese and Russian choices. No global changes to Blizzard fonts.
- Ten languages: enUS, deDE, esES, esMX, frFR, koKR, ptBR, ruRU, zhCN and zhTW; enUS fallback.
- Integrated chat diagnostics, off by default; single/paired tests require explicit action.

## Debugging kurz (DE)

Die alte Option „Debug“ zeigt allgemeine Meldungen im Chat. Die neue **Chatdiagnose** ist separat: `/qa` → Chatdiagnose oder folgende Befehle.

1. Aufzeichnung einschalten, normale Regeln beibehalten, Fehler beim gewöhnlichen Spielen reproduzieren:

```text
/qa diag on
/qa diag mode normal
/qa diag status
```

2. Danach Tests abbrechen, Aufzeichnung ausschalten und speichern:

```text
/qa diag cancel
/qa diag off
/reload
```

3. Die Datei `<WoW-Client>/WTF/Account/<ACCOUNT>/SavedVariables/QuestAnnounce.lua` enthält **QuestAnnounceDiagnosticsDB** neben den persönlichen Profilen. Vor dem Teilen Profile und Namen/Partner-/Kanalangaben entfernen. Clientversion, Sprache und Fehlerbeschreibung beilegen. Erst danach bei Bedarf `/qa diag clear` verwenden.

Partnertests, Einzeltests und Roh-Probes: [Debug-Anleitung (DE/EN)](DEBUG-ANLEITUNG-GUIDE.md). Tests senden sichtbare Nachrichten nur nach ausdrücklichem Start; keine kompletten Logs werden automatisch hochgeladen.

## Debugging quick start (EN)

The old “Debug” option prints general chat messages. The new **Chat Diagnostics** feature is separate: open `/qa` → Chat Diagnostics or use these commands.

1. Enable recording, keep normal rules and reproduce the problem during ordinary gameplay:

```text
/qa diag on
/qa diag mode normal
/qa diag status
```

2. Afterwards cancel tests, stop recording and save:

```text
/qa diag cancel
/qa diag off
/reload
```

3. The file `<WoW-client>/WTF/Account/<ACCOUNT>/SavedVariables/QuestAnnounce.lua` contains **QuestAnnounceDiagnosticsDB** alongside personal profiles. Remove profiles and names/peer/channel settings before sharing. Include client version, locale and a description. Only afterwards, use `/qa diag clear` if needed.

Paired tests, single tests and raw probes: [Debug Guide (DE/EN)](DEBUG-ANLEITUNG-GUIDE.md). Tests send visible messages only after explicit action; complete logs are never automatically uploaded.

## Clients / Bekannte Grenzen / Known limitations

DE: 14 TOCs mit identischer Ladereihenfolge und denselben gespeicherten Variablen. Aktuelle Kennungen: Retail `120105`, Era/Hardcore/SoD `11509`, TBC/Anniversary `20506`, MoP `50504`, Forever `16001`, Titan Reforged (China) `38002`. Historische Wrath-/Cata-Kennungen bleiben erhalten; PTR wird nicht als Live-Unterstützung ausgegeben.

EN: 14 TOCs share load order and saved variables. Current identifiers: Retail `120105`, Era/Hardcore/SoD `11509`, TBC/Anniversary `20506`, MoP `50504`, Forever `16001`, Titan Reforged (China) `38002`. Historical Wrath/Cata identifiers are retained; PTR is not presented as live support.

DE: **Automatisches GUILD wird auf der modernen Retail-Regel vorsorglich zurückgehalten**, weil geschützte Aufrufe auch ohne sichtbare Chat-/Map-Sperre beobachtet wurden. Die Option bleibt gespeichert; OFFICER ist unabhängig. Automatisches CHANNEL ist dort ebenfalls eingeschränkt. Andere Clients behalten den konservativen Kampffallback. Es gibt keine Umgehung von Blizzard-Sperren und keinen Wechsel zu alten Dropdown-/Chat-Modi.

EN: **Automatic GUILD is conservatively withheld by the modern Retail policy** because protected calls were observed even without visible chat/map restrictions. The preference is preserved; OFFICER remains independent. Automatic CHANNEL is also restricted there. Other clients retain conservative combat handling. Blizzard restrictions are not bypassed, and legacy dropdown/chat modes are not reintroduced.

DE: Lokale Lua-5.1-, Übersetzungs-, Metadaten- und Partnersimulationen bestehen. Tatsächliches Laden aller Clients ohne Outdated-Schalter, regionale API-/Gameplay-Tests und die visuelle koKR/zhCN/zhTW/ruRU-Abnahme bleiben offen. Ein erfolgreicher API-Aufruf oder eigener Chat-Echo ist kein Zustellnachweis.

EN: Local Lua 5.1, translation, metadata and peer simulations pass. Actual loading on every client without the outdated-addon toggle, regional API/gameplay tests and visual koKR/zhCN/zhTW/ruRU acceptance remain pending. A successful API call or local chat echo is not proof of delivery.

## Entwicklung / Development

Der versionierte Stand und die ZIPs enthalten nur Addondateien, Icon und aktuelle Dokumentation. Keine PowerShell-Dateien, Testordner, Workflows, Referenzaddons, persönlichen Logs oder alten Plan-/RC-Dokumente. Lokale Entwicklungsunterlagen bleiben außerhalb der Veröffentlichung erhalten. Keine automatische Build-/Upload-Pipeline.

The tracked tree and ZIPs contain only addon files, the icon and current documentation. No PowerShell files, test folders, workflows, reference addons, personal logs or obsolete plan/RC documents. Local development material is preserved outside the distribution. No automatic build/upload pipeline.

Änderungen / Changes: [CHANGELOG.txt](CHANGELOG.txt). Sichtbare Texte in den Lokalisierungsdateien mitpflegen / Maintain localization files when changing visible text.

Danke an [user_n6i4a961y2ds2da7](https://legacy.curseforge.com/members/user_n6i4a961y2ds2da7) für den Schriftartenhinweis und an [Nerf_Teh_Derp](https://www.curseforge.com/members/nerf_teh_derp) für den Chatbericht / Thanks for the tooltip-font and chat reports.

Teile der Modernisierung und Dokumentation wurden mit Unterstützung von ChatGPT/Codex erstellt. / Parts of the modernization and documentation were created with ChatGPT/Codex assistance.
