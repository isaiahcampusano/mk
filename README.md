# MK Circuit
**[Play MK Circuit in your browser](https://isaiahcampusano.github.io/mk/)**

<img width="793" height="450" alt="image" src="https://github.com/user-attachments/assets/dec4d2dd-2cb6-4065-a941-f1bb2bd4baba" />

A 3D chase-cam racing game built in Godot 4. The track is inspired by Mario
Circuit 3, with flat-shaded low-poly visuals and six-kart arcade racing.

---

## Play

1. Install Godot 4.6.3 (the version used for testing and web exports).
2. Import this folder from the Godot Project Manager.
3. Press **F6** or **F5** to run.

No external assets or add-ons are required.

Every push to `main` is exported for the web and deployed to GitHub Pages by
the included GitHub Actions workflow.

## Controls

| Action | Keyboard |
| --- | --- |
| Choose driver / kart | Arrow keys + Enter |
| Return from kart selection | Escape |
| Accelerate / brake | W/S or Up/Down |
| Steer | A/D or Left/Right |
| Hop | X |
| Drift and charge a mini-turbo | Shift while steering |
| Use held item | Space |
| Toggle chase / debug camera | F3 |
| Restart race | R or Enter |

## Included MVP systems

- A real 3D ribbon track with asphalt, penalizing dirt/grass, and physical walls
- Flat, unshaded low-poly geometry inspired by the readability of SNES racers
- A smooth collision-aware chase camera plus an F3 whole-track debug camera
- Low-poly karts, rotating item cubes, boost flames, and banana hazards
- Four original drivers and four kart bodies backed by editable Godot Resources
- A persistent driver → kart → countdown pre-race flow
- Resolved loadout stats that scale speed, acceleration, handling, and drifting
- Responsive acceleration, reverse, speed-scaled steering, hop, drift, and mini-turbo
- 59 ordered checkpoints; skipped or backward checkpoints never count
- Countdown → Racing → Finished state machine and three-lap races
- Five rivals that anticipate corners and obey the same checkpoints and walls
- Ten three-lane item stations with independent six-second respawns, banana spin-outs, and mushroom speed boosts
- Out-of-bounds recovery at the last valid checkpoint
- Live lap, position, held-item, timer, and replay UI
- Driver/kart identification in the race HUD and final standings

## Technical circuit

The flat circuit is approximately **7,825 world units** long, compared with 2,995
in the previous layout. A long start straight leads into two opposing hairpins,
linked S-curves, a chicane, and an outer return straight with sweeping corners.
The road remains 200 units wide. Ground, recovery bounds, and the F3 overview
camera adapt to the generated road and walls.

Six karts start in two rows of three, with 60 units between rows. The player starts
on the rear left in fourth place; COM 3–5 occupy the front row. Painted slots and
a full-width checkered line show the grid. Crossing the line at launch does not
award a lap.

Each of the ten item stations has left, center, and right boxes at lateral offsets
of −40, 0, and +40 units. Each box respawns independently after six seconds.
Station identity and lap number determine mushroom/banana alternation; holding an
item prevents collecting another box.

World geometry, cameras, items, and kart handling remain code-driven in `main.gd`.
`RaceManager.gd` owns countdowns, checkpoints, ranking, laps, and finish order.
See [race-logic notes](docs/race-logic-audit.md) and the
[verification report](docs/circuit-verification.md) for implementation details.

## Verify locally

With Godot 4.6.3 on your PATH, import the project and run:

```sh
godot --headless --editor --path . --quit
godot --headless --path . tests/TestRaceConfig.tscn
godot --headless --path . tests/TestKartMechanics.tscn
godot --headless --path . tests/TestMainConfiguration.tscn
godot --headless --path . --script tests/test_race_manager.gd
godot --headless --path . tests/TestCircuitGeometry.tscn
godot --headless --path . --fixed-fps 60 tests/TestCircuitIntegration.tscn
```

The integration suite runs three seeded AI races across all 16 driver/kart
combinations, then two races through the player-input branch using the fastest
and lowest-handling loadouts. Both extremes currently select Bramble Knox / Vortex
GT. Every racer must complete three laps without recovery or prolonged stalls.

For browser verification, install the matching Godot web export templates, export
the Web preset to `build/web/index.html`, then run `npm ci`,
`npx playwright install chromium`, and `npm run test:web`. The smoke test checks
selection, loadout preservation, the grid, item counts, and restart, and saves
wide/narrow overview and starting-grid screenshots under `.artifacts/test-results`.

CI limits each Godot suite to four minutes, rejects script errors even if Godot
exits successfully, and requires an explicit completion message. Deployment still
occurs only through the existing GitHub Pages workflow after successful checks.

Inspiration: [Mario Circuit 3](https://www.mariowiki.com/Mario_Circuit_3)

