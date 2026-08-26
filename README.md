# Memento Mori Clock for Omarchy

An Omarchy clock/calendar plugin that completes the native `LIFE` affordance
with a quiet, local Four Thousand Weeks view.

The ordinary clock remains ordinary: click it and the familiar Omarchy
calendar opens. Configure LIFE by double-clicking the calendar's year rail,
then click the LIFE rail to enter the finite timeline.

## What it does

- preserves the native clock label, calendar, month navigation, timezone
  action, and format cycling;
- uses exactly 4,000 weeks as the default horizon;
- supports local Weeks, Months, and Years projections of the same date span;
- distinguishes lived, current, and future cells;
- resolves every hovered cell to its life-relative position and exact date
  interval;
- stores the exact birth date and optional horizon override only in local
  Omarchy shell settings.

It deliberately does not add goals, habits, streaks, journaling, quotes,
coaching, milestones, chapters, or motivational notifications.

## Install

```bash
omarchy plugin add https://github.com/rishwanth-th/omarchy-plugin-memento-mori.git --enable
```

This is a clock replacement, so a composed profile should select
`rishwanth.memento-mori` in place of `omarchy.clock`, preserving its desired
bar position and clock-format settings.

## Configure LIFE

1. Click the clock to open Calendar.
2. Double-click the year-progress rail.
3. Enter the exact birth date as `YYYY-MM-DD` and a week horizon. Leave the
   horizon at `4000` for the Four Thousand Weeks default.
4. Press Enter.
5. Click the LIFE rail to open Memento Mori.

The birth date is written to `~/.config/omarchy/shell.json` as local widget
state. Do not commit that value to a public or shared profile.

## Development

```bash
npm test
omarchy plugin validate .
```

The plugin inherits the current native clock implementation and adds:

- `LifeRail.qml` — the shared LIFE progress affordance;
- `LifeView.qml` — the three projections and Canvas interaction;
- `Model.js` — clock behavior plus exact date, horizon, and projection math.

The inherited Omarchy clock code remains under its upstream MIT copyright;
see [LICENSE](LICENSE).

See [DESIGN.md](DESIGN.md) for the product boundary and V1/V2 decisions.

## License

[MIT](LICENSE)
