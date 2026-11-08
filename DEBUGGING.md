# Chatdiagnose / Chat diagnostics — 9.3.0.11

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

Beide Spieler installieren **9.3.0.11** (Diagnosebuild **20261007-1**) und aktivieren `/qa diag on` sowie `/qa diag mode normal`. Beide tragen den jeweils anderen mit `/qa diag partner Name-Realm` ein. Der Empfänger aktiviert anschließend `/qa diag receive on`; ein Partnerwechsel deaktiviert den Empfang wieder.

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

Both players install **9.3.0.11** (diagnostic build **20261007-1**) and enable `/qa diag on` and `/qa diag mode normal`. Each sets the other using `/qa diag partner Name-Realm`. The recipient then enables `/qa diag receive on`; changing partners disables receiving again.

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
