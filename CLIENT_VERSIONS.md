# Clientstände / Client versions — 03.10.2026

Die Metadatenprüfung umfasst alle bisher unterstützten Varianten und Forever. Alle 14 TOCs laden dieselben sieben Lua-Dateien in derselben Reihenfolge, verwenden `QuestAnnounceDB` und `QuestAnnounceDiagnosticsDB` und Addonversion 9.3.0.11-Rc1. TOC-Zahl bedeutet nicht 14 verschiedene Spielclients: einige Dateien sind erhaltene historische Aliase.

The metadata check covers all previously supported variants plus Forever. All 14 TOCs share seven Lua files, load order, both saved variables, and version 9.3.0.11-Rc1. Several TOCs are retained aliases, not separate game clients.

DE: Chat-/Diagnoseänderungen vom 06.10.2026 gelten für alle Varianten. Die kanalabhängige Kampfoptimierung ist durch Nutzerprüfungen nur für Retail 12.1.0.69933 belegt und wird bei vorhandener moderner Retail-API angewendet. Ungeprüfte Clientfamilien verwenden den konservativen Kampffallback. 70 Client-/Locale-Mocks bestehen; das ist kein Nachweis tatsächlicher Client-Kompatibilität. Kanalregeln und weitere Abnahme: [9.3.0.11-Rc1](RELEASE_NOTES_V9.3.0.11-Rc1.md). Die unten angegebenen Interface-/Quellstände stammen aus der Metadatenrecherche vom 03.10.2026 und wurden für diesen RC nicht neu festgelegt.

EN: Chat/diagnostic changes dated 06 October 2026 cover all variants. User measurements establish channel-specific combat optimization only for Retail 12.1.0.69933; it is applied when the modern Retail API is available. Unmeasured client families use conservative combat handling. All 70 client/locale mocks pass; this does not prove actual client compatibility. Channel policy and pending acceptance: [9.3.0.11-Rc1](RELEASE_NOTES_V9.3.0.11-Rc1.md). Interface/source versions below come from the 03 October metadata research and were not redefined for this RC.

| Variante / Variant | Recherchierter Stand / Source version | Interface | TOC |
| --- | --- | --- | --- |
| Retail/Mainline | 12.1.5.70077 (UI-Tag); Live-Mirror noch 12.1.0.69933 | 120105 und 120100; ältere bestehende Kennungen erhalten | `QuestAnnounce_Mainline.toc` |
| Classic | 1.15.9.70003 | 11509 | `QuestAnnounce_Classic.toc` |
| Classic Era | derselbe Era-Zweig / same Era branch | 11509 | `QuestAnnounce_ClassicEra.toc` (Alias) |
| Hardcore | derselbe Era-Zweig / same Era branch | 11509 | `QuestAnnounce_Hardcore.toc` (Alias) |
| Season of Discovery | derselbe Era-Zweig / same Era branch | 11509 | `QuestAnnounce_SeasonOfDiscovery.toc` (Alias) |
| TBC | 2.5.6.69795 | 20506 | `QuestAnnounce_TBC.toc` |
| Anniversary | TBC Anniversary 2.5.6.69795 | 20506 | `QuestAnnounce_Anniversary.toc` (Alias) |
| Wrath | historisch: 30405; finaler Clientbuild nicht belegt | 30405 unverändert / unchanged | `QuestAnnounce-Wrath.toc` |
| Cataclysm | historischer UI-Tag 4.4.2.60895 | 40402 unverändert / unchanged | `QuestAnnounce_Cata.toc` + `QuestAnnounce_Cataclysm.toc` (Alias) |
| MoP/Mists | 5.5.4.70032 | 50504 | `QuestAnnounce_Mists.toc` + `QuestAnnounce_MoP.toc` (Alias) |
| Forever/Camelot | Beta-Zweig 1.60.1.70205 | 16001 | `QuestAnnounce_Camelot.toc` |

`QuestAnnounce.toc` dient zusätzlich als universelle Fallback-TOC mit clientbezogenen `Interface-*`-Angaben. Diese werden nicht als Laufzeit-Schalter für veraltete APIs verwendet. Die API-Auswahl bleibt auf vorhandene Funktionen gestützt.

## Quellen und Grenzen / Sources and limitations

- Retail: [offizielle 12.1.5-Updatehinweise](https://worldofwarcraft.blizzard.com/en-gb/news/24304162/1215-content-update-notes), [12.1.5 UI-Quellstand](https://github.com/Gethe/wow-ui-source/tree/12.1.5), [Live-Mirror](https://github.com/Gethe/wow-ui-source/blob/live/version.txt). Der Mirror meldet beim Abruf noch 12.1.0; deshalb werden beide Kennungen unterstützt. Regionale Ausrollung ist ohne lokalen Client nicht bestätigt.
- Era/Hardcore/SoD: [classic_era](https://github.com/Gethe/wow-ui-source/blob/classic_era/version.txt).
- TBC/Anniversary: [classic_anniversary](https://github.com/Gethe/wow-ui-source/blob/classic_anniversary/version.txt).
- MoP: [classic](https://github.com/Gethe/wow-ui-source/blob/classic/version.txt).
- Forever: [forever](https://github.com/Gethe/wow-ui-source/blob/forever/version.txt). Dies ist ein Beta-Clientstand, keine Live-Freigabe.
- Cataclysm: [4.4.2 UI-Quellstand](https://github.com/Gethe/wow-ui-source/tree/4.4.2).
- Wrath: Interface `30405` wird von der aktuellen [BigWigs-TOC](https://github.com/BigWigsMods/BigWigs/blob/master/BigWigs.toc) weiterhin geführt. Das ist eine Gegenprüfung der erhaltenen Kennung, kein Nachweis eines aktiven offiziellen Wrath-Clients oder eines finalen Builds.
- Canonical-TOC-Namen und Camelot-Zuordnung: [Packager-Quellcode](https://github.com/BigWigsMods/packager/blob/master/release.sh). Vorhandene alternative Namen bleiben erhalten.

Blizzards extrahierte UI-Quellen wurden für vorhandene Settings-, Quest-, Chat- und Fontmodule der oben verfügbaren Clientzweige verglichen. Das prüft Quellstände, nicht einen laufenden Client. Die obige Tabelle dokumentiert die geprüften Metadaten; Testwerkzeuge und CI-Workflows wurden auf Wunsch aus dem PR entfernt. Die folgenden Ergebnisse stammen aus den Prüfungen vor dieser Entfernung.

## Prüfung / Validation

- Bestanden: explizite Dateiliste aller 14 TOCs, Interface-/Versionswerte, gemeinsame Kern-Dateien und SavedVariables; Quelltext-Schutzprüfungen; 70 Lua-5.1-Mock-Kombinationen für sieben Clientfamilien und zehn Locales. Aliase verwenden identischen Code. Neue Locale-Texte: zehn Tabellen, je 234 Schlüssel.
- Offen für alle Varianten: echtes Laden bei ausgeschaltetem „Veraltete Addons laden“, tatsächliche API-Funktion, Einstellungen, Questabläufe, Links und Sounds sowie Kampf-/Taint-Verhalten. Ein Mock ist kein Client-Kompatibilitätsnachweis.
- Offen für koKR/zhCN/zhTW/ruRU: native Zeichen in beiden Tooltips, neue/alte Profile, alle angebotenen Fontassets und `/reload`. Erfolgreiches `SetFont` beweist keine Glyphenabdeckung.
- Historische Zweige bleiben erhalten, werden aber nicht als aktuelle offizielle Live-Angebote ausgegeben.

All real-client loading, gameplay/API, and visual glyph tests remain pending. Source and mock validation must not be presented as completed in-game compatibility tests. Historical variants retain their identifiers without inventing active official clients.
