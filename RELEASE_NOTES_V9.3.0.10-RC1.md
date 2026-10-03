# Quest Announce 3 — V9.3.0.10 RC1 Multi

Lokaler Release Candidate vom 03.10.2026; noch nicht auf GitHub veröffentlicht. Der vorherige 9.3.0.9 RC1 bleibt unverändert.

Local release candidate dated 2026-10-03; not yet published to GitHub. The previous 9.3.0.9 RC1 remains unchanged.

## Änderungen / Changes

- Gemeinsame sprachgerechte Schriftauflösung für Optionen und Minimap; automatische Client-Schrift basiert auf dem Community-Vorschlag `GameFontNormal:GetFont()`, ergänzt um `GameTooltipText` und sichere Fehlerbehandlung.
- Shared locale-aware font resolution for options and minimap; automatic client font implements the community's `GameFontNormal:GetFont()` suggestion with `GameTooltipText` and defensive fallback handling.
- Native Schriftwahlen für Koreanisch, vereinfachtes/traditionelles Chinesisch und Russisch. Bekannte inkompatible Altwerte fallen auf die Client-Schrift zurück, ohne gespeicherte Profile zu ändern; lateinische Schriftwahlen, Größe, Farben und eigene Pfade bleiben erhalten.
- Native font choices for Korean, simplified/traditional Chinese, and Russian. Known incompatible legacy values fall back to the client font without changing saved profiles; Latin choices, size, colors, and custom paths remain available.
- Forever-/Camelot-TOC ergänzt; bestehende Clientstände aktualisiert, Canonical-Mists-/Cata- und universelle TOC hinzugefügt. Anniversary verwendet den recherchierten TBC-Zweig. Details: [CLIENT_VERSIONS.md](CLIENT_VERSIONS.md).
- Added Forever/Camelot, canonical Mists/Cata, and universal TOCs; updated existing client metadata. Anniversary uses the researched TBC branch. See the client matrix for source details and limitations.
- Keine Änderungen an Questabgabe-, Chat-Lockdown-, Cinematic-/Taint- oder Soundlogik; vorhandene Schutzmechanismen bleiben bestehen. Drei neue UI-Texte in allen zehn Sprachen.
- No changes to quest turn-in, chat lockdown, cinematic/taint, or sound behavior; existing protections remain intact. Three new UI strings translated into all ten locales.

Danke / Thank you: [user_n6i4a961y2ds2da7](https://legacy.curseforge.com/members/user_n6i4a961y2ds2da7) für den hilfreichen Schriftartenhinweis / for the helpful tooltip-font report.

## Bestanden / Passed

Die folgenden Prüfungen wurden vor dem Entfernen der Testwerkzeuge bestanden. Der PR enthält auf Wunsch keine Testwerkzeuge oder GitHub-Workflows; automatische CI-Prüfung und Artefaktbereitstellung sind nicht eingerichtet.

The following checks passed before test tooling was removed. As requested, this PR includes no test tooling or GitHub workflows; automated CI verification and artifact delivery are not configured.

- 14 TOCs mit identischer Kern-Ladereihenfolge und Addonversion / matching core load order and addon version.
- Zehn Locale-Tabellen mit 234 Schlüsseln und passenden Platzhaltern / ten locales with 234 keys and matching placeholders.
- 70 Lua-5.1-Mock-Kombinationen: beide Tooltip-Arten und -seiten, Fonts/Fallbacks, Defaults, Rücksetzen, Profilwechsel, Questabgabe und einmaliges Kampf-Retry / both tooltips and sides, fonts/fallbacks, defaults, reset, profile load, turn-in events, and combat replay.
- Bestehende Quelltext-Prüfungen für Taint-Isolation, Funktionen und Chat-Schutz / existing source safety checks for taint isolation, preserved features, and chat lockdown.

## Noch offen / Still pending

Echte Client-Ladetests ohne Outdated-Schalter auf allen Varianten; API-/Gameplay-Prüfung; visuelle Glyphenprüfung auf koKR/zhCN/zhTW/ruRU; erneute normale und Videoquest-Abgaben einschließlich vollständigem Video und Abbruch. Historische Clientstände und Live-/Beta-Quellen sind in der Versionsmatrix getrennt dokumentiert. Frühere Praxistests des alten RC sind keine Abnahme dieses Builds.

Real-client loading without the outdated-addon toggle, API/gameplay validation, visual glyph tests on the four affected locales, and normal/cinematic turn-ins including completion and cancellation remain pending. Historical and live/beta source statuses are separated in the matrix. Previous RC in-game tests are not acceptance tests for this build.
