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

Calendar defines the panel dimensions. Weeks and Months share its exact frame,
Canvas budget, grid envelope, and vertical row stride, so entering LIFE or
changing resolution moves neither the widget nor the grid. The rail supplies
global horizon context while the grid remains a movable local view.

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

Crossing the tiny gaps between cells preserves the last hovered interval,
avoiding a flash back to the present. Hover receives a crisp outline distinct
from the filled present cell; V1 does not imply click or persistent selection.

Present retains accent ticks on both axes while hover adds foreground ticks
without replacing them. When both points share an axis coordinate, the one
accent tick remains rather than drawing competing labels in one place.
Hairline guides connect each point only upward to the horizontal axis and
leftward to the vertical axis; they never continue into later columns or
lower ages. Quiet edge arrows disclose whether earlier or later rows remain.

Scales provide orientation; hover provides precision:

- Weeks: exact week interval, age, and week-in-life-year.
- Months: exact calendar interval, age, and month-in-life-year.

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

## Implementation boundary

- `horizonWeeks = 4000` is the default and core model.
- Exact birth date and horizon override are local widget settings.
- One `Canvas` renders the dense grid; date, projection, and hit-test math
  remains outside QML object trees where practical.
- The fixed Canvas paints only the absolute rows in the current attention
  window; scrolling changes that window without resizing the panel.
- Motion must preserve stable geometry and respect reduced-motion settings.

## Non-goals

No chapters, milestones, goals, habits, streaks, tasks, journaling, quotes,
coaching, loved-one counters, or motivational notifications.

Future experiments belong in [Roadmap](roadmap.md) until their meaning and
cost are clear enough to graduate into this design contract.
