# Clientstände / Client versions — 08.11.2026

**Aktuelle Addonversion / Current addon version: 9.3.0.11 Multi.**

DE: Alle 14 TOCs laden dieselben neun Lua-Dateien in gleicher Reihenfolge und verwenden `QuestAnnounceDB` sowie `QuestAnnounceDiagnosticsDB`. Neuere Buildnummern allein erfordern keine neue Interfacekennung. Titan Reforged (China) ergänzt `38002`; historisches Wrath `30405` bleibt erhalten. Die Release-Promotion ändert keine Quest-, Chat-, Schrift- oder Sicherheitslogik und setzt keine Profile zurück.

EN: All 14 TOCs share nine Lua files in the same order and use `QuestAnnounceDB` and `QuestAnnounceDiagnosticsDB`. A newer build alone does not require a new interface identifier. Titan Reforged (China) adds `38002`; historical Wrath `30405` is retained. Release promotion changes no quest, chat, font or safety logic and resets no profiles.

DE: Die Chat-/Partnerdiagnose verwendet weiterhin Diagnosebuild `20261007-1`. Die moderne Retail-Regel hält automatisches GUILD vorsorglich zurück; andere Clients behalten ihren konservativen Kampffallback. Die echten Retail-Belege vom 05./06.10. betreffen 12.1.0.69933 und sind keine neue Abnahme aktueller Builds. Anleitung und Einschränkungen: [README.md](README.md), [DEBUGGING.md](DEBUGGING.md).

EN: Chat/peer diagnostics retain revision `20261007-1`. Modern Retail policy conservatively withholds automatic GUILD; other clients retain conservative combat handling. Real Retail evidence from October 5/6 covers 12.1.0.69933 and is not new acceptance of current builds. Instructions and limitations: README and DEBUGGING.

| Variante / Variant | Recherchierter Stand / Source version | Interface | TOC |
| --- | --- | --- | --- |
| Retail/Mainline | 12.1.5.70783 (Live-Quellstand / live source) | 120105; 120100 und ältere bestehende Kennungen erhalten | `QuestAnnounce_Mainline.toc` |
| Classic | 1.15.9.70576 | 11509 | `QuestAnnounce_Classic.toc` |
| Classic Era | derselbe Era-Zweig / same Era branch | 11509 | `QuestAnnounce_ClassicEra.toc` (Alias) |
| Hardcore | derselbe Era-Zweig / same Era branch | 11509 | `QuestAnnounce_Hardcore.toc` (Alias) |
| Season of Discovery | derselbe Era-Zweig / same Era branch | 11509 | `QuestAnnounce_SeasonOfDiscovery.toc` (Alias) |
| TBC | 2.5.6.70577 | 20506 | `QuestAnnounce_TBC.toc` |
| Anniversary | TBC Anniversary 2.5.6.70577 | 20506 | `QuestAnnounce_Anniversary.toc` (Alias) |
| Wrath | historisch: 30405; finaler Clientbuild nicht belegt | 30405 unverändert / unchanged | `QuestAnnounce-Wrath.toc` |
| Wrath / Titan Reforged (China) | 3.80.2.70522 (`classic_titan`) | 38002 ergänzt / added; kein Gameplay-Nachweis / no gameplay validation | `QuestAnnounce-Wrath.toc` |
| Cataclysm | historischer UI-Tag 4.4.2.60895 | 40402 unverändert / unchanged | `QuestAnnounce_Cata.toc` + `QuestAnnounce_Cataclysm.toc` (Alias) |
| MoP/Mists | 5.5.4.70631 | 50504 | `QuestAnnounce_Mists.toc` + `QuestAnnounce_MoP.toc` (Alias) |
| Forever/Camelot | 1.60.1.70862; veröffentlicht / released | 16001 unverändert / unchanged | `QuestAnnounce_Camelot.toc` |

`QuestAnnounce.toc` dient zusätzlich als universelle Fallback-TOC mit clientbezogenen `Interface-*`-Angaben. Diese werden nicht als Laufzeit-Schalter für veraltete APIs verwendet. Die API-Auswahl bleibt auf vorhandene Funktionen gestützt.

## Quellen und Grenzen / Sources and limitations

- Retail: [offizielle Updateübersicht](https://worldofwarcraft.blizzard.com/en-us/content-update-notes), [Live-Quellstand 12.1.5.70783](https://github.com/Gethe/wow-ui-source/blob/live/version.txt). Die bisherige Übergangsnotiz von 12.1.0 zu 12.1.5 ist überholt; alte eingetragene Kennungen bleiben erhalten. Regionale Ausrollung ist ohne lokalen Client nicht bestätigt.
- Era/Hardcore/SoD: [classic_era](https://github.com/Gethe/wow-ui-source/blob/classic_era/version.txt).
- TBC/Anniversary: [classic_anniversary](https://github.com/Gethe/wow-ui-source/blob/classic_anniversary/version.txt).
- MoP: [classic](https://github.com/Gethe/wow-ui-source/blob/classic/version.txt).
- Forever: [forever, 1.60.1.70862](https://github.com/Gethe/wow-ui-source/blob/forever/version.txt), [offizielle Veröffentlichung](https://worldofwarcraft.blizzard.com/en-gb/news/24302093). Die frühere Beta-Einstufung vom Oktober ist überholt. Der offizielle globale Start am 04.11.2026 um 23:00 GMT entspricht dem 05.11.2026 um 00:00 Uhr in Berlin; dies ist kein Nachweis erfolgreicher Addon-Ausführung.
- Cataclysm: [4.4.2 UI-Quellstand](https://github.com/Gethe/wow-ui-source/tree/4.4.2).
- Historisches Wrath: Interface `30405` wird von der [BigWigs-TOC](https://github.com/BigWigsMods/BigWigs/blob/master/BigWigs.toc) weiterhin geführt und bleibt erhalten; kein Nachweis eines aktiven historischen Live-Angebots oder finalen Builds.
- Titan Reforged (China): [offizielles Classic-Angebot](https://wow.blizzard.cn/classic/home.html), [classic_titan, 3.80.2.70522](https://github.com/Gethe/wow-ui-source/blob/classic_titan/version.txt), [Questies Wrath-TOC mit 38002](https://github.com/Questie/Questie/blob/master/Questie_Wrath.toc). Ein offizieller regionaler Wrath-basierter Client, nicht der historische globale 3.4.x-Client und nicht das Retail-Remix-Event. Nur Metadaten ergänzt, vollständige regionale Ingame-Abnahme offen.
- PTR getrennt: [ptr, 12.1.7.70740](https://github.com/Gethe/wow-ui-source/blob/ptr/version.txt). Interface `120107` wird nicht vorsorglich als Live-Unterstützung eingetragen. Nicht allein die höchste Nummer aus fremden Addons übernehmen.
- Canonical-TOC-Namen und Camelot-Zuordnung: [Packager-Quellcode](https://github.com/BigWigsMods/packager/blob/master/release.sh). Vorhandene alternative Namen bleiben erhalten.

Blizzards extrahierte UI-Quellen wurden bei der ursprünglichen Umsetzung für vorhandene Settings-, Quest-, Chat- und Fontmodule verglichen. Am 08.11.2026 wurden die veröffentlichten Versionsstände und TOCs neu abgeglichen; die Titan-Quest-/Chat-/Restriktionsdokumentation wurde zusätzlich als Quellreferenz geprüft. Das ist kein vollständiger neuer API-Audit und kein laufender Client. Testwerkzeuge und CI-Workflows bleiben auf Wunsch außerhalb des versionierten Addons und des Pakets.

## Prüfung / Validation

- Metadatenstand 08.11.2026: alle 14 TOCs, Interfacewerte einschließlich `30405`/`38002`, universelle Flavor-Angaben, neun gemeinsame Lua-Dateien in gleicher Reihenfolge und beide SavedVariables geprüft. Die übrigen Live-Kennungen waren bereits aktuell.
- Lokal erneut bestanden: bestehende Lua-5.1-/70-Client-Locale-Mocks und Chat-/Partnerdiagnose-Simulationen. Aliase verwenden identischen Code. Neue Chat-/Diagnosetexte sind in allen zehn Sprachtabellen enthalten. Simulierte Projekt-/API-Kombinationen sind keine Abnahme des nativen Titan-Clients.
- Offen für alle Varianten: echtes Laden bei ausgeschaltetem „Veraltete Addons laden“, tatsächliche API-Funktion, Einstellungen, Questabläufe, Links und Sounds sowie Kampf-/Taint-Verhalten. Ein Mock ist kein Client-Kompatibilitätsnachweis.
- Offen für koKR/zhCN/zhTW/ruRU: native Zeichen in beiden Tooltips, neue/alte Profile, alle angebotenen Fontassets und `/reload`. Erfolgreiches `SetFont` beweist keine Glyphenabdeckung.
- Historische Zweige bleiben erhalten, werden aber nicht als aktuelle offizielle Live-Angebote ausgegeben.

All real-client loading, gameplay/API, and visual glyph tests remain pending. Source and mock validation must not be presented as completed in-game compatibility tests. Historical variants retain their identifiers without inventing active official clients.
