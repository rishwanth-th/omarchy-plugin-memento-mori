# Design philosophy

## Intent

The plugin is a finite-time reminder, not a productivity product. Its job is
to make a chosen lifetime horizon visible, countable, and immediately
comprehensible while feeling like Omarchy completed its own hidden LIFE idea.

The source lineage is documented separately in [Inspirations](inspirations.md).
Those references are bounded inputs, not a feature checklist.

## Native interaction

The clock must remain a clock.

1. Clicking the bar clock opens Calendar.
2. Double-clicking the year rail configures the exact local birth date and
   optional week horizon.
3. The resulting LIFE rail is the entrance to Memento Mori.
4. `H/J/K/L` retain the inherited Calendar navigation grammar. Pressing `M`
   for Memento Mori toggles the anchored panel between Calendar and the finite
   timeline. Clicking LIFE enters through the same path; the visible back
   action is the direct pointer return.
5. A visible back action returns to Calendar; Escape closes the panel.

The LIFE rail is shared across Calendar and Memento Mori. It always remains
week-based, including while Months is selected, so the horizon's progress
never changes merely because its projection changed. The adjacent lived and
remaining counts do translate into the active resolution.

## V1 visual grammar

V1 uses uniform sequencing. It does not insert four-week month gaps or a 4-4-5
cadence: a birth-date-anchored timeline cannot truthfully promise those visual
groups are calendar months. A single unit legend names each horizontal scale;
the tick labels carry only their number so the axis reads as one sentence
rather than twelve repeated abbreviations.

- Weeks uses 52 columns per visual life-year, with an `M` scale and twelve
  proportional life-month ticks. Exact calendar intervals remain in the
  readout rather than being implied by gaps.
- Months uses 12 exact calendar intervals per life-year across the same
  horizontal span. Stronger third-month ticks and breathing room after months
  3, 6, and 9 disclose quarters without reducing the axis to `Q1–Q4`.
- Lived cells are softly filled, the present is the only accent, and future
  cells are quietly outlined.
- Weeks and Months are the only grid resolutions. Years remains legible as
  sparse ticks on the LIFE rail instead of becoming a third grid mode.
- Clicking the tiny `M →` cue toggles resolution in place. Keyboard shortcuts
  use `P` for the same reversible projection action without a permanent mode
  bar.

## Attention window

The panel allocates a fixed grid-height budget, then derives how many complete
life-year rows fit under the active theme and scale. The present is placed
within that capacity rather than hard-coding a row count. Projection changes
preserve the temporal starting point.

Tiny `M →` and `Y ↓` cues disclose the horizontal and vertical dimensions.
Hovering anywhere along either axis accents its corresponding scale; only the
tiny `M →` cue is an action. The first, present, and last visible ages appear
alongside every five-year landmark. Wheel and keyboard navigation slide the
window one life-year at a time, and returning to now restores the default.

Calendar defines the stable panel dimensions. LIFE uses the same panel frame
with a deliberately wider temporal field: Weeks and Months share one grid
envelope and vertical row stride, and the LIFE rail track aligns exactly with
that envelope. Entering LIFE or changing resolution therefore moves neither
the widget nor the temporal frame. The rail supplies global horizon context
while the grid remains a movable 31-life-year local view.

## Progress grammar

The LIFE rail and grid use the same temporal language: muted lived time, a
thin accent at the exact present boundary, and a recessed future.

Projection-aware lived and remaining counts sit beneath their corresponding
rail segments, using the rail itself as their span rather than adding a second
bracket. Quiet decade labels, shorter five-year ticks, and barely-there annual
ticks carry scale without becoming a second grid. The present marker also
names its current life year.

The centered readout above the grid is the single source of calendar
precision; no pointer-following tooltip repeats it. Only the exact
birth-anchored interval remains there (`20–26 AUG 2026`). The inspected
`W 5` / `M 1` coordinate and age sit directly on the horizontal and vertical
axes. Past, present, and future are not repeated in text because the cells and
legend already encode that state.

Visible gaps remain truthful negative space, but are not dead interaction
zones. Midpoint ownership assigns every point in a channel to its nearest
cell, so crossing a semantic gap advances inspection continuously instead of
pausing or flashing back to present. Hover receives a crisp outline distinct
from the filled present cell; V1 does not imply click or persistent selection.

Opening LIFE begins from present even when the popup appears beneath a parked
pointer. T or Space restores that same keyboard-owned present state. Hover
takes ownership only after deliberate pointer movement, so a stationary mouse
cannot immediately undo a reset or make reopening start from an accidental
cell.

Present retains accent ticks on both axes while hover adds foreground ticks
without replacing them. When both points share an axis coordinate, the one
accent tick remains rather than drawing competing labels in one place.
Hairline guides connect each point only upward to the horizontal axis and
leftward to the vertical axis; they never continue into later columns or
lower ages. Quiet edge arrows disclose whether earlier or later rows remain.

Scales provide orientation; hover provides precision:

- Weeks: exact week interval, age, and week-in-life-year.
- Months: exact calendar interval, age, and month-in-life-year.

## Temporal roles and held span

The interface has three temporal roles, not three competing pins:

- **Present** is the permanent origin and the only accent.
- **Inspection** is the transient pointer hover or keyboard cursor. It answers
  "what is here, and how far is it from now?" through the shared date readout,
  axes, foreground guides, and a live projection-aware delta.
- **Hold** is one deliberate, session-only pin. It answers "keep this
  relationship visible" through a quiet cell outline, a local orthogonal
  ruler whose measurements emerge when their geometry can carry them, and the
  LIFE segment between that exact date and present.

Inspection is the live temporal measure; hold is the retained spatial measure.
The full `109 WEEKS AFTER NOW` treatment remains visible while a non-present
cell is actively inspected, then leaves with the pointer or keyboard probe. A
hold may retain the quieter `109W` at its ruler endpoint when the overall span
can carry it: enough to keep a distant pin's temporal significance apparent
without forcing copy onto a nearby pin. While the held relationship itself is
inspected, that compact total fades and the full header readout owns exactness.
The pin preserves the selected point and its relationship to the common present
origin while inspection continues elsewhere.

The local ruler always leaves present horizontally, reaches the held point's
column, then turns vertically into the pin. A same-row or same-column
measurement naturally collapses to one straight segment. The hairline crosses
cells without filling, striking through, or selecting them; their existing
boundaries become implicit ruler ticks. The elbow has no marker because it is
not a third temporal point.

Present retains its accented origin tick and guides. Inspection owns a
transient coordinate tick. The hold does not claim either axis. Instead, each
roomy ruler leg carries its own magnitude and a sufficiently long ruler may
carry the full projected total at its held endpoint: `8W`, `2Y`, and `112W`.
A zero-length component disappears. Row wrap remains truthful, so a ruler may
travel right `9M`, rise `2Y`, and terminate at `15M`. Its route from accented
present to neutral pin communicates direction; signs and BEFORE/AFTER prose
would repeat what the geometry already says.

Exact present/inspection coordinates merge. When their text would collide,
the present label stays nearest its axis while only the inspection label moves
to a second lane with a short leader back to its exact tick. The held ruler is
therefore free of axis-label collisions. Its neutral outline, engraved values,
and line strengthen together only while the held point, either ruler leg, or
the LIFE span is inspected.

Labels earn their space from rendered geometry. Both component values interrupt
the center of their own hairline with a small background knockout; the vertical
value remains horizontally readable rather than rotating with its leg. Each
emerges through a short transition band only when that leg can contain it. A
nearby ruler remains silent instead of falling back to the axes, because its
distance is already directly legible in cells. The endpoint total likewise
requires enough overall length and side room, and yields to the full header
readout while the held relationship is actively inspected. A horizontal-only
ruler shows its total once on the line rather than duplicating component and
endpoint copy. Retargeting and dragging let these measurements emerge or recede
with the ruler; reduced motion resolves directly to the same ownership state.

Pin creation draws the horizontal leg before the vertical leg at a bounded,
distance-aware speed, then settles into quiet geometry. Retargeting reshapes
the existing ruler in `180ms` instead of collapsing it back to present. The
LIFE rail simultaneously carries the same relationship at whole-horizon scale;
it remains the fallback when either local endpoint is outside the attention
viewport. Hovering the held cell, local ruler, or rail span recalls the full
delta through the ordinary inspection grammar.

The held endpoint is also the ruler's pointer handle. Dragging it beyond a
deliberate movement threshold snaps the exact date between cells, reshapes both
rulers, and updates the live delta. Release commits, Escape restores the
original date, and dropping onto present clears the measurement. The pin cell
uses an open-hand cursor at rest and a closed hand while moving; no separate
drag handle or persistent instruction is added.

Horizontal keyboard traversal preserves one interval per deliberate press.
During key repeat, its cadence is scaled by the full rendered cell stride, so
Weeks and Months traverse at the same target visual speed despite their
different column widths. Vertical movement remains one exact life-year row in
either projection.

One exact date may be held at a time. Retargeting replaces it, leaving LIFE
clears it, and projection changes map it into the containing week or month
without changing its identity. Multiple pins, labels, chapters, annotations,
or persistence would constitute a personal-history product and remain outside
this plugin.

## V2 motion grammar

Projection changes use a calm left-to-right resolution seam by default. It
finishes in `360ms`, never overlays the two settled grids, and preserves the
panel, viewport, axes, row stride, and present anchor. The pinned lived and
remaining readouts resolve through simultaneous local shimmers constrained to
their text envelopes, rather than one tracer crossing the empty rail. The
lived readout owns the active unit; remaining stays unitless before, during,
and after the transition so its envelope never expands temporarily.

An exact date-overlap interference lens is retained as a session-only motion
alternative. Pressing `A`, or triple-clicking an otherwise inert part of the
grid, alternates the motion style without creating a third projection or a
visible setting. `P` toggles Weeks and Months as one reversible projection
action. The lens splits intervals only at their real shared dates, holds their
interference at a stable midpoint, and resolves in `520ms`. It is never
persisted; the calm seam remains the startup default.

In both styles, the active coordinate is one synchronized atom. Present,
inspection, and the held endpoint each derive their displayed cell, axis
ticks, guides, and local ruler from the same interpolation progress. This
prevents guides from arriving before the point they locate. It is a foundation
for the projection transition, not the final aesthetic treatment of the whole
grid seam.

## Implementation boundary

- [Keyboard and interaction manual](keyboard.md) is the source of truth for
  active bindings, inherited Omarchy routing, and future shortcut allocation.
- `horizonWeeks = 4000` is the default and core model.
- Exact birth date and horizon override are local widget settings.
- One structural `Canvas` renders the dense grid and a separate lightweight
  interaction `Canvas` renders hover, focus, pins, axes, guides, rulers, and
  labels. Pointer and keyboard inspection must not repaint the dense field.
  Date, projection, and hit-test math remains outside QML object trees where
  practical.
- The fixed Canvas paints only the absolute rows in the current attention
  window; scrolling changes that window without resizing the panel.
- Motion must preserve stable geometry and respect reduced-motion settings.
- Row-group spacing must be derived from truthful age structure. Fixed gaps in
  Weeks must not imply calendar-month boundaries that the birth-anchored model
  does not contain.

## Non-goals

No chapters, milestones, goals, habits, streaks, tasks, journaling, quotes,
coaching, loved-one counters, or motivational notifications.

Future experiments belong in [Roadmap](roadmap.md) until their meaning and
cost are clear enough to graduate into this design contract.
