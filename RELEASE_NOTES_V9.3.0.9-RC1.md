# Quest Announce 3 – V9.3.0.9 RC1 Multi

Diese Vorabversion konzentriert sich auf WoW-12-Cinematic-/Taint-Sicherheit und einen stabilen Abschluss der 9.3.0.9-Änderungen.

This prerelease focuses on WoW 12 cinematic/taint safety and stabilization of the 9.3.0.9 changes.

## Änderungen / Changes

- Questabgabe-Erkennung vollständig von Blizzard-Abgabefunktionen und -Buttons entkoppelt; `QUEST_TURNED_IN` wird verzögert verarbeitet.
- Turn-in detection is fully detached from Blizzard turn-in functions and buttons; `QUEST_TURNED_IN` is processed asynchronously.
- Addon-eigener Raid-Hinweis und eigene Dialoge ersetzen gemeinsam genutzte Blizzard-Ausgabepfade.
- Addon-owned raid notices and dialogs replace shared Blizzard output paths.
- Questabschlussprüfungen verwenden immer Quest-IDs und prüfen bei `1/1` den vollständigen Queststatus.
- Quest completion checks always use quest IDs and verify the complete quest state for `1/1` events.
- Kampfblockierte externe Chatmeldungen werden höchstens zehn Sekunden gehalten und einmalig nach Kampfende geprüft, ohne lokale Ausgaben oder Sounds zu wiederholen.
- Combat-blocked external chat messages are retained for at most ten seconds and checked once after combat without replaying local output or sounds.
- Gespeicherte Altprofile erhalten alle aktuellen Standardwerte und aktualisieren Minimap sowie Questtyp-Anzeige sofort.
- Saved legacy profiles receive every current default and immediately refresh minimap and quest-type UI state.
- Alle temporären A/B-Diagnosezweige wurden aus der Produktionslogik entfernt.
- All temporary A/B diagnostic branches were removed from production code.

## Bestätigte Praxistests / Confirmed in-game tests

- Normale Questabgabe / normal quest turn-in
- Video vollständig abgespielt / cinematic played to completion
- Video abgebrochen oder übersprungen / cinematic cancelled or skipped
- Questabgabe während oder unmittelbar nach Kampf / turn-in during or immediately after combat
- Keine Lua-, Taint- oder `ADDON_ACTION_BLOCKED`-Fehler beobachtet / no Lua, taint, or `ADDON_ACTION_BLOCKED` errors observed

## Automatische Prüfungen / Automated verification

- Chat-Lockdown, Warteschlange und einmalige Wiedergabe
- Cinematic-/Taint-Isolation und addon-eigene UI-Ausgaben
- Erhalt von Quest-, Sound-, Link-, Profil- und Einstellungsfunktionen
- Zehn Lokalisierungen mit identischen Schlüsseln und passenden Format-Platzhaltern
- Zehn WoW-Client-TOCs mit einheitlicher Version 9.3.0.9

