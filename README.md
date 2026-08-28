# MK Circuit

![Uploading image.png…]()


A complete, self-contained Godot 4 MVP of a two-kart top-down racer. The track
is inspired by Mario Circuit 3 without copying its art or exact geometry.

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
| Accelerate / brake | W/S or Up/Down |
| Steer | A/D or Left/Right |
| Drift and charge a mini-turbo | Shift while steering |
| Use held item | Space |
| Restart race | R or Enter |

## Included MVP systems

- A closed track with asphalt, penalizing dirt/grass, and physical walls
- Responsive acceleration, reverse, speed-scaled steering, drift, and mini-turbo
- 16 ordered checkpoints; skipped or backward checkpoints never count
- Countdown → Racing → Finished state machine and three-lap races
- A waypoint-following rival subject to the same checkpoints and walls
- Respawning item boxes, banana spin-outs, and mushroom speed boosts
- Out-of-bounds recovery at the last valid checkpoint
- Live lap, position, held-item, timer, and replay UI

The entire game is deliberately code-driven in `main.gd`, which makes the MVP
easy to inspect, tune, and extend without generated editor metadata.
2d snes mk mario circuit race 

wiki: https://www.mariowiki.com/Mario_Circuit_3

