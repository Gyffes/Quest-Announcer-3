# Quest Announce 3 – V9.3.0.9 Multi

Stable release of the tested V9.3.0.9 RC1. No production-logic changes were introduced after the confirmed RC tests.

## Highlights
- WoW 12 cinematic/taint hardening around quest turn-in processing and LowHealthFrame-sensitive paths.
- Deferred `QUEST_TURNED_IN` processing and quest-ID based completion checks.
- Addon-owned raid notice and dialog output instead of shared Blizzard output paths.
- Combat-blocked external chat retry for at most ten seconds without replaying local output or sounds.
- Complete legacy-profile migration and ten-locale consistency validation.
- Multi-client package for all supported WoW variants.

## Confirmed tests
- Normal quest turn-in.
- Cinematic played to completion.
- Cinematic cancelled/skipped.
- Quest turn-in during or immediately after combat.
- No observed Lua, taint, or `ADDON_ACTION_BLOCKED` errors in the RC test set.

## Package
The attached `QuestAnnounce-3-V9.3.0.9-Multi.zip` is the install/update package for WowUp/WowUpHub. It contains a top-level `QuestAnnounce` addon directory with all supported client TOCs.
