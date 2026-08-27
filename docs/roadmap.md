# Roadmap

V1 establishes the information architecture and interaction grammar. V2 adds
motion and tactility only where they make temporal structure easier to
understand. It is not permission to add product machinery.

V2 is organized as interaction workstreams, not as a collection of effects.
Each workstream begins with a product intent and ends with a stable decision.
It may use isolated experiments to answer uncertain questions, but an
experiment is a method rather than the deliverable. A workstream graduates
into [Design philosophy](design.md) only after live review proves its meaning,
timing, cancellation, and reduced-motion behavior. Rejected experiments stay
here with a short reason so the same ambiguity is not rediscovered.

## Motion contract

- Motion explains containment, passage, focus, or temporal distance.
  Decoration alone is not enough.
- The panel frame, Canvas budget, grid envelope, row stride, and present
  anchor remain fixed throughout every transition.
- Ordinary feedback should follow Omarchy's short `140–160ms` OutCubic
  vocabulary. Structural motion may take roughly `320–420ms`, but must feel
  responsive before it feels cinematic.
- Every animation is interruptible. A new action cancels stale work and
  settles into one coherent state rather than building a queue.
- Repeated opening must not become tedious.
- Reduced motion resolves immediately to the same semantic endpoint.
- The present remains the accent and semantic anchor while another interval
  is inspected or selected.
- Playfulness must not become gamification, urgency, particles, or bounce for
  its own sake.

## Workstream 1 — Weeks ↔ Months semantic morph

**Status:** complete. Stable seam retained as the default; exact-overlap
interference retained as an optional session lens. Tracked in DAZ-272 and
DAZ-274.

Weeks and Months are two resolutions of one exact birth-anchored timeline.
Their transition should disclose that containment without pretending every
month contains four weeks.

### Stable grammar

1. A narrow resolution seam travels left-to-right across the stable grid.
2. Ahead of the seam the source projection remains settled; behind it the
   destination projection is already settled.
3. Cells switch only at the seam. The two resolutions never overlap and cells
   do not travel to a false one-to-one spatial destination.
4. No fixed four-week grouping is shown: both endpoints retain their exact
   birth-anchored week and calendar-month semantics.
5. Axis precision switches with the destination while panel and viewport
   geometry remain fixed.

### Why the seam remains the default

Because 52-week life-year rows drift against birth-anchored calendar months,
moving exact overlap fragments forms dense interference fields across ages.
Even when mathematically faithful, that motion asks for more attention than a
frequently used widget transition should require. The clean cutover therefore
remains the startup behavior and primary product expression.

### Retained alternative — exact date-overlap lens

The DAZ-274 refinement precomputes every real date-overlap fragment, eases the
fragments into a stationary midpoint, holds that structure for roughly
`104ms`, and then resolves it. It is educational and visually distinctive,
but deliberately subordinate to the stable seam.

- `3` alternates the motion style for subsequent `1` / `2` changes.
- A triple-click on an otherwise inert grid region provides the pointer
  equivalent without colliding with the single-click projection cue.
- The choice is session-only and adds no visible control or persisted setting.
- The annotated tag `experiment/date-overlap-interference-v1` preserves the
  reviewed standalone specimen.

### Rejected alternative — neutral filament lens

A narrow lens was also tested in which:

1. Ahead of the lens, source cells remain fully settled.
2. Entering the lens, cells collapse vertically into a quiet horizontal
   filament for each life-year row.
3. A broad, low-opacity shimmer may travel inside the neutral filament. It
   must use coarse spacing rather than fine alternating lines, so it cannot
   alias into accidental moire.
4. Leaving the lens, destination cells expand from the same row filament.
5. Source and destination grids are never visible in the same pixels.

Although semantically neutral, the filament felt mechanically different but
visually too close to the stable seam, while its independent shimmer taught
nothing that emerged from Weeks and Months themselves. It was discarded.

### Acceptance

- Both directions communicate one timeline at a different resolution and end
  on the unchanged V1 grids.
- No fixed four-week grouping or false calendar semantics.
- Present, lived, and future states are exact at both endpoints.
- `M →`, `1`, and `2` use the currently selected transition.
- `3` and the grid triple-click change only motion style, never projection.
- Hit-testing pauses only during the short morph.
- Rapid reversal creates no queued or orphaned animation.
- Reduced motion can snap to the destination without a different layout.

### Reject if

- Boundary weeks visibly jump to an arbitrary month.
- The axes, grid, or widget jiggle.
- The moving fragments read as noise rather than containment.
- Reversal requires waiting for the previous animation to finish.

## Workstream 2 — LIFE entrance

**Status:** next. Tracked in DAZ-275.

The LIFE rail may travel from birth through its year ticks to the present,
with lived fill following behind it. Once the global sweep settles, the local
present cell and its two guide lines resolve into place.

The rail should tell the whole-horizon story; the compact viewport should not
pretend to animate thousands of off-screen cells.

### Prototype 1 — global passage, local settle

- The Calendar rail and LIFE rail remain settled at the same exact progress;
  entrance never rewinds the visible timeline from present back to birth.
- On the first completed LIFE entrance of a shell session, a subordinate
  passage tracer holds at birth for `60ms`, then travels through lived time
  toward the stationary present marker over `420ms` using InOutCubic timing.
  It dissolves as it arrives so the real present remains the only accent.
- Exact percentage, date readout, grid, and present cell are available
  immediately. Lived and remaining labels stay pinned to their final segment
  geometry and brighten with the rail rather than sliding or reflowing.
- The present cell's two coordinate guides resolve during the final `160ms`,
  handing attention from the global rail to the local viewport.
- Repeat entrances retain the same `60ms` hold and passage trace in a shorter
  `320ms` sweep, with the guide handoff occupying the final `160ms`. The
  transition remains perceptible without repeating the full first-session
  timing or resetting settled state.
- Calendar remains keyboard-first: `M` toggles Calendar and LIFE. Clicking the
  rail enters through the same path, while the visible back action is the
  direct pointer return.
- Closing or interacting mid-sweep cancels stale motion. An interrupted first
  entrance does not count as completed and may replay next time.
- Changing birth date or horizon rearms the full entrance. Reduced motion
  resolves directly to the same final state.

### Questions

- Does the sweep explain scale, or merely delay the answer?
- Should it run once per session, only after configuration changes, or on
  every opening?
- Can repeat openings use only a short present-cell settle?
- Should the lived grid fill by visible life-year rather than individual cell?

### Reject if

- Opening LIFE becomes a ceremony the user has to wait through.
- The current value is unavailable during animation.
- The viewport implies it contains the whole 4,000-week sweep.

## Workstream 3 — Temporal-distance pin

Clicking a cell may pin a deliberate comparison with the present. The LIFE
rail would gain a quiet second marker and highlight only the segment between
now and the selected interval. The existing exact-date readout remains the
primary label; one concise delta may describe how far behind or ahead the
selection lies.

This is the purpose that may earn click interaction. Pinning is not a doorway
to journaling, milestones, or a detail product.

### Questions

- Is the visual segment sufficient, or does a compact `+587 WEEKS` delta help?
- Does click again clear the pin, with Escape as the keyboard equivalent?
- Should keyboard inspection move the pin for accessibility?
- How does a pinned date survive projection changes without changing meaning?

### Reject if

- Pinning merely freezes hover without enabling comparison.
- A second marker competes with the present accent.
- The delta creates productivity pressure or countdown urgency.

## Workstream 4 — Hover-guide motion

Hover should draw the foreground coordinate guides from the axes toward the
inspected cell over a short, cancellable interval. The present accent and its
guides remain stationary.

A traveling animation directly from the present to every hovered cell is not
the default direction: it can imply that now moved and becomes noisy under
rapid pointer motion. Temporal distance belongs to deliberate pinning.

### Reject if

- Exact date feedback waits for the animation.
- Pointer movement leaves queued trails or stale guides.
- Hover makes the present appear to move.

## Workstream 5 — Viewport movement

Wheel and keyboard navigation may slide by one exact life-year row using a
short, cancellable transition and a restrained edge response. It retains
stable dimensions and exact stopping positions.

Inertial scrolling is intentionally excluded if it makes ages harder to land
on. This is polish, not core meaning.

## Evaluation order

1. Weeks ↔ Months semantic morph — complete.
2. LIFE entrance — next.
3. Temporal-distance pin.
4. Hover-guide motion.
5. Viewport movement.

Only one workstream may change runtime behavior at a time. Each one receives
its own live review before the next begins.
