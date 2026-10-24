# Dark Flip: handoff 02 (24 Oct 2026)

Paste this into a new chat (with `dark-flip.patch` attached) to pick up where we left off: merging Dark Flip 1.0.0 into the **Tournament Edition** build (the one with Dark Pop and the trainer).

**Rule (unchanged):** no builds without Jaq's go-ahead. Tell him the plan before a build is made.

## Where it stands

- **Dark Flip 1.0.0** is delivered as `build-dark-flip.yml` (patch embedded) plus `README.md` and `dark-flip.patch` (the same patch as a plain file).
- It's built on **vanilla ReSkate v2.1.2**, game build 20260929 (Steam build 25414733).
- Patch SHA-256: `52067DA37D97C0B9D674D22412E53A532DBE6BC2F0A3CECC3C28E0BC26428830` (102,810 bytes).
- The patch applies cleanly to a fresh v2.1.2 and passes a MinGW syntax check. That check covers the Dark Flip files plus the two menu files it touches.
- **The 1.0.0 build has not been run or played yet.** Jaq will send logs once the workflow is done and it's tested.
- **0.3.1 was play-tested and works.** In one session, every dark catch with LT or RT plus the stick started the body flip, once Dark Flip was ready.
- Two problems found in 0.3.1 are fixed in 1.0.0 but not yet tested:
  - the front/back direction came out swapped;
  - it was slow to get ready.

## What it does (1.0.0)

- Catch any flip trick dark, then press and hold LT or RT with the left stick up or down.
- The game's own body flip starts, with its spin assist and height rule, and no grab pose.
- The direction comes from the stick: down = backflip, up = frontflip.
- **On by default.** Toggle it at SANDBOX > TUNE > TRICKLINING > DARK FLIP (a card under Dark Pop) or with `darkflip on|off`. The setting is saved to `%LOCALAPPDATA%\ReSkate\dark-flip.ini` (`enabled=1/0`; on if the file is missing).
- **Research tools, off by default:**
  - `darkflip probe on`: per-step CSVs, 20–40 MB per session.
  - `darkflip watch on`: CPU watchpoints for 60 s or 10 dark airs.
  - `darkflip names`: a full search for state names.
- Console verbs: `darkflip on|off|status|probe on|off|watch on|off|mark <text>|names`.

## How it works (the findings)

### Why dark catches block body flips

- A body flip starts on the step after a **grab intent** turns on (`Bool.Intent.RightHandGrab`, set by LT, or `Bool.Intent.LeftHandGrab`, set by RT; the names are mirrored relative to what you see) while the stick's flip intent (`Bool.Intent.BackFlip` or `Bool.Intent.FrontFlip`) is on.
- When it starts, `Bool.Intent.FlipFaster` = 1 and `Float.Intent.BodyFlipSpeedMod` goes from 1.0 to 1.3 for about 30 steps.
- `GP.CanGrab` and `GrabType` (the grab pose) aren't needed for the flip.
- Once the dark-catch intent is on (`Bool.Intent.WantsDark`, then `Bool.GP.IsDark`), the **anim graph refuses new grab intents**: it writes 0 to the grab byte every step.

### Why the heelflip glitch works

- LT was pressed on the same step as RB, or one step after (about 17 ms).
- The grab intent registered before the refusal kicked in, and the flip latched.
- The game then cleared the grab intent when `IsDark` came on, but the flip kept going.
- In the test data, the timing explained everything. Whether trick choice also matters wasn't tested.

### Where the decision happens

- It's in the **anim graph** (data-driven), not hard-coded C++.
- Every bool game state is set through one function:
  - **`Skate+0x11dd7a0`**: `push rbx / sub rsp,20h / mov rax,rdx / movzx ebx,r8b / lea rdx,[rcx-60h] / mov r8b,1 / mov rcx,rax / call <resolve> / mov [rax],bl / add rsp,20h / pop rbx / ret`
  - It **returns the address of the byte it wrote** (rax). The first 24 bytes, checked before hooking, are `40 53 48 83 ec 20 48 8b c2 41 0f b6 d8 48 8d 51 a0 41 b0 01 48 8b c8 e8`.
- **Callers:**
  - graph nodes at `Skate+0x1039ba3` (writes every step, value in `sil`) and `Skate+0x10392cf`, via `call [rax+20h]`;
  - the graph dispatch loop at `Skate+0x16d2136` / `0x16d20e5`;
  - frames under it include `ReSkate.dll+0x1d02bb`, a ReSkate hook in that chain.
- **The generic bool getter** is around `Skate+0x11dd4f1` (`movzx eax, byte [rax]`), reached via `Skate+0x121c2bc` and `0x108faae`.

### The fix

- The hook on `Skate+0x11dd7a0` calls the original, then checks the returned address.
- While forcing, if the graph just wrote 0 to that one grab byte, the hook writes 1. Every other write passes untouched.
- **Forcing is on only while all of these hold:**
  - in the air;
  - `WantsDark` or `IsDark` is on;
  - LT or RT was pressed fresh during this air and is still held;
  - `FrontFlip` or `BackFlip` is on;
  - `FlipFaster` isn't on yet;
  - fewer than 12 steps of forcing.
- In testing it only had to force for 1–2 steps before the game's flip latched.

### Direction

- After a dark catch, the game sets the flip intent relative to the board, which is turned around. In every dark air of the 00:44 session, stick up gave `BackFlip` and stick down gave `FrontFlip`. That was still true after leaving the dark catch.
- In normal body flips, stick down gives `BackFlip`.
- 1.0.0 latches the direction from the stick (left Y ≤ −16000 = back, ≥ +16000 = front) when it first forces.
- For the rest of that air, the hook rewrites the graph's `FrontFlip`/`BackFlip` writes: "a flip" stays on, carried by the chosen bit.
- **Untested:** whether the graph sets those two bits through this setter. The log line says whether it fixed them or "the game kept its own direction".

### State positions change every launch

- Pages and places are handed out at load. For example, `IsDark` was at 4:0x0d8, then 2:0x6da, 2:0x6f1, 4:0x006, 2:0x6b4 and 2:0x5d2 across launches.
- Never hard-code them. (0.2.0 did, and read the wrong bytes.)
- **How the positions are found:**
  - The search looks for `Animation/Dingo/<name>` strings on the game's heap (MEM_PRIVATE only, background priority, 1 ms pause per 4 MB chunk).
  - The state object holds the name `char*` at +0x18 and the handle at +0x28: page = handle & 0xfff, place = (handle >> 12) & 0x7ff.
  - The state pages hang off AntDrivenComponent → the states block (vtable 0x61a8bd8), with 16 pages at +0x60, 0x71c bytes each.
- **Some states (FrontFlip, BackFlip, FlipFaster) don't exist until the game first uses them.**
  - A search at skater load takes about 40 s and comes up short.
  - A search after a landing takes about 1.5 s and finds them.
  - So 1.0.0 searches after a landing until everything is found, and Dark Flip is ready from the second air.
- **Learning from the setter (0.3.1) didn't work.** It assumed rdx is the state object, and no state was ever learned that way. 1.0.0 tries rdx, `*rdx` and `rdx − 0x28`, and logs a one-time `Dark Flip: diagnostic, the setter's arguments: …` line with the first 6 rdx values. **Read that line first in the next logs.**

### Every value read is sanity-checked

- A bool state must read 0 or 1. Anything else skips the step, counted in the log.
- If the setter's bytes don't match, the hook isn't installed and the fix is off: "not available for this game build" in the menu.

## What the patch touches (13 files, against vanilla 2.1.2)

| File | Change |
|---|---|
| `Extension/Skater/dark_flip.cpp` (new, ~1,580 lines) | Everything: probe, search, fix, setter hook, watch, settings, console text |
| `Extension/Skater/dark_flip.h` (new) | `start`, `on_client_tick`, `command`, `enabled`, `set_enabled`, `ready`, `hook_in`, `version` |
| `Extension/Skater/dark_flip_commands.cpp` (new) | Console verbs |
| `Extension/Console/commands.cpp/.h` | `register_dark_flip_commands` (after the trainer commands) |
| `Runtime/runtime_init.cpp` | `dark_flip::start(r.base)` **after `grind_exit::start`** (needs No Bail's hooks up) |
| `Runtime/client_tick.cpp` | `dark_flip::on_client_tick(client)` after the plugins tick |
| `cmake/Runtime.cmake` | the two new `.cpp` files |
| `Extension/UI/Overlay/input_capture.cpp`, `overlay.h` | **`DingoSDKOverlaySetGamepadObserver`**: a read-only pad observer next to the gamepad filter (the same one Grab Fix added) |
| `Extension/UI/Overlay/skate_menu_skater.cpp`, `skate_menu_internal.h` | `dark_flip_controls(menu)`: the DARK FLIP card |
| `Extension/Trainer/trainer_page.cpp` | calls `dark_flip_controls(menu)` right after `dark_pop_controls(...)` on the trickline topic |

## Merging into the Tournament Edition: watch for these

**What the Tournament Edition is (checked in `Sivaes/darkpop`, 24 Oct):**
- It's `.github/workflows/build-dark-pop.yml` in this repo: "ReSkate Trainer 0.8.5 Tournament Edition", which is Nakas's trainer 0.7.1 merged with Dark Pop 3.4 and Grab Fix 0.4.0.
- It's built on **ReSkate v2.1.1**, not 2.1.2. Its patch is embedded as base64 (a tar `package/` holding the patch and the package files, 58 file diffs).
- **Dark Flip's patch is against v2.1.2**, so it has to be ported to 2.1.1 (or the Tournament Edition moved to 2.1.2). The three new files should carry over unchanged. The small hunks in `commands`, `runtime_init`, `client_tick`, `cmake`, the menu and `input_capture` need re-applying by hand.
- The 2.1.1 → 2.1.2 change that moved addons into Lua plugins may move those hunks around.
- **Found in the Tournament Edition's patch:**
  - **Grab Fix already adds and uses `DingoSDKOverlaySetGamepadObserver`** (its `check_pad`, set and cleared with its release and check options). Dark Flip uses the same single slot. **They will overwrite each other**, so this must be fixed in the merge.
  - **Grab Fix also takes a No Bail step listener** (`add_no_bail_step_listener(&on_step)`).
  - **Nothing in it hooks `Skate+0x11dd7a0`**, so there's no hook clash.
  - `dark_pop_controls(menu, model, callbacks)` is there, so the DARK FLIP card can go right after it.

1. **The gamepad observer (a confirmed clash).**
   - The Tournament Edition's Grab Fix already adds `DingoSDKOverlaySetGamepadObserver`, so don't apply Dark Flip's `input_capture.cpp`/`overlay.h` hunks.
   - It's a **single slot**, and Grab Fix sets it to `check_pad`. Make it a small list of observers (2–4 entries), or have one observer call both Grab Fix's `check_pad` and Dark Flip's `observe_pad`.
   - Dark Flip needs the pad (LT, RT, left Y) on the physics thread.
2. **No Bail step listeners.** There are only 4 slots (`no_bail_step_listener_slots`). Dark Flip takes one whenever the fix or probe is on. Check that the Tournament Edition's Dark Pop, trainer and probes don't already use all 4.
3. **The setter hook at `Skate+0x11dd7a0`.**
   - Search the Tournament Edition for `11dd7a0` or any hook on that function. Two Detours hooks on the same target through ReSkate's hook service will clash (`hook_prepare` → AlreadyPrepared).
   - If the trainer hooks it, chain the logic into one hook.
4. **The game build.** Everything here is for game build 20260929. If the Tournament Edition targets another build, the setter address and bytes, the states block vtable (0x61a8bd8), the AntDriven vtable (0x63aaee8) and the skater offsets have to be found again. The byte check keeps the fix off safely until then.
5. **Debug registers.** The watch (opt-in only) sets DR0–DR3 on every thread. Make sure nothing in the Tournament Edition uses hardware breakpoints, or leave the watch out of the TE build.
6. **The menu.** The Tournament Edition's trickline page may differ from vanilla 2.1.2. Put `dark_flip_controls(menu)` wherever the Dark Pop card is drawn.
7. **`runtime_init` order.** Dark Flip must start after No Bail (it uses `no_bail_available()` and `add_no_bail_step_listener`). It installs the setter hook inside a `HookBatch`.
8. **Dark Pop together.** Dark Flip doesn't touch landings. Stock over-rotates near-dark landings into back bails, which Dark Pop fixes. 0.3.1 had 3 bails in 10 dark airs, likely from the swapped direction. Retest them together.
9. **Applying the patch.**
   - Patch the Tournament Edition with `git apply --3way dark-flip.patch`.
   - If that fails, copy the three new files in and hand-apply the small hunks from the table above.
   - The workflow's embedded copy is base64 in the "Apply the Dark Flip patch" step, and it's checked against `PATCH_SHA256`.
   - **Keep any `${{ }}` expressions out of that `run:` block.** GitHub would evaluate the whole embedded patch as one expression, which is capped at 21,000 characters.

## To check in the 1.0.0 test logs

- `Dark Flip 1.0.0 started: on`, `grab hook in (Skate+0x11dd7a0)`, then `Dark Flip: ready; its game states: …` soon after the first landing.
- The `diagnostic, the setter's arguments` line, which shows how to fix the learning path.
- One line per dark flip:
  - "direction set from the stick (N fix(es))" means the direction fix works;
  - "the game kept its own direction" means FrontFlip/BackFlip aren't set through this setter, so the watch should be aimed at them.
- The menu toggle is there, works, and is remembered across a restart.
- RT is fine. It worked twice, but most tests used LT.

## Still to test or do

- RT more; riding switch and fakie; online with other skaters around (the hook only acts on the local skater's bytes, but check).
- The landings with Dark Pop on.
- Make the setter learning work, so Dark Flip is ready on the first air.
- Clean up the old `dark-flip-steps-*` and `dark-flip-states-*` CSVs in `logs`.

## Version history (23–24 Oct)

- **0.1.0, the probe.** The first build's automatic name search scanned every mapped file (about 55 s) and slowed the PC.
- **0.1.1.** The search runs on command only and gently. The 0.1.0 data showed the glitch mechanism above.
- **0.2.0, a write from outside.** It read the wrong bytes: it had positions from an earlier launch hard-coded.
- **0.2.1.** It found the positions by name. Writes from the no-bail step listener were overwritten by the graph before being read: "0 kept, 12 cleared".
- **0.2.2.** It added the search retry and `darkflip watch`, which found `Skate+0x11dd7a0`.
- **0.3.0, the setter hook.** The first working dark body flip, from a normal-timing RT press.
- **0.3.1.** Partial search results are kept. 17 of 17 worked in one session; in another, it wasn't ready for the first ~12 airs, and the direction came out swapped.
- **1.0.0.** Direction from the stick, a search after landing, the menu toggle and saved setting, quiet defaults, and the learning diagnostic.

## Useful references

- The live Skate.exe is at `C:\Users\gray0\Desktop\Reskate`. The trainer tuning dump is at `%LOCALAPPDATA%\ReSkate\trainer\tuning-values.txt`.
- **Body flip tuning:**
  - `PhysicsAirstates.MinBodyFlipTimeVsUpY` (needs 0.8–1.2 s of air);
  - `BodyFlipMinGrabTimeFraction` = 0.3;
  - `FlipMaxSpeed` = 10;
  - `FlipBodySpinScalar` = 0.5.

  Dark Flip doesn't touch any of these. The game's own height rule applies.
- **Physics states:** 100s riding, 200/201 air, 300 wipeout, 504 off board, 600s board placement/footplants. One physics step = 16.67 ms.
- Jaq plays regular, with Dark Catch Assist off and Legacy Dark Catches on.
