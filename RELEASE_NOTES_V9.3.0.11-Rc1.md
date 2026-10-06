# Quest Announce 9.3.0.11-Rc1

DE: Dieser RC verbessert den automatischen Versand je Chatkanal. Ausgangspunkt ist [Issue #22](https://github.com/Gyffes/Quest-Announcer-3/issues/22), gemeldet von [Nerf_Teh_Derp auf CurseForge](https://www.curseforge.com/members/nerf_teh_derp). Die Optimierung baut auf den Tooltip-/Clientänderungen aus PR #21 auf. Keine Stable-Freigabe; Ingame-Abnahme des neuen Codes steht aus.

EN: This RC improves automatic sending per chat channel. It addresses [issue #22](https://github.com/Gyffes/Quest-Announcer-3/issues/22), reported by [Nerf_Teh_Derp on CurseForge](https://www.curseforge.com/members/nerf_teh_derp), and builds on the tooltip/client changes in PR #21. This is not a stable release; in-game acceptance of the new code is pending.

## Versand / Sending

| Ziel / Destination | Retail mit moderner API / Retail with modern API | Weitere Clients / Other clients |
| --- | --- | --- |
| PARTY | Home-Gruppe, kein Raid / Home party, not a raid | Gruppentest + konservativer Kampffallback / Group checks + conservative combat fallback |
| INSTANCE_CHAT | Instanzgruppe / Instance group | Instanzgruppe + Kampffallback / Instance group + combat fallback |
| RAID | Raidgruppe, neue Option / Raid group, new option | Raidgruppe + Kampffallback / Raid group + combat fallback |
| WHISPER, Fokus / Focus | Gültiges Ziel; Fokus als Spielerflüstern / Valid recipient; player focus uses whisper | Gültiges Ziel + Kampffallback / Valid recipient + combat fallback |
| OFFICER | Gildenzugehörigkeit; tatsächliche Sprechrechte bestimmt WoW / Guild membership; WoW enforces actual speaking rights | Gildenzugehörigkeit + Kampffallback / Guild membership + combat fallback |
| GUILD | Zusätzlich Map-Restriktion prüfen / Also check Map restriction | Gildenzugehörigkeit + Kampffallback / Guild membership + combat fallback |
| SAY | Instanz außerhalb PvP/Arena / Instance outside PvP/arena | Bisherige Instanzregel + Kampffallback / Previous instance rule + combat fallback |
| EMOTE | Neue Option; gewöhnlicher Kampf allein sperrt nicht / New option; ordinary combat alone does not block | Bisherige öffentliche Instanzregel + Kampffallback / Previous public-instance rule + combat fallback |
| CHANNEL | Automatischer Versand gesperrt; lokalisierter Hinweis / Automatic sending disabled; localized notice | Bisherige Instanzregel, beigetretener Kanal + Kampffallback / Previous instance rule, joined channel + combat fallback |
| YELL, echter / actual RAID_WARNING | Nur ausdrückliche Diagnoseziele / Explicit diagnostic targets only | Nur ausdrückliche Diagnoseziele / Explicit diagnostic targets only |

DE: Chat-Lockdown, aktivierende/aktive Chat- oder Encounter-Restriktionen und laufende Encounters stellen alle normalen Chatziele zurück. Fehlerhafte/geheime Abfragewerte erteilen keine Freigabe. Die Retail-Regeln beruhen auf den Nutzerprüfungen in **12.1.0.69933**, nicht auf einer Garantie für alle künftigen Builds. Andere Clientfamilien erhalten dieselben Funktionen mit konservativem Kampffallback, bis verlässliche Messungen vorliegen. Es wird keine Blizzard-Sperre umgangen.

EN: Chat lockdown, activating/active Chat or Encounter restrictions, and encounters defer all normal chat destinations. Failed/secret queries do not grant permission. Retail rules derive from user tests on **12.1.0.69933**, not a guarantee for future builds. Other client families receive the same features with conservative combat handling until reliable measurements are available. No Blizzard restriction is bypassed.

DE: Pro Ziel bleibt die neueste Nachricht höchstens zehn Sekunden vorgemerkt; gemeinsamer Mindestabstand eine Sekunde, wechselnde Zielreihenfolge. Bereits versendete Ziele werden nicht wiederholt. Fokus-Empfänger bleibt fest; identische Fokus-/Whisper-Ziele werden zusammengefasst. Pause, Deaktivierung, Profil- und Chateinstellungswechsel bereinigen wartende Nachrichten. Lua-/Schutzfehler lösen keinen erneuten Sendeversuch aus. Überlange (>255 Bytes), mehrzeilige oder geheime Texte werden verworfen, ohne UTF-8 oder Questlinks abzuschneiden.

EN: Each destination retains only its latest message for up to ten seconds; a shared one-second minimum interval and rotating destination order limit traffic. Sent destinations are not replayed. Focus recipients are frozen; identical Focus/Whisper destinations are deduplicated. Pause, disabling, profile and chat-setting changes clear pending messages. Lua/protection errors do not trigger retries. Oversized (>255 bytes), multiline or secret messages are discarded without truncating UTF-8 or quest links.

## Optionen / Options

DE: „Chatankündigungen“ erklärt den bisherigen Hauptschalter `announceTo.chatFrame`; bestehende Profile werden nicht auf Raid umgedeutet. EMOTE und RAID sind standardmäßig aus. Rechts stehen Emote und darunter Raid; in der Mitte Offizier, Gilde, Fokus. Lokaler Raidwarnungsersatz, UI-Fehleranzeige, Selbstmeldungen, Sounds und Questlogik bleiben getrennte Ausgabewege. Die UI-Fehleranzeige verwendet die MessageFrame-Signatur mit Deckkraft als fünftem Argument; eine Anzeigedauer wird hier nicht übergeben und das globale Fenster nicht umkonfiguriert. Neue Texte und Tooltips sind in allen zehn vorhandenen Locales enthalten.

EN: “Chat announcements” explains the existing `announceTo.chatFrame` master switch; old profiles are not reinterpreted as raid settings. EMOTE and RAID default to off. The right column contains Emote then Raid; the middle contains Officer, Guild, Focus. The local raid-warning replacement, UI errors, self messages, sounds and quest logic remain separate output paths. UI errors use the MessageFrame signature with alpha as the fifth argument; no display duration is passed here and the global frame is not reconfigured. New labels and tooltips cover all ten existing locales.

## Diagnose / Diagnostics

DE: Das neue Unterpanel „Chatdiagnose“ bietet stille Aufzeichnung und getrennte aktive Tests. Diagnose ist standardmäßig aus und unabhängig vom Debugschalter. Das alte separate QAChatDiagnostics-Addon bitte deaktivieren, um `/qadiag` eindeutig zuzuordnen. Stille Aufzeichnung sendet keine Zusatznachrichten. Aktive Serien senden sichtbare Tests und können absichtlich Blizzard-Schutzfehler sichtbar machen; nur mit passenden Testpartnern/-gruppen starten.

EN: The new “Chat diagnostics” panel offers silent recording and separate active tests. Diagnostics default to off and are independent of debug logging. Disable the old standalone QAChatDiagnostics addon to avoid an ambiguous `/qadiag` command. Silent recording sends no additional messages. Active suites send visible probes and can intentionally expose Blizzard protection errors; run them with suitable test partners/groups.

```text
/qa diag on
/qa diag status
/qa diag whisper Name-Realm
/qa diag channel AlreadyJoinedPrivateChannel
/qa diag suite out
/qa diag suite combat
/qa diag suite encounter
/qa diag frames
/qa diag received TEST-ID
/qa diag cancel
/qa diag off
/qa diag clear
```

DE: Serien prüfen SAY, YELL, EMOTE, PARTY, RAID, RAID_WARNING, INSTANCE_CHAT, GUILD, OFFICER, WHISPER, CHANNEL. Startverzögerung fünf Sekunden, Schrittintervall mindestens acht Sekunden, Laufzeit höchstens fünf Minuten. Fehlende Gruppen/Ziele/Berechtigungen werden übersprungen; andere Kontextzustände warten. Kein automatischer Kanalbeitritt, kein Neustart nach Reload. Normale Chatnachrichten warten während einer Serie innerhalb ihrer Zehn-Sekunden-Grenze. `frames` prüft nach fünf Sekunden UIErrorsFrame und den eigenen Raid-Hinweis; kann ebenso abgebrochen werden. Befehlswörter sind in allen Sprachen identisch.

EN: Suites cover SAY, YELL, EMOTE, PARTY, RAID, RAID_WARNING, INSTANCE_CHAT, GUILD, OFFICER, WHISPER, CHANNEL. They start after five seconds, use at least eight seconds between steps, and expire after five minutes. Missing groups/targets/permissions are skipped; mismatching contexts wait. No automatic channel joining or restart after reload. Normal announcements wait within their ten-second limit during a suite. `frames` tests UIErrorsFrame and the owned raid notice after five seconds and can also be cancelled. Command tokens are identical across languages.

DE: Nach `/reload` oder Logout enthält `WTF/Account/<ACCOUNT>/SavedVariables/QuestAnnounce.lua` sowohl `QuestAnnounceDB` als auch **`QuestAnnounceDiagnosticsDB`**. Der zweite Eintrag ist die gesuchte Diagnose, maximal 2000 Datensätze und 20 Sitzungen. Empfänger/Testkanal stehen in separaten Diagnoseeinstellungen; sie werden nicht in Versandprotokolle geschrieben. Nachrichtentexte, fremde normale Chatnachrichten und rohe Lua-Fehlermeldungen werden nicht gespeichert. Sitzung/Build/Locale, Zeit, Kanal, Zustand, Entscheidungsgründe und Schutzereignisse werden erfasst. Keine automatische Übertragung. `/qa diag clear` löscht nur Datensätze. Getestete lokale Anzeige/API-Rückkehr sind kein Zustellnachweis; Empfang kann mit Test-ID separat bestätigt werden.

EN: After `/reload` or logout, `WTF/Account/<ACCOUNT>/SavedVariables/QuestAnnounce.lua` contains both `QuestAnnounceDB` and **`QuestAnnounceDiagnosticsDB`**. The latter holds diagnostics, bounded to 2000 records and 20 sessions. Recipient/test-channel names live in separate diagnostic settings and are not written to send records. Message text, unrelated normal chat and raw Lua error messages are not saved. Logs include session/build/locale, time, channel, state, decision reasons and protection events. No automatic upload. `/qa diag clear` clears records only. Local echo/API return does not prove delivery; receipt can be recorded separately by test ID.

## Prüfung und Quellen / Validation and sources

DE: Geprüft: 14 TOCs, Lua-5.1-Laden und Optionsaufbau in 70 Client-/Locale-Kombinationen, vollständige neue Übersetzungen ohne Fallback, Altprofile, Routing, Sperrübergänge, Ablauf, Versandabstände, Fokus, Pause, geheime/fehlende APIs, Schutzfehler ohne Retry und Diagnosebegrenzung. Die Testwerkzeuge, Referenzaddons und persönlichen Logs sind nicht Teil des PR oder Pakets. Diese Prüfungen simulieren APIs; sie bestätigen keine tatsächliche Blizzard-Freigabe.

EN: Checked: 14 TOCs, Lua 5.1 loading/options construction in 70 client/locale combinations, all new translations without fallback, legacy profiles, routing, restriction transitions, expiry, spacing, focus, pause, secret/missing APIs, protection errors without retry, and bounded diagnostics. Test tools, reference addons and personal logs are excluded from the PR and package. These checks simulate APIs and do not establish actual Blizzard permissions.

DE: Zur Gegenprüfung wurden die vom Nutzer gespeicherten Blizzard-UI/API-Quellen aus [Townlong-Yak](https://www.townlong-yak.com/framexml/live) verwendet, insbesondere ChatInfoDocumentation (`HasRestrictions`, `RestrictedForMacroChatMessages`, `SecretArguments`), RestrictedActionsDocumentation und die UIErrorsFrame-Ausgabe. Diese Quellen dokumentieren Mechanismen, nicht jede Kanal-/Kontextkombination. Offene Abnahme: echtes Laden aller erreichbaren Clients, Questfortschritt/-abgabe inklusive Videoquests, tatsächlicher Empfang aller Ziele, Gruppenwechsel, `/reload`, lange/asiatische Labels und lokale Anzeigen im Kampf/Encounter.

EN: Cross-checks used the user-saved Blizzard UI/API sources from [Townlong-Yak](https://www.townlong-yak.com/framexml/live), especially ChatInfoDocumentation (`HasRestrictions`, `RestrictedForMacroChatMessages`, `SecretArguments`), RestrictedActionsDocumentation and UIErrorsFrame output. These document mechanisms, not every channel/context combination. Pending acceptance: actual loading on accessible clients, quest progress/turn-ins including cinematics, destination receipt, group changes, `/reload`, long/Asian labels and local displays during combat/encounters.
