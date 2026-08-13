# Quest Announce 3

Quest Announce 3 ist ein World-of-Warcraft-Addon, das Quest-Fortschritt und Quest-Abschlüsse automatisch in gewählte Ausgabekanäle meldet.  
Quest Announce 3 is a World of Warcraft addon that automatically announces quest progress and quest completion to selected output channels.

## Version / Version

Aktueller Stand: **9.3.0.7**
Current version: **9.3.0.7**

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
- Spezialbehandlung für Sound-ID 8959: stummer Zielkanal bleibt stumm, hörbarer Zielkanal wird konsistent berücksichtigt.
- Neue Allgemein-Optionen: Minimap-Button sichtbar/unsichtbar sowie „Eigene Meldungen“ (Addon-Status-/Warnmeldungen für den eigenen Client an/aus).
- Lokalisierungen für die neuen Optionen in allen unterstützten Sprachen ergänzt.
- TBC-2.5.5-Kompatibilitätsfix: Legacy-Questlog-APIs werden abgefangen, damit kein `GetNumQuestLogEntries`-Lua-Fehler mehr auftritt.
- Zusätzlicher 9.3.0.5-Hotfix: Tooltip-Schriften werden intern auf gültige WoW-Assetpfade gemappt, damit kein `SetFont(): Invalid font file asset` mehr auftritt.
- 9.3.0.7-Update: Questabgabe-Sound wird standardmäßig nur noch im manuellen Questdialog-Kontext abgespielt; optional kann Auto-Turn-In-Sound separat aktiviert werden.
- 9.3.0.7-Feinschliff: Questabgabe-Sound im manuellen Kontext wird nur noch bei expliziter Abgabe-Aktion (Abgeben/Quest beenden Button) ausgelöst.
- 9.3.0.7: Alle QA3-Auswahlfelder sind jetzt addon-eigene Radio-Menüs; die globale Blizzard-`UIDropDownMenu`-API wird nicht mehr verwendet und kann beim Laden der Optionen keinen UI-Taint mehr setzen.
- 9.3.0.7: Alle unterstützten Locales sind wieder vollständig; CI prüft künftig Taint-Isolation und Übersetzungsvollständigkeit.
- 9.3.0.7: Multi-Kompatibilität bleibt erhalten: Retail, Classic Era, Hardcore, Anniversary, Season of Discovery, TBC, Wrath, Cataclysm und MoP nutzen weiterhin dieselbe getestete Codebasis.
- 9.3.0.7: Sound-ID 8959 respektiert jetzt den ausgewählten WoW-Soundkanal auch für Effekte und Musik.

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
- 9.3.0.7: All supported locales are complete again; CI now checks both taint isolation and localization completeness.
- 9.3.0.7: Multi-client compatibility remains intact: Retail, Classic Era, Hardcore, Anniversary, Season of Discovery, TBC, Wrath, Cataclysm, and MoP continue to use the same tested codebase.
- 9.3.0.7: Sound ID 8959 now respects the selected WoW sound channel for Effects and Music as well.

## Hauptfunktionen (DE)

- Fortschritts- und Abschlussmeldungen für Quests.
- Ausgabe in verschiedene Ziele:
  - Chatkanäle (Sagen, Gruppe, Instanz, Gilde, Offizier, Flüstern, benutzerdefinierter Kanal, Fokus-Flüstern)
  - UI-Rahmen (Chat Frame, Raid Warning Frame, UI Errors Frame)
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
- Robuste Font-Auflösung für Tooltips (Label/Pfad + Fallback auf `STANDARD_TEXT_FONT`)
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
  - Chat channels (/say, party, instance, guild, officer, whisper, custom channel, focus whisper)
  - UI frames (Chat Frame, Raid Warning Frame, UI Errors Frame)
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
- Robust tooltip font resolution (label/path + `STANDARD_TEXT_FONT` fallback)
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

- Die UI arbeitet auf `QuestAnnounceDB.profile`.
- Fehlende Übersetzungen werden per Metatable auf `enUS` zurückgeführt.
- Für Änderungen an sichtbaren Texten immer `Localization.lua` mitpflegen.

## Development Notes (EN)

- The UI works with `QuestAnnounceDB.profile`.
- Missing translations fall back to `enUS` via metatable behavior.
- When changing visible text, always update `Localization.lua`.

## Hinweis zur Erstellung / Creation Note

Teile der Modernisierung, Dokumentation und technischen Überarbeitung dieses Projekts wurden mit Unterstützung von ChatGPT/Codex erstellt.  
Parts of the modernization, documentation, and technical refactoring of this project were created with support from ChatGPT/Codex.
