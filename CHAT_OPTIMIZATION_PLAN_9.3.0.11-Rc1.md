# Plan: Quest Announce 9.3.0.11-Rc1

## Nachprüfung und Überarbeitung vom 07.10.2026 / Review and revision dated October 7

DE: Nach den echten Retail-Logs vom 5./6. Oktober wurde die Folgeumsetzung mit Diagnosebuild `20261007-1` durchgeführt: vorläufige Retail-GUILD-Zurückhaltung statt unvollständigem Map-Guard, getrennte normale Tests/Raw-Probes, Aufbauphasen und Kanalfortschritt, 60 Sekunden nutzbare/180 Sekunden harte Aufbaufrist, begrenzte Antwortenwiederholung, protokollierter Kontrollverkehr, Reload-Neuaufbau und Starter-/Echohinweise. 38 neue Texte in zehn Sprachen und DE/EN-Kommentare ergänzt. Der Einzelabgleich bleibt zur Protokollkompatibilität erhalten. Vorherige echte Empfangsbelege sind dokumentiert; Ursachen und Live-Abnahme des neuen Builds bleiben offen. Vollständiger Folgeplan: CHAT_DIAGNOSTICS_FOLLOWUP_PLAN_2026-10-07.md. Historische Aussagen unten beschreiben den vorherigen Stand.

EN: Follow-up implementation after real Retail logs from October 5/6 uses diagnostic build `20261007-1`: temporary Retail GUILD withholding replaces the incomplete Map guard; separate normal tests/raw probes; setup phases/channel progress; 60 seconds usable/180 seconds hard setup limit; bounded missing-reply retries; logged control traffic; fresh setup after reload; Starter/echo notices. Added 38 strings across ten locales and DE/EN comments. Individual preparation is retained for protocol compatibility. Previous real receipts are documented; underlying causes and live acceptance of the new build remain pending. Full follow-up plan: CHAT_DIAGNOSTICS_FOLLOWUP_PLAN_2026-10-07.md. Historical statements below describe the previous build.

Stand: 06.10.2026. Vom Nutzer zur Umsetzung freigegeben; als 9.3.0.11-Rc1 umgesetzt. Automatisierte Prüfungen und Paketprüfung erfolgen vor dem Draft-PR; die Ingame-Abnahme des RC bleibt offen. Bezug: GitHub Issue #22 (https://github.com/Gyffes/Quest-Announcer-3/issues/22), ursprünglich von Nerf_Teh_Derp auf CurseForge gemeldet. Ergebnis und Testanleitung: RELEASE_NOTES_V9.3.0.11-Rc1.md.

## Ziel und Evidenz

Automatischen Chatversand pro Kanal, Client und Restriktionszustand entscheiden statt pauschal bis Kampfende zu warten. Bestehende Funktionen, Profile und lokale Ausgaben erhalten. Neue Ausgabeoptionen EMOTE und RAID sowie integrierte Diagnose ergänzen.

Retail 12.1.0.69933 wurde in offener Welt, Flammenschlund, Onyxias Hort und Rubinlebensbecken (Anhänger) geprüft. Empfang/Ausgabe wurde vom Nutzer für die relevanten nicht blockierten Tests bestätigt. Bei getesteten Encounters wurden sämtliche versuchten Kanäle blockiert, während Chat=2 und InChatMessagingLockdown=true waren. GUILD wurde in getesteten Instanzen auch ohne Encounter blockiert; CHANNEL in allen bisherigen automatischen Tests. SAY/YELL wurden draußen blockiert, in Instanzen ohne Chatsperre nicht. Das sind Befunde für die getesteten Situationen, keine universellen Garantien.

Chat-Lockdown kann vor persönlichem Kampfstatus aktiv werden. API-Rückkehr/pcall-Erfolg ist kein Zustellnachweis. Gespeicherte Townlong-Quellen und verfügbare Blizzard-Unterlagen erneut prüfen.

## Versandlogik und Clients

- Beide pauschalen Kampfprüfungen in IsChatSendRestricted und DispatchChatOutputs durch konsistente zentrale Entscheidungen ersetzen.
- Alle vorhandenen Clientvarianten unterstützen: Retail, Era/Hardcore/SoD, TBC/Anniversary, Wrath, Cata, MoP/Mists, Forever/Camelot und universelle TOC. Historische Aliase sind keine eigenständigen Clients.
- APIs, sichere Rückgabewerte und Activating/Active-Zustände prüfen. Fehlende APIs oder unsichere Werte bedeuten keine Sendefreigabe. Regeln je Client durch Quellen/Messungen begründen, andernfalls konservativer Fallback mit Diagnosemöglichkeit.
- Retail: aktive Chatsperre bzw. aktivierende Chat-/Encounter-Restriktion stellt alle Chatziele zurück.
- PARTY/INSTANCE_CHAT/RAID: passende Gruppenart prüfen; gewöhnlicher Kampf allein keine pauschale Verzögerung in belegten Kontexten. PARTY und RAID ausdrücklich trennen, keine Doppelzustellung erzeugen.
- RAID nur bei passender Raidgruppe. EMOTE eigener Versandzweig. Beide neuen Optionen standardmäßig aus.
- WHISPER: Empfänger prüfen. Fokus als WHISPER an gültigen Spieler mit vollständigem Namen behandeln; geheime/nicht auswertbare Werte sicher abweisen.
- OFFICER: Gildenzugehörigkeit und verfügbare Berechtigungsprüfung, getrennte Regeln von GUILD.
- GUILD bei aktiver Retail-Map-Restriktion zunächst zurückstellen; außerhalb belegter Sperrkontexte gewöhnlichen Kampf nicht pauschal abwarten.
- SAY client-/kontextabhängig, auf geprüfter Retailbasis nur erlaubter Instanzkontext ohne Chatsperre; draußen nicht automatisch freigeben.
- CHANNEL auf geprüfter Retailbasis automatisch sperren. Andere Clients separat bewerten. Lokalisierter Hinweis auf derzeitige Blizzard-Blockierung, ohne Warnspam. Gespeicherte Kanaloptionen erhalten.
- YELL und echter RAID_WARNING-Chat nur als Diagnoseziele, keine neuen produktiven Ausgabeoptionen in diesem RC.
- Questlinks, Nachrichtengröße, Sonderzeichen und geheim/nicht auswertbar gewordene Inhalte prüfen, insbesondere bei echten Questereignissen.

## Wartende Ausgaben

- Ziele getrennt vormerken; bereits versendete Ziele nicht nachholen. Empfänger beim Vormerken festhalten, kein Umleiten durch Fokuswechsel.
- Bisherige Zehn-Sekunden-Grenze für veraltete Meldungen erhalten. Speicher und Versand begrenzen; keine Nachrichtenstapel nach langen Bosskämpfen.
- Vor Nachholen Einstellungen, Pause, Profil, Zielkonfiguration, Gruppe und Restriktionen erneut prüfen.
- Bei Pause/Deaktivierung, Profilwechsel und Reset bereinigen.
- Auf Restriktionsänderung und Kampfende im folgenden Timerdurchlauf erneut prüfen; nicht unmittelbar vom Eventzustand auf Freigabe schließen.
- Keine Wiederholungsschleifen gegen unveränderte Sperren. Normale Ausgabe und aktive Diagnose koordinieren, damit gemeinsame Versandlast keine Nachrichtenflut erzeugt.

## Optionen und bestehende lokale Ausgaben

- Chatfenster in Chatankündigungen umbenennen, Hauptschalter und Unterziele im Tooltip erklären; announceTo.chatFrame erhalten. Kein Umdeuten vorhandener Profile auf RAID.
- Historie: Chat Frame/Chatfenster bereits in ältestem verfügbaren Commit 5c933b9 vom 16.10.2022, Version 9.0.1.2. Keine belegte Umbenennung von Schlachtzug zu Chatfenster.
- Layout der Kanaloptionen:

| Zeile | Links | Mitte | Rechts |
| --- | --- | --- | --- |
| 1 | SAY | OFFICER | EMOTE (neu) |
| 2 | PARTY | GUILD (getauscht) | RAID (neu) |
| 3 | INSTANCE_CHAT | Fokus (getauscht) | |

- Whisper-/Kanal-Eingabefelder darunter erhalten. UI-Skalierung, Fensterbreite, lange Übersetzungen und Tooltips prüfen.
- Neue Optionen in Defaults, Migration/Laden, Reset, Profilwechsel, Import/Export, Übersicht, UI-Refresh und Testnachrichten integrieren. Bestehende Einstellungen erhalten.
- Addon-eigenen Raidwarnungsersatzframe funktional/optisch erhalten. Chatwartelogik darf lokale Anzeige, UI-Fehlerausgabe und Sounds nicht versehentlich zurückstellen.
- UIErrorsFrame:AddMessage separat anhand Quellen und gezielter Tests außerhalb Kampf, im Kampf und Encounter prüfen. Unterschiedliche Signaturen/fehlende Frames berücksichtigen. Bei belegter Einschränkung gezielte Anpassung; keine Hooks oder Änderungen an Blizzards Fehlerbehandlung.

## Integrierte Diagnose

- Separater Diagnosemodus, standardmäßig aus, unabhängig vom bestehenden Debugmodus. Einstellungen und Slash-Befehle für Aktivierung/Status/Abbruch/Logverwaltung.
- Stille Aufzeichnung echter Versandentscheidungen ohne zusätzliche Chatnachrichten. Kein dauerhaftes Diagnose-Polling im ausgeschalteten Zustand.
- Aktive Serien ausdrücklich starten: out/combat/encounter, alle elf relevanten Chattypen inklusive YELL und RAID_WARNING. Nachrichten sichtbar, Schutzfehler nicht unterdrücken. Fehlende Voraussetzungen überspringen; Abstand, Timeout, Abbruch und einmaliger Versuch pro Schritt.
- Eigene Testempfänger-/Testkanalkonfiguration, kein Überschreiben produktiver Einstellungen oder automatischer Kanalbeitritt.
- Optional gezielte lokale Anzeigetests für UI-Fehlerfenster/Raidersatz zur fehlenden Abnahme vorsehen.
- Eigene SavedVariable QuestAnnounceDiagnosticsDB in allen Produktions-TOCs. WoW schreibt erst bei Reload/Logout/sauberem Exit; keine beliebige Datei aus dem Addon heraus schreiben.
- Begrenzter Ringspeicher, Sitzungszahl und Textlängen; Loglöschung getrennt von Profilen. Schema/Altwerte robust behandeln. Keine Netzwerkübertragung.
- Build/Client, Session, Zeit, Kanal, Kontext, Restriktionen, Entscheidung/Grund, wartende Abläufe und relevante Fehler erfassen. Nachrichtentexte standardmäßig nicht speichern; Empfängerangaben minimieren.
- Sitzungskennung plus Test-ID verhindert Verwechslungen nach Reload/zwischen Spielern. Lokale Anzeige, fremder Empfang, API-Rückkehr und Blockierung getrennt erfassen. Keine ungeprüfte Zuordnung fremder Schutzfehler.
- Manuelle Empfangsbestätigung und Erfassung passender Testnachrichten beim Empfänger mit aktivierter Diagnose. Keine automatische Empfangsbehauptung.
- Aktivierte stille Aufzeichnung darf nach Reload fortgesetzt werden. Aktive Serien niemals automatisch neu starten.
- Fehlende APIs als nicht verfügbar protokollieren. Andere Clients durch echte Diagnosemessungen verifizieren, ohne Retail-Befunde zu übertragen.

## Lokalisierung, Kommentare und Dateien

- Sämtliche vorhandenen Sprachentabellen und Fallbacks berücksichtigen: Beschriftungen, Tooltips, Diagnosebefehls-Hilfe, Status, Fehler, Bestätigung, Abbruch, Profilübersicht, CHANNEL-Hinweis und lange Texte. Schrift-/Glyphenfallbacks erhalten und prüfen.
- Neue/geänderte Codeabschnitte verständlich auf DE/EN dokumentieren: Wirkung und Begründung. Veraltete Kommentare aktualisieren; keine auskommentierten Altblöcke.
- QuestAnnounce.lua, Config.lua, Localization.lua und weitere Lua-Dateien soweit erforderlich ändern. Zusätzliche Module, falls sinnvoll, in alle TOCs korrekt eintragen.
- Alle 14 Produktions-TOCs und aktuelle Versionsreferenzen auf exakt 9.3.0.11-Rc1. SavedVariables und Ladefolge konsistent. Interface-Kennungen nur bei belegtem Bedarf ändern.
- README, CHANGELOG.txt, CLIENT_VERSIONS.md und neue RC-Release-Notes zweisprachig aktualisieren; alte Release Notes erhalten. Dank/Verweis auf Nerf_Teh_Derp, Issue #22.

## Prüfung und Lieferung

- Vor Beginn Branch, Remote, Zielbranch und bestehende PR-/RC-Basis prüfen; Änderungen nicht vermischen.
- Lua-Syntax/Laden, alle TOCs, Dateien/Ladefolge, Localization-Key-/Platzhalterabdeckung und Profilkompatibilität prüfen.
- Clientfamilien mit/ohne moderne APIs; Kampf/Map/Chat/Encounter und Übergangszustände, gemischte Ziele, Ablauf, Duplikate, Tod, Pause, Reset, Profil-/Gruppen-/Fokuswechsel testen.
- Neue EMOTE-/RAID-Optionen, aktive/passive Diagnose, Speichergrenzen, Reload, Loglöschung und Ergebniszuordnung testen.
- Bestehende Questannahme/Fortschritt/Abschluss/Abgabe, Filter, Links, Sounds, lokale Anzeigen, Minimap und Einstellungen auf Regressionen prüfen.
- Echte Questereignisse und lokale Anzeigetests im Spiel separat abnehmen. Quellenprüfung/Mocks sind kein Ingame-Kompatibilitätsnachweis. Fehlende Clientzugänge, insbesondere Forever, dokumentieren.
- Installierbares RC-Paket prüfen: Addon-Wurzelordner, benötigte Lua-/TOC-Dateien, Medien und Version. reference/, persönliche Logs und separates Diagnoseaddon nicht versehentlich aufnehmen.
- Nach Freigabe auf codex/-Branch implementieren, prüfen, committen/pushen und zweisprachigen Draft-PR mit Issue #22 und Test-/Abnahmegrenzen erstellen; PR dem Chat anhängen.
- Kein automatischer Merge oder Release. Keine Garantie völliger Fehlerfreiheit, sondern dokumentierte Tests und offene Abnahmen.

## Status

Alle besprochenen Ergänzungen sind umgesetzt. Lua-5.1-Mocks, 70 Client-/Locale-Kombinationen, TOC-/Übersetzungsprüfung und gezielte Routing-/Diagnoseprüfungen bestehen. Der Draft-PR baut auf dem noch offenen PR #21 auf. Die echte Ingame-Abnahme bleibt ausdrücklich offen; Details und Befehle stehen in RELEASE_NOTES_V9.3.0.11-Rc1.md.

## Ergänzung vom 06.10.2026 / Extension on 2026-10-06

DE: Freigegebener Diagnoseausbau umgesetzt: gegenseitiger Testpartner mit ausdrücklichem Empfangsmodus; Channel-Auswahl; vorab abgeglichene IDs und Chattypen; automatische Bestätigung erst nach tatsächlichem Chatereignis beim Partner; Ergebnisliste und manueller Button für lokale/unbestätigte Tests. Begrenzte Addon-Kommunikation statt sichtbarer Bestätigungsnachrichten; temporäre Sperren/Drosselungen puffern Rückmeldungen bis zehn Minuten über Reload, dauerhafte/geschützte Fehler werden nicht wiederholt. Empfängerbelege bleiben separat gespeichert. Keine Wiederaufnahme aktiver Tests, keine Umgehung von Blizzard-Sperren. GUID/Name-Realm-Echoerkennung, Accountmerkmale, ältere API-Varianten, zehn Locales und alle TOCs berücksichtigt. Zweiclient-Mocks bestehen; echte Partnerkommunikation im Spiel ist noch zu prüfen. Vollständiger Ablauf und Grenzen in den RC-Hinweisen.

EN: Approved diagnostic extension implemented: mutual test partner with explicit receiver mode; channel selection; prepared IDs/chat types; automatic acknowledgement only after the peer receives the actual chat event; result list and manual button for local/unconfirmed tests. Bounded addon communication replaces visible confirmation messages; temporary locks/throttles buffer replies for up to ten minutes across reload, permanent/protected failures are not retried. Recipient evidence is stored independently. No resumption of active suites or bypass of Blizzard restrictions. GUID/name-realm echo detection, account flags, older API variants, ten locales and all TOCs covered. Two-client mocks pass; actual in-game peer communication remains to be tested. Full workflow and limits are documented in the RC notes.
