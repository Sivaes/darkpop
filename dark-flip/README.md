# Dark Flip

Body flips out of a dark catch in skate., on ReSkate.

Catch any flip trick dark, then press and hold **LT or RT** with the **left stick up or down**, the same input as a normal body flip. The game's own body flip starts, with its own spin assist and its own height rule, and **no grab pose**.

- Stick **down** = backflip, stick **up** = frontflip (the normal way, even after a dark catch).
- Works with any flip trick, not just the heelflip / impossible glitch timing.
- **On by default.** Toggle it in **SANDBOX > TUNE > TRICKLINING > DARK FLIP**, or in the console with `darkflip on` / `darkflip off`. The setting is kept between launches.

Built on **ReSkate 2.1.2**, game build 20260929 (Steam build 25414733).

## Install

1. Download the latest release zip (`ReSkate_DarkFlip-<version>-ReSkate2.1.2.zip`).
2. Close the game and the ReSkate launcher.
3. Copy `ReSkate.dll` and `ReSkateLauncher.exe` over the ones in your ReSkate folder (keep a backup of the originals).
4. Start ReSkate as usual.

To uninstall, put your original two files back.

## Use

- Play with **Dark Catch Assist off** and **Legacy Dark Catches on** (how it was tested).
- Dark Flip gets ready by itself on your **first landing** after the skater loads. Do an ollie or a flip before your first dark body flip. `darkflip status` says whether it is ready.
- Each dark body flip writes one line to `logs\ReSkate.log`, starting with `Dark Flip:`.
- For dark landings that the stock game over-rotates into a bail, use Dark Pop alongside it.

## Console

| Command | What it does |
|---|---|
| `darkflip on` / `darkflip off` | Turn it on or off (saved) |
| `darkflip status` | On or off, and whether it is ready |
| `darkflip probe on` / `off` | Research: record every air to `logs\dark-flip-*.csv` (large files) |
| `darkflip watch on` / `off` | Research: log which game code reads and writes the grab intent, for 60 s or 10 dark airs |
| `darkflip names` | Research: search the game's memory for all of the skater's state names |

## How it works

skate. only starts a body flip once a grab intent is on. In a dark catch, the game's animation graph refuses a new grab press. That is why only the heelflip glitch timing (grab pressed the same moment as the dark catch) ever worked.

Dark Flip hooks the game's "set bool state" function (`Skate+0x11dd7a0`). It checks the function byte for byte first and stays off if it doesn't match. When the graph writes "no grab" during a dark catch while you hold LT or RT with the stick, Dark Flip turns that one write into "grab". Everything else passes through untouched. It never touches the grab pose states, so the game starts its normal body flip.

After a dark catch, the game picks the flip direction relative to the board, which is now turned around. So for flips Dark Flip starts, the direction is set from the stick instead.

The game hands out the positions of its states fresh each launch, so Dark Flip finds them by name after your first landing.

## Build

The whole build is `.github/workflows/build-dark-flip.yml`; the patch is embedded in it. Run it from the Actions tab (**Build Dark Flip**). Tick **release** to publish a GitHub release with the zip. The Spotify helper is left out of the build.
