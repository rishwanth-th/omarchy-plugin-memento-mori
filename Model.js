// Pure date and format math for the clock widget and its calendar panel.
// Everything here is locale- and Qt-free so it can be unit tested under node
// (test/shell.d/clock-test.sh); the QML owns month/weekday naming through
// Qt.locale().

var MS_PER_DAY = 86400000

// Weekday indices match both JS Date.getDay() and QML's Locale.Sunday…
// Locale.Saturday, so a locale's firstDayOfWeek can be passed straight in.
var WEEKDAY_NAMES = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]

// ---- Bar label formats. Right-clicking the clock walks these in order and
//      writes the result back to shell.json, so the label the bar shows and
//      the format the config stores are always the same thing.
//
// The locale-shaped time presets are each followed by their 12-hour twin, so
// the walk from a 24-hour label to the same label in AM/PM is a single right
// click rather than a lap of the ring. The ISO preset is deliberately left
// without one: ISO 8601 writes time on a 24-hour clock, so an AM/PM variant
// would contradict the only thing that format is for.
var CLOCK_FORMATS = [
  "dddd HH:mm",
  "dddd h:mm AP",
  "HH:mm",
  "h:mm AP",
  "ddd d MMM HH:mm",
  "ddd d MMM h:mm AP",
  "d MMMM 'W'ww yyyy",
  "yyyy-MM-dd HH:mm"
]

// Vertical bars have room for a few stacked lines and nothing else, so the
// ring stays short. AM/PM costs a fourth line, which is why only the plain
// time carries it here.
var VERTICAL_CLOCK_FORMATS = [
  "HH\n—\nmm",
  "h\n—\nmm\nAP",
  "dd\nMMM\n'W'ww\n''yy",
  "HH\nmm"
]

function clockFormats(vertical) {
  return vertical ? VERTICAL_CLOCK_FORMATS.slice() : CLOCK_FORMATS.slice()
}

// The presets in a fixed order, plus the configured alternate and current
// format when they are something else. The order must not depend on which
// entry is current: cycling writes the result back to shell.json, and a ring
// that reshuffled itself around the current value would bounce between two
// entries instead of walking.
function clockFormatRing(configured, configuredAlt, presets) {
  var ring = []
  var candidates = (presets || []).concat([configuredAlt, configured])
  for (var i = 0; i < candidates.length; i++) {
    var format = String(candidates[i] === undefined || candidates[i] === null ? "" : candidates[i])
    if (format === "" || ring.indexOf(format) !== -1) continue
    ring.push(format)
  }
  return ring.length > 0 ? ring : ["HH:mm"]
}

// Next entry after `current`. An unknown current format (a hand-written one
// that is not in the ring) starts the walk at the top.
function nextClockFormat(ring, current) {
  if (!ring || ring.length === 0) return ""
  var index = ring.indexOf(String(current === undefined || current === null ? "" : current))
  return ring[(index + 1) % ring.length]
}

// Two-digit ISO week, substituted into a format's 'ww' token before Qt
// formats it -- Qt has no ISO week specifier of its own.
function isoWeekLiteral(year, month, day) {
  return pad2(isoWeek(year, month, day))
}

function pad2(value) {
  var n = Number(value)
  return (n < 10 ? "0" : "") + n
}

// Stable "yyyy-MM-dd" identity for a day, so a grid cell can be compared
// against today without dragging Date objects through bindings.
function dateKey(year, month, day) {
  return year + "-" + pad2(Number(month) + 1) + "-" + pad2(day)
}

function keyForDate(date) {
  return dateKey(date.getFullYear(), date.getMonth(), date.getDate())
}

function coerceWeekStart(value) {
  if (value === undefined || value === null) return null
  if (typeof value === "number")
    return isFinite(value) ? ((Math.round(value) % 7) + 7) % 7 : null

  var text = String(value).replace(/^\s+|\s+$/g, "").toLowerCase()
  if (text === "") return null

  for (var i = 0; i < WEEKDAY_NAMES.length; i++)
    if (WEEKDAY_NAMES[i] === text || WEEKDAY_NAMES[i].substr(0, 3) === text) return i

  var parsed = parseInt(text, 10)
  return isFinite(parsed) ? ((parsed % 7) + 7) % 7 : null
}

// Configured week start, falling back to the locale's own first day when
// the setting is missing or nonsense.
function normalizedWeekStart(value, fallback) {
  var configured = coerceWeekStart(value)
  if (configured !== null) return configured
  var fallbackStart = coerceWeekStart(fallback)
  return fallbackStart === null ? 1 : fallbackStart
}

function weekStartSettingName(index) {
  return WEEKDAY_NAMES[normalizedWeekStart(index, 1)]
}

// The toggle flips between the two conventions people actually switch
// between. A calendar configured to any other start (Saturday, say) is
// shown as-is and lands on Monday the first time it is toggled.
function toggledWeekStart(index) {
  return normalizedWeekStart(index, 1) === 1 ? 0 : 1
}

function weekdayOrder(weekStart) {
  var start = normalizedWeekStart(weekStart, 1)
  var out = []
  for (var i = 0; i < 7; i++) out.push((start + i) % 7)
  return out
}

// ISO-8601 week number: the week owning the Thursday of that date's
// Monday-based week. Mirrors the clock widget's 'ww' format token.
function isoWeek(year, month, day) {
  var date = new Date(Date.UTC(year, month, day))
  var weekday = date.getUTCDay() || 7
  date.setUTCDate(date.getUTCDate() + 4 - weekday)
  var yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1))
  return Math.ceil(((date.getTime() - yearStart.getTime()) / MS_PER_DAY + 1) / 7)
}

function dayOfYear(year, month, day) {
  return Math.round((Date.UTC(year, month, day) - Date.UTC(year, 0, 1)) / MS_PER_DAY) + 1
}

function daysInYear(year) {
  return dayOfYear(year, 11, 31)
}

// Share of the year already behind you: whole days completed over days in
// the year, so January 1 reads 0% and December 31 reads 100%.
function yearProgress(year, month, day) {
  var total = daysInYear(year)
  if (total <= 0) return 0
  return Math.max(0, Math.min(1, (dayOfYear(year, month, day) - 1) / total))
}

function yearProgressPercent(year, month, day) {
  return Math.round(yearProgress(year, month, day) * 100)
}

// Memento mori. The default span is a round number rather than anything from
// an actuarial table: the point of the bar is the reminder, not the
// arithmetic, and whoever wants a different number can say so.
var DEFAULT_LIFE_EXPECTANCY = 90

// A birth year rather than an age, so the bar keeps counting on its own
// instead of going stale the moment it is entered. 0 means "not set", which
// is also what a blank, malformed, future, or implausibly distant year means.
function parseBirthYear(value, currentYear) {
  var now = Math.round(Number(currentYear))
  if (!isFinite(now)) return 0
  var text = String(value === undefined || value === null ? "" : value).replace(/^\s+|\s+$/g, "")
  if (!/^\d{4}$/.test(text)) return 0
  var year = parseInt(text, 10)
  if (!isFinite(year) || year > now || year < now - 120) return 0
  return year
}

// Whole years, the way people say their age: born in 1979 makes you 47 for
// all of 2026, whichever side of your birthday today falls.
function ageFromBirthYear(birthYear, currentYear) {
  var born = parseBirthYear(birthYear, currentYear)
  if (born <= 0) return 0
  return Math.round(Number(currentYear)) - born
}

// 0 means "not set", which is also what a blank, negative, fractional, or
// absurd entry means — the life bar simply stays hidden.
function parseAge(value) {
  var text = String(value === undefined || value === null ? "" : value).replace(/^\s+|\s+$/g, "")
  if (!/^\d+$/.test(text)) return 0
  var years = parseInt(text, 10)
  if (!isFinite(years) || years <= 0 || years > 120) return 0
  return years
}

// Unset or nonsense falls back to the default rather than to zero, so the
// bar always has something to measure against.
function parseLifeExpectancy(value) {
  var text = String(value === undefined || value === null ? "" : value).replace(/^\s+|\s+$/g, "")
  if (!/^\d+$/.test(text)) return DEFAULT_LIFE_EXPECTANCY
  var years = parseInt(text, 10)
  if (!isFinite(years) || years <= 0 || years > 150) return DEFAULT_LIFE_EXPECTANCY
  return years
}

function lifeProgress(age, expectancy) {
  var years = parseAge(age)
  var span = parseLifeExpectancy(expectancy)
  if (years <= 0 || span <= 0) return 0
  return Math.max(0, Math.min(1, years / span))
}

function lifeProgressPercent(age, expectancy) {
  return Math.round(lifeProgress(age, expectancy) * 100)
}

// ---- Four Thousand Weeks -------------------------------------------------
// The horizon is expressed in weeks even when the panel projects the same
// interval as months or years. This keeps every view derived from one exact
// finite span rather than three subtly different life-expectancy models.
var DEFAULT_HORIZON_WEEKS = 4000
var MAX_HORIZON_WEEKS = 7800

function parseHorizonWeeks(value) {
  var text = String(value === undefined || value === null ? "" : value).replace(/^\s+|\s+$/g, "")
  if (!/^\d+$/.test(text)) return DEFAULT_HORIZON_WEEKS
  var weeks = parseInt(text, 10)
  if (!isFinite(weeks) || weeks < 52 || weeks > MAX_HORIZON_WEEKS) return DEFAULT_HORIZON_WEEKS
  return weeks
}

function dateFromKey(value) {
  var match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(value === undefined || value === null ? "" : value))
  if (!match) return null
  var year = parseInt(match[1], 10)
  var month = parseInt(match[2], 10) - 1
  var day = parseInt(match[3], 10)
  var date = new Date(year, month, day, 12, 0, 0, 0)
  if (date.getFullYear() !== year || date.getMonth() !== month || date.getDate() !== day) return null
  return date
}

function utcDayNumber(date) {
  return Math.floor(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()) / MS_PER_DAY)
}

function daysBetween(start, end) {
  if (!(start instanceof Date) || !(end instanceof Date)) return 0
  return utcDayNumber(end) - utcDayNumber(start)
}

function parseBirthDate(value, today) {
  var date = dateFromKey(value)
  var now = today instanceof Date ? today : new Date()
  if (!date || daysBetween(date, now) < 0 || daysBetween(date, now) > 121 * 366) return ""
  return dateKey(date.getFullYear(), date.getMonth(), date.getDate())
}

function addDays(date, count) {
  var next = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 12, 0, 0, 0)
  next.setDate(next.getDate() + Number(count))
  return next
}

// Month and year projections stay anchored to the original birth day. Jan 31
// plus one month therefore becomes the final valid day of February without
// making every later interval drift from that clamped date.
function addCalendarMonths(date, count) {
  var target = new Date(date.getFullYear(), date.getMonth() + Number(count), 1, 12, 0, 0, 0)
  var finalDay = new Date(target.getFullYear(), target.getMonth() + 1, 0, 12, 0, 0, 0).getDate()
  target.setDate(Math.min(date.getDate(), finalDay))
  return target
}

function addCalendarYears(date, count) {
  return addCalendarMonths(date, Number(count) * 12)
}

function lifeStats(birthKey, today, horizonValue) {
  var now = today instanceof Date ? today : new Date()
  var normalizedBirth = parseBirthDate(birthKey, now)
  var horizonWeeks = parseHorizonWeeks(horizonValue)
  if (normalizedBirth === "") {
    return { configured: false, horizonWeeks: horizonWeeks, livedWeeks: 0, remainingWeeks: horizonWeeks, currentWeek: -1, progress: 0, percent: 0 }
  }

  var birth = dateFromKey(normalizedBirth)
  var elapsed = Math.max(0, Math.floor(daysBetween(birth, now) / 7))
  var lived = Math.min(horizonWeeks, elapsed)
  var current = elapsed < horizonWeeks ? elapsed : -1
  var progress = horizonWeeks > 0 ? lived / horizonWeeks : 0
  return {
    configured: true,
    horizonWeeks: horizonWeeks,
    livedWeeks: lived,
    remainingWeeks: Math.max(0, horizonWeeks - lived),
    currentWeek: current,
    progress: progress,
    percent: Math.round(progress * 1000) / 10
  }
}

function cellStatus(start, end, today) {
  var now = utcDayNumber(today)
  if (utcDayNumber(end) < now) return "lived"
  if (utcDayNumber(start) <= now) return "current"
  return "future"
}

function formatDateRange(start, end) {
  var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  if (start.getFullYear() === end.getFullYear() && start.getMonth() === end.getMonth())
    return start.getDate() + "–" + end.getDate() + " " + months[start.getMonth()] + " " + start.getFullYear()
  if (start.getFullYear() === end.getFullYear())
    return start.getDate() + " " + months[start.getMonth()] + "–" + end.getDate() + " " + months[end.getMonth()] + " " + start.getFullYear()
  return start.getDate() + " " + months[start.getMonth()] + " " + start.getFullYear() + "–" + end.getDate() + " " + months[end.getMonth()] + " " + end.getFullYear()
}

// The split grid readout keeps exact calendar time (always including year)
// apart from life-relative AGE and PAST/PRESENT/FUTURE context.
function compactDateRangeParts(startKey, endKey) {
  var start = dateFromKey(startKey)
  var end = dateFromKey(endKey)
  if (!start || !end) return { range: "", month: "", year: "", date: "" }
  var months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
  var range = ""
  if (start.getFullYear() === end.getFullYear() && start.getMonth() === end.getMonth())
    range = start.getDate() + "–" + end.getDate()
  else if (start.getFullYear() === end.getFullYear())
    range = start.getDate() + "–" + months[end.getMonth()] + " " + end.getDate()
  else
    range = start.getDate() + "–" + end.getFullYear() + " "
      + months[end.getMonth()] + " " + end.getDate()
  var month = months[start.getMonth()]
  var year = String(start.getFullYear())
  var date = ""
  if (start.getFullYear() === end.getFullYear() && start.getMonth() === end.getMonth())
    date = start.getDate() + "–" + end.getDate() + " " + month + " " + year
  else if (start.getFullYear() === end.getFullYear())
    date = start.getDate() + " " + month + "–" + end.getDate() + " "
      + months[end.getMonth()] + " " + year
  else
    date = start.getDate() + " " + month + " " + year + "–" + end.getDate()
      + " " + months[end.getMonth()] + " " + end.getFullYear()
  return {
    range: range,
    month: month,
    year: year,
    date: date
  }
}

function compactDateRange(startKey, endKey) {
  return compactDateRangeParts(startKey, endKey).date
}

function projectionReadout(cell, mode, today) {
  var parts = projectionReadoutParts(cell, mode, today)
  if (!parts) return ""
  return parts.date + " · " + parts.position + " · " + parts.age + " · " + parts.status
}

function projectionReadoutParts(cell, mode, today) {
  if (!cell) return ""
  var date = compactDateRangeParts(cell.startKey, cell.endKey)
  var monthMode = mode === "months"
  var span = monthMode ? 12 : 52
  var offset = Math.max(0, Math.floor(Number(cell.index) || 0))
  var age = Math.floor(offset / span)
  var position = (monthMode ? "MONTH " : "WEEK ") + (offset % span + 1)
  var statuses = { lived: "PAST", current: "PRESENT", future: "FUTURE" }
  return {
    date: date.date,
    dateRange: date.range,
    dateMonth: date.month,
    dateYear: date.year,
    position: position,
    age: "AGE " + age,
    status: statuses[cell.status] || String(cell.status || "").toUpperCase()
  }
}

function projectionStats(cells, mode) {
  var intervals = Array.isArray(cells) ? cells : []
  var lived = 0
  for (var i = 0; i < intervals.length; i++)
    if (intervals[i].status === "lived") lived++
  return {
    lived: lived,
    remaining: Math.max(0, intervals.length - lived),
    unit: mode === "months" ? "months" : "weeks"
  }
}

// Resolve one exact day into whichever projection currently renders it. A
// pin keeps the day as its identity, rather than adopting the destination
// cell's boundary, so switching weeks -> months -> weeks never makes it
// drift through the calendar.
function projectionIndexForDate(cells, value) {
  var intervals = Array.isArray(cells) ? cells : []
  var date = dateFromKey(value)
  if (!date || intervals.length === 0) return -1
  var day = utcDayNumber(date)
  var low = 0
  var high = intervals.length - 1

  while (low <= high) {
    var middle = Math.floor((low + high) / 2)
    var start = dateFromKey(intervals[middle].startKey)
    var end = dateFromKey(intervals[middle].endKey)
    if (!start || !end) return -1
    var startDay = utcDayNumber(start)
    var endDay = utcDayNumber(end)
    if (day < startDay) high = middle - 1
    else if (day > endDay) low = middle + 1
    else return middle
  }

  return -1
}

// LIFE's horizon is canonically week-based. Map an exact day to that same
// scale so a secondary rail marker agrees with the settled present marker
// and remains stable while the grid changes projection.
function lifeProgressForDate(birthKey, value, horizonValue) {
  var birth = dateFromKey(birthKey)
  var date = dateFromKey(value)
  if (!birth || !date) return -1
  var horizonWeeks = parseHorizonWeeks(horizonValue)
  var week = Math.floor(daysBetween(birth, date) / 7)
  return Math.max(0, Math.min(horizonWeeks, week)) / horizonWeeks
}

// Split source intervals by exact date overlap. The fractions tile each
// inclusive interval without pretending that calendar months contain a fixed
// number of weeks. Their changing row alignment is the mathematical source
// of the interference pattern used by the DAZ-274 experiment.
function projectionOverlapSegments(sourceCells, targetCells,
                                   sourceFirst, sourceLast,
                                   targetFirst, targetLast) {
  var sources = Array.isArray(sourceCells) ? sourceCells : []
  var targets = Array.isArray(targetCells) ? targetCells : []
  var parsedSourceFirst = Number(sourceFirst)
  var parsedSourceLast = Number(sourceLast)
  var parsedTargetFirst = Number(targetFirst)
  var parsedTargetLast = Number(targetLast)
  var sourceStart = Math.max(0, Math.min(sources.length,
    isFinite(parsedSourceFirst) ? Math.floor(parsedSourceFirst) : 0))
  var sourceEnd = Math.max(sourceStart, Math.min(sources.length,
    isFinite(parsedSourceLast) ? Math.floor(parsedSourceLast) : sources.length))
  var targetStart = Math.max(0, Math.min(targets.length,
    isFinite(parsedTargetFirst) ? Math.floor(parsedTargetFirst) : 0))
  var targetEnd = Math.max(targetStart, Math.min(targets.length,
    isFinite(parsedTargetLast) ? Math.floor(parsedTargetLast) : targets.length))
  var segments = []
  var targetCursor = targetStart

  for (var sourceIndex = sourceStart; sourceIndex < sourceEnd; sourceIndex++) {
    var sourceCell = sources[sourceIndex]
    var sourceStartDate = dateFromKey(sourceCell.startKey)
    var sourceEndDate = dateFromKey(sourceCell.endKey)
    if (!sourceStartDate || !sourceEndDate) continue
    var sourceStartDay = utcDayNumber(sourceStartDate)
    var sourceEndDay = utcDayNumber(sourceEndDate)
    var sourceDays = sourceEndDay - sourceStartDay + 1
    if (sourceDays <= 0) continue

    while (targetCursor < targetEnd) {
      var cursorEnd = dateFromKey(targets[targetCursor].endKey)
      if (cursorEnd && utcDayNumber(cursorEnd) >= sourceStartDay) break
      targetCursor++
    }

    for (var targetIndex = targetCursor; targetIndex < targetEnd; targetIndex++) {
      var targetCell = targets[targetIndex]
      var targetStartDate = dateFromKey(targetCell.startKey)
      var targetEndDate = dateFromKey(targetCell.endKey)
      if (!targetStartDate || !targetEndDate) continue
      var targetStartDay = utcDayNumber(targetStartDate)
      var targetEndDay = utcDayNumber(targetEndDate)
      if (targetStartDay > sourceEndDay) break

      var overlapStart = Math.max(sourceStartDay, targetStartDay)
      var overlapEnd = Math.min(sourceEndDay, targetEndDay)
      if (overlapStart > overlapEnd) continue
      var targetDays = targetEndDay - targetStartDay + 1
      if (targetDays <= 0) continue

      segments.push({
        sourceIndex: sourceIndex,
        targetIndex: targetIndex,
        sourceStart: (overlapStart - sourceStartDay) / sourceDays,
        sourceEnd: (overlapEnd - sourceStartDay + 1) / sourceDays,
        targetStart: (overlapStart - targetStartDay) / targetDays,
        targetEnd: (overlapEnd - targetStartDay + 1) / targetDays
      })
    }
  }

  return segments
}

function projectionCells(mode, birthKey, today, horizonValue) {
  var now = today instanceof Date ? today : new Date()
  var normalizedBirth = parseBirthDate(birthKey, now)
  if (normalizedBirth === "") return []
  var birth = dateFromKey(normalizedBirth)
  var horizonWeeks = parseHorizonWeeks(horizonValue)
  var horizonEnd = addDays(birth, horizonWeeks * 7 - 1)
  var cells = []
  var index = 0

  while (true) {
    var start
    var end
    var primary

    if (mode === "months") {
      start = addCalendarMonths(birth, index)
      if (utcDayNumber(start) > utcDayNumber(horizonEnd)) break
      end = addDays(addCalendarMonths(birth, index + 1), -1)
      if (utcDayNumber(end) > utcDayNumber(horizonEnd)) end = horizonEnd
      primary = "Year " + (Math.floor(index / 12) + 1) + " · Month " + (index % 12 + 1)
    } else if (mode === "years") {
      start = addCalendarYears(birth, index)
      if (utcDayNumber(start) > utcDayNumber(horizonEnd)) break
      end = addDays(addCalendarYears(birth, index + 1), -1)
      if (utcDayNumber(end) > utcDayNumber(horizonEnd)) end = horizonEnd
      primary = "Year " + (index + 1)
    } else {
      if (index >= horizonWeeks) break
      start = addDays(birth, index * 7)
      end = addDays(start, 6)
      primary = "Year " + (Math.floor(index / 52) + 1) + " · Week " + (index % 52 + 1)
    }

    var status = cellStatus(start, end, now)
    cells.push({
      index: index,
      startKey: keyForDate(start),
      endKey: keyForDate(end),
      status: status,
      primary: primary,
      secondary: formatDateRange(start, end) + " · " + status
    })
    index++
  }

  return cells
}

// Place the current row a little above the middle of a bounded viewport.
// That keeps enough history for orientation while leaving more of the finite
// future visible. The result is always clamped at birth and at the horizon.
function temporalViewportStart(currentRow, totalRows, visibleRows) {
  var total = Math.max(0, Math.floor(Number(totalRows) || 0))
  if (total === 0) return 0
  var visible = Math.max(1, Math.min(total, Math.floor(Number(visibleRows) || 1)))
  var current = Math.max(0, Math.min(total - 1, Math.floor(Number(currentRow) || 0)))
  var historyRows = Math.floor(visible * 0.4)
  return Math.max(0, Math.min(total - visible, current - historyRows))
}

// Always six rows of seven days. A fixed grid keeps the popup exactly the
// same height in every month, so stepping through the year never makes the
// panel jump under the pointer.
function monthGrid(year, month, weekStart, todayKey) {
  var start = normalizedWeekStart(weekStart, 1)
  var leading = (new Date(year, month, 1).getDay() - start + 7) % 7
  var cursor = new Date(year, month, 1 - leading)
  var today = String(todayKey || "")
  var weeks = []

  for (var w = 0; w < 6; w++) {
    var days = []
    var thursday = null
    for (var d = 0; d < 7; d++) {
      var cellYear = cursor.getFullYear()
      var cellMonth = cursor.getMonth()
      var cellDay = cursor.getDate()
      var weekday = cursor.getDay()
      var key = dateKey(cellYear, cellMonth, cellDay)
      if (weekday === 4) thursday = { year: cellYear, month: cellMonth, day: cellDay }
      days.push({
        key: key,
        year: cellYear,
        month: cellMonth,
        day: cellDay,
        weekday: weekday,
        inMonth: cellMonth === month && cellYear === year,
        weekend: weekday === 0 || weekday === 6,
        today: key === today
      })
      cursor.setDate(cursor.getDate() + 1)
    }
    // Number every row by the ISO week owning its Thursday. That is the
    // definition itself for Monday-start weeks, and the only answer that
    // stays stable for the other starts, where a row straddles two ISO
    // weeks but shares all of Monday through Thursday with one of them.
    var anchor = thursday || days[0]
    weeks.push({
      week: isoWeek(anchor.year, anchor.month, anchor.day),
      days: days
    })
  }
  return weeks
}

function stepMonth(year, month, delta) {
  var target = new Date(year, Number(month) + Number(delta), 1)
  return { year: target.getFullYear(), month: target.getMonth() }
}

if (typeof module !== "undefined") {
  module.exports = {
    dateKey: dateKey,
    keyForDate: keyForDate,
    normalizedWeekStart: normalizedWeekStart,
    weekStartSettingName: weekStartSettingName,
    toggledWeekStart: toggledWeekStart,
    weekdayOrder: weekdayOrder,
    isoWeek: isoWeek,
    dayOfYear: dayOfYear,
    daysInYear: daysInYear,
    yearProgress: yearProgress,
    yearProgressPercent: yearProgressPercent,
    parseAge: parseAge,
    parseBirthYear: parseBirthYear,
    ageFromBirthYear: ageFromBirthYear,
    parseLifeExpectancy: parseLifeExpectancy,
    lifeProgress: lifeProgress,
    lifeProgressPercent: lifeProgressPercent,
    parseHorizonWeeks: parseHorizonWeeks,
    dateFromKey: dateFromKey,
    daysBetween: daysBetween,
    parseBirthDate: parseBirthDate,
    addDays: addDays,
    addCalendarMonths: addCalendarMonths,
    addCalendarYears: addCalendarYears,
    lifeStats: lifeStats,
    formatDateRange: formatDateRange,
    compactDateRange: compactDateRange,
    projectionReadout: projectionReadout,
    projectionReadoutParts: projectionReadoutParts,
    projectionStats: projectionStats,
    projectionIndexForDate: projectionIndexForDate,
    lifeProgressForDate: lifeProgressForDate,
    projectionOverlapSegments: projectionOverlapSegments,
    projectionCells: projectionCells,
    temporalViewportStart: temporalViewportStart,
    monthGrid: monthGrid,
    stepMonth: stepMonth,
    clockFormats: clockFormats,
    clockFormatRing: clockFormatRing,
    nextClockFormat: nextClockFormat,
    isoWeekLiteral: isoWeekLiteral
  }
}
