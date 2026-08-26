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

V1 uses uniform cells. It does not insert four-week month gaps or a 4-4-5
cadence: a birth-date-anchored timeline cannot truthfully promise those visual
groups are calendar months.

- Weeks: 52 columns per visual life-year, with twelve proportional life-month
  ticks across the horizontal axis and age landmarks every five rows. Exact
  calendar intervals remain in the readout rather than being implied by gaps.
- Months: 12 exact calendar intervals per life-year, with quarter landmarks
  across the horizontal axis.
- Years: 10 columns per decade, with year-in-decade ticks horizontally and
  decades on the vertical axis.
- Lived cells are softly filled.
- The current cell is the only accent.
- Future cells are quietly outlined.
- Weeks and Months open as a bounded temporal viewport around now. The
  current life-year sits slightly above center so the panel retains history
  for orientation while showing more of the finite future.
- The absolute age axis remains visible while the viewport moves. Wheel and
  keyboard navigation explore earlier or later rows; returning to now restores
  the default framing.
- Years remains the compact whole-horizon overview.
- A quiet expand action reveals the complete configured horizon in the same
  anchored surface. It is a contemplative view, not the panel default.
- All compact projections inhabit one fixed panel and Canvas frame. Collapsed
  Months and Years grids are centered within it, so projection changes do not
  move the surrounding interface.
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
