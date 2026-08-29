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

**Status:** reopened for focused aesthetic iteration after the reference-frame
correction. The calm exchange remains the default; exact-overlap interference
remains an optional session lens. Tracked in DAZ-272 and DAZ-274.

Weeks and Months are two resolutions of one exact birth-anchored timeline.
Their transition should disclose that containment without pretending every
month contains four weeks.

### Stable grammar

1. The source topology recedes in place before the destination resolves in
   place; structural channels do not travel across the field.
2. Five-year and quarter channels remain a fixed scaffold. Ordinary Month
   boundaries and Weeks-only life-month channels cross-dissolve globally at
   their own fixed positions.
3. The active point, guide, and held ruler may travel because they represent
   one exact date; structural axes and their annotations remain stationary.
4. No fixed four-week grouping is shown: both endpoints retain their exact
   birth-anchored week and calendar-month semantics.
5. Axis precision switches with the destination while panel and viewport
   geometry remain fixed.
6. Lived and remaining values retain their pinned geometry. Two local
   shimmers resolve their units simultaneously inside the text envelopes;
   no filament crosses the empty space between them.

### Why the calm exchange remains the default

Because 52-week life-year rows drift against birth-anchored calendar months,
moving exact overlap fragments forms dense interference fields across ages.
Even when mathematically faithful, that motion asks for more attention than a
frequently used widget transition should require. A calm in-place exchange is
therefore the startup behavior and primary product expression.

### Retained alternative — exact date-overlap lens

The DAZ-274 refinement precomputes every real date-overlap fragment, eases the
fragments into a stationary midpoint, holds that structure for roughly
`104ms`, and then resolves it. Moving future outlines are omitted and the
visible lived fragments are restricted to the present threshold, making the
relationship read as a local temporal fold instead of a full-field moire. It
is educational and visually distinctive, but deliberately subordinate to the
calm exchange.

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

**Status:** complete. Live temporal measure and the orthogonal held ruler were
graduated through DAZ-277 and DAZ-278.

Clicking a cell pins one deliberate comparison with the present. The LIFE rail
gains a quiet second marker and highlights only the segment between now and
the selected interval. The existing exact-date readout remains the primary
label.

This is the purpose that may earn click interaction. Pinning is not a doorway
to journaling, milestones, or a detail product.

The static proof established that one exact date can survive projection
changes, gain a quiet foreground outline, and form a subordinate LIFE segment
without competing with the accented present. Pointer click and the keyboard
inspection cursor share the same single-pin state; leaving LIFE clears it.

The pin is a complete secondary coordinate rather than a floating mark. Its
week/month value and age remain visible on the grid axes, and its life-year
value remains visible on the LIFE scale. Duplicate coordinates collapse to
one label, while the present keeps the only accent and inspection remains
subordinate.

### Rejected ownership — persistent pin sentence

The first numeric proof placed `109 WEEKS AFTER NOW` or `105 WEEKS BEFORE NOW`
permanently beside the unchanged centered date after pinning. Although its
geometry stayed fixed and its arithmetic was exact, freezing a transient
measurement made the pin compete with the date and merely preserve hover.

Live review retained the treatment but changed its owner. The sentence is
useful while the pointer or keyboard cursor is moving because inspection is
already transient and explicitly asks how the chosen interval relates to now.
It must leave with inspection rather than become permanent dashboard copy.

### Stable grammar — live measure and held ruler

The corrected proof assigns distinct jobs to inspection and pinning:

1. Pointer hover and keyboard inspection show the exact date, coordinates, and
   full projection-aware delta from the shared present origin.
2. Clicking or pressing Enter holds that interval without freezing its full
   prose readout: a quiet cell outline, component values engraved into the
   orthogonal present-to-pin ruler, an unsigned endpoint total, LIFE marker,
   and LIFE span remain while inspection moves elsewhere.
3. The local ruler travels horizontally from present to the pin column, then
   vertically into the held cell. It never colors the cells it crosses; the
   grid itself supplies the ruler's divisions.
4. Pin creation draws horizontal then vertical at a bounded distance-aware
   speed. Retargeting reshapes the existing ruler, while pointer dragging snaps
   its held endpoint between exact cells. Escape cancels a drag and dropping on
   present clears it.
5. Hovering the held cell, either local ruler leg, or the LIFE span recalls the
   same full delta through the ordinary inspection grammar; no separate pin
   tooltip or countdown exists.
6. The LIFE ruler gains clearer neutral contrast and remains the global
   relationship when local endpoints leave the viewport.
7. Reduced motion resolves directly to the same held geometry.
8. Opening and T/Space begin from present without inheriting a parked pointer;
   deliberate mouse movement transfers inspection back to hover.
9. Horizontal key repeat is normalized by rendered cell distance, preserving
   one interval per deliberate press while giving Weeks and Months coherent
   traversal speed.
10. Present remains the accented origin coordinate, inspection remains a
    transient coordinate, and the hold becomes a self-describing ruler rather
    than a third peer tick. Weeks or Months live on the horizontal leg,
    life-years remain horizontally readable inline with the vertical leg, and
    zero-length components vanish.
11. Exact coordinate overlaps merge. For near collisions the present label
    stays nearest the axis and inspection moves into a second lane with a short
    leader. The held measurement no longer occupies either axis.
12. Both component labels interrupt their own legs and emerge only when the
    rendered leg gives them enough room. Near rulers remain silent rather than
    moving measurements onto the axes; horizontal-only rulers avoid duplicate
    totals.
13. The terminal total omits signs and BEFORE/AFTER wording, requires enough
    overall ruler length and endpoint room, and fades when inspection of the
    held relationship gives the full header readout ownership. The route from
    accented present to neutral pin supplies direction.

Weeks count weekly grid intervals and Months count exact birth-anchored
calendar-month intervals. A pin inside the present interval produces no
redundant zero delta.

### Boundary — not multiple pins

Present is an origin, inspection is a probe, and the pin is one held
relationship. Multiple pins are not extra playfulness: useful marks would need
names, editing, collision handling, keyboard traversal, deletion, and likely
persistence. That is a separately justified personal-history plugin.

### Reject if

- Pinning merely freezes hover without enabling comparison.
- A second marker competes with the present accent.
- The delta creates productivity pressure or countdown urgency.
- A grid-spanning connector obscures cells or implies a path through
  intervening intervals.

## Workstream 4 — Grid rhythm and contextual spacing

**Status:** negative-space lens, shared temporal frame, direct inspection, and
synchronized coordinate progression under live review, tracked in DAZ-279.
The active branch remains separate from `main`.

Tim Urban's five-year row separation may make age groups more immediately
legible. Because it changes geometry rather than decoration, it must be tested
before later guide and viewport motion is refined.

The design intent is two-dimensional. Gaps are not an ornamental treatment or
a copied quarter token; they are the material through which the grid reveals
the next truthful temporal group before labels are read.

- Along age, both projections form exact five-life-year bands.
- Across Weeks, twelve proportional life-month phrases distribute the
  indivisible 52-week row with an irregular 4/5-week beat.
- Across Months, larger channels after months 3, 6, and 9 form exact quarters.

These life-month phrases are not calendar months. Exact calendar boundaries
often fall inside seven-day cells and drift across rows; inspection retains
that precision.

### Bounded specimens

1. **Control — unchanged density.** The uniform field remains the baseline.
2. **Rejected cadence-only cue — `982c080`.** Stronger gutter marks were too
   subtle and tested label hierarchy rather than structural spacing.
3. **Rejected budget-preserving lattice — `a4b405e`.** Redistributing the old
   gap total made the intended structure nearly imperceptible. Geometry
   preservation incorrectly displaced meaning as the primary criterion.
4. **Topology specimen.** Deliberately strong uninterrupted channels proved
   the 12-by-five-year and 4-by-five-year compositions, but equal channel
   widths fragmented Weeks and made Months resemble detached tables.
5. **Refined rhythm — `f30a222`.** The visual composition succeeded, but its
   implementation rescanned preceding boundaries inside every Canvas cell
   paint. Calendar and LIFE interaction became unacceptably slow, especially
   during projection motion. The live plugin was restored to `main` before the
   geometry was rebuilt.
6. **Optimized gap lens — `10ca4e5`.** Closed-form boundary counts make cell
   geometry constant-time. Projection channels are now slightly thinner than
   five-year channels, reversing the previous hierarchy while preserving one
   continuous field. `G` or the `toggleGaps` IPC entry point opens and closes
   the rhythm over a short session-only transition. Present remains the sole
   accent and the held ruler remains foreground.
7. **Shared temporal frame — `b0fb136`.** The panel gains a restrained amount
   of breathing room while Calendar remains its stable size contract. The grid
   and LIFE rail now occupy the same exact horizontal span; the reviewed theme
   renders both at `437px` while preserving 31 complete life-year rows.
8. **Direct inspection — `3027b59`.** Every semantic channel uses nearest-cell
   midpoint ownership, removing sticky dead space without visually closing the
   gaps. Dense structure and lightweight interaction render separately, and
   horizontal repeat derives from full rendered stride so Weeks and Months
   share one target visual speed.
9. **Synchronized coordinate atom — `de9f7f5`.** During either projection
   style, each active date drives its displayed point, axis ticks, guides, and
   held ruler from one progress value. This removes the observed lead where
   rulers reached the destination before their point. Broader aesthetic
   composition of the Weeks-Months seam remains the next focused experiment.
10. **Anchored reference frame — `3a3c506`.** Exact rail/grid width equality is
    was initially rejected because the terminal percentage appeared to need a
    separate spatial obligation. The rail shared the field's left edge and
    reserved its right label. The 1–12 scale and source/destination coordinate
    ticks became fixed; five-year and quarter channels became a stationary
    scaffold while Weeks-only phrases breathed globally. The default traveling
    wipe became an in-place resolution exchange, while the active cell,
    guides, and held ruler preserved their coherent transfer. A 32-row frame
    gave the `437 × 267.92` grid a `1.631` aspect ratio without increasing
    width or abandoning Omarchy's exact vertical centering.
11. **Engraved frame and collision lanes — `0358002`.** Review showed that the
    shortened rail paid more compositional cost than the percentage required.
    The `437px` rail now restores exact frame equality while its percentage
    interrupts the terminal span with a background knockout. Permanent axis
    scales retain their lane; present and inspection allocate two dynamic
    lanes by text-envelope collision, with lower-priority inspection text
    yielding only when both are occupied. Ordinary Month boundaries now stay
    fixed through projection motion, and the optional exact-overlap lens
    confines moving lived fragments to a narrow present-time fold rather than
    animating a full-field interference texture.

No specimen adds alternating fills, a second accent, fixed four-week months,
or decorative animation.

### Progressive materialization

The workstream follows the method established by the held ruler:

1. Make the truthful structure unmistakable.
2. Tune proportion, hierarchy, density, and breathing without hiding it.
3. Test coexistence with present, inspection, pin, ruler, and motion.
4. Accept playful behavior only when it emerges from temporal structure.

The optimized specimen lets the projection exchange resolve twelve Weeks
phrases into four Month quarters while the five-year bands remain anchored.
The gap toggle itself makes the temporal phrases breathe out of, or settle
back into, the uniform field without changing the panel during interaction,
the visible context, exact date, or pin identity. The shared temporal frame
intentionally widens the earlier grid once, then remains invariant. At the
reviewed theme scale the grid and engraved LIFE track are both `437px`, and 32
visible rows produce a `267.92px` grid height. The
open-state projection channel is `3.75`, the five-year channel is `4`, and the
open and closed grid heights remain effectively identical.

Crossing a semantic channel now transfers ownership at the nearest-cell
midpoint. The negative space stays visible, but no longer pauses inspection.
Direct physical pointer review must decide whether Weeks now feels as slick
and tactile as Months before the behavior is promoted.

### Questions

- Does the field read first as one lifetime and then as meaningful temporal
  phrases, rather than as detached panels or a spreadsheet?
- Are the column and row channels perceptually coherent without being
  numerically identical?
- Do Weeks retain enough individual-cell legibility at the refined density?
- Does opening and closing the rhythm feel like a useful temporal lens rather
  than a settings toggle or a layout trick?
- Can the present retain a calm default position when variable row gaps are
  introduced?
- Do hit-testing, axis guides, wheel movement, pin coordinates, LIFE entrance,
  and both projection transitions remain exact and stable?
- Does the extra structure reduce moire, or create stronger accidental bands?

### Reject if

- The panel changes dimensions during page, projection, or gap transitions,
  exceeds the fitted screen budget, or useful context decreases.
- Weeks imply fixed four-week or exact calendar months.
- Existing motion must distort exact temporal coordinates to accommodate the
  gaps.
- Calendar or LIFE interaction regresses in latency or frame pacing.
- The field resembles detached cards, a spreadsheet, or decorative striping.
- The channels compete with present, inspection, or the held ruler.

## Workstream 5 — Hover-guide motion

Hover should draw the foreground coordinate guides from the axes toward the
inspected cell over a short, cancellable interval. The present accent and its
guides remain stationary.

A traveling animation directly from the present to every hovered cell is not
the default direction: it can imply that now moved and becomes noisy under
rapid pointer motion. Textual distance belongs to live inspection; the one
retained spatial connection belongs to deliberate pinning.

### Reject if

- Exact date feedback waits for the animation.
- Pointer movement leaves queued trails or stale guides.
- Hover makes the present appear to move.

## Workstream 6 — Viewport movement

Wheel and keyboard navigation may slide by one exact life-year row using a
short, cancellable transition and a restrained edge response. It retains
stable dimensions and exact stopping positions.

Inertial scrolling is intentionally excluded if it makes ages harder to land
on. This is polish, not core meaning.

## Workstream 7 — Transition light treatment

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
3. Temporal-distance pin — complete.
4. Grid rhythm and contextual spacing — active.
5. Hover-guide motion.
6. Viewport movement.
7. Transition light treatment.

Only one workstream may change runtime behavior at a time. Each one receives
its own live review before the next begins.
