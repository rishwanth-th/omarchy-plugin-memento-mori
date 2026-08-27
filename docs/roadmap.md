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
6. Lived and remaining values retain their pinned geometry. Two local
   shimmers resolve their units simultaneously inside the text envelopes;
   no filament crosses the empty space between them.

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

- `A` alternates the motion style for subsequent `P` projection changes.
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
- Lived and remaining readouts change units without shifting, reflowing, or
  becoming detached from the grid transition.
- `M →` and `P` toggle projection using the currently selected transition.
- `A` and the grid triple-click change only motion style, never projection.
- Hit-testing pauses only during the short morph.
- Rapid reversal creates no queued or orphaned animation.
- Reduced motion can snap to the destination without a different layout.

### Reject if

- Boundary weeks visibly jump to an arbitrary month.
- The axes, grid, or widget jiggle.
- The moving fragments read as noise rather than containment.
- Reversal requires waiting for the previous animation to finish.

## Workstream 2 — LIFE entrance

**Status:** complete. Tracked in DAZ-275.

The entrance moves attention from the whole-life summary to the local present
without ever making the settled values untrue.

### Settled design — global passage, local focus

- The Calendar rail and LIFE rail remain settled at the same exact progress;
  entrance never rewinds the visible timeline from present back to birth.
- A subordinate white tracer travels over that rail from birth toward the
  stationary present marker, then dissolves as it arrives. It suggests passage
  without replacing or moving the true value.
- Exact percentage, date readout, grid, and present cell remain available.
  Lived and remaining labels stay pinned to their final segment geometry and
  brighten without sliding or reflowing.
- The full entrance holds the tracer at birth for `60ms`, then sweeps for
  `420ms`. After `160ms`, the present cell and labels resolve over `320ms`,
  while coordinate guides draw from the axes during the final `160ms`. Every
  layer lands together at `480ms`.
- Repeat entrances retain the same grammar in `380ms`: a `60ms` hold and
  `320ms` tracer, with a shorter `240ms` local resolve and final `160ms` guide
  handoff landing at the same moment.
- Calendar remains keyboard-first: `M` toggles Calendar and LIFE. Clicking the
  rail enters through the same path, while the visible back action is the
  direct pointer return.
- Closing or interacting mid-entrance cancels stale motion. An interrupted
  first entrance does not count as completed and may replay next time.
- Changing birth date or horizon rearms the full entrance. Reduced motion
  resolves directly to the same final state.

The accepted motion stays below half a second, keeps the true present visible,
and confines whole-horizon movement to the rail rather than pretending the
compact viewport contains all 4,000 weeks.

## Workstream 3 — Temporal-distance pin

**Status:** static proof of concept under live review. Tracked in DAZ-277.

Clicking a cell may pin a deliberate comparison with the present. The LIFE
rail would gain a quiet second marker and highlight only the segment between
now and the selected interval. The existing exact-date readout remains the
primary label; one concise delta may describe how far behind or ahead the
selection lies.

This is the purpose that may earn click interaction. Pinning is not a doorway
to journaling, milestones, or a detail product.

The first proof deliberately stops before motion and numbers. One exact date
survives projection changes, its containing cell gains a quiet foreground
outline, and the LIFE rail shows a subordinate marker plus only the segment
between it and the accented present. Pointer click and the keyboard inspection
cursor share the same single-pin state; leaving LIFE clears it.

The pin is a complete secondary coordinate rather than a floating mark. Its
week/month value and age remain visible on the grid axes, and its life-year
value remains visible on the LIFE scale. Duplicate coordinates collapse to one
label, while the present keeps the only accent and hover remains subordinate.

### Questions

- Is the visual segment sufficient, or does a compact `+587 WEEKS` delta help?
- Does the static cell-to-rail relationship read clearly enough to earn
  further motion?
- Is the keyboard cursor visually distinct enough from the deliberate pin?
- After live review, should a compact numeric delta be tested or omitted?

### Active experiment — projection delta

The discardable delta branch tests one fixed, right-aligned readout beside the
unchanged centered date: `109 WEEKS AFTER NOW` or `105 WEEKS BEFORE NOW`.
Weeks count weekly grid intervals and Months count exact birth-anchored monthly
intervals. The geometry does not move, the wording is symmetric around now,
and a pin inside the current interval shows no redundant zero delta.

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

## Workstream 6 — Transition light treatment

**Status:** parked. Tracked in DAZ-276.

Explore whether restrained glow, glints, or sparse glitter can make direction
and arrival easier to perceive in the transitions that already carry temporal
meaning. Light must be emitted by an existing seam, tracer, guide, or landing
point; it cannot become an independent particle layer.

### Questions

- Can a brief glint clarify where a transition resolves without becoming a
  reward animation?
- Should treatment derive only from the active theme's accent and foreground?
- Can sparse light remain stable across scaling and avoid moire or flicker?

### Reject if

- The effect is decorative when the underlying transition is already clear.
- Glitter competes with the present accent or makes ordinary toggles feel
  ceremonial.
- Particles linger, queue, or imply urgency, achievement, or gamification.

## Evaluation order

1. Weeks ↔ Months semantic morph — complete.
2. LIFE entrance — complete.
3. Temporal-distance pin — next.
4. Hover-guide motion.
5. Viewport movement.
6. Transition light treatment.

Only one workstream may change runtime behavior at a time. Each one receives
its own live review before the next begins.
