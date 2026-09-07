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
