# ReSkate Dark Pop @MOD@

skate. patch 0.32.0 removed the **dark pop**: catch a flip dark side, work the D-pad menu around the
landing, and the board pops you back up. There is no old code to switch back on, so this mod recreates it.

## Use
Everything is in **Insert > SKATER > BOOSTS**, all off by default.

- **Dark Pop**: hold **D-pad Right** as your flip trick lands and, instead of landing, you pop again.
  At most one forced pop per second. **No Bail can stay off**: the mod holds off bails only while you hold
  D-pad Right in the air and from the pop until just after the next landing, so ordinary falls still happen.
- **Dark Pop extra pop** (0 to +25 m/s, default 0): an extra upward speed added to each forced pop.
- **Dark pop probe**: records what the game does to two files in the game's `logs` folder,
  `dark-pop-probe-<time>.csv` and `dark-pop-fast-<time>.csv`. A new pair is made each time you switch it on.
  Turn it on, do your attempts, turn it off, and send both files.

How it goes: pre-wind 360 inward heelflip (any flip trick works), catch it dark side with **RB**, and hold
**D-pad Right** through the landing.

## Install
1. Install ReSkate normally and run it once.
2. Put this folder in the game's `Mods` folder (`Mods\<author>-ReSkate_DarkPop`).
3. **Close the game and the launcher**, then double-click **Install.bat**. It saves your current
   `ReSkate.dll` and `ReSkateLauncher.exe` in a `backup` folder there and copies this mod's over them.
4. Start `ReSkateLauncher.exe` as usual.

**Uninstall:** close the game and the launcher and run **Uninstall.bat**.

The mod is a build of ReSkate itself, so it replaces `ReSkate.dll`. Do not combine it with other mods that
do that (Revert Boost, the old ReSkate Trainer): the last one installed wins.

## Crashes
The start-up notice says `Modified build: ReSkate_DarkPop <version>`, and crash reports are labelled with
the mod's name and version (`build.mod`, `build.mod_version`) so the ReSkate developers can tell them apart.
Please report crashes here, not to them. If you suspect the mod, switch Dark Pop off and see if it still
happens, and send the end of `logs\ReSkate.log` (lines starting `Dark Pop`).

## Good to know
- Built on **ReSkate @BASE@** (mod version @MOD@).
- Play offline or in a private session. It follows ReSkate's session rules: if a host turns off boosts or
  No Bail, Dark Pop is off too.
- Each forced pop and the landing after it are written to `logs\ReSkate.log` (`Dark Pop: ...`).

## Source and license
GPL-3.0, the same as ReSkate. Not affiliated with EA, Full Circle or the ReSkate developers.
