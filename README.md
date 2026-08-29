# MK Circuit

<img width="827" height="469" alt="image" src="https://github.com/user-attachments/assets/f3c303cc-f68b-4ff0-8491-5beecf610c0f" />



A 3D chase-cam racing game built in Godot 4. The track is inspired by Mario
Circuit 3, with flat-shaded low-poly visuals and two-kart arcade racing.

**[Play MK Circuit in your browser](https://isaiahcampusano.github.io/mk/)**

## Play

1. Install Godot 4.3 or newer.
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
- Responsive acceleration, reverse, speed-scaled steering, drift, and mini-turbo
- 16 ordered checkpoints; skipped or backward checkpoints never count
- Countdown → Racing → Finished state machine and three-lap races
- A waypoint-following rival subject to the same checkpoints and walls
- Respawning item boxes, banana spin-outs, and mushroom speed boosts
- Out-of-bounds recovery at the last valid checkpoint
- Live lap, position, held-item, timer, and replay UI
- Driver/kart identification in the race HUD and final standings

The entire race remains deliberately code-driven in `main.gd`, which makes the
3D geometry, camera, gameplay rules, and kart handling easy to inspect and tune.
2d snes mk mario circuit race 

wiki: https://www.mariowiki.com/Mario_Circuit_3

