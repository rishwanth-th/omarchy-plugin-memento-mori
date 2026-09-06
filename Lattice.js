// One axis.
//
// A life is a single timeline. The grid folds it, and the fold is a way of
// showing a line rather than a second dimension: one direction reads
// `t mod fold`, the other reads `t div fold`. So there are not two axes to
// choose. There is one position on a scale, and the fold and the tick both
// follow from it.
//
// That position is a rung. Zooming moves along the rungs, and because the
// same life is being counted at every one of them, moving is the whole point:
// forty million minutes and seventy-seven years are the same span, and they
// do not feel like the same span.
//
// Qt- and paint-free, like Model.js and Motion.js, so node can test it
// (tests/lattice.test.js). Nothing here knows about pixels except the
// legibility bounds, which are given to it rather than assumed.

var DAYS_PER_YEAR = 365.2425

// Every unit is a length in days and a name. The length does the arithmetic;
// the name does the meaning, and the two are independent — a summer and a
// year are the same length and are not the same thing.
//
// The kind says where a unit's length comes from, which is what decides
// whether it will tile:
//
//   clock     a fixed count of smaller clock units, running free of the
//             solar year: a week is seven days whatever the year is doing
//   calendar  defined as a division of the solar year, so it tiles the year
//             exactly and its individual lengths may still vary
//   rate      defined as a count per year, so it tiles by construction and
//             has no exact boundaries at all
var UNITS = {
  second:    { days: 1 / 86400,          kind: "clock",    plural: "seconds" },
  minute:    { days: 1 / 1440,           kind: "clock",    plural: "minutes" },
  hour:      { days: 1 / 24,             kind: "clock",    plural: "hours" },
  day:       { days: 1,                  kind: "clock",    plural: "days" },
  week:      { days: 7,                  kind: "clock",    plural: "weeks" },
  fortnight: { days: 14,                 kind: "clock",    plural: "fortnights" },
  month:     { days: DAYS_PER_YEAR / 12, kind: "calendar", plural: "months" },
  quarter:   { days: DAYS_PER_YEAR / 4,  kind: "calendar", plural: "quarters" },
  season:    { days: DAYS_PER_YEAR / 4,  kind: "calendar", plural: "seasons" },
  year:      { days: DAYS_PER_YEAR,      kind: "calendar", plural: "years" },
  summer:    { days: DAYS_PER_YEAR,      kind: "calendar", plural: "summers" },
  decade:    { days: DAYS_PER_YEAR * 10, kind: "calendar", plural: "decades" }
}

function unit(name) {
  return UNITS[name] || null
}

function lengthInDays(name) {
  var found = unit(name)
  return found ? found.days : 0
}

// A unit defined as so many per year: books at twenty a year, visits home at
// three. It has no exact boundaries — nobody finishes their five hundredth
// book on a particular Tuesday — so it tiles the year by construction and its
// edges are honestly fractional.
function ratePerYear(name, count, plural) {
  return {
    days: DAYS_PER_YEAR / count,
    kind: "rate",
    plural: plural || (name + "s"),
    perYear: count
  }
}

// The only conversion there is: everything is a length in days.
function convert(amount, fromDays, toDays) {
  if (!(toDays > 0)) return 0
  return amount * fromDays / toDays
}

// How many of a unit a span holds. The whole point of the ladder: the same
// span, counted differently, is the same span and does not feel like it.
function countIn(spanDays, unitDays) {
  return convert(spanDays, 1, unitDays)
}

// A tick tiles a fold when the fold is a whole number of ticks. This is not a
// coincidence to be discovered per pair — it is exactly whether the fold was
// defined in terms of the tick. Days tile fortnights, hours tile days,
// months tile years. Weeks do not tile years, because a week is seven days
// whatever the sun is doing.
function tiles(foldDays, tickDays) {
  var count = foldDays / tickDays
  return Math.abs(count - Math.round(count)) < 1e-9
}

// What a fold has left over after as many whole ticks as fit. Zero wherever
// the tick tiles; at a year ticked by weeks it is the 1.24 days that make a
// birthday land on a different weekday each year.
function remainderDays(foldDays, tickDays) {
  if (tickDays <= 0) return 0
  return foldDays - Math.floor(foldDays / tickDays + 1e-9) * tickDays
}

// The ladder: every fold and tick pairing that can be drawn and read.
//
// Bounds are passed in rather than assumed, because they are facts about a
// particular grid at a particular size, not about time. `minTickPixels` is
// the one that does the real work — it is why the ladder stops, and why the
// week is where a whole-life row comes to rest.
function rungs(options) {
  var settings = options || {}
    var catalogue = settings.units || UNITS
  var minTicks = settings.minTicksPerFold || 8
  var maxTicks = settings.maxTicksPerFold || 60
  var width = settings.gridWidth || 0
  var minPixels = settings.minTickPixels || 0
  var found = []

  for (var foldName in catalogue) {
    for (var tickName in catalogue) {
      var foldDays = catalogue[foldName].days
      var tickDays = catalogue[tickName].days
      var count = foldDays / tickDays
      if (count < minTicks || count > maxTicks) continue
      if (width > 0 && minPixels > 0 && width / count < minPixels) continue
      found.push({
        fold: foldName,
        tick: tickName,
        foldDays: foldDays,
        tickDays: tickDays,
        ticksPerFold: count,
        tiles: tiles(foldDays, tickDays),
        remainderDays: remainderDays(foldDays, tickDays)
      })
    }
  }

  // Ordered by how much time a tick holds: zooming out is walking forwards.
  found.sort(function (first, second) {
    if (first.tickDays !== second.tickDays) return first.tickDays - second.tickDays
    return first.foldDays - second.foldDays
  })
  return found
}

// A grid shows four levels at once, not one: the cell, the grouping inside a
// row, the row itself, and the grouping of rows. The current grid is week,
// quarter, year, five years — and it is not special. It is one entry in this
// enumeration, which is the point: zooming slides the window of four along
// the ladder rather than changing the kind of thing being looked at.
//
// The gaps are what make the middle two visible. A grouping is drawn as space
// rather than as a line or a colour, so the levels above the cell are read as
// rhythm; toggling those gaps is toggling whether the neighbours are shown at
// all.
//
// Each level must hold a legible count of the one below. Two is not a
// grouping and fifty cannot be seen as one, so the ratio band does most of
// the filtering here.
function nestings(options) {
  var settings = options || {}
  var catalogue = settings.units || UNITS
  var lowest = settings.minRatio || 3
  var highest = settings.maxRatio || 14
  var minPerRow = settings.minTicksPerFold || 8
  var maxPerRow = settings.maxTicksPerFold || 60

  var ordered = []
  for (var name in catalogue) ordered.push({ name: name, days: catalogue[name].days })
  ordered.sort(function (a, b) { return a.days - b.days })

  var found = []
  for (var a = 0; a < ordered.length; a++)
    for (var b = a + 1; b < ordered.length; b++)
      for (var c = b + 1; c < ordered.length; c++)
        for (var d = c + 1; d < ordered.length; d++) {
          var ratios = [
            ordered[b].days / ordered[a].days,
            ordered[c].days / ordered[b].days,
            ordered[d].days / ordered[c].days
          ]
          var legible = true
          for (var i = 0; i < ratios.length; i++)
            if (ratios[i] < lowest || ratios[i] > highest) legible = false
          if (!legible) continue
          var perRow = ordered[c].days / ordered[a].days
          if (perRow < minPerRow || perRow > maxPerRow) continue
          found.push({
            cell: ordered[a].name,
            group: ordered[b].name,
            fold: ordered[c].name,
            rowGroup: ordered[d].name,
            cellDays: ordered[a].days,
            foldDays: ordered[c].days,
            ratios: ratios,
            ticksPerFold: perRow
          })
        }
  found.sort(function (first, second) { return first.cellDays - second.cellDays })
  return found
}

// What the instrument reads at a rung: how many rows a span occupies, and how
// many ticks it comes to in total.
function reading(rung, spanDays) {
  return {
    rows: spanDays / rung.foldDays,
    ticks: spanDays / rung.tickDays
  }
}

if (typeof module !== "undefined") {
  module.exports = {
    DAYS_PER_YEAR: DAYS_PER_YEAR,
    UNITS: UNITS,
    unit: unit,
    lengthInDays: lengthInDays,
    ratePerYear: ratePerYear,
    convert: convert,
    countIn: countIn,
    tiles: tiles,
    remainderDays: remainderDays,
    rungs: rungs,
    nestings: nestings,
    reading: reading
  }
}
