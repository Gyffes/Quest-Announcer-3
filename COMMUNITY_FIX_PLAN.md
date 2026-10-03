# Behebungsplan: Community-Meldungen vom 03.10.2026

Status: Technische Umsetzung für 9.3.0.10 RC1 abgeschlossen; automatische Prüfungen bestehen, echte Ingame-Abnahme und Veröffentlichung stehen aus. Dieser Plan bleibt als Referenz erhalten und ist keine Zusage bereits absolvierter Clienttests.

## Umsetzungsstand

- Gemeinsamer Schriftkatalog/-helfer in der Kern-Datei; Optionen und Minimap verwenden denselben sicheren Stilpfad. Client-Fontobjekte werden nur gelesen.
- Automatische Client-Schrift, native Auswahl für die vier betroffenen Locales und nichtdestruktive Behandlung bekannter Altwerte umgesetzt. Drei neue UI-Texte in allen zehn Locale-Tabellen.
- Alle bestehenden TOCs geprüft und aktive Kennungen aktualisiert. Canonical-Camelot-/Mists-/Cata-TOCs und universelle TOC ergänzt; alle bestehenden Aliase erhalten. Einzelheiten und Quellengrenzen in [CLIENT_VERSIONS.md](CLIENT_VERSIONS.md).
- Lua-5.1-Tests führen echten Addon-Code unter simulierten Client-APIs aus: 70 Clientfamilien-/Locale-Kombinationen, beide Tooltips, Reset, Profilwechsel, Fontfehler, Questabgabe und Kampf-Retry. Bestehende Source-/Taint-Schutzprüfungen bleiben aktiv.
- Offen: echte Ladeprüfung auf allen Clientvarianten, native Glyphendarstellung und erneute normale/Videoquest-Tests einschließlich Abbruch. Automatische Tests können diese Abnahme nicht ersetzen.
- Neuer RC lokal vorbereitet; das bisherige Release bleibt unverändert. Veröffentlichung separat.

## 1. Ausgangsbefund vor Umsetzung

### WoW Forever: plausible Metadatenursache, noch kein reproduzierter Laufzeitfehler

Im Ausgangsstand enthielt keine der zehn TOC-Dateien die Forever-Interfacekennung `16001`. Unter der angenommenen Bedingung, dass „Veraltete Addons laden“ ausgeschaltet ist, ist die fehlende passende Kennung eine plausible Erklärung. Die konkrete Clientversion und die vom Client tatsächlich ausgewählte TOC müssen vor der Freigabe geprüft werden; eine höhere Interfacekennung allein beweist keine API-Kompatibilität.

[Blizzard nennt für einen Forever-Betabuild vom September Version 1.60.1](https://us.forums.blizzard.com/en/wow/t/beta-client-update-september-22/2358655/1). [Platers aktuelle TOC verwendet `Interface-Camelot: 16001`](https://github.com/Tercioo/Plater-Nameplates/blob/master/Plater.toc). Diese Hinweise ersetzen nicht die Prüfung des konkret gemeldeten Updates.

### Tooltip-Schrift: problematische Auflösung im Code bestätigt

- `Minimap.lua`, `QuestAnnounce:GetTooltipFontPath`: vier feste Fontpfade, keine Locale-Auswertung und unkontrollierte Weitergabe gespeicherter Pfade.
- `Config.lua`, `ResolveTooltipFontPath`: dieselbe Auflösung unabhängig erneut implementiert.
- Defaults, Rücksetzen und Auswahllabels verwenden ebenfalls „Friz Quadrata TT“. Nur den Fallback zu ändern würde bestehende Profile deshalb nicht reparieren.
- Beide Tooltip-Pfade überschreiben die geerbte Schrift mit `SetFont`. Dadurch geht die sprachgerechte Schriftwahl des Clients verloren.
- Die Behauptung, alle vier Dateien enthielten grundsätzlich keine kyrillischen Zeichen, ist zu pauschal: [Blizzards Classic-Schriftdefinitionen verwenden `ARIALN.TTF` auch für russische Fontfamilien](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_Fonts_Shared/Classic/GameFonts.xml). Belegt ist die fehlende sprachgerechte Auswahl, nicht die vollständige Glyphenabdeckung jeder Datei auf jedem Client.
- Dass `STANDARD_TEXT_FONT` ausschließlich Retail vorbehalten sei, ist nicht als gesicherte Tatsache übernommen. Der Helfer muss auch ohne dieses Global funktionieren.

Die vorhandene Release-Prüfung läuft durch. Sie prüft überwiegend Quelltextstrukturen und Lokalisierungsschlüssel, nicht gerenderte Glyphen oder tatsächliche WoW-Ereignisabläufe. Ein visueller Ingame-Nachweis liegt für diese Meldung noch nicht vor.

## 2. Ursprünglicher Umsetzungsplan (Referenz)

### A. Alle unterstützten Clients prüfen und Versionskennungen aktualisieren

Die Prüfung umfasst alle vorhandenen Client-TOCs: Mainline/Retail, Classic, Classic Era, Hardcore, Anniversary, Season of Discovery, TBC, Wrath, Cataclysm und MoP sowie die neu hinzukommende Forever-Unterstützung. Keine vorhandene Variante wird stillschweigend ausgelassen oder entfernt.

1. Für jede Variante eine Versionsmatrix anlegen: Client/Produktzweig, aktuelle Spielversion, Build, Interfacekennung, Quelle und Prüfdatum, zuständige TOC sowie Metadaten-, API- und Ingame-Teststatus. Live und Beta/PTR getrennt dokumentieren; ein Betabuild ersetzt nicht ungeprüft die Live-Kennung.
2. Die zum Umsetzungszeitpunkt aktuellen offiziellen Clientdaten recherchieren und, soweit der Client verfügbar ist, mit `GetBuildInfo()` abgleichen. Alle betroffenen `Interface`-/`X-Interface`-Angaben konsistent auf die verifizierten aktuellen Werte bringen. Gemeinsam genutzte Clientzweige dürfen dieselbe bestätigte Kennung verwenden.
3. Für historische Varianten ohne laufenden offiziellen Clientzweig den letzten belegbaren offiziellen Stand dokumentieren und bestehende Kompatibilität erhalten; keine erfundene „aktuelle“ Kennung und kein Rückbau moderner APIs. Unklare Angaben als offen kennzeichnen und vor einer entsprechenden Kompatibilitätszusage klären.
4. Jeden Client auf tatsächlich verfügbare Questlog-, Settings-, Tooltip-, Sound- und Chat-APIs prüfen. Das Aktualisieren einer TOC ist kein Funktionsnachweis. Fehlende lokale Clients ausdrücklich nennen; Quellen-/Mock-Prüfungen nicht als absolvierte Ingame-Tests ausgeben.

#### Forever-Ladeproblem gezielt prüfen

1. Auf dem betroffenen Client `GetBuildInfo()` und `WOW_PROJECT_ID` erfassen; Interfacekennung und TOC-Auswahl mit ausgeschaltetem Laden veralteter Addons bestätigen.
2. Die vom Client unterstützte Forever-/Camelot-TOC-Konvention prüfen. Anschließend passende Metadaten bzw. eine passende TOC mit denselben Kern-Dateien und SavedVariables ergänzen. `16001` ist der recherchierte Ausgangswert, kein dauerhaft festgeschriebener Wert für unbekannte künftige Builds.
3. Vorhandene Client-TOCs erhalten und im Rahmen der vollständigen Versionsmatrix ebenfalls aktualisieren. Jede Änderung benötigt einen belegten Clientstand; Addonversion und WoW-Interfaceversion bleiben getrennte Angaben.
4. Moderne APIs weiterhin anhand ihrer Verfügbarkeit verwenden. Forever nicht aufgrund von `16001` pauschal als Legacy-Classic behandeln. Bestehende lokale Kompatibilitätsadapter für tatsächlich ältere Clients behalten, ohne globale Blizzard-APIs umzuschreiben.

### B. Eine gemeinsame Schriftauflösung einführen

#### Berücksichtigung des Nutzervorschlags

Der vorgeschlagene Zugriff auf `GameFontNormal:GetFont()` ist ausdrücklich die Grundlage der geplanten Lösung, kein verworfener Ansatz. Für Tooltips kann zunächst das vorhandene Tooltip-Fontobjekt `GameTooltipText` gelesen werden; `GameFontNormal` ist die nächste Quelle. Entscheidend ist der sprachgerechte Font des Clients, nicht eine neue feste Liste als alleiniger Standard.

Der Vorschlag wird an vier Stellen vervollständigt:

- Fontobjekt, `GetFont`-Methode und nichtleeren Stringpfad prüfen; den Aufruf gegen Fehler absichern und bei Bedarf die nächste Quelle versuchen.
- Den Rückfall `STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"` nicht unverändert übernehmen: Er kann wieder einen ungeeigneten westlichen Font auswählen. Ohne sicheren Ersatz die geerbte Client-Schrift erhalten, besonders auf koKR/zhCN/zhTW/ruRU.
- Die Auflösung auch auf gespeicherte bekannte Schriftnamen/-pfade anwenden. Sonst umgeht beispielsweise ein bestehendes Profil mit „Friz Quadrata TT“ den neuen Fallback weiterhin.
- Dieselbe Entscheidung für Minimap, Optionen, Defaults, Reset und Profilwechsel verwenden, damit der Fehler nicht in einem zweiten Helfer bestehen bleibt.

Das ist eine robustere Einbindung des Nutzervorschlags in die vorhandene Addonstruktur, keine grundsätzlich andere Schrifttechnik. Zusätzliche native Schriftvarianten dienen nur dem Erhalt der Auswahlfunktion; die automatische Client-Schrift bleibt der sichere Ausgangspunkt.

#### Umsetzung

1. Den gemeinsamen Helfer und Schriftkatalog in `QuestAnnounce.lua` definieren, bevor `Config.lua` und `Minimap.lua` geladen werden. Beide Tooltip-Pfade und ihre Auswahllabels beziehen ihre Daten daraus; keine zweite Pfadtabelle.
2. „Automatisch (Client-Schrift)“ als stabile, lokalisierte Auswahl ergänzen. Den Pfad vorzugsweise aus einem vorhandenen Client-Fontobjekt wie `GameTooltipText` oder `GameFontNormal` lesen. Objekt, Methode und Rückgabepfad prüfen. Globale Fontobjekte nur lesen, niemals verändern.
3. Bestehende vier Schriftwahlen für lateinische Locales erhalten. Für nichtlateinische Locales sprachgerechte Varianten anbieten, soweit auf dem Client geprüft; andernfalls die Client-Schrift verwenden. Keine externen Schriftdateien oder neue Bibliotheksabhängigkeiten erforderlich.

| Unterstützte Locales | Geplante Schriftstrategie |
| --- | --- |
| enUS, deDE, esES, esMX, frFR, ptBR | Automatisch plus bestehende vier Schriftwahlen |
| koKR | Koreanische Client-Schrift; `2002.TTF` als zu prüfender nativer Kandidat |
| zhCN | Vereinfachtes Chinesisch; `ARKai_C.ttf` / `ARKai_T.ttf` als zu prüfende Kandidaten |
| zhTW | Traditionelles Chinesisch; `bHEI01B.TTF` / `blei00d.ttf` als zu prüfende Kandidaten |
| ruRU | Kyrillische Client-Schrift; `FRIZQT___CYR.TTF` / `MORPHEUS_CYR.TTF` als zu prüfende Kandidaten |

Die genannten Dateien stammen aus Blizzards Schriftdefinitionen. Ihre Verfügbarkeit und Darstellung sind vor Aufnahme in eine clientübergreifende Auswahlliste separat zu prüfen. Nicht behaupten, jede dekorative westliche Schrift besitze auf jedem Client ein identisches nichtlateinisches Gegenstück.

4. Auch bekannte westliche Pfade aus Altprofilen erkennen: Sie dürfen auf koKR/zhCN/zhTW/ruRU die sichere Auswahl nicht umgehen. Gültige benutzerdefinierte Pfade weiterhin unterstützen, aber deren Glyphenabdeckung nicht allein aus erfolgreichem `SetFont` ableiten. Effektive Ersatzwahl im Auswahlfeld/Hinweis transparent anzeigen, gespeicherten Originalwert nicht stillschweigend löschen.
5. Fehlschlagende `SetFont`-Aufrufe sicher behandeln und auf die Client-Schrift zurückfallen. Falls kein verwendbarer Pfad verfügbar ist, die geerbte Tooltip-Schrift erhalten statt einen ungültigen Pfad oder einen garantierten westlichen Fallback aufzuzwingen. Farben und übrige Darstellung weiter anwenden.
6. Defaults, Reset, Profilwechsel, Profilübersicht und Tooltip-Aktualisierung konsistent anpassen. Keine vollständigen Profilresets; Größe, Farben und andere Einstellungen bleiben erhalten. Lesbarkeit geht bei einer inkompatiblen Schrift vor einer nicht darstellbaren dekorativen Wahl.

### C. Kommentare und Lokalisierungen

- Geänderte Helfer mit DE-/EN-Kommentaren zu Locale-Auswahl, Fallback, Altprofilen und addon-eigener UI dokumentieren.
- Vorhandene Kommentare an das tatsächliche Verhalten angleichen, beispielsweise die Minimap-Titelgröße `fontSize + 4`.
- Kommentare sind Erklärungen, keine auskommentierten alten Implementierungen, Diagnosezweige oder deaktivierten Funktionen.
- Neue sichtbare Begriffe wie „Automatisch (Client-Schrift)“ und gegebenenfalls der Hinweis auf eine Ersatzschrift in allen zehn Locale-Tabellen ergänzen. Neue Schlüssel nur hinzufügen, wenn sie in der Umsetzung tatsächlich verwendet werden.
- Stabile interne Schriftwerte nicht durch übersetzte Labels ersetzen. UTF-8, gleiche Schlüssel und passende Format-Platzhalter prüfen.

### D. Prüfungen erweitern

- Vorhandene Chat-, Cinematic-/Taint-, Funktionserhalt- und Lokalisierungsprüfungen weiter ausführen.
- Testannahmen zu genau zehn TOCs und lokalen Config-Fonthelfern an die neue Struktur anpassen, ohne Schutzprüfungen zu entfernen. Forever muss ausdrücklich in der erwarteten Clientliste stehen; bloßes Zählen beliebiger TOCs genügt nicht.
- Ausführbare Lua-Tests mit simulierten Client-Fontobjekten ergänzen: alle zehn Locales; fehlendes `STANDARD_TEXT_FONT`; fehlendes/defektes Fontobjekt; leere/ungültige Werte; alte Namen und Pfade; eigene Pfade; fehlgeschlagenes `SetFont`; Profilwechsel und Reset. Beide Tooltip-Aufrufer müssen denselben Resolver verwenden.
- Verifizieren, dass globale Blizzard-Fonts und fremde Tooltips unverändert bleiben. Lua-Syntax und TOC-Ladereihenfolge prüfen.
- Ingame: koKR/zhCN/zhTW/ruRU jeweils Minimap- und Optionen-Tooltip mit nativen Buchstaben, lateinischen Zeichen und Zahlen prüfen; neue und alte Profile, Schriftwahl, Größe, Farben, Reset, Profilwechsel und `/reload`. enUS/deDE als Vergleich. Glyphendarstellung kann ein Mock-Test nicht beweisen.
- Ingame: Forever ohne „Veraltete Addons laden“ starten, Optionen öffnen und normale Questannahme, Fortschritt, Abschluss und Abgabe testen. Videoquest vollständig und mit Abbruch testen; Auto-Turn-In-Option, Soundkanäle, Questlinks, Kampf-/Chat-Schutz und ausbleibende doppelte Meldungen prüfen.
- Für jeden unterstützten Client aus der Versionsmatrix Ladefähigkeit mit ausgeschaltetem Outdated-Schalter, Optionen, Questabläufe, Links, Sounds und Schutzmechanismen prüfen. Ingame-Tests auf allen verfügbaren Clients durchführen und fehlende Clients als offene Abnahme dokumentieren; für ungetestete Varianten keine neue Laufzeitgarantie behaupten. Repräsentative Einzeltests ersetzen nicht die vollständige Clientliste.

### E. Dokumentation und RC

README und Changelog zunächst als geplante, unveröffentlichte Arbeiten kennzeichnen. Nach Umsetzung durch tatsächliche Änderungen, getestete Builds und verbleibende Grenzen ersetzen. Im Changelog ein kurzer Dank an [user_n6i4a961y2ds2da7](https://legacy.curseforge.com/members/user_n6i4a961y2ds2da7) für den Schriftartenhinweis.

Die verifizierten Spielversionen/Interfacekennungen aller unterstützten Clients und der jeweilige Teststatus werden in der Dokumentation aufgeführt. Die Versionsdaten vor dem RC-Build erneut abgleichen, damit ein zwischenzeitliches Clientupdate nicht ungeprüft bleibt.

Erst nach erfolgreicher Umsetzung und Prüfungen einen neuen RC mit konsistenter Addonversion, passenden TOCs, ZIP-Inhalt und Prüfsumme vorbereiten. Der bisherige RC1 bleibt unverändert; kein bestehendes Release überschreiben. Ein RC darf vor abgeschlossenen Ingame-Tests bereitgestellt werden, muss dann die noch offenen Tests ausdrücklich nennen. Veröffentlichung ist ein separater Umsetzungsschritt, nicht Teil dieser Planungsrunde.

## 3. Unveränderliche Schutzregeln

- Keine Rückkehr zu `UIDropDownMenu`, globalen Popup-Einträgen oder Änderungen an Blizzards `EventRegistry`.
- Keine neuen Hooks an Questabgabe-Buttons oder Blizzard-Questabschlussfunktionen. Eventbasierter Intent und entkoppelte `QUEST_TURNED_IN`-Verarbeitung bleiben erhalten.
- Anonymes addon-eigenes Raidwarnungsfenster, sichere Questlink-Nachhooks und Kampfprüfungen bleiben erhalten.
- Chat-Retry bleibt auf die jüngste Nachricht und zehn Sekunden beschränkt; keine Wiederholung lokaler Sounds oder Frames.
- Questfilter, Ausgabekanäle, Fokus-Flüstern, Minimap-Bedienung, Soundoptionen, Profile und bestehende unterstützte Locales werden nicht gestrichen.

## 4. Abnahmekriterien

Die Meldungen gelten erst als behoben, wenn Forever mit passender TOC ohne Outdated-Schalter lädt und die Funktionsprüfung besteht, beide Tooltip-Arten auf den vier betroffenen Locales lesbar sind, Altprofile ohne Einstellungsverlust funktionieren und die bisherigen Schutzprüfungen weiterhin bestehen. Zusätzlich muss die Versionsmatrix alle unterstützten Clients abdecken und jede TOC dem belegten aktuellen beziehungsweise letzten offiziellen Stand entsprechen. Offene Ingame-Tests bleiben als solche sichtbar und verhindern eine Behauptung vollständiger Laufzeitprüfung. Bis dahin bleiben Metadatenhypothese, technische Umsetzung und Ingame-Bestätigung getrennt dokumentiert.
