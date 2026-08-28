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

Urban's writable calendar also suggests life chapters, turning points, and
future goals. Those are evidence that personal landmarks can be meaningful,
not a requirement that this compact widget store them. Memento Mori keeps one
temporary held date for comparison; a collection of named landmarks would be
a different product.

The article's slightly stronger separation between five-year row groups is a
useful contextual-spacing specimen. It groups truthful age intervals rather
than pretending birth-anchored weeks align into fixed calendar months. The
active specimen treats negative space as temporal structure: five-year life
bands vertically, twelve proportional 4/5-week life-month phrases in Weeks,
and four exact quarters in Months. Its channel weights are intentionally
proportioned to the cells they separate rather than copied from one existing
gap. The unchanged grid remains the control.

### Tim Urban — “The Tail End”

[The Tail End](https://waitbutwhy.com/2015/12/the-tail-end.html) changes the
unit of reflection from elapsed time to remaining experiences and time with
particular people. Its lesson is that a life fraction and a relationship's
remaining fraction can differ dramatically.

That is a conceptual extension, not a pin feature. Supporting visits, seasons,
books, relationships, or other estimated units would require personal inputs
and assumptions that belong in a separately justified plugin or lens.

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

### Interaction research

Ben Shneiderman's [visual information-seeking
mantra](https://drum.lib.umd.edu/items/cd983adb-568a-47d3-b43a-1d8d8b8c72f4/full)
and Heer and Shneiderman's [interaction
taxonomy](https://idl.uw.edu/papers/interactive-dynamics) distinguish stable
overview and selection from details requested during inspection. That
distinction informs the temporal grammar: present is the origin, hover or the
keyboard cursor is a live measure from now, and one clicked date is a held
spatial relationship. The full numerical sentence belongs to transient
inspection; persistent selection retains geometry without freezing that detail
into dashboard text.

Research on [personal temporal
landmarks](https://cutrell.org/papers/SISLandmarks_Interact2003.pdf) shows that
meaningful events can improve orientation and recall. It also reinforces the
boundary: once marks need names, memory, search, or persistence, the design has
crossed from a finite-time reminder into a personal-history system.

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
The Tail End         -> alternative temporal units
Bryan Braun         -> projection precedent
In Weeks            -> low-noise inspection
Interaction research-> overview, probe, and held selection
Omarchy clock       -> native interaction and implementation
```

## Anti-specimens

Contemporary memento-mori products commonly add journals, goals, habits,
streaks, quotes, AI coaching, motivational notifications, loved-one counters,
or generic productivity systems. Their presence elsewhere is not evidence
that they belong here. A future experiment must independently earn any new
concept before it enters the stable design.

Multiple pins are subject to the same boundary. Without names they are
ambiguous decoration; with names they quickly require editing, collision
handling, navigation, deletion, and persistence. If that system ever earns a
purpose, it should be designed as its own plugin rather than accumulated here.
