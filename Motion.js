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
    duration: 420,
    markOpacity: 0.22
  },
  lens: {
    duration: 640,
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
    // The two lattices are stroked across every visible cell, so this is a
    // full field of hairlines rather than a local mark, so this value decides
    // how far above the grid that field sits. Measured at the midpoint
    // against the settled ends, within one capture run each: 0.09 rides
    // +0.63 of a level above the grid and reads as a hovering sheet, 0.06
    // sinks to -0.69 and reads as sunken, and the layer comes out flush near
    // 0.075. It should sit just proud, not float and not submerge.
    wireInk: 0.08
  }
}

// How far the geometry has travelled from source rect to target rect: one
// unbroken ease across the whole clock, identical for both treatments.
//
// Rects used to be carried halfway, frozen while the interference was at full
// strength, then carried the rest of the way, on the same edges the ink hands
// off across. That coupling was a mistake. Conservation is a law about how
// much of the grid is present; pace is a question about how fast things move,
// and binding the second to the first spent 40% of the morph with nothing
// moving at all and paid for it with rects going half again as fast on either
// side — arrival late and hurried, a stop, then another hurry.
//
// Nothing was bought by the stillness. The two lattices whose beat is the
// point are drawn as wireframes at their own fixed positions, so the
// interference does not depend on the fragments holding still. They can
// travel through it.
function morphGeometry(time, usesLens) {
  return smoothstep(time)
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
//
// The cut travels on the same ease the rects do. The two treatments used to
// be shaped in different places — the seam by the QML animation's easing
// curve, the lens by edges in this table — which is why they moved with
// different characters for no stated reason. Both are shaped here now, and
// the animation driving them runs linear.
function seamChannels(time) {
  var t = clamp01(time)
  return {
    position: smoothstep(t),
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
