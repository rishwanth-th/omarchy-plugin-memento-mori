// The time half of the lattice.
//
// The grid derives every horizontal coordinate from one atom, the week. This
// file does the same thing for time: every transition is a pure function of
// one number — where it is on its own clock — built from one shaping
// primitive and a table of edges.
//
// Two consequences are worth the indirection. A motion can be read as a
// shape rather than reconstructed from constants scattered across painters.
// And a motion can be held at a chosen instant and measured, because nothing
// about a frame depends on how the clock arrived there. Qt- and paint-free,
// like Model.js, so node can test it (tests/motion.test.js).

// ---- Shaping primitive. Everything below is built from this one function:
//      a smoothstep between two edges, flat outside them.
function clamp01(value) {
  var x = Number(value)
  if (!(x > 0)) return 0
  return x > 1 ? 1 : x
}

function smoothstep(value) {
  var x = clamp01(value)
  return x * x * (3 - 2 * x)
}

// Rises from 0 to 1 across [start, end]; held flat outside. A zero-width
// edge is a step, which is what a reduced-motion or degenerate table wants.
function ramp(time, start, end) {
  if (end <= start) return time < start ? 0 : 1
  return smoothstep((time - start) / (end - start))
}

// ---- The projection morph, as data.
//
// Two treatments answer the same question — what happens to a week when the
// calendar becomes the ruler — with opposite honesty about superposition.
//
// The travelling seam refuses to superimpose 52 and 12 columns at all: a
// hard clip, each side at its own fixed geometry and full strength, so the
// exchange has a location and never dims.
//
// The exact-overlap lens does the opposite, and superimposes them on purpose.
// Its beat pattern is real 52-week against calendar-month interference, not
// drawn texture, which is why its channel weights are the thing to get right:
// the moire IS the transition rather than a decoration over it.
var PROJECTION_MORPH = {
  seam: {
    duration: 360,
    // The seam is the only moving thing, so its clock is the eased one and
    // its position is read straight off it.
    markOpacity: 0.22
  },
  lens: {
    duration: 520,
    // Edges, in clock order. Everything the lens paints is one of these.
    //
    // Two edges, and everything else follows from them. The interference is
    // not a third window with its own timings: it is exactly what the two
    // settled projections are not carrying, so the lens can never be showing
    // less than a whole grid.
    sourceOut: [0, 0.30],
    targetIn: [0.70, 1],
    // One interval, not two windows. A cell always denotes a definite range
    // of dates; what a morph changes is the granularity of its name, never
    // whether it has one. So the two readings are complements of a single
    // crossover and always sum to a whole label.
    labelCrossover: [0.44, 0.56],
    // Ink densities, not timings: how strongly a channel paints when it is
    // fully present. Fragments cover the same area as the grid but at higher
    // density, so they reach the grid's weight below full opacity. Measured,
    // by holding the morph on its plateau where the fragments carry the whole
    // image: 0.66 there reads within 0.4% of the settled grid.
    fragmentInk: 0.66,
    wireInk: 0.09
  }
}

// How far the geometry has travelled from source rect to target rect. The
// seam moves rects not at all — each side stays at its own projection's fixed
// geometry — so its geometry clock is its own clock. The lens carries rects
// halfway, holds them superimposed while the interference is at full
// strength, then carries them the rest of the way; it shares the two edges of
// the interference window, because the hold IS the window's flat top.
function morphGeometry(time, usesLens) {
  var t = clamp01(time)
  if (!usesLens) return t
  var lens = PROJECTION_MORPH.lens
  return 0.5 * ramp(t, lens.sourceOut[0], lens.sourceOut[1])
    + 0.5 * ramp(t, lens.targetIn[0], lens.targetIn[1])
}

// What each channel of the lens weighs at this instant.
function lensChannels(time) {
  var t = clamp01(time)
  var lens = PROJECTION_MORPH.lens
  var source = 1 - ramp(t, lens.sourceOut[0], lens.sourceOut[1])
  var target = ramp(t, lens.targetIn[0], lens.targetIn[1])
  // What neither settled projection is carrying, the interference carries.
  // The grid is therefore whole at every instant: the two treatments differ
  // in whether the resolutions are superimposed, never in how much is there.
  var interference = 1 - source - target
  return {
    source: source,
    target: target,
    fragment: lens.fragmentInk * interference,
    wire: lens.wireInk * interference,
    interference: interference
  }
}

// A tick's two readings name the same instant at two granularities, so they
// hand off to each other exactly as the grid's ink does: the target is the
// complement of the source, and a whole label is present at every moment.
//
// While the lens holds both lattices superimposed, both readings are
// therefore present at half strength, at their own two positions. That is the
// same claim the cells are making underneath them — this instant is being
// read two ways at once — rather than the axis going quiet while the grid
// says otherwise.
function morphLabelChannels(geometryProgress) {
  var p = clamp01(geometryProgress)
  var crossover = PROJECTION_MORPH.lens.labelCrossover
  var target = ramp(p, crossover[0], crossover[1])
  return { source: 1 - target, target: target }
}

// The seam's own reading: where the cut is, and how strongly it is marked.
// The mark is present only while the cut is travelling, and absent at both
// ends where there is nothing to mark.
function seamChannels(time) {
  var t = clamp01(time)
  return {
    position: t,
    mark: Math.sin(Math.PI * t) * PROJECTION_MORPH.seam.markOpacity
  }
}

function projectionMorphDuration(usesLens) {
  return usesLens ? PROJECTION_MORPH.lens.duration : PROJECTION_MORPH.seam.duration
}

if (typeof module !== "undefined") {
  module.exports = {
    clamp01: clamp01,
    smoothstep: smoothstep,
    ramp: ramp,
    morphGeometry: morphGeometry,
    lensChannels: lensChannels,
    morphLabelChannels: morphLabelChannels,
    seamChannels: seamChannels,
    projectionMorphDuration: projectionMorphDuration,
    PROJECTION_MORPH: PROJECTION_MORPH
  }
}
