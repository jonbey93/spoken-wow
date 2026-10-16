# Spoken Combat

Spoken Combat is a separate module bundled with Spoken. Open Options → AddOns →
Spoken → Combat. Enable Module controls the module for your Spoken profile; Speak on
Entering Combat is off by default and saved per character. Preview Combat Voice works
with automatic speech off, while the module is enabled. Any character can use the
`nightelf-female-standard` English voice. Eight short lines play in a shuffled order on
entering combat, with at least 45 seconds between successful combat reactions. Reshuffling
does not repeat the last line. Skipped triggers are discarded, never queued.

Combat speech has no narrator, queue entry, subtitle, transcript or portrait. It uses
Spoken's selected audio channel and skips while narration is speaking. Narration that starts
during a reaction stops it. Leaving combat lets it finish; disabling the feature, dying or
using `/spoken stop` stops it. Preview ignores the enable switch and combat cooldown, but
still respects narration, sound settings and a reaction already playing.

Legacy 1.12, 2.4.3 and 3.3.5 clients are excluded: their playback can stop other sounds or
take over the music channel. This feature needs independent stoppable playback.

## Approved catalogue and voice

The catalogue contains the eight original combat quips, beginning with "So much for a
peaceful walk." The narration uses dry, conversational delivery.

The approved baseline is take 3 of that line: Chatterbox Nano, temperature `0.5`, top-p
`0.9`, repetition penalty `1.2`, and seed `73`. The voice reference combines native English
female night elf player greetings, thanks and farewells. Match output RMS to
`0.12552565336227417`, with a peak limit of `0.94`. All eight selected recordings have listening
approval. Record the seed and any pronunciation respelling with each future take. Line 02 is
approved with the spoken spelling `e-loon` and seed `77`; the displayed text stays
"Elune, a little backup?".

The pinned model, settings and reference hashes are in `combat-voice-recipe.json`.
The selected recordings, reference, native source clips, take metadata, listening preview
and offline reproduction helper are kept locally under
`pipelines/quests/audio-previews/combat-voice/`. All eight selected recordings have listening approval. These files are gitignored and need a separate backup. Generate previews outside the shipped pipelines,
then package supplied recordings below. Never write local previews into the take archive.

## Produce the recordings

Deploy the site changes before using the new page. Sign in with English regeneration
permission and open `/enUS/combat`, also linked from the English Voices page. Select the
provider and settings on Voices and ensure `nightelf-female-standard` exists there.
Each Generate or Regenerate click uses the signed-in person's saved provider key and spends
credits. No CLI or addon generates speech.

Generate and audition lines 01, 02 and 03 first. Finish the set after checking that the voice
sounds like the character and each delivery is brief. The target is 1–3 seconds; recordings
longer than 6 seconds cannot be packaged. The download requires all 8 current recordings.

The catalogue is `apps/web/src/lib/combat/lines.json`. Its keys and derived paths are frozen:
`c:nightelf-female-standard:01` through `:08`, with archive files
`combat/nightelf-female-standard-01.mp3` through `-08.mp3`. These takes use source `quests`
in the shared take table and the quests `audio-history/combat/` directory, so existing
quests history backups keep them. They are not NPC corpus rows and do not enter quest packs.
The page exports the selected immutable take versions directly from the production archive.

The download is a standalone `SpokenCombatAudio-<version>.zip`, installed beside Spoken.
It contains `SpokenCombatAudio/SpokenCombatAudio.toc`, a self-registering `Data/Sounds.lua`
manifest and eight files under `SpokenCombatAudio/Sounds/Combat/`. It never overwrites
Spoken or Spoken Combat. The main Spoken download carries the Combat module without voices.

The sound pack registers in `SpokenCombatAudioPacks`. Spoken Combat discovers compatible
packs and resolves their clips from the pack's own folder. Missing or incompatible packs
leave the module silent and show installation guidance. The source pack has an empty
manifest; only a recording-package build contains playable audio.

The pack version is independent of Spoken. `apps/web/src/lib/combat/audio-pack.json`
and `addons/SpokenCombatAudio/SpokenCombatAudio.toc` carry its release metadata; packaging
tests require them to agree. Audio pack notes live in `docs/combat/CHANGELOG.md`.

## Test in game

For an independent test using your own recordings, place the eight clips in a folder,
named `01.wav` through `08.wav` in the catalogue's order. MP3 and OGG Vorbis are also accepted;
use one file per number, with a maximum duration of 6 seconds. PCM WAV must be 16-bit mono
or stereo. These files stay yours and are copied into a package, never into the take archive.

```sh
python scripts/spoken/package-combat-recordings.py /path/to/recordings
```

This writes `dist/SpokenCombatAudio-0.0.1.zip`. WAV input needs only Python;
MP3 and OGG need `ffprobe` on PATH or supplied through `--ffprobe`. This command packages
existing files and makes no speech requests. No site account or provider credentials are
needed. Keep the original recordings outside git. The addon uses the supplied audio as-is;
the `nightelf-female-standard` filename identifies the intended slot, not the recording's
actual speaker.

1. Install a build of Spoken that includes Combat Voice. Close WoW and extract the recording
   zip into `Interface/AddOns`, creating the separate `SpokenCombatAudio` folder beside `Spoken` and `Spoken_Combat`.
2. Start WoW. Open Options → AddOns → Spoken → Combat, enable the module and click Preview Combat Voice.
   `/spoken combat test` also previews while the switch is off and bypasses the cooldown.
3. Enable Speak on Entering Combat, or use `/spoken combat on`, on any character.
4. Fight an enemy. One short line should play without showing any narrator UI. Leave combat
   and re-enter within 45 seconds: no second reaction. Re-enter after 45 seconds: another
   line. Preview repeatedly to audition all eight and check variety.
5. Start a quest or zone reading, then enter combat: only narration should speak. Start a
   reading during a reaction: narration takes precedence and stops the reaction.
6. Try several narrator styles, including Sound Only, and another character. The combat
   voice stays invisible, and the second character starts with the feature off.
7. Disable Combat Voice while a line is speaking to stop it immediately. Reload and verify
   that the character's enable switch persists.

Spoken updates do not replace the sound pack. Update the sound pack by extracting its
new zip over the existing `SpokenCombatAudio` folder with WoW closed. Existing development
recording zips that overlay `Spoken` or `Spoken_Combat` must be repackaged from their eight
original recordings; they are not standalone sound packs. Keep those originals and backups.

The store does not yet have a Spoken Combat Audio project. Publishing the separate pack
and adding its dependency to any desired Everything bundles are release work.
