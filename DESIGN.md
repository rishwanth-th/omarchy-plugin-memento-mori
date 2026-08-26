# Design philosophy

## Intent

The plugin is a finite-time reminder, not a productivity product. Its job is
to make a chosen lifetime horizon visible, countable, and immediately
comprehensible while feeling like Omarchy completed its own hidden LIFE idea.

The reference lineage is intentionally bounded:

- Oliver Burkeman provides the 4,000-week finite-horizon principle.
- Tim Urban provides the whole-life grid and one-week visual unit.
- Bryan Braun provides the Weeks, Months, and Years projection precedent.
- In Weeks provides the modern low-noise treatment and precise hover reading.
- `omarchy.clock` is the implementation and interaction parent.

## Native interaction

The clock must remain a clock.

1. Clicking the bar clock opens Calendar.
2. Double-clicking the year rail configures the exact local birth date and
   optional week horizon.
3. The resulting LIFE rail is the entrance to Memento Mori.
4. Clicking LIFE switches the same anchored panel to the finite timeline.
5. A visible back action returns to Calendar; Escape closes the panel.

The LIFE rail is one shared component across Calendar and Memento Mori. It
always remains week-based, including while Months or Years is selected, so
the horizon's progress never changes merely because its projection changed.

## V1 visual grammar

V1 uses uniform sequencing. It does not insert four-week month gaps or a 4-4-5
cadence: a birth-date-anchored timeline cannot truthfully promise those visual
groups are calendar months. A single unit legend names each horizontal scale;
the tick labels carry only their number so the axis reads as one sentence
rather than twelve repeated abbreviations.

- Weeks: 52 columns per visual life-year, with an `M` scale and twelve
  proportional life-month ticks across the horizontal axis. Exact calendar
  intervals remain in the readout rather than being implied by gaps.
- Months: 12 exact calendar intervals per life-year expand across the same
  horizontal span. The `M 1–12` scale keeps month precision while stronger
  third-month ticks and breathing room after months 3, 6, and 9 disclose the
  four quarters without reducing the axis to only `Q1–Q4`.
- Years: 10 columns per decade, with year-in-decade ticks horizontally and
  decades on the vertical axis.
- Lived cells are softly filled.
- The current cell is the only accent.
- Future cells are quietly outlined.
- Compact mode is one shared five-life-year attention window: two life-years
  before the current one, the current life-year, and two after. Weeks and
  Months render those five years as rows; Years renders the same interval as
  five centered year cells. Projection changes preserve the interval.
- The absolute age axis remains visible while the viewport moves. Wheel and
  keyboard navigation slide the attention window one life-year at a time;
  returning to now restores the default framing. `AGE` is written once as a
  quiet vertical legend rather than being repeated beside every tick.
- The LIFE rail uses the same temporal grammar as the grid: muted lived time,
  a thin accent marker at the exact present boundary, and a recessed future.
- A quiet zoom-out action reveals the complete configured horizon for every
  projection in the same anchored surface. It is a contemplative overview,
  not the panel default.
- Calendar defines the compact clock frame. All compact projections inhabit
  that same panel and a fixed Canvas frame, with their content centered inside
  it, so entering LIFE or changing projection does not move the surrounding
  interface. Expanded mode likewise uses one full-height frame across Weeks,
  Months, and Years.
- The stable readout above the grid is the single source of hover precision;
  no second pointer-following tooltip repeats it.
- A faint current-row attention band and quiet edge arrows communicate the
  viewport's default focus and whether earlier or later rows remain.

Scales provide orientation. Hover provides precision:

- Weeks: `Year N · Week M`, exact week interval, status.
- Months: `Year N · Month M`, exact calendar interval, status.
- Years: `Year N`, exact birthday-to-birthday interval, status.

## Implementation boundary

- `horizonWeeks = 4000` is the default and core model.
- Exact birth date and horizon override are local widget settings.
- One `Canvas` renders the dense grid; date, projection, and hit-test math
  remains outside QML object trees where practical.
- Compact and expanded modes share that Canvas and exact cell collection;
  changing modes only changes which absolute rows are painted.
- V1 may crossfade or reflow between projections, but does not require a
  literal cell-merging animation.

V2 may experiment with grouped spacing and a true collapse/morph if it makes
the temporal containment more intuitive without introducing false month
semantics or destabilizing the long-lived Omarchy shell.

## Non-goals

No chapters, milestones, goals, habits, streaks, tasks, journaling, quotes,
coaching, loved-one counters, or motivational notifications.
