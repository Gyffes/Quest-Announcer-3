# Quest Announce 3

Quest Announce 3 ist ein World-of-Warcraft-Addon, das Quest-Fortschritt und Quest-Abschlüsse automatisch in gewählte Ausgabekanäle meldet.  
Quest Announce 3 is a World of Warcraft addon that automatically announces quest progress and quest completion to selected output channels.

## Version / Version

Aktueller Stand: **9.3.0.11-Rc1**
Current version: **9.3.0.11-Rc1**

Vorbereiteter GitHub-RC / Prepared GitHub RC: **V9.3.0.11-Rc1-Multi**. Noch nicht veröffentlicht / Not published yet.

Aktuelles Stable-Release / Current stable release: **V9.3.0.9-Multi**.

## Chatoptimierung / Chat optimization

DE: `9.3.0.11-Rc1` ersetzt die pauschale Kampfverzögerung auf der geprüften Retailbasis durch kanalabhängige Regeln. Andere Clients behalten einen konservativen Kampffallback. EMOTE und RAID sind neue, standardmäßig ausgeschaltete Ausgabeziele. „Chatankündigungen“ erklärt den bisherigen Chat-Hauptschalter. Lokale Anzeigen und Sounds bleiben unabhängig von der Chatwarteschlange. Neue Texte und Tooltips sind in allen zehn Sprachen enthalten.

EN: `9.3.0.11-Rc1` replaces blanket combat deferral on the tested Retail basis with channel-specific rules. Other clients retain a conservative combat fallback. EMOTE and RAID are new destinations, off by default. “Chat announcements” explains the existing chat master switch. Local displays and sounds remain independent of the chat queue. New text and tooltips cover all ten languages.

DE: Separate stille Diagnose unter „Chatdiagnose“ oder `/qa diag on`; keine Zusatznachrichten. Aktive Tests werden ausdrücklich gestartet. Nach `/reload` steht `QuestAnnounceDiagnosticsDB` in der SavedVariables-Datei `QuestAnnounce.lua`. Die Umsetzung wurde automatisiert geprüft; die Ingame-Abnahme des neuen RC ist offen. Vollständige Kanalregeln, Grenzen und Befehle: [RC-Hinweise](RELEASE_NOTES_V9.3.0.11-Rc1.md). [Freigegebener Plan](CHAT_OPTIMIZATION_PLAN_9.3.0.11-Rc1.md), [Issue #22](https://github.com/Gyffes/Quest-Announcer-3/issues/22).

EN: Separate silent diagnostics are available under “Chat diagnostics” or `/qa diag on`; no additional messages. Active tests require explicit starting. After `/reload`, `QuestAnnounceDiagnosticsDB` is stored in the `QuestAnnounce.lua` SavedVariables file. Implementation passed automated checks; in-game acceptance of this RC is pending. Full channel rules, limitations and commands: [RC notes](RELEASE_NOTES_V9.3.0.11-Rc1.md). [Approved plan](CHAT_OPTIMIZATION_PLAN_9.3.0.11-Rc1.md), [issue #22](https://github.com/Gyffes/Quest-Announcer-3/issues/22).

## Community-Korrekturen 9.3.0.10 / Community fixes 9.3.0.10

Stand / Date: 03.10.2026. **Umgesetzt; Ingame-Abnahme offen / Implemented; in-game acceptance pending.** Der bisherige 9.3.0.9 RC1 wurde nicht überschrieben / The previous 9.3.0.9 RC1 has not been overwritten.

- DE: Alle bestehenden Clientvarianten sind in einer expliziten Versionsmatrix erfasst. Aktive TOCs wurden anhand der recherchierten Clientdaten aktualisiert; historische Wrath-/Cataclysm-Kennungen bleiben erhalten. Forever erhält `QuestAnnounce_Camelot.toc` mit Interface `16001`. Canonical-TOCs für Mists/Cata und eine universelle Fallback-TOC ergänzen die vorhandenen Dateien. Anniversary verwendet jetzt den TBC-Zweig, nicht die Era-Kennung.
- EN: An explicit version matrix covers every existing client variant. Active TOCs were updated against researched client data; historical Wrath/Cataclysm identifiers remain available. Forever gains `QuestAnnounce_Camelot.toc` with interface `16001`. Canonical Mists/Cata TOCs and a universal fallback TOC supplement the existing files. Anniversary now uses the TBC branch rather than the Era identifier.
- DE: Beide Tooltip-Arten verwenden denselben Schriftkatalog und Helfer. „Automatisch (Client-Schrift)“ liest `GameTooltipText:GetFont()` bzw. `GameFontNormal:GetFont()`. Koreanisch, vereinfachtes/traditionelles Chinesisch und Russisch erhalten eigene native Schriftwahlen. Bekannte ungeeignete Altwerte werden zur Anzeige durch die Client-Schrift ersetzt, ohne den gespeicherten Wert zu löschen. Eigene Pfade bleiben unterstützt; ihre Zeichenabdeckung liegt in der Verantwortung des Nutzers.
- EN: Both tooltip types share one font catalog and helper. “Automatic (Client Font)” reads `GameTooltipText:GetFont()` or `GameFontNormal:GetFont()`. Korean, simplified/traditional Chinese, and Russian have native font choices. Known incompatible legacy values use the client font for display without deleting the saved preference. Custom paths remain supported; users must ensure their glyph coverage.
- DE: Globale Blizzard-Schriften bleiben unverändert. Fehlende Fontobjekte und fehlgeschlagene `SetFont`-Aufrufe werden abgefangen; Größe, Farben, Profile und bestehende Quest-/Taint-/Kampfschutzmechanismen bleiben erhalten. Neue sichtbare Texte sind in allen zehn Sprachen übersetzt.
- EN: Global Blizzard fonts remain unchanged. Missing font objects and failed `SetFont` calls are handled safely; size, colors, profiles, and existing quest/taint/combat protections remain intact. New visible text is translated into all ten languages.
- DE: Vor dem Entfernen der Testwerkzeuge geprüft: 14 TOCs, zehn Locale-Tabellen mit jeweils 234 Schlüsseln und 70 Lua-5.1-Mock-Kombinationen. Dieser PR enthält keine Testwerkzeuge oder CI-Workflows. Keine Aussage über abgeschlossene Ingame-Prüfung: Ladestatus ohne Outdated-Schalter, echte API-Ausführung, Glyphendarstellung und normale/Videoquest-Abgaben müssen auf den jeweiligen Clients noch bestätigt werden.
- EN: Verified before removing test tooling: 14 TOCs, ten locale tables with 234 keys each, and 70 Lua 5.1 mock combinations. This PR includes no test tooling or CI workflows. This is not completed in-game validation: loading without the outdated-addon toggle, real API execution, glyph rendering, and normal/cinematic quest turn-ins still need confirmation on the respective clients.

Clientstände und Quellen / Client versions and sources: [CLIENT_VERSIONS.md](CLIENT_VERSIONS.md). Plan und Abnahme / Plan and acceptance: [COMMUNITY_FIX_PLAN.md](COMMUNITY_FIX_PLAN.md). RC-Hinweise / RC notes: [RELEASE_NOTES_V9.3.0.10-RC1.md](RELEASE_NOTES_V9.3.0.10-RC1.md).

## Projektstatus (DE)

Das Addon wurde in der aktuellen Entwicklungsphase grundlegend modernisiert:

- Umstellung auf **Standalone** (Abhängigkeiten auf Ace/andere Fremd-Addons entfernt).
- Große Teile der Logik und der Optionen wurden auf Basis des alten Codes neu aufgebaut.
- Erweiterte Link-Funktionalität für Questtexte (klickbar + Wowhead-Copy-Flow).
- Fokus-Flüstern wurde überarbeitet und stabilisiert.
- Umfangreiche Lokalisierungs-Überarbeitung (inkl. Fallback auf `enUS`).
- Minimap-Button optisch/technisch verbessert (rundes Icon-Masking).
- Neues Profilverwaltungs-Untermenü mit Speichern/Laden/Kopieren/Überschreiben/Löschen und Profilübersicht.
- Neuer Questtyp-Filterbereich (normal, Weltquest, trivial, Kampagne, Story) mit defensiver API-Auswertung.
- Neues Sound-Untermenü mit Sound-IDs, Test-/Reset-Buttons, Aktivierungs-Checkboxen und Soundkanal-Auswahl (Master/Effekt/Umgebung/Dialog/Musik).
- Neue Sound-Events für Quest angenommen (ID 6197) und Questabgabe (Standard-Questabgabe), inkl. geordneter Wiedergabelogik ohne Sound-Überlagerung.
- Nachfolgende UI-Feinarbeiten: dynamische Reflow-Layouts für Sound- und Questtyp-Optionen bei UI-Skalierung/Panelbreite.
- Der Standard-Fortschrittston 8959 (Raid Warning) folgt jetzt auch in WoW 12.1 dem gewählten Ausgabekanal: QA3 spielt dafür die passende Audiodatei direkt ab Ein Fallback auf das alte SoundKit erfolgt nur bei explizit gewähltem Master.
- Neue Allgemein-Optionen: Minimap-Button sichtbar/unsichtbar sowie „Eigene Meldungen“ (Addon-Status-/Warnmeldungen für den eigenen Client an/aus).
- Lokalisierungen für die neuen Optionen in allen unterstützten Sprachen ergänzt.
- TBC-2.5.5-Kompatibilitätsfix: Legacy-Questlog-APIs werden abgefangen, damit kein `GetNumQuestLogEntries`-Lua-Fehler mehr auftritt.
- Zusätzlicher 9.3.0.5-Hotfix: Tooltip-Schriften werden intern auf gültige WoW-Assetpfade gemappt, damit kein `SetFont(): Invalid font file asset` mehr auftritt.
- 9.3.0.7-Update: Questabgabe-Sound wird standardmäßig nur noch im manuellen Questdialog-Kontext abgespielt; optional kann Auto-Turn-In-Sound separat aktiviert werden.
- 9.3.0.7-Feinschliff: Questabgabe-Sound im manuellen Kontext wird nur noch bei expliziter Abgabe-Aktion (Abgeben/Quest beenden Button) ausgelöst.
- 9.3.0.7: Alle QA3-Auswahlfelder sind jetzt addon-eigene Radio-Menüs; die globale Blizzard-`UIDropDownMenu`-API wird nicht mehr verwendet und kann beim Laden der Optionen keinen UI-Taint mehr setzen.
- 9.3.0.7: Alle unterstützten Locales sind wieder vollständig; Taint-Isolation und Übersetzungsvollständigkeit wurden geprüft.
- 9.3.0.7: Multi-Kompatibilität bleibt erhalten: Retail, Classic Era, Hardcore, Anniversary, Season of Discovery, TBC, Wrath, Cataclysm und MoP nutzen weiterhin dieselbe getestete Codebasis.
- 9.3.0.7: Die Soundausgabe respektiert den ausgewählten WoW-Soundkanal. Hinweis: Der Blizzard-SoundKit 8959 ist auf manchen Clients an Master gebunden; für getrennte Kanäle kann eine andere Fortschritts-Sound-ID gewählt werden.
- 9.3.0.8: Chat-Ausgaben werden gegen WoW-Chat-/Encounter-Lockdowns abgesichert. Öffentliche automatische Chat-Typen (SAY/YELL/EMOTE/CHANNEL) werden vor dem Blizzard-Aufruf geprüft und bei geschütztem Client-Kontext übersprungen; Tooltip und Popup erklären die Einschränkung.
- 9.3.0.9: Normaler Kampf wird zusätzlich über `InCombatLockdown()` erkannt. Die jüngste blockierte Chatmeldung wird höchstens zehn Sekunden gehalten und nach Kampfende einmalig erneut geprüft, ohne lokale Frames oder Sounds zu wiederholen. Die Questabgabe-Erkennung nutzt nur noch Quest-Events und verarbeitet `QUEST_TURNED_IN` zeitlich entkoppelt. Die lokale Raidwarnungs-Ausgabe verwendet ein anonymes QuestAnnounce-Hinweisfenster statt Blizzards gemeinsamem `RaidWarningFrame`, damit anschließende Cinematics keinen markierten `LowHealthFrame`-Pfad übernehmen. Questlinks verwenden einen sicheren `SetItemRef`-Nachhook; Links-, Rechts- und Shift-Klick sowie der Classic-Fallback bleiben erhalten.
- 9.3.0.9 Stable: Temporäre Taint-Diagnosezweige wurden entfernt. Questabschlussprüfungen verwenden konsequent Quest-IDs, Altprofile werden vollständig migriert, und alle zehn Lokalisierungen werden automatisiert auf Schlüssel und Format-Platzhalter geprüft.

## Project Status (EN)

The addon has been significantly modernized in the current development phase:

- Migrated to **standalone** mode (Ace/third-party addon dependencies removed).
- Large parts of the logic and options were rebuilt based on the legacy code.
- Extended quest link functionality (clickable quest text + Wowhead copy flow).
- Focus whisper support was revised and stabilized.
- Major localization overhaul (including `enUS` fallback behavior).
- Improved minimap button visuals/technical behavior (round icon masking).
- New profile management submenu with save/load/copy/overwrite/delete actions and a profile overview.
- New quest-type filter section (normal, world, trivial, campaign, story) with defensive API-based detection.
- New sound submenu with sound IDs, test/reset buttons, per-sound enable checkboxes, and sound output channel selection (Master/Effects/Ambience/Dialog/Music).
- New sound events for quest accepted (ID 6197) and quest turn-in (default turn-in sound), including ordered playback logic to avoid overlapping sound spam.
- Follow-up UI refinements: dynamic reflow layouts for sound and quest-type options under varying UI scale/panel widths.
- Special handling for sound ID 8959: muted target channels stay silent, audible target channels are handled consistently.
- New general options: show/hide minimap button and “Self Messages” (toggle addon status/warning messages for your own client).
- Added translations for the new options across all supported locales.
- TBC 2.5.5 compatibility fix: legacy quest log APIs are now bridged to avoid `GetNumQuestLogEntries` Lua errors.
- Additional 9.3.0.5 hotfix: tooltip fonts are internally mapped to valid WoW asset paths to prevent `SetFont(): Invalid font file asset`.
- 9.3.0.7 update: quest turn-in sound now plays only in manual quest dialog context by default; auto turn-in sound can be enabled separately.
- 9.3.0.7 refinement: in manual context, turn-in sound now requires an explicit turn-in action (turn-in/complete quest button click).
- 9.3.0.7 taint-hardening: QuestAnnounce tooltips were internally hardened and fragile template-region stripping was removed.
- 9.3.0.7: All QA3 selectors now use addon-owned radio menus; the global Blizzard `UIDropDownMenu` API is no longer used, preventing option-load UI taint.
- 9.3.0.7: All supported locales are complete again; taint isolation and localization completeness were checked.
- 9.3.0.7: Multi-client compatibility remains intact: Retail, Classic Era, Hardcore, Anniversary, Season of Discovery, TBC, Wrath, Cataclysm, and MoP continue to use the same tested codebase.
- 9.3.0.7: Sound output respects the selected WoW sound channel. Note: Blizzard SoundKit 8959 is Master-bound on some clients; choose another progress sound ID for separate channel routing.
- 9.3.0.8: Chat output is protected against WoW chat/encounter lockdowns. Public automated chat types (SAY/YELL/EMOTE/CHANNEL) are checked before calling Blizzard APIs and skipped when the client context is protected; tooltip and popup explain the limitation.
- 9.3.0.9: Ordinary combat is additionally detected through `InCombatLockdown()`. The latest blocked chat message is retained for at most ten seconds and checked once after combat without replaying local frames or sounds. Turn-in detection now relies only on quest events and defers `QUEST_TURNED_IN` processing. Local raid-warning output uses an anonymous QuestAnnounce notice frame instead of Blizzard's shared `RaidWarningFrame`, preventing following cinematics from inheriting a marked `LowHealthFrame` path. Quest links use a secure `SetItemRef` post-hook; left-, right-, and Shift-click plus the Classic fallback remain available.
- 9.3.0.9 Stable: Temporary taint diagnostic branches were removed. Quest completion checks consistently use quest IDs, legacy profiles receive a complete migration, and automated validation checks keys and format placeholders across all ten localizations.

## Hauptfunktionen (DE)

- Fortschritts- und Abschlussmeldungen für Quests.
- Ausgabe in verschiedene Ziele:
  - Chatkanäle (Sagen, Gruppe, Instanz, Raid, Emote, Gilde, Offizier, Flüstern, benutzerdefinierter Kanal, Fokus-Flüstern), abhängig von Clientrestriktionen
  - Hauptschalter Chatankündigungen; lokale Anzeigen im eigenen Raid-Hinweisfenster und UI-Fehlerfenster
  - Separate stille Chatdiagnose und ausdrücklich gestartete Testserien
- Konfigurierbare Sound-IDs für Fortschritt, Abschluss, Quest angenommen und Questabgabe.
- Pro Sound ein Test-Button, Zurücksetzen-Button und Aktivierungs-Checkbox.
- Neue optionale Sound-Checkbox für Auto-Turn-In-Quests (`Play Turn-In Sound for Auto Turn-In`, Standard: aus).
- Auswahl des WoW-Soundkanals (Master, Effekt, Umgebung, Dialoge, Musik).
- Dynamische Layout-Anpassung für Sound- und Questtyp-Bereiche bei abweichender UI-Skalierung.
- Sound-ID 8959 berücksichtigt Kanal-Stummschaltung (kein unerwarteter Ton bei stummem Zielkanal).
- Minimap-Button:
  - Linksklick: Addon an/aus
  - Mittelklick: temporäre Pause an/aus (schnelles Stummschalten ohne Deaktivierung)
  - Rechtsklick: Optionen öffnen
  - Drag & Drop mit gespeicherter Position
- Tooltip-Styling (Schriftart, Größe, Farben)
- Gemeinsame sprachgerechte Font-Auflösung für Tooltips (Client-Fontobjekte, native Auswahl, Altprofil-/Pfadbehandlung und abgesicherte Fallbacks ohne Pflicht auf `STANDARD_TEXT_FONT`)
- Tooltip-Styling wirkt auf QuestAnnounce-eigene Tooltips (z. B. Optionen + Minimap), ohne globale Beeinflussung fremder Addon-/Blizzard-Tooltips
- Tooltip-Interna sind gehärtet (addon-eigene Frames, kein fragiles Region-Stripping), wodurch das Risiko von Taint/Nebeneffekten in Blizzard-Map/Widget-Hoverpfaden reduziert wird.
- Questlinks in Ankündigungen (taint-sicher):
  - Linksklick: Quest im Questlog öffnen
  - Rechtsklick: Wowhead-URL im Copy-Dialog öffnen
  - Shift+Linksklick: offizieller Questlink wird in den Chat eingefügt
- Slash-Command: `/qa`

## Main Features (EN)

- Quest progress and completion announcements.
- Output to different targets:
  - Chat channels (/say, party, instance, raid, emote, guild, officer, whisper, custom channel, focus whisper), subject to client restrictions
  - Chat announcements master switch; local displays in the owned raid notice and UI error frame
  - Separate silent chat diagnostics and explicitly started test suites
- Configurable sound IDs for progress, completion, quest accepted, and quest turn-in.
- Per-sound test button, reset button, and enable checkbox.
- New optional auto-turn-in sound checkbox (`Play Turn-In Sound for Auto Turn-In`, default: off).
- Selectable WoW sound channel (Master, Effects, Ambience, Dialog, Music).
- Dynamic layout adaptation for sound and quest-type sections under different UI scales.
- Sound ID 8959 respects target-channel muting (no unexpected playback when target channel is muted).
- Optional quest-type filters (normal/world/trivial/campaign/story, only where API data is reliable).
- Minimap button:
  - Left click: toggle addon on/off
  - Middle click: toggle temporary pause (quick mute without disabling)
  - Right click: open options
  - Drag & drop with saved position
- Tooltip styling (font, size, colors)
- Shared locale-aware tooltip font resolution (client font objects, native choices, legacy profile/path handling, and safe fallbacks without requiring `STANDARD_TEXT_FONT`)
- Tooltip styling applies to QuestAnnounce-owned tooltips (e.g. options + minimap) without globally impacting third-party/Blizzard tooltips
- Tooltip internals are hardened (addon-owned frames, no fragile region stripping), reducing taint/side-effect risk in Blizzard map/widget hover paths.
- Quest links in announcements (taint-safe):
  - Left click: open quest in quest log
  - Right click: open Wowhead URL in copy dialog
  - Shift+Left click: insert official quest link into chat
- Slash command: `/qa`

## Dateistruktur / File Structure

- `QuestAnnounce.lua` – Kernlogik, Events, Parsing, Versandlogik / Core logic, events, parsing, message routing
- `Config.lua` – Blizzard-Optionspanel und Einstellungen / Blizzard settings panel and options
- `Minimap.lua` – Minimap-Button, Tooltip, Positionierung / Minimap button, tooltip, positioning
- `Localization.lua` – Übersetzungen aller unterstützten Locales / Translations for all supported locales
- `CHANGELOG.txt` – Versionshistorie / Version history
- `QuestAnnounce_*.toc` – Versions-/Interface-Dateien je WoW-Spielvariante / Version/interface files per WoW variant

## Hinweise für Entwicklung (DE)

- Testwerkzeuge, PowerShell-Skripte und GitHub-Workflows sind auf Wunsch nicht Bestandteil dieses PRs. Die dokumentierten Prüfungen wurden vor ihrer Entfernung durchgeführt; eine automatische CI-Prüfung oder Paketbereitstellung ist hier nicht eingerichtet.
- Die UI arbeitet auf `QuestAnnounceDB.profile`.
- Fehlende Übersetzungen werden per Metatable auf `enUS` zurückgeführt.
- Für Änderungen an sichtbaren Texten immer `Localization.lua` mitpflegen.

## Development Notes (EN)

- Test tooling, PowerShell scripts and GitHub workflows are excluded from this PR as requested. Documented checks were performed before their removal; no automated CI verification or package delivery is configured here.
- The UI works with `QuestAnnounceDB.profile`.
- Missing translations fall back to `enUS` via metatable behavior.
- When changing visible text, always update `Localization.lua`.

## Hinweis zur Erstellung / Creation Note

Teile der Modernisierung, Dokumentation und technischen Überarbeitung dieses Projekts wurden mit Unterstützung von ChatGPT/Codex erstellt.  
Parts of the modernization, documentation, and technical refactoring of this project were created with support from ChatGPT/Codex.
