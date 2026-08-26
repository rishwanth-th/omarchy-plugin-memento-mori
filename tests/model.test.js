const test = require("node:test")
const assert = require("node:assert/strict")
const Model = require("../Model.js")

function localDate(year, month, day) {
  return new Date(year, month - 1, day, 12, 0, 0, 0)
}

test("the default horizon is 4,000 weeks and invalid overrides fall back", () => {
  assert.equal(Model.parseHorizonWeeks(undefined), 4000)
  assert.equal(Model.parseHorizonWeeks("4000"), 4000)
  assert.equal(Model.parseHorizonWeeks("5200"), 5200)
  assert.equal(Model.parseHorizonWeeks("51"), 4000)
  assert.equal(Model.parseHorizonWeeks("forever"), 4000)
})

test("birth dates are exact, local, and bounded", () => {
  const today = localDate(2026, 8, 26)
  assert.equal(Model.parseBirthDate("2000-02-29", today), "2000-02-29")
  assert.equal(Model.parseBirthDate("2001-02-29", today), "")
  assert.equal(Model.parseBirthDate("2027-01-01", today), "")
})

test("life progress remains week-based", () => {
  const stats = Model.lifeStats("2000-01-01", localDate(2026, 8, 26), 4000)
  assert.deepEqual(stats, {
    configured: true,
    horizonWeeks: 4000,
    livedWeeks: 1390,
    remainingWeeks: 2610,
    currentWeek: 1390,
    progress: 0.3475,
    percent: 34.8
  })
})

test("month arithmetic stays anchored to the original day", () => {
  const january31 = localDate(2000, 1, 31)
  assert.equal(Model.keyForDate(Model.addCalendarMonths(january31, 1)), "2000-02-29")
  assert.equal(Model.keyForDate(Model.addCalendarMonths(january31, 2)), "2000-03-31")
})

test("all projections terminate at the same 4,000-week horizon", () => {
  const today = localDate(2026, 8, 26)
  const weeks = Model.projectionCells("weeks", "2000-01-01", today, 4000)
  const months = Model.projectionCells("months", "2000-01-01", today, 4000)
  const years = Model.projectionCells("years", "2000-01-01", today, 4000)

  assert.equal(weeks.length, 4000)
  assert.equal(months.length, 920)
  assert.equal(years.length, 77)
  assert.equal(weeks.at(-1).endKey, "2076-08-28")
  assert.equal(months.at(-1).endKey, "2076-08-28")
  assert.equal(years.at(-1).endKey, "2076-08-28")
})

test("hover labels name the selected projection and exact interval", () => {
  const today = localDate(2000, 1, 3)
  const week = Model.projectionCells("weeks", "2000-01-01", today, 4000)[0]
  const month = Model.projectionCells("months", "2000-01-01", today, 4000)[0]
  const year = Model.projectionCells("years", "2000-01-01", today, 4000)[0]

  assert.equal(week.primary, "Year 1 · Week 1")
  assert.equal(week.secondary, "1–7 Jan 2000 · current")
  assert.equal(month.primary, "Year 1 · Month 1")
  assert.equal(year.primary, "Year 1")
})

test("grid readouts split exact time from life-relative context", () => {
  const today = localDate(2026, 8, 26)
  const currentWeek = Model.projectionCells("weeks", "2001-08-23", today, 4000)
    .find(cell => cell.status === "current")
  const futureMonth = Model.projectionCells("months", "2001-08-23", today, 4000)
    .find(cell => cell.startKey.startsWith("2035-"))

  assert.match(Model.projectionReadout(currentWeek, "weeks", today),
    /^20–26 AUG 2026 · WEEK 5 · AGE 25 · PRESENT$/)
  assert.doesNotMatch(Model.projectionReadout(currentWeek, "weeks", today), /YEAR/)
  assert.match(Model.projectionReadout(futureMonth, "months", today),
    /^.+ 2035 · MONTH \d+ · AGE 33 · FUTURE$/)

  assert.deepEqual(Model.projectionReadoutParts(currentWeek, "weeks", today), {
    interval: "20–26 AUG 2026 · WEEK 5",
    context: "AGE 25 · PRESENT"
  })
})

test("finite-time counts follow the active projection", () => {
  const today = localDate(2026, 8, 26)
  const weeks = Model.projectionCells("weeks", "2001-08-23", today, 4000)
  const months = Model.projectionCells("months", "2001-08-23", today, 4000)

  assert.deepEqual(Model.projectionStats(weeks, "weeks"), {
    lived: 1304,
    remaining: 2696,
    unit: "weeks"
  })
  assert.deepEqual(Model.projectionStats(months, "months"), {
    lived: 300,
    remaining: 620,
    unit: "months"
  })
})

test("the temporal viewport favors the future and clamps at both ends", () => {
  assert.equal(Model.temporalViewportStart(25, 77, 5), 23)
  assert.equal(Model.temporalViewportStart(30, 77, 24), 21)
  assert.equal(Model.temporalViewportStart(2, 77, 24), 0)
  assert.equal(Model.temporalViewportStart(76, 77, 24), 53)
  assert.equal(Model.temporalViewportStart(3, 8, 24), 0)
})
