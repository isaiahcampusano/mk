# Technical circuit verification

Baseline: `98ab2629bf6badad2fe375d8d3ed2b267223361c`.
Environment: Windows, Godot 4.6.3 stable, Playwright 1.63.0 with headless Chromium.

## Delivered behavior

- 7,825.19-unit flat circuit with 59 checkpoints, opposing hairpins, linked esses,
  a chicane, and an outer return. Minimum checkpoint segment: 127.79 units.
- Two rows of three karts; centers 55/115 units behind the full-width finish line.
- Thirty independently respawning item boxes across ten three-lane stations.
- Signed pre-start ranking, corner-anticipating AI, recovery target synchronization,
  dynamic ground bounds, and an overview camera fitted to the circuit.

## Automated results

| Suite | Result and coverage |
| --- | --- |
| RaceConfig | PASS: selection, invalid-content fallbacks, and catalog handling; expected warning cases exercised |
| Kart mechanics | PASS: hop, drift, mini-turbo, and independent item animation |
| Main configuration | PASS: selected loadout, model geometry, six racers, and thirty boxes |
| RaceManager | PASS: row ranking, stable ties, launch/reverse behavior, checkpoint order, rearming, three laps, and finish ordering |
| Circuit geometry | PASS: valid boundaries and ribbon triangles, 200-unit width, bounds, wide/narrow camera fit, grid clearance, pickup/respawn, recovery, and restart cleanup |
| Circuit integration | PASS: five seeded full races; all racers finish without recovery or checkpoint stalls lasting 20 seconds |
| Web export smoke | PASS: selection flow, selected loadout, grid dimensions, track length, thirty boxes, restart generation, and no captured runtime errors |

The final six-suite run used the shell runner extracted directly from the CI
workflow, through Git Bash on Windows. Runner checks also verified success,
nonzero exit, script error despite a success marker, missing completion marker,
and a hanging subprocess. All five checks returned the expected result; the hang
case used a shortened test-only timeout. The final Chromium smoke run passed in
27.9 seconds. The hosted Ubuntu workflow has not been run or deployed remotely.

### Full-race integration

The first three runs exercise all 16 resolved driver/kart combinations. The final
two use scripted acceleration, braking, steering, and item input through the actual
player-control branch. No racer is teleported or granted checkpoint progress.

| Seed | Mode | Race duration (simulated seconds) |
| --- | --- | ---: |
| 4200 | Six AI racers | 82.63 |
| 4201 | Six AI racers | 92.10 |
| 4202 | Six AI racers | 84.48 |
| 4203 | Fastest player loadout plus five AI | 86.60 |
| 4204 | Lowest-handling player loadout plus five AI | 91.60 |

Both extreme-loadout selections currently resolve to Bramble Knox / Vortex GT:
top speed 469.49 and turn rate 1.90. These scripted checks demonstrate completion
and control-path compatibility; they are not a human assessment of game feel.

## Browser performance comparison

Baseline and updated release exports ran sequentially on the same machine at
1280 × 720. Three repetitions alternated execution order. Each camera warmed up
for 1.2 seconds before a five-second requestAnimationFrame sample. The player
remained stationary while AI raced. Values below average the three per-run means.

| Camera | Baseline mean frame interval | Updated mean frame interval | Change |
| --- | ---: | ---: | ---: |
| Chase | 115.39 ms | 111.49 ms | −3.4% |
| Overview | 113.96 ms | 116.74 ms | +2.4% |

No sustained regression above 10% was observed. Absolute frame times in this
headless environment are slow and must not be presented as representative GPU
gameplay performance. The measurement does not cover a full player-driven lap or
all hardware/browser combinations.

## Visual checks and delivery

Browser screenshots were inspected for the separated starting grid, painted slots,
full-width finish line, item lanes, circuit boundaries, and overview framing at
1280 × 720 and 720 × 900. The narrow browser viewport preserves the existing
letterboxed presentation. Existing HUD glyph rendering is unchanged.

The delivery bundle includes the source, a baseline-relative patch, these results,
raw test/performance evidence, and the three screenshots. No remote push, merge,
or deployment is part of this local delivery. The existing Pages workflow remains
the release path; a revert of the change set is the rollback path.
