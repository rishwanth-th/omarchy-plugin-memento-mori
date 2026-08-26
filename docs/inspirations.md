# Inspirations and specimens

Memento Mori is not an average of every life-calendar product. Each reference
below contributes one bounded idea; omissions are as intentional as additions.

## Conceptual lineage

### Oliver Burkeman — *Four Thousand Weeks*

[Four Thousand Weeks](https://www.oliverburkeman.com/books) supplies the
finite-horizon principle: an ordinary human life is usefully imaginable as
roughly 4,000 weeks. The plugin keeps `horizonWeeks = 4000` as its core model
instead of treating `76.7 years` as the concept.

It does **not** turn finitude into a demand to optimize every remaining cell.

### Tim Urban — “Your Life in Weeks”

[Your Life in Weeks](https://waitbutwhy.com/2014/05/life-weeks.html) supplies
the visual grammar: one cell per week, 52 cells forming a life-year, and a
finite lifespan becoming graspable as a field of small marks.

The plugin adapts that whole-life idea to a compact desktop widget rather than
reproducing the article or its poster.

## Interaction and visual specimens

### Bryan Braun — “Your Life”

Bryan Braun's interactive [Weeks](https://www.bryanbraun.com/your-life/weeks),
[Months](https://www.bryanbraun.com/your-life/months), and
[Years](https://www.bryanbraun.com/your-life/years) views establish a useful
projection precedent. V1 keeps Weeks and Months, but moves Years to the LIFE
rail because a third grid mode did not earn its visual cost.

### In Weeks

[In Weeks](https://inweeks.org/) demonstrates a modern, low-noise treatment,
responsive density, and precise inspection of lived, present, and future
intervals. Its immediate legibility is the important specimen—not its full
page layout.

### 4000 Weeks browser extension

The [4000 Weeks extension](https://chromewebstore.google.com/detail/4000-weeks/nmbibaeninkpbgediblebkapmeobmekk)
is a restraint specimen: the idea remains effective with almost no surrounding
product machinery.

## Implementation parent

The native [`omarchy.clock`](https://github.com/basecamp/omarchy/tree/quattro/shell/plugins/panels/clock)
is the interaction and implementation parent. Memento Mori preserves its bar
label, calendar, navigation, timezone action, format cycling, dimensions, and
theme vocabulary, then extends only the existing LIFE path.

This parentage is why the result is a clock replacement rather than a new
calendar application.

## Lineage at a glance

```text
Four Thousand Weeks -> finite horizon
Tim Urban           -> visual grammar
Bryan Braun         -> projection precedent
In Weeks            -> low-noise inspection
Omarchy clock       -> native interaction and implementation
```

## Anti-specimens

Contemporary memento-mori products commonly add journals, goals, habits,
streaks, quotes, AI coaching, motivational notifications, loved-one counters,
or generic productivity systems. Their presence elsewhere is not evidence
that they belong here. A future experiment must independently earn any new
concept before it enters the stable design.
