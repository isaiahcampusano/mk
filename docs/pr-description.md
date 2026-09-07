# Gameplay systems and race-logic update

Closes #10, #11, #13, #15, and #18.

## Summary

- Gives item boxes independent, visual-only rotation and pulse animation.
- Adds an X-key hop, direction-locked drifting, and a duration-scaled mini-turbo.
- Makes character and vehicle resources self-identifying and discovers menu options from data folders.
- Gives every kart profile a distinct generated model silhouette, color, and existing resolved handling stats.
- Moves countdown, checkpoints, laps, progress ranking, finish order, and the end transition into `RaceManager`.
- Replaces distance-to-checkpoint ranking with lap/segment/projected-distance progress and deterministic ties.

## Race ownership audit

The before/after ownership map and the captured #11 reproduction are in
`docs/race-logic-audit.md`.

## Verification

- Godot 4.3 script import completed without parse errors.
- `tests/test_race_manager.gd` passes checkpoint, ranking, countdown, and finish-state regressions.
- `tests/TestKartMechanics.tscn` passes hop, drift threshold, mini-turbo, and item-visual isolation regressions.
- Character selection, vehicle selection, and race scenes each completed a 180-frame rendered smoke run without script or runtime errors.
