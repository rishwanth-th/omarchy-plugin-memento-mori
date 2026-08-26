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

- Weeks: 52 columns per visual life-year, sparse landmarks at weeks 1, 13,
  26, 39, and 52, with age landmarks every five rows.
- Months: 12 columns per life-year, derived from exact calendar intervals.
- Years: 10 columns per decade, with decades on the vertical axis.
- Lived cells are softly filled.
- The current cell is the only accent.
- Future cells are quietly outlined.
- The complete configured horizon remains visible.

Scales provide orientation. Hover provides precision:

- Weeks: `Year N · Week M`, exact week interval, status.
- Months: `Year N · Month M`, exact calendar interval, status.
- Years: `Year N`, exact birthday-to-birthday interval, status.

## Implementation boundary

- `horizonWeeks = 4000` is the default and core model.
- Exact birth date and horizon override are local widget settings.
- One `Canvas` renders the dense grid; date, projection, and hit-test math
  remains outside QML object trees where practical.
- V1 may crossfade or reflow between projections, but does not require a
  literal cell-merging animation.

V2 may experiment with grouped spacing and a true collapse/morph if it makes
the temporal containment more intuitive without introducing false month
semantics or destabilizing the long-lived Omarchy shell.

## Non-goals

No chapters, milestones, goals, habits, streaks, tasks, journaling, quotes,
coaching, loved-one counters, or motivational notifications.
