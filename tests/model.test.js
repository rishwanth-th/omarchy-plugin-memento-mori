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
    date: "20–26 AUG 2026",
    dateRange: "20–26",
    dateMonth: "AUG",
    dateYear: "2026",
    position: "WEEK 5",
    age: "AGE 25",
    status: "PRESENT"
  })

  assert.deepEqual(Model.projectionReadoutParts({
    index: 5,
    startKey: "2026-08-27",
    endKey: "2026-09-02",
    status: "future"
  }, "weeks", today), {
    date: "27 AUG–2 SEP 2026",
    dateRange: "27–SEP 2",
    dateMonth: "AUG",
    dateYear: "2026",
    position: "WEEK 6",
    age: "AGE 0",
    status: "FUTURE"
  })

  assert.deepEqual(Model.projectionReadoutParts({
    index: 51,
    startKey: "2026-12-28",
    endKey: "2027-01-03",
    status: "future"
  }, "weeks", today), {
    date: "28 DEC 2026–3 JAN 2027",
    dateRange: "28–2027 JAN 3",
    dateMonth: "DEC",
    dateYear: "2026",
    position: "WEEK 52",
    age: "AGE 0",
    status: "FUTURE"
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

test("one exact temporal pin maps across projections without drifting", () => {
  const today = localDate(2026, 8, 26)
  const birth = "2001-08-23"
  const weeks = Model.projectionCells("weeks", birth, today, 4000)
  const months = Model.projectionCells("months", birth, today, 4000)
  const pinKey = "2026-08-20"
  const weekIndex = Model.projectionIndexForDate(weeks, pinKey)
  const monthIndex = Model.projectionIndexForDate(months, pinKey)

  assert.equal(weeks[weekIndex].startKey, "2026-08-20")
  assert.equal(months[monthIndex].startKey, "2026-07-23")
  assert.equal(months[monthIndex].endKey, "2026-08-22")
  assert.equal(Model.projectionIndexForDate(weeks, pinKey), weekIndex)
  assert.equal(Model.projectionIndexForDate(months, "not-a-date"), -1)
  assert.equal(Model.projectionIndexForDate(months, "2200-01-01"), -1)
})

test("live temporal inspection stays symmetric and follows the active projection", () => {
  const today = localDate(2026, 8, 28)
  const birth = "2001-08-23"
  const weeks = Model.projectionCells("weeks", birth, today, 4000)
  const months = Model.projectionCells("months", birth, today, 4000)

  assert.deepEqual(Model.projectionDelta(weeks, "weeks", "2028-09-28"), {
    configured: true,
    count: 109,
    direction: "AFTER NOW",
    unit: "WEEKS",
    label: "109 WEEKS AFTER NOW"
  })
  assert.deepEqual(Model.projectionDelta(weeks, "weeks", "2024-08-22"), {
    configured: true,
    count: 105,
    direction: "BEFORE NOW",
    unit: "WEEKS",
    label: "105 WEEKS BEFORE NOW"
  })
  assert.deepEqual(Model.projectionDelta(months, "months", "2028-09-28"), {
    configured: true,
    count: 25,
    direction: "AFTER NOW",
    unit: "MONTHS",
    label: "25 MONTHS AFTER NOW"
  })
  assert.deepEqual(Model.projectionDelta(months, "months", "2026-08-28"), {
    configured: false,
    count: 0,
    direction: "",
    unit: "",
    label: ""
  })
})

test("an exact temporal pin uses the canonical week-based LIFE rail", () => {
  const birth = "2001-08-23"

  assert.equal(Model.lifeProgressForDate(birth, "2026-08-20", 4000), 1304 / 4000)
  assert.equal(Model.lifeProgressForDate(birth, birth, 4000), 0)
  assert.equal(Model.lifeProgressForDate(birth, "2200-01-01", 4000), 1)
  assert.equal(Model.lifeProgressForDate(birth, "not-a-date", 4000), -1)
})

test("projection overlap fragments preserve exact week and month boundaries", () => {
  const today = localDate(2000, 2, 1)
  const weeks = Model.projectionCells("weeks", "2000-01-31", today, 4000)
  const months = Model.projectionCells("months", "2000-01-31", today, 4000)
  const segments = Model.projectionOverlapSegments(weeks, months, 4, 5, 0, 2)

  assert.equal(weeks[4].startKey, "2000-02-28")
  assert.equal(weeks[4].endKey, "2000-03-05")
  assert.equal(months[0].endKey, "2000-02-28")
  assert.equal(months[1].startKey, "2000-02-29")
  assert.equal(segments.length, 2)
  assert.deepEqual(segments.map(segment => [segment.sourceIndex, segment.targetIndex]), [
    [4, 0],
    [4, 1]
  ])
  assert.equal(segments[0].sourceStart, 0)
  assert.equal(segments[0].sourceEnd, 1 / 7)
  assert.equal(segments[0].targetStart, 28 / 29)
  assert.equal(segments[0].targetEnd, 1)
  assert.equal(segments[1].sourceStart, 1 / 7)
  assert.equal(segments[1].sourceEnd, 1)
  assert.equal(segments[1].targetStart, 0)
  assert.equal(segments[1].targetEnd, 6 / 31)

  const reverse = Model.projectionOverlapSegments(months, weeks, 0, 2, 4, 5)
  assert.equal(reverse.length, 2)
  assert.deepEqual(reverse.map(segment => [segment.sourceIndex, segment.targetIndex]), [
    [0, 4],
    [1, 4]
  ])
  assert.deepEqual(Model.projectionOverlapSegments(weeks, months, 0, 0, 0, 0), [])
})

test("the temporal viewport favors the future and clamps at both ends", () => {
  assert.equal(Model.temporalViewportStart(25, 77, 5), 23)
  assert.equal(Model.temporalViewportStart(30, 77, 24), 21)
  assert.equal(Model.temporalViewportStart(2, 77, 24), 0)
  assert.equal(Model.temporalViewportStart(76, 77, 24), 53)
  assert.equal(Model.temporalViewportStart(3, 8, 24), 0)
})
