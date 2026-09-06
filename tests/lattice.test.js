const test = require("node:test")
const assert = require("node:assert/strict")
const Lattice = require("../Lattice.js")

const Y = Lattice.DAYS_PER_YEAR
const LIFE_DAYS = 28000
const EXTRA = Object.assign({}, Lattice.UNITS, {
  lustrum: { days: 5 * Y, kind: "calendar", plural: "lustra" },
  book: Lattice.ratePerYear("book", 20)
})

test("every unit is a length in days and a name, independently", () => {
  // Geometry comes from the length; meaning does not come from it at all.
  assert.equal(Lattice.lengthInDays("summer"), Lattice.lengthInDays("year"))
  assert.equal(Lattice.lengthInDays("season"), Lattice.lengthInDays("quarter"))
  assert.notEqual(Lattice.unit("summer").plural, Lattice.unit("year").plural)
  assert.equal(Lattice.lengthInDays("nonsense"), 0)
})

test("one life, counted at every rung, is the same life", () => {
  const counts = {}
  for (const name of ["minute", "hour", "day", "week", "month", "year"])
    counts[name] = Lattice.countIn(LIFE_DAYS, Lattice.lengthInDays(name))
  assert.equal(Math.round(counts.week), 4000)
  assert.equal(Math.round(counts.day), 28000)
  assert.equal(Math.round(counts.hour), 672000)
  assert.equal(Math.round(counts.year), 77)
  assert.equal(Math.round(counts.month), 920)
  // Each rung is the one below it re-expressed, not a different quantity.
  for (const name of ["minute", "hour", "day", "week", "month"])
    assert.ok(Math.abs(
      counts[name] * Lattice.lengthInDays(name) - LIFE_DAYS) < 1e-6)
})

test("a tick tiles a fold exactly when the fold was defined from it", () => {
  const d = Lattice.lengthInDays
  // Defined against the year, so they tile it.
  for (const name of ["month", "quarter", "season", "year"])
    assert.ok(Lattice.tiles(d("year"), d(name)), `${name} should tile a year`)
  assert.ok(Lattice.tiles(Y, Lattice.ratePerYear("book", 20).days))
  // A clock unit runs free of the solar year, so it does not.
  assert.ok(!Lattice.tiles(d("year"), d("week")))
  assert.ok(!Lattice.tiles(d("year"), d("fortnight")))
  assert.ok(!Lattice.tiles(d("month"), d("day")))
  // Clock units do tile each other.
  assert.ok(Lattice.tiles(d("day"), d("hour")))
  assert.ok(Lattice.tiles(d("fortnight"), d("day")))
})

test("the leftover is the fact that makes a birthday move weekday", () => {
  const left = Lattice.remainderDays(Y, 7)
  assert.ok(Math.abs(left - 1.2425) < 1e-6, `left ${left} days over`)
  assert.equal(Lattice.remainderDays(Y, Lattice.lengthInDays("month")), 0)
  assert.equal(Lattice.remainderDays(Lattice.lengthInDays("day"), 1 / 24), 0)
})

test("the ladder is ordered by how much time a tick holds", () => {
  const ladder = Lattice.rungs({ units: EXTRA, gridWidth: 437, minTickPixels: 3 })
  assert.ok(ladder.length > 0)
  for (let i = 1; i < ladder.length; i++)
    assert.ok(ladder[i].tickDays >= ladder[i - 1].tickDays)
  // Every rung must be drawable at the width it was given.
  for (const rung of ladder) assert.ok(437 / rung.ticksPerFold >= 3)
})

test("the grid we already have is one entry in the enumeration", () => {
  // Not asserted into existence — it falls out of the ratio bounds, which is
  // the claim: the current design is a rung rather than a special case.
  const found = Lattice.nestings({ units: EXTRA })
  const current = found.find((n) => n.cell === "week" && n.group === "quarter"
    && n.fold === "year" && n.rowGroup === "lustrum")
  assert.ok(current, "week / quarter / year / lustrum should be enumerable")
  assert.equal(Math.round(current.ticksPerFold), 52)
  assert.deepEqual(current.ratios.map((r) => Math.round(r * 10) / 10),
    [13, 4, 5])

  // And the Months projection is the same frame with the cell moved up one.
  const months = found.find((n) => n.cell === "month" && n.group === "quarter"
    && n.fold === "year" && n.rowGroup === "lustrum")
  assert.ok(months, "the two projections should share a frame")
  assert.equal(Math.round(months.ticksPerFold), 12)
})

test("a rate unit slots between them without disturbing the frame", () => {
  // Books at twenty a year: five to a quarter, twenty to a year, a hundred to
  // a lustrum. All whole, because a rate unit tiles by construction — so it
  // can be a cell today without re-deriving anything above it.
  const book = Lattice.ratePerYear("book", 20).days
  assert.ok(Lattice.tiles(Lattice.lengthInDays("quarter"), book))
  assert.ok(Lattice.tiles(Lattice.lengthInDays("year"), book))
  assert.ok(Lattice.tiles(5 * Y, book))
  assert.equal(Math.round(Lattice.countIn(Y, book)), 20)
  assert.equal(Math.round(Lattice.countIn(LIFE_DAYS, book)), 1533)
})

test("nesting ratios stay legible in both directions", () => {
  for (const n of Lattice.nestings({ units: EXTRA }))
    for (const ratio of n.ratios) {
      assert.ok(ratio >= 3, "a grouping of two is not a grouping")
      assert.ok(ratio <= 14, "fifty of a thing cannot be seen as one")
    }
})
