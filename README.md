# Quest Announce 3 (QuestAnnounce 3 / QA3)

**World of Warcraft quest announcement addon for Retail and Classic.** Quest Announce 3 announces quest progress and completion through configurable chat channels, local notices and sounds. Standalone: no Ace or other addon dependency.

**World-of-Warcraft-Quest-Addon für Retail und Classic.** Quest Announce 3 meldet Questfortschritt und Questabschluss über einstellbare Chatkanäle, lokale Hinweise und Sounds. Eigenständig: keine Abhängigkeit von Ace oder anderen Addons.

[GitHub source / Quellcode](https://github.com/Gyffes/Quest-Announcer-3) · [Latest release / Aktuelles Release](https://github.com/Gyffes/Quest-Announcer-3/releases/latest) · [CurseForge](https://www.curseforge.com/wow/addons/quest-announce-3) · [WoWInterface](https://www.wowinterface.com/downloads/info11002-QuestAnnounce3.html) · [Feedback](https://github.com/Gyffes/Quest-Announcer-3/issues)

## Aktuelle Version / Current version

**9.3.0.12-Rc1 Multi — 12.11.2026**

Entwicklungsstand / Development candidate: **9.3.0.12-Rc1**, Diagnosebuild / diagnostic build **20261112-1**. Beide Testpartner verwenden dieselbe Addonversion / both peers should use the same addon version. Bisheriges stabiles Release / Existing stable release: **V9.3.0.11-Multi**. Der RC ist noch nicht als neues stabiles Release veröffentlicht / The RC has not been published as a new stable release.

DE: Ergänzt optional erfüllte Einzelziele bei Fortschrittsfrequenz 0 und eine auswählbare Gruppenkanal-Priorität (#24/#25). Beide Optionen sind standardmäßig aus. Tooltip-/Sprachkorrekturen, Chatdiagnose und bisherige Ausgabeziele bleiben erhalten. Die Clientkennungen wurden am 12.11.2026 erneut abgeglichen; regionale Ingame-Abnahmen stehen weiter aus.

EN: Adds optional individual objective announcements at progress frequency 0 and selectable group-channel priority (#24/#25). Both options default to off. Locale-aware tooltip fixes, chat diagnostics and existing destinations are retained. Client identifiers were rechecked on November 12, 2026; regional in-game acceptance remains pending.

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

## Neue Optionen (DE)

Unter `/qa` im Hauptbereich:

- **Erfüllte Questziele bei Fortschritt 0 melden:** Fortschrittsfrequenz auf **0** setzen und die Option einschalten. Jedes neu erfüllte Ziel wird einmal je Questannahme gemeldet; beim letzten Ziel folgt zusätzlich der Gesamtquest-Abschluss. Zwischenstände bleiben stumm. Bei anderen Frequenzen gilt die bisherige Fortschrittsregel. Login, Reload, Aktivierung, Profilwechsel und Wiederaufnahme nach Pause holen keine fertigen Ziele nach.
- **Gruppenkanal automatisch wählen:** Gewünschte Checkboxen für **Instanz, Schlachtzug und/oder Gruppe** aktivieren, Chatankündigungen einschalten und die Automatik aktivieren. Die Prioritätsauswahl bietet alle sechs Reihenfolgen; Standard ist **Instanz > Schlachtzug > Gruppe**. Ausgeschaltet bleibt die bisherige Ausgabe in alle ausgewählten Kanäle bestehen.

Die Automatik verwendet höchstens einen aktivierten, tatsächlich verfügbaren und erlaubten Gruppenkanal pro Meldung. Bei **Schlachtzug > Instanz > Gruppe** und einer bekannten, ausschließlich für RAID geltenden Sperre wird INSTANCE_CHAT verwendet, sofern aktiviert, verfügbar und erlaubt; andernfalls der nächste passende Kandidat. PARTY setzt eine passende Gruppe voraus und ist im Raid nicht automatisch verfügbar. Solo erfolgt kein Gruppenversand. Flüstern, andere Chatziele, lokale Anzeigen und Sounds bleiben unabhängig.

Globale oder unklare Blizzard-Sperren erlauben keinen Kanalwechsel. Ein unerwarteter Schutzfehler beim Senden löst keine Wiederholung derselben Meldung in anderen Kanälen aus; spätere Meldungen können den inzwischen bekannten gesperrten Kanal überspringen. Gruppen-, Profil-, Modus- oder Prioritätswechsel verwerfen betroffene wartende Gruppenaufträge.

Nur ein tatsächlich gemeldeter eigener Schutzfehler sperrt den betroffenen Kanal vorsorglich bis `/reload`. Eine vorher erkannte gewöhnliche Einschränkung erzeugt diese Sperre nicht; spätere Meldungen werden erneut geprüft. Die Schutzfehlersperre wird nicht im Profil gespeichert.

Ziel-/Questabschlussereignisse erhalten eine begrenzte Warteschlange: höchstens acht je Ausgabeziel und 64 insgesamt, maximal zehn Sekunden gültig und mindestens eine Sekunde Abstand zwischen Chatversuchen. Gewöhnliche Fortschritte behalten nur den neuesten Stand je Ziel. Ablauf und Überlauf werden diagnostiziert; blockierte oder abgelaufene Meldungen werden nicht unbegrenzt nachgeliefert. Lokale Anzeigen und Sounds werden bei Chatwiederholungen nicht erneut ausgelöst.

## New options (EN)

In the main section of `/qa`:

- **Announce completed objectives at progress 0:** Set progress frequency to **0** and enable this option. Each newly completed objective is announced once per quest acceptance; the final objective is followed by whole-quest completion. Intermediate progress stays silent. Other frequencies retain existing rules. Login, reload, enabling, profile changes and resuming after pause do not replay completed objectives.
- **Automatically select group channel:** Enable the desired **Instance, Raid and/or Party** checkboxes, enable chat announcements and turn on automatic selection. Choose any of the six priority orders; the default is **Instance > Raid > Party**. With automatic selection off, existing output to all selected channels is retained.

Automatic selection uses at most one enabled, actually available and permitted group channel per message. With **Raid > Instance > Party**, a known RAID-only restriction selects INSTANCE_CHAT if enabled, available and allowed; otherwise the next eligible candidate is considered. PARTY requires an appropriate group and is not automatically available in a raid. Solo players send no group chat. Whispers, other chat destinations, local displays and sounds remain independent.

Global or unknown Blizzard restrictions never permit channel switching. An unexpected protection failure during sending does not replay that message in another channel; later messages can skip the now-known blocked channel. Group, profile, mode or priority changes discard affected pending group work.

Only an actual reported own protection failure conservatively disables that channel until `/reload`. An ordinary restriction detected before sending does not latch the channel; later messages are checked again. The protection-failure latch is not saved in the profile.

Objective/quest milestones use a bounded queue: at most eight per destination and 64 overall, valid for up to ten seconds, with at least one second between chat attempts. Ordinary progress retains only the latest message per destination. Expiry and overflow are diagnosed; blocked or expired messages are not delivered indefinitely. Chat retries do not replay local displays or sounds.

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

Danke an **C0res1ash** für das CurseForge-Feedback zu [#24](https://github.com/Gyffes/Quest-Announcer-3/issues/24) und [#25](https://github.com/Gyffes/Quest-Announcer-3/issues/25) / Thanks for the CurseForge feedback on objective announcements and group-channel priority.

Teile der Modernisierung und Dokumentation wurden mit Unterstützung von ChatGPT/Codex erstellt. / Parts of the modernization and documentation were created with ChatGPT/Codex assistance.
