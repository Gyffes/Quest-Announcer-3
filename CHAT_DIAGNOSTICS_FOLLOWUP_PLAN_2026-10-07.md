# Umsetzungsplan: Chatversand und Diagnose nach den Tests vom 5./6. Oktober

Stand: 07.10.2026. Status: freigegeben und umgesetzt als Diagnosebuild `20261007-1` innerhalb des bestehenden 9.3.0.11-Rc1. Lokale Routing-/Zweiclient-/Locale-Prüfungen bestanden; reale Ursachenklärung und Live-Abnahme bleiben offen. Die Abschnitte unten erhalten den freigegebenen Plan als Arbeitsgrundlage.

Umsetzungsentscheidung: Der bestehende Einzelabgleich wurde für Protokollkompatibilität beibehalten. Fortschritt, nutzbare/hart begrenzte Fristen und Wiederholungen fehlender Antworten verbessern den Aufbau; Paketbündelung wurde nicht als unbelegte neue Protokolländerung eingeführt. Ein separates BUILD-Paket ergänzt die Diagnosekennung. Es waren keine neuen Module, TOC-Ladefolgeänderungen oder destruktiven Schemawechsel nötig.

EN: Planned follow-up to the existing 9.3.0.11-Rc1: investigate and conservatively handle unresolved GUILD restrictions, improve peer preparation/reload behavior, and make diagnostic evidence and failure reasons clear in all supported locales. Existing functions and profiles remain supported. Observations from Retail do not establish permissions on other clients.

## 1. Grundlage, Umfang und Versionsbasis

- Auf dem vorhandenen Branch `codex/chat-optimization-9.3.0.11-rc1` und dem bestehenden offenen RC weiterarbeiten. Vor Implementierung Status, HEAD, Remote, PR #23 und dessen Basis PR #21 erneut abgleichen. Keine unabhängigen Änderungen vermischen.
- Versionsbasis bleibt entsprechend dem bisherigen Auftrag **9.3.0.11-Rc1**. Die neue Diagnose erhält zusätzlich eine eindeutige interne Build-/Diagnoserevision; bei beiden Spielern protokollieren und im Status anzeigen. Gleiche TOC-Version allein reicht für den Abgleich verschiedener Teststände nicht aus.
- Quellen: vorhandener ursprünglicher Umsetzungsplan, Abschlussbericht vom 6. Oktober, beide Accounts und das vorherige separate Diagnoseaddon. Persönliche Daten und Logs verbleiben lokal.
- Bei der Umsetzung Blizzards extrahierte API-/UI-Quellen aus Townlong erneut heranziehen: ChatInfo, RestrictedActions, Enum-Werte, ChatFrameEditBox und MessageFrame/UIErrorsFrame. Quellenstand/Build festhalten. Aktuelle Primärquellen nachprüfen, wenn eine neue Restriktionsregel oder API-Annahme erforderlich wird.
- Questie und Issue-Berichte sind Vergleichsmaterial; fehlende Issues sind keine Sendefreigabe. Keine Gleichsetzung von Macro-Regeln, sichtbarem Chat und Addon-Kommunikation.
- Kein Merge oder Stable-Release im Rahmen dieser Umsetzung.

## 2. Verbindliche Befunde und offene Grenzen

- Retail 12.1.0.69933: GUILD in den jüngsten Instanz- und Freiwelttests blockiert; draußen auch bei Map=0, Chat=0 und chatLock=false. Anfangs am 5. Oktober draußen noch unblockierte Aufrufe und Nutzerbestätigung. Der Grund dieser unterschiedlichen Ergebnisse ist offen.
- GUILD-Instanzfehler bestanden schon im separaten Diagnoseaddon. Kein belegter Fehler durch die neu hinzugefügte Empfangsbestätigung; kein bisher gefundener falscher GUILD-Parameter.
- OFFICER separat betrachten. Neueste Aufrufe ohne Schutzfehler; neuester Starter-Empfänger kann Gildenempfang nicht belegen. Frühere Nutzerbestätigungen bleiben als solche dokumentiert.
- 18 tatsächliche Partnerempfänge für SAY/YELL/EMOTE/PARTY/INSTANCE_CHAT/WHISPER in den jeweiligen gemessenen Kontexten abgeglichen. Das ist keine Freigabe jeder Kanal-/Kontextkombination.
- Encounter: Partner erkannt, Vorbereitung beim frühen Pull noch unvollständig; Chatsperre pausiert Kommunikation, Aufbaufrist läuft weiter. Keine Chatprobes in dieser abgebrochenen Serie.
- Zwei weitere Aufbaufehler nach Reload draußen ohne Chatsperre; eigenständig untersuchen. Empfangsmodus, Prefix, Transport und Protokollverarbeitung sind mit den alten Logdaten nicht hinreichend rekonstruierbar.
- Alle vorhandenen Sendeversuche mit ATTEMPT sind Diagnoseversuche. Normaler Questversand ohne aktive Serie ist nicht separat ingame nachgewiesen.
- Fremde Addon-Schutzfehler dürfen nicht QuestAnnounce zugerechnet werden. API-Rückkehr, eigener Echo und fremder Empfang bleiben verschiedene Befunde.
- Keine weiteren Ingame-Tests des Nutzers als Voraussetzung. Offene Live-Abnahmen bleiben dokumentiert. Lokale Simulationen sind kein Blizzard-Freigabenachweis.

## 3. Normale Kanalregeln

Gemeinsame zentrale Entscheidung mit eindeutigem Ergebnis: senden, temporär warten oder diesen Versand verwerfen. Gründe strukturiert erfassen. Aktivierende/aktive Chat-/Encounter-Sperren, Chatsperre und sichere API-Abfragen erhalten. Keine Blizzard-Sicherheitsfunktionen überschreiben oder Sperren umgehen.

| Ziel | Nächste Umsetzung |
|---|---|
| GUILD | Sender, Sprache/optionale Argumente, Aufrufkontext und beide Diagnose-/Normalpfade gezielt auditieren. Map=0/Chat=0 niemals allein als sichere Freigabe darstellen. Falls kein belastbarer gezielter Fix nachgewiesen werden kann, automatisches GUILD auf der gemessenen Retailbasis vorübergehend vor dem API-Aufruf zurückhalten. Das ist eine vorsichtige Addon-Entscheidung, keine Behauptung eines generellen Blizzard-Verbots. Profilwahl erhalten; begründeter lokalisierter Status statt Fehlerserie. |
| OFFICER | Eigene Regel erhalten, nicht wegen GUILD pauschal sperren. Gildenzugehörigkeit prüfen; tatsächliche Sprechrechte WoW überlassen, sofern keine geeignete API belegt ist. CanEditOfficerNote nicht als Sprechrecht verwenden. |
| PARTY | Passende Home-Gruppe, kein Raid; gewöhnlicher Retail-Kampf allein bleibt kein pauschaler Verzögerungsgrund. |
| INSTANCE_CHAT | Nur passende Instanzgruppe; Aufenthalt in einer Instanz allein reicht nicht. |
| RAID | Nur Raidgruppe; vorhandene eigene Option und Gruppenprüfung erhalten. |
| WHISPER / Fokus | Gültiger Spieler mit vollständigem Namen; Fokus ist derselbe Chattyp WHISPER. Beim Vormerken Ziel einfrieren, identische Fokus-/Whisper-Ziele nur einmal bedienen. |
| SAY | Bestehende Retail-Instanzregel außerhalb PvP/Arena erhalten; draußen keine automatische Freigabe. |
| YELL | Diagnoseziel mit eigener Kontextdarstellung; im derzeitigen Produktionsrouting keine eigene YELL-Checkbox hinzufügen. |
| EMOTE | Vorhandene Ausgabeoption erhalten; neue Freiwelt-Empfangsbelege aufnehmen, gemeinsame Sperren beachten. |
| CHANNEL | Automatischer Retail-Versand weiter gesperrt; Hinweis für alle Sprachen, gespeicherter Kanal erhalten. Diagnose darf bewusst einen einzelnen Restriktionstest durchführen. |
| RAID_WARNING | Echten Netzwerkchat weiter als Diagnoseziel behandeln. Vorhandener produktiver Raidwarnungsersatz bleibt lokale Anzeige. Keine Umwandlung in einen geschützten Blizzard-Raidwarnungsaufruf. |

Für unerwartete eigene geschützte normale Aufrufe eine begrenzte, kanalbezogene Laufzeitsperre prüfen: keine wiederholten Aufrufe unter unveränderten Bedingungen, andere Ziele bleiben aktiv. Ein API-Erfolg ohne Empfang ist kein Grund, solche Sperren automatisch aufzuheben. Bei GUILD genügt Kampfende/Map=0 ausdrücklich nicht zum Entsperren. Diagnoseergebnisse dürfen keine unbelegte automatische Produktivfreigabe auslösen.

## 4. Weitere Clients

- Derselbe Funktions-/Diagnoseumfang in allen vorhandenen Varianten: Retail, Era/Classic/Hardcore/SoD, TBC/Anniversary, Wrath, Cata, MoP/Mists, Forever/Camelot und universelle TOC.
- Vorhandene Funktionen, sichere Werte und API-Rückgabevarianten prüfen, nicht allein eine TOC-/Interface-Zahl als Laufzeitentscheidung verwenden.
- Andere Clientfamilien behalten den konservativen Kampffallback und ihre bisherigen Regeln. Neue Retail-GUILD-Sperre nicht ohne Beleg auf alle Clients übertragen.
- Fehlende/unsichere Restriktionswerte erteilen keine Freigabe. Fehlende Diagnose-Transport-APIs führen zu klarer Meldung und manueller Diagnosemöglichkeit.
- Clientkennung, Spielbuild, API-Fähigkeiten und Regelgrund protokollieren. Ungeprüfte Clients, insbesondere Forever, nicht als live bestätigt ausgeben.

## 5. Warteschlange und unveränderte Grundfunktionen

- Neueste Meldung pro Ziel höchstens zehn Sekunden vormerken; globale Versandabstände, faire Zielreihenfolge und begrenzter Speicher erhalten.
- Bereits gesendete Ziele nicht wiederholen; geschützte oder dauerhafte Fehler weder mit pcall noch mit Retry-Schleifen als erledigten Versand behandeln.
- Vor Nachholen Pause, Aktivierung, Profil, Zielwahl, Gruppe, Empfänger und Restriktionen erneut prüfen. Profilwechsel/Reset/Deaktivierung/Tod sauber bereinigen.
- Lange Partner-Vorbereitung darf normalen Questversand nicht unnötig blockieren: Vorbereitung benötigt noch keine exklusiven sichtbaren Chat-Sendeslots. Echte Diagnoseprobes und normale Meldungen teilen sich weiterhin den globalen Abstand und eindeutige Fehlerzuordnung.
- Erhalten: Questannahme, Fortschritt, Abschluss und Abgabe, Filter, Links und Klickaktionen, Auto-Turn-In-/Soundlogik, lokale Anzeigen, Minimap, Profile, Import/Export, Defaults und Reset.
- Layout erhalten: rechts EMOTE mit RAID darunter; mittig OFFICER, GUILD, Fokus. „Chatankündigungen“ bleibt Hauptschalter mit bestehendem Profilfeld, keine Umdeutung alter Profile auf RAID.

## 6. Partneraufbau als sichtbarer, prüfbarer Ablauf

Phasen: inaktiv → Partner suchen → Partner erkannt → Kanäle vorbereiten → bereit/wartet auf Testkontext → Test läuft → abgeschlossen/abgebrochen. Eine unterbrochene Vorbereitung wird zusätzlich als Wartezustand angezeigt, ohne Bereitschaft vorzutäuschen.

- Schon vor Start Partnerangabe, eigener/anderer Charakter, Empfangskonfiguration soweit bekannt, Prefix-Registrierung und vorhandene APIs prüfen.
- Erst nach der vollständigen Bestätigung aller ausgewählten Kanal-/Test-IDs bereit melden. Fortschritt z. B. „7 von 11 Kanälen vorbereitet“.
- Vorabpakete möglichst zusammenfassen, wenn Sitzungs-/Tokenprüfung und die API-Nachrichtengröße von 255 Bytes das erlauben. Anzahl und Gesamtlänge begrenzen, keine Drosselungsumgehung. Bei Protokolländerung versionieren und Versionskonflikte klar melden; sonst bewährten Einzelabgleich erhalten.
- Reihenfolge und Prioritäten der internen Warteschlange prüfen; enqueue-Fehler, volle Queue und abgelaufene Pakete nicht still verlieren.
- Gezielt begrenzte Wiederholung fehlender Verbindungsantworten zulassen, sofern keine Schutz-/permanenten Fehler vorliegen. Doppelte HELLO/Registrierungen/ARMED/ACK müssen idempotent bleiben. Keine Wiederholung sichtbarer Testnachrichten.
- Zeitbudget konkret planen: maximal 60 Sekunden nutzbare Aufbauzeit ohne lokale Chatsperre, dazu höchstens 180 Sekunden gesamte Aufbauzeit. Sperren beider Seiten können nur anhand verfügbarer sicherer Informationen unterschieden werden. Budget, Empfänger-Registrierungsfrist und Paketablauf müssen zusammenpassen.
- Beginnt ein Encounter vor Bereitschaft, „Vorbereitung durch Chatsperre unterbrochen“ anzeigen, sofern die Sperre tatsächlich gemessen wird. Kein Versand ohne vollständige Vorbereitung; während desselben ausdrücklich gestarteten Runs erst nach Freigabe weiterarbeiten, mit den genannten Grenzen.
- Nach Bereitschaft getrennte fünfminütige Serienfrist und zehnminütige Empfangsbelegfrist erhalten. Start der Serie, Bereitschaft und Empfangstimeout nicht mit einer allgemeinen „Verbindung abgelaufen“-Meldung vermischen.
- Abbruch differenzieren: kein Partnerantwort, unvollständige Registrierung, Chatsperre, API/Prefix nicht verfügbar, Protokollkonflikt, Transportfehler, Abbruch/Tod/Reload. Kein pauschaler Rat „Empfang aktivieren“, wenn der Partner bereits erkannt wurde.

## 7. Reload und Transport

- Prefix-Registrierung neu initialisieren und alle belegten Rückgaben behandeln: moderne Enum-Ergebnisse, ältere bool/nil-Varianten, Fehler und geheime Werte. Empfangsevents und Timerlebenszyklus prüfen.
- Gespeicherte Diagnoseeinstellungen beim Laden validieren. Empfang aktiv bleibt aktiv, wenn ausdrücklich so gespeichert; Partnerwechsel/Reset darf dagegen keine alte Autorisierung beibehalten.
- Aktive Serien und teilweise Aufbauten bei Reload abbrechen. Ein neuer ausdrücklich gestarteter Run muss eine neue Verbindung aufbauen können; kein altes Pair/Token darf ihn blockieren.
- Tatsächliche Empfangsbelege dürfen innerhalb ihrer zehnminütigen Frist erhalten bleiben und später gemeldet werden. Alte Belege klar alten IDs zuordnen, alte Bereitschaftsantworten nicht neuen Serien zuschlagen.
- PARTY/RAID/INSTANCE_CHAT nur verwenden, wenn der gewählte Partner in genau diesem Roster steht; sonst gezieltes WHISPER nach vorhandenen Regeln. Gruppe, vollständiger Name/Realm, Wechsel und Offlinefälle prüfen.
- Starter-/Veteranmerkmale berücksichtigen und fehlende Gilden-/Offizier-Eignung erklären. Nicht aus einem Starterflag pauschal alle Empfangstests verbieten; EMOTE/PARTY/WHISPER sind in den Logs belegt.
- Wenn der Aufbau draußen scheitert, den letzten nachweisbaren Protokollschritt anzeigen. Ein erfolgreicher SendAddonMessage-Aufruf allein beweist keine Antwort oder Zustellung.

## 8. Diagnosebedienung und Nachweise

- Stille Aufzeichnung weiterhin separat, standardmäßig aus. Keine zusätzlichen sichtbaren Chatmeldungen durch passives Logging; aktiven Testversand ausdrücklich starten.
- In der Testauswahl verständlich unterscheiden: Prüfung des normalen Versandwegs und bewusster Restriktionstest direkt an der Blizzard-API. Letzterer kann Schutzmeldungen erzeugen; Hinweis/Tooltip ohne wiederholte Bestätigungsdialoge.
- Vor jedem Test Kontext, Voraussetzungen und die normale Routingentscheidung samt Grund protokollieren. Raw-Probe und Normalversand unmissverständlich kennzeichnen.
- Alle elf Chattypen auswählbar. Fehlende Zugehörigkeit/Ziele überspringen; tatsächliches Überspringen, vorzeitiger Abbruch und durchgeführter Versuch unterscheiden.
- Automatische Bestätigung nur nach passendem tatsächlichem CHAT_MSG beim gewählten anderen Client. Eigenen Echo, API-Rückkehr, lokale Anzeige, manuelle Bestätigung und Partnerempfang getrennt anzeigen.
- Empfängerbeleg und zurückgesendetes ACK getrennt behandeln. Fehlendes ACK ist „unbestätigt“, nicht automatisch „nicht angekommen“.
- GUILD/OFFICER-Empfang als ungeeignet kennzeichnen, wenn bekannte Account-/Zugangsmerkmale entgegenstehen. Unbekannte Offizierrechte als unbekannt belassen. Manuelle Bestätigung weiter per Button/Slash erlauben.
- Lokale UIErrorsFrame-/Raidersatztests erhalten; Rückkehr ohne Fehler nicht als visuell bestätigte Anzeige ausgeben.

## 9. Logdaten und Migration

- `QuestAnnounceDiagnosticsDB` bleibt in WoWs `QuestAnnounce.lua`-SavedVariables-Datei. Speicherung bei Reload/Logout/sauberem Exit erläutern; keine frei wählbare Dateiausgabe versprechen.
- Neue Felder: Diagnosebuild/Protokoll, Phase, vorbereitete/gewählte Kanäle, Zeitbudgets, Kontrollnachrichtenart/-richtung, Transport, API-Ergebnis, Warteschlangenzustand, Restriktionswartezeit und sichere Ablehnungsgründe.
- Neu markieren: normaler Versand versus bewusster Test; eigenen Chat-/Transportfehler versus fremdes Addonereignis. Fremde Fehler optional nur aggregiert erfassen, damit sie relevante Belege nicht aus dem Ringpuffer verdrängen.
- Keine Nachrichtentexte, Klartextpartnernamen, GUIDs oder vollständige Paketpayloads im Ereignislog. Partnerangaben nur in notwendigen Einstellungen; Diagnosekennungen für Zuordnung verwenden.
- Bestehende Grenzen erhalten bzw. explizit begründet anpassen: 2000 Records, 20 Sitzungen, 100 Ergebnisse/Beleglisten, 64 Transportpakete; begrenzte Feldlängen und Ablauf aller temporären Daten.
- Schema nur bei Strukturbedarf erhöhen; vorhandene gültige Einstellungen/Belege migrieren, kein blindes Löschen wegen neuer Schemanummer. Defekte Altwerte sicher begrenzen.
- Timer nur während tatsächlicher Arbeit betreiben; deaktivierte Diagnose hinterlässt keine aktiven Test-/Transporttimer. Loglöschung getrennt von Profilreset und nachvollziehbar behandeln.

## 10. Lokalisierung, Tooltips und Kommentare

- Alle zehn vorhandenen Locales: enUS, deDE, frFR, esES, esMX, ptBR, ruRU, koKR, zhCN und zhTW. Nicht eigens unterstützte Locales verwenden weiterhin den bestehenden Fallback.
- Vollständige neue Texte für Aufbauphasen, Fortschritt, Wartezustände, Zeitüberschreitungen, GUILD-Hinweis, Starter-Eignung, Versionskonflikte, Testarten und Ergebnisgrenzen.
- Platzhalter, Schrift-/Glyphenfallback, lange Labels, UI-Skalierung, Statusaktualisierung und Scrollbereich prüfen. Technische Kennungen nur dort zeigen, wo sie die Diagnose unterstützen.
- Neue/geänderte Codeabschnitte in DE und EN erklären: Wirkung, Grenzen und Grund der Regel. Veraltete Kommentare korrigieren; keine auskommentierten alten Codeblöcke anhäufen.

## 11. Voraussichtlich betroffene Dateien

| Dateien | Aufgabe |
|---|---|
| ChatRouting.lua | Kanalentscheidungen, GUILD-Fallback, Fehler-/Wartelogik, Koordination normaler Meldungen mit Diagnose |
| Diagnostics.lua | Testarten, Zustände, Timeouts, Ereignis-/Kontextprotokoll, Migration |
| DiagnosticsPeer.lua | Aufbau, Transport, Protokollprüfung, Wiederholungsgrenzen, Reload-/Belegverwaltung |
| Config.lua | Status/Fortschritt, Testauswahl, Hinweise und Tooltips |
| LocalizationDiagnostics.lua / LocalizationChat.lua | Vollständige mehrsprachige Diagnose-/Kanaltexte |
| QuestAnnounce.lua / Localization.lua / Minimap.lua | Nur notwendige Integration/Defaults/Status; bestehende Funktionen bewahren |
| Alle 14 Produktions-TOCs | Version, SavedVariables, Dateiliste und Ladefolge prüfen; nur erforderliche Änderungen |
| README.md / CHANGELOG.txt / CLIENT_VERSIONS.md / RELEASE_NOTES_V9.3.0.11-Rc1.md | DE/EN aktualisieren: neuer Ablauf, gemessene Ergebnisse, Grenzen, Version/Diagnosebuild |
| Ursprünglicher und dieser Plan | Fortschritt und offene Abnahmen korrekt dokumentieren |

Keine unnötige Modulaufteilung. Zusätzliche Datei nur mit begründetem Bedarf und konsistenter Ladefolge in allen TOCs. Interface-Kennungen ohne neue belegte Anforderung erhalten.

## 12. Prüfung vor Lieferung

1. Lua-5.1-Syntax und vollständiges Laden; alle TOC-Dateilisten, Versionen, SavedVariables und Reihenfolgen. Vorhandene Client-/Locale-Matrix erneut prüfen, inklusive fehlender moderner APIs und sicherer Rückgaben.
2. Routing: jeder Kanal einzeln und gemischte Ziele; aktive/aktivierende/inaktive Chat-/Map-/Encounter-Zustände, gewöhnlicher Kampf, unbekannte/geheime Werte, GUILD blockiert bei sonst freiem Zustand, OFFICER unabhängig. Keine ungeprüfte Freigabe und keine Fehlerwiederholung.
3. Normalversand/Diagnose konkurrierend: Aufbau reserviert keine unnötigen Chatslots, Abstände eingehalten, keine Duplikate, Ablauf/Tod/Pause/Profil-/Gruppen-/Fokuswechsel korrekt.
4. Zweiclient-Simulation: erfolgreiche Vorbereitung, verlorene/verzögerte Antworten, Queue voll, partielle Kanalbestätigung, früher Pull, Sperre nur auf einer Seite, 60/180-Sekunden-Grenzen, bereits bereiter Encounter-Run, harte/temporäre API-Fehler, falscher Sender/Token/ID/Protokoll, Doppelnachrichten.
5. Reload beider Clients einzeln und gemeinsam: neue Verbindung möglich, keine Testwiederaufnahme, gültige Belege erhalten, alte Antworten eindeutig getrennt, Empfangseinstellung und Timer korrekt.
6. Ergebniszuordnung: API-Rückkehr und Echo erzeugen keinen Empfangsbeweis; Starter-Gildenfall verständlich; fremde Schutzfehler nicht unserem Kanal zuordnen; lokale Displays bleiben separat.
7. Defaults, Altprofile, Import/Export, Reset, Einstellungen und alle neuen Lokalisierungsschlüssel/Platzhalter prüfen. Lange Übersetzungen und vorhandene Fonts berücksichtigen.
8. Gezielt vorhandene Regressionstests zu Questannahme/Fortschritt/Abschluss/Abgabe, Links, Sounds/Auto-Turn-In, Minimap und lokalen Frames wiederverwenden. Fehlende neue Szenarien ergänzen, keine bedeutungslosen Implementierungskopien testen.
9. Paketprüfung: QuestAnnounce-Wurzelordner, vollständige Medien und benötigte Lua-/TOC-Dateien, eindeutiger Diagnosebuild und SHA256. Keine reference-Verzeichnisse, persönlichen Logs, Laufzeittesttools oder separates Diagnoseaddon ausliefern.

Bestehende reale Messergebnisse bleiben Belege des alten Stands. Neue Mock-Ergebnisse nicht als abgeschlossene Ingame-Abnahme ausgeben. Neue echte Quest-/Partner-/Clienttests bleiben offen, ohne weitere Arbeit vom Nutzer zu verlangen.

## 13. Umsetzung und Abnahme

Reihenfolge: gezielte Quellen-/Codeprüfung → Versandentscheidung und getrennte Diagnosepfade → Partneraufbau/Reload → Log-/UI-/Locale-Erweiterung → Regressionen → Dokumentation/Paket → GitHub-PR aktualisieren.

Abnahmebedingungen:

- Alle vereinbarten Funktionen, Profile und Ziele bleiben vorhanden; temporäre Kanalzurückhaltung wird sichtbar begründet.
- Unaufgeklärter Retail-GUILD-Fall erzeugt im normalen Versand keine wiederholten geschützten Versuche; eine sichere Freigabe wird nicht behauptet.
- Aufbauphase, Bereitschaft, Chatsperre und tatsächlicher Timeout sind unterscheidbar; keine scheinbare Partner-Trennung nach bereits abgeschlossener Vorbereitung.
- Neuer Run nach Reload besteht die lokalen Protokolltests; reale frühere Ausfälle bleiben bis Live-Nachweis als nicht abschließend geklärt dokumentiert.
- Nur echte Fremdempfangsereignisse erzeugen automatische Empfangsbestätigung; fehlende Belege und lokale Anzeige klar getrennt.
- Alle neuen UI-Texte/Tooltips lokalisiert, DE/EN-Codekommentare vorhanden, Checks bestanden und Grenzen dokumentiert.

Bestehenden Draft-PR #23 gezielt aktualisieren statt einen zweiten identischen PR zu erstellen, Bezug Issue #22 und PR #21 erhalten. Beschreibung, Titel und Tests DE/EN auf den tatsächlichen Endstand ausrichten; Nerf_Teh_Derp/CurseForge-Verweis erhalten. Den betroffenen PR dem Chat zuordnen. Sanitisierten Plan und Quelländerungen einchecken; private Logs/Testwerkzeuge bleiben lokal. Commit/Push/PR-Update gehören zur später freigegebenen Umsetzung, nicht zu diesem Planungsauftrag.
