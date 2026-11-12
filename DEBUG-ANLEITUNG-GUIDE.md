# Debug-Anleitung / Debug Guide — 9.3.0.12-Rc1

## Deutsch

Die allgemeine Option **Debug** und die neue **Chatdiagnose** sind unabhängig. Chatdiagnose ist bei neuen Installationen aus; bestehende Aufzeichnungseinstellungen bleiben erhalten. Sie speichert begrenzte Zustands-/Fehlerdaten und keine normalen Nachrichtentexte. Optionen: `/qa` → Chatdiagnose. Befehlswörter sind in jeder Sprache identisch.

### 1. Einen gewöhnlichen Fehler aufzeichnen

```text
/qa diag on
/qa diag mode normal
/qa diag status
```

Normal spielen und das Problem reproduzieren. Danach `/qa diag cancel`, `/qa diag off` und `/reload`. Aufzeichnung allein startet keine Chat-Testserie. Abbrechen beendet Tests; Ausschalten beendet zusätzlich Empfang und Rückmeldungen. Beide Befehle behalten aufgezeichnete Ergebnisse.

### 2. Empfang mit einem Partner prüfen

Beide Spieler installieren **9.3.0.12-Rc1** (Diagnosebuild **20261112-1**) und aktivieren `/qa diag on` sowie `/qa diag mode normal`. Beide tragen den jeweils anderen mit `/qa diag partner Name-Realm` ein. Der Empfänger aktiviert anschließend `/qa diag receive on`; ein Partnerwechsel deaktiviert den Empfang wieder.

Der Sender startet zunächst nur einen gezielten Flüstertest:

```text
/qa diag channels WHISPER
/qa diag suite out
```

Auf **Partner bereit** warten. Für Kampf/Boss die Serie vor Kampfbeginn mit `suite combat` bzw. `suite encounter` vorbereiten und erst nach Bereitschaft beginnen. Andere gewünschte Kanäle z. B. mit `/qa diag channels GUILD OFFICER` wählen; beide brauchen die passenden Rechte und für lokale Kanäle ausreichende Reichweite. Bestehende Blizzard-/Addon-Sperren bleiben im normalen Modus wirksam; GUILD kann daher bewusst übersprungen werden.

**Beim Partner empfangen** setzt ein passendes Chatereignis beim anderen Client voraus. Eigener Echo/API-Erfolg genügt nicht. Ohne Rückmeldung bleibt ein Test ausstehend und wird spätestens nach zehn Minuten unbestätigt. Das ist keine automatische Fehlermeldung und keine Lesebestätigung.

### 3. Einzeltests und Sonderfälle

Für manuelle Tests das Partnerfeld mit `/qa diag partner` leeren. Flüsterziel: `/qa diag whisper Name-Realm`. Custom-Kanal: `/qa diag channel BereitsBeigetretenerKanal`. Kanalwahl und anschließend `suite out`, `suite combat` oder `suite encounter`; ohne Partner erfolgt keine automatische Empfangsbestätigung. Lokale Anzeigen: `/qa diag frames`, danach im Ergebnisfeld manuell sichtbar bestätigen. Manuelle Empfangsbestätigung ist auch mit `/qa diag received TEST-ID` möglich.

**Nur für gezielte Fehlersuche:** `/qa diag mode probe` oder „Blizzard-Restriktionen direkt prüfen“. Roh-Probes können geschützte Aufrufe/Fehler erzeugen; sie umgehen keine Blizzard-Sperren. Nicht standardmäßig verwenden. Mit `/qa diag mode normal` zurückschalten; Modus nur außerhalb einer laufenden Serie wechseln.

Tests starten mit Verzögerung, senden höchstens alle acht Sekunden und laufen höchstens fünf Minuten nach Vorbereitung. Partneraufbau: 60 Sekunden lokal nutzbare Zeit, maximal 180 Sekunden insgesamt. `/qa diag cancel` beendet die Serie; nach Reload startet keine Serie automatisch neu. `/qa diag off` beendet auch Empfang/Rückmeldungen.

### 4. Protokoll sichern und teilen

Nach `/reload` oder Logout: `<WoW-Client>/WTF/Account/<ACCOUNT>/SavedVariables/QuestAnnounce.lua`. Gesucht ist **QuestAnnounceDiagnosticsDB**, nicht die Lua-Quelldatei unter AddOns. Diese SavedVariables-Datei enthält außerdem persönliche Profile. Nur den benötigten Diagnoseauszug weitergeben und vorher Profil-/Partner-/Ziel-/Kanalnamen entfernen. Clientversion/Build, Sprache, Situation, Kanal und Testergebnis beilegen.

Keine vollständigen Logs werden automatisch hochgeladen; Partnertests übertragen begrenzte Test-/Steuerinformationen und Empfangsrückmeldungen. Aufzeichnung: maximal 2000 Datensätze und 20 Sitzungen; Ergebnisse/Empfangspuffer sind ebenfalls begrenzt. Erst nach dem Sichern `/qa diag clear` verwenden: löscht die Diagnoseeinträge, Ergebnisse und Empfangspuffer und stoppt Tests, behält aber Profile und Einstellungen.

### 5. Neue Ziel- und Gruppenoptionen prüfen

Mit `/qa diag on` und `/qa diag mode normal` aufzeichnen. Beide neuen Optionen sind standardmäßig aus. Für einen Vergleich zunächst ausgeschaltet lassen; anschließend einzeln und zusammen einschalten:

1. Fortschrittsfrequenz **0**, „Erfüllte Questziele bei Fortschritt 0 melden“ an: bei einer noch unvollständigen Quest 9/10 → 10/10 erreichen. Eine Zielmeldung erwarten, keine Zwischenstände. Beim letzten Ziel zusätzlich genau einen Gesamtabschluss erwarten. Bei Reload/Pause keine Nachholung; nach echter Neuannahme darf dieselbe Quest erneut melden.
2. Gewünschte Gruppenkanäle ankreuzen, Chatankündigungen und „Gruppenkanal automatisch wählen“ einschalten, Priorität wählen. Pro Meldung höchstens einen passenden Gruppenkanal erwarten. Beispiel: **Schlachtzug > Instanz > Gruppe**; bei einer bereits bekannten reinen RAID-Sperre kann INSTANCE_CHAT übernehmen, sofern aktiviert, verfügbar und erlaubt. Ohne belegte Sperre keinen künstlichen Schutzfehler provozieren. Solo keine Gruppenmeldung; Flüstern und lokale Anzeigen separat prüfen.
3. Bei globaler Chat-/Encounter-Sperre keinen Kanalwechsel erwarten. Nach einem unerwarteten eigenen Schutzfehler wird dieselbe Meldung nicht auf einen anderen Gruppenkanal wiederholt; nur spätere Meldungen berücksichtigen die bekannte Kanalsperre. Gruppen-/Prioritätswechsel dürfen alte Meldungen nicht neu zustellen.

Im Rohprotokoll bedeutet `GROUP_CANDIDATE_SKIPPED` einen kanalspezifisch ausgeschlossenen Kandidaten; `ATTEMPT` nennt den tatsächlich versuchten Kanal. `DEFERRED` enthält z. B. den globalen Sperrgrund. `no eligible group route` bedeutet keinen aktivierten, verfügbaren und erlaubten Kandidaten; `milestone queue full` bedeutet die Kapazitätsgrenze (acht je Ziel, 64 insgesamt). Ereignisse verfallen nach zehn Sekunden (`EXPIRED`); es gibt keine unbegrenzte Nachlieferung. Nachrichtentexte werden nicht mitprotokolliert, also Zielreihenfolge, gewählte Priorität, Checkboxen und beobachtete Anzeige im Fehlerbericht ergänzen.

Ausdrückliche Diagnose-Kanaltests bleiben Einzeltests der gewählten Kanäle. Die automatische Priorität fasst diese Testserie nicht zusammen; für ihre Prüfung normale Questmeldungen verwenden. Lokale Simulationen ersetzen keine native Client-/Sprach-/Gameplay-Abnahme.

`previous protected send` bedeutet: Ein eigener tatsächlicher Schutzfehler hat diesen Kanal bis `/reload` vorsorglich gesperrt. Normale Vorab-Ablehnungen setzen diese Sperre nicht. Sie wird nicht im Profil gespeichert; andere Kanäle werden unabhängig geprüft.

## English

The general **Debug** option and new **Chat Diagnostics** are independent. Diagnostics are off on new installations; existing recording preferences are preserved. They store bounded state/error information, not ordinary message text. Open `/qa` → Chat Diagnostics. Command tokens are identical in every locale.

### 1. Record an ordinary problem

```text
/qa diag on
/qa diag mode normal
/qa diag status
```

Play normally and reproduce the problem. Afterwards use `/qa diag cancel`, `/qa diag off` and `/reload`. Recording alone starts no chat-test suite. Cancel stops tests; off also stops receiving and acknowledgements. Both preserve recorded results.

### 2. Check receipt with a partner

Both players install **9.3.0.12-Rc1** (diagnostic build **20261112-1**) and enable `/qa diag on` and `/qa diag mode normal`. Each sets the other using `/qa diag partner Name-Realm`. The recipient then enables `/qa diag receive on`; changing partners disables receiving again.

The sender initially runs only a targeted whisper test:

```text
/qa diag channels WHISPER
/qa diag suite out
```

Wait for **Partner ready**. Prepare combat/boss tests before the pull using `suite combat` or `suite encounter`, then wait for readiness. Select other desired channels, for example `/qa diag channels GUILD OFFICER`; both players need appropriate rights and sufficient range for local channels. Existing Blizzard/addon restrictions remain effective in normal mode; GUILD may therefore be deliberately skipped.

**Received by partner** requires a matching chat event on the other client. Local echo/API success is insufficient. Without acknowledgement a result stays pending and becomes unconfirmed after at most ten minutes. This is not an automatic failure or a read receipt.

### 3. Manual tests and special cases

Clear the partner field with `/qa diag partner` for manual tests. Whisper target: `/qa diag whisper Name-Realm`. Custom channel: `/qa diag channel AlreadyJoinedChannel`. Select channels, then use `suite out`, `suite combat` or `suite encounter`; without a peer there is no automatic remote receipt. Local displays: `/qa diag frames`, then manually confirm visibility in the result selector. Manual receipt can also be recorded with `/qa diag received TEST-ID`.

**Targeted troubleshooting only:** `/qa diag mode probe` or “Probe Blizzard restrictions directly”. Raw probes may cause protected-action errors; they do not bypass Blizzard restrictions. Do not use by default. Restore `/qa diag mode normal`; change modes only when no suite is running.

Tests start after a delay, send no more than once every eight seconds and run for at most five minutes after preparation. Peer setup allows 60 seconds of locally usable time and a 180-second overall limit. `/qa diag cancel` stops the suite; no suite automatically resumes after reload. `/qa diag off` also stops receiving/acknowledgements.

### 4. Save and share evidence

After `/reload` or logout: `<WoW-client>/WTF/Account/<ACCOUNT>/SavedVariables/QuestAnnounce.lua`. Look for **QuestAnnounceDiagnosticsDB**, not the Lua source under AddOns. The same SavedVariables file also contains personal profiles. Share only the required diagnostic extract and remove profile/peer/target/channel names first. Include client version/build, locale, situation, channel and result.

Complete logs are never automatically uploaded; paired tests exchange bounded test/control metadata and acknowledgements. Recording is limited to 2000 records and 20 sessions; result/receipt buffers are also bounded. Only after saving, use `/qa diag clear`: clears diagnostic entries, results and receipt buffers and stops tests, preserving profiles and settings.

### 5. Verify new objective and group options

Record with `/qa diag on` and `/qa diag mode normal`. Both new options default to off. Compare with both disabled first, then enable them individually and together:

1. Set progress frequency to **0**, enable “Announce completed objectives at progress 0” and advance an incomplete quest from 9/10 to 10/10. Expect one objective message and no intermediate progress. For the final objective, also expect one whole-quest completion. Reload/pause must not replay completions; a genuinely reaccepted quest may announce again.
2. Check the desired group destinations, enable chat announcements and “Automatically select group channel”, then choose a priority. Expect at most one eligible group destination per message. Example: **Raid > Instance > Party**; a previously known RAID-only block may select INSTANCE_CHAT if enabled, available and allowed. Do not manufacture a protection error to simulate a block. Solo players send no group message; check whispers and local output separately.
3. Global chat/encounter restrictions must not switch channels. After an unexpected own protection failure, that message is not replayed in another group channel; only later messages take the known channel block into account. Group/priority changes must not resend old messages.

In raw records, `GROUP_CANDIDATE_SKIPPED` identifies a channel-specific exclusion; `ATTEMPT` names the channel actually attempted. `DEFERRED` includes reasons such as global restrictions. `no eligible group route` means no enabled, available and permitted candidate; `milestone queue full` means the capacity limit (eight per destination, 64 overall). Events expire after ten seconds (`EXPIRED`); no unlimited backlog is delivered. Message text is not recorded, so include objective order, selected priority, checkboxes and observed output in the report.

Explicit diagnostic channel tests still test each chosen channel. Automatic priority does not collapse that suite; verify it with ordinary quest announcements. Local simulations do not replace native client/language/gameplay acceptance.

`previous protected send` means an actual own protection failure has conservatively disabled this channel until `/reload`. Ordinary preflight rejections do not latch it. The latch is not saved in the profile; other channels are checked independently.
