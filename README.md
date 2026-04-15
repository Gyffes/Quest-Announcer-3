# Quest Announce 3

Quest Announce 3 ist ein World-of-Warcraft-Addon, das Quest-Fortschritt und Quest-Abschlüsse automatisch in gewählte Ausgabekanäle meldet.

## Projektstatus

## Version

Aktueller Stand: **9.3.0.1**

Das Addon wurde in der aktuellen Entwicklungsphase grundlegend modernisiert:

- Umstellung auf **Standalone** (Abhängigkeiten auf Ace/andere Fremd-Addons entfernt).
- Große Teile der Logik und der Optionen wurden auf Basis des alten Codes neu aufgebaut.
- Erweiterte Link-Funktionalität für Questtexte (klickbar + Wowhead-Copy-Flow).
- Fokus-Flüstern wurde überarbeitet und stabilisiert.
- Umfangreiche Lokalisierungs-Überarbeitung (inkl. Fallback auf `enUS`).
- Minimap-Button optisch/technisch verbessert (rundes Icon-Masking).
- Neues Profilverwaltungs-Untermenü mit Speichern/Laden/Kopieren/Überschreiben/Löschen und Profilübersicht.

## Hauptfunktionen

- Fortschritts- und Abschlussmeldungen für Quests.
- Ausgabe in verschiedene Ziele:
  - Chatkanäle (Sagen, Gruppe, Instanz, Gilde, Offizier, Flüstern, benutzerdefinierter Kanal, Fokus-Flüstern)
  - UI-Rahmen (Chat Frame, Raid Warning Frame, UI Errors Frame)
- Konfigurierbare Sound-IDs für Fortschritt und Abschluss.
- Minimap-Button:
  - Linksklick: Addon an/aus
  - Rechtsklick: Optionen öffnen
  - Drag & Drop mit gespeicherter Position
- Tooltip-Styling (Schriftart, Größe, Farben)
- Slash-Command: `/qa`

## Dateistruktur

- `QuestAnnounce.lua` – Kernlogik, Events, Parsing, Versandlogik
- `Config.lua` – Blizzard-Optionspanel und Einstellungen
- `Minimap.lua` – Minimap-Button, Tooltip, Positionierung
- `Localization.lua` – Übersetzungen aller unterstützten Locales
- `CHANGELOG.txt` – Versionshistorie
- `QuestAnnounce_*.toc` – Versions-/Interface-Dateien je WoW-Spielvariante (Retail, Classic Era/Hardcore/SoD/Anniversary, Cataclysm Classic, MoP Classic)

## Hinweise für Entwicklung

- Die UI arbeitet auf `QuestAnnounceDB.profile`.
- Fehlende Übersetzungen werden per Metatable auf `enUS` zurückgeführt.
- Für Änderungen an sichtbaren Texten immer `Localization.lua` mitpflegen.

## Hinweis zur Erstellung

Teile der Modernisierung, Dokumentation und technischen Überarbeitung dieses Projekts wurden mit Unterstützung von ChatGPT/Codex erstellt.
