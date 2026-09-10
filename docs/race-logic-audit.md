# Race logic audit (#10 / #11)

## Previous ownership

- `main.gd::_physics_process` owned countdown, race timing, state transitions, and control locking.
- `main.gd::check_checkpoint` owned checkpoint order, lap increments, and the finish trigger.
- `main.gd::race_score` and `sort_race_positions` owned ranking.
- `main.gd::finish_race` owned final presentation as well as mutating race state.
- `main.gd::update_hud` was a read-only consumer of laps, position, state, and elapsed time.
- `main.gd::recover_kart` was a checkpoint-state reader used to place a kart back on track.

## Captured #11 reproduction

The old `race_score` ranked racers in the same segment using Euclidean distance to
the next checkpoint. A kart moving forward but laterally offset from the track
center could become farther from that point than a trailing centered kart, so the
sort key decreased and the displayed order flipped even though neither kart had
passed the other. Equal coarse scores were also left to an unstable sort order.

The regression test recreates this with two racers in the same segment: the leader
has the greater projection along the segment but is farther from the next marker.
The old distance-to-marker score ranks it second; the new segment projection ranks
it first.

## New ownership

`RaceManager.gd` is the single writer for countdown/race state, ordered checkpoint
registration, lap completion, monotonic track progress, race position, finish
order, and the idempotent end transition. `main.gd` now owns only world simulation
and presentation, and delegates all race mutations to the manager. Progress is
compared as `(lap, segment, projected distance within segment)`, with racer spawn
order as a deterministic exact-tie break. A debug-build assertion reports any
frame where projected progress decreases while velocity is forward.

## Technical circuit and starting grid

The circuit now has 59 checkpoints across 7,825.19 units. The shortest segment is
127.79 units, above the 105.8-unit checkpoint rearm threshold. The closing segment
is included in validation, and the first point is not repeated at the end.
Mitered road offsets maintain 200-unit segment width. Startup validation checks
flatness, length, segment spacing, road/outer-wall boundary intersections, and
folded shoulder/road triangles. Walls retain their physical collision shapes.

The start tangent is shared by spawn placement and the finish-line paint. Rear-row
centers are 115 units behind the line; front-row centers are 55 units behind it.
Columns are at −50, 0, and +50 units. Racer-array order remains PLAYER, COM 1–5,
so the front row initially ranks first through third and the player ranks fourth.

Before the first forward start crossing, `progress_tuple()` uses signed distance
along the start straight, preserving the separation between grid rows. Stable
array order still breaks same-row ties. `has_crossed_start` is reset at race start
and latched by forward movement past the start within the checkpoint corridor.
It cannot be cleared by reversing. The first required checkpoint remains 1;
launch therefore awards no lap. Existing checkpoint rearming, three-lap completion,
and finish-order rules remain in force.

## Items, AI, and recovery

Ten explicit station waypoint indices replace the old placement list. Each station
creates three boxes at offsets −40, 0, and +40; `station_id` controls item alternation
independently of `track_index`. The latter still identifies placement and animation
phase. Availability and the six-second cooldown belong to each individual box.
The existing one-held-item rule and 35-unit pickup distance remain unchanged.

AI targets the next checkpoint owned by RaceManager, instead of advancing a separate
waypoint whenever it gets close. It examines the next three corners, estimates a
handling-dependent corner speed, and begins braking before entering the checkpoint
radius. Heading error also caps speed during sharp corrections. Recovery resets
the AI waypoint to the next required checkpoint; it grants no checkpoint or lap.

The smoke-test report adds item count, grid dimensions, track length, initial player
position, race state, and an incrementing race generation. It is emitted after
each restart so browser tests can distinguish a fresh countdown from stale data.

See [verification results](circuit-verification.md) for the test scenarios and
measured limits. Elevation, additional items, AI overtaking, and item-lane strategy
are outside this change.
