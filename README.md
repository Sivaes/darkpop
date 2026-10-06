# ReSkate Dark Pop

A patch for [ReSkate](https://github.com/Dingo-Shenanigans/ReSkate) (GPL-3.0) that tries to
bring back the dark catch pop removed in skate. 0.32.0, plus a recorder for measuring attempts. Toggles in
Insert > SKATER > BOOSTS, all off until you turn them on.

This repository holds only the patch (`patches/dark-pop.patch`), the Thunderstore package files
(`thunderstore/`) and the workflows. ReSkate's source is fetched from the ReSkate project when you build,
so nothing of theirs is copied here.

## Build it
1. Actions > **Build Dark Pop** > Run workflow.
2. `upstream_ref`: a ReSkate release tag such as `v1.0.9` (or `main`). `mod_version`: this mod's version.
3. Leave **publish** off for a test zip; download it from the run's Artifacts.

If the **Apply the patch** step fails, ReSkate changed a file the patch edits and the patch needs updating.

Not affiliated with EA, Full Circle or the ReSkate developers.
