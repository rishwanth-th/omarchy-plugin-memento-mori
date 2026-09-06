const test = require("node:test")
const assert = require("node:assert/strict")
const Motion = require("../Motion.js")

const SAMPLES = 1001
function eachTime(fn) {
  for (let i = 0; i < SAMPLES; i++) fn(i / (SAMPLES - 1))
}

test("the shaping primitive is flat outside its edges and smooth between", () => {
  assert.equal(Motion.ramp(-1, 0.2, 0.8), 0)
  assert.equal(Motion.ramp(0.2, 0.2, 0.8), 0)
  assert.equal(Motion.ramp(0.8, 0.2, 0.8), 1)
  assert.equal(Motion.ramp(2, 0.2, 0.8), 1)
  assert.ok(Math.abs(Motion.ramp(0.5, 0.2, 0.8) - 0.5) < 1e-12)
  // A zero-width edge is a step, so a degenerate table still resolves.
  assert.equal(Motion.ramp(0.49, 0.5, 0.5), 0)
  assert.equal(Motion.ramp(0.5, 0.5, 0.5), 1)
  // Non-finite input resolves to the start of the ramp rather than NaN.
  assert.equal(Motion.smoothstep(NaN), 0)
})

test("the trapezoid window holds at full strength between its inner edges", () => {
  assert.equal(Motion.window(0, 0, 0.4, 0.6, 1), 0)
  assert.equal(Motion.window(0.4, 0, 0.4, 0.6, 1), 1)
  assert.equal(Motion.window(0.5, 0, 0.4, 0.6, 1), 1)
  assert.equal(Motion.window(0.6, 0, 0.4, 0.6, 1), 1)
  assert.equal(Motion.window(1, 0, 0.4, 0.6, 1), 0)
})

test("every channel stays inside its own ink budget", () => {
  const lens = Motion.PROJECTION_MORPH.lens
  eachTime((t) => {
    const c = Motion.lensChannels(t)
    for (const key of ["source", "target", "interference"])
      assert.ok(c[key] >= 0 && c[key] <= 1, `${key} out of range at t=${t}`)
    assert.ok(c.fragment >= 0 && c.fragment <= lens.fragmentInk)
    assert.ok(c.wire >= 0 && c.wire <= lens.wireInk)
  })
})

test("both morphs start at the source and land exactly on the target", () => {
  for (const usesLens of [false, true]) {
    assert.equal(Motion.morphGeometry(0, usesLens), 0)
    assert.equal(Motion.morphGeometry(1, usesLens), 1)
  }
  const start = Motion.lensChannels(0)
  const end = Motion.lensChannels(1)
  assert.equal(start.source, 1)
  assert.equal(start.target, 0)
  assert.equal(start.fragment, 0)
  assert.equal(end.source, 0)
  assert.equal(end.target, 1)
  assert.equal(end.fragment, 0)
})

test("geometry never travels backwards", () => {
  for (const usesLens of [false, true]) {
    let previous = -1
    eachTime((t) => {
      const value = Motion.morphGeometry(t, usesLens)
      assert.ok(value >= previous - 1e-12, `geometry reversed at t=${t}`)
      previous = value
    })
  }
})

test("the lens holds its rects still exactly while the interference is full", () => {
  // The hold is the flat top of the interference window, not a second set of
  // constants that could drift away from it.
  eachTime((t) => {
    if (Motion.lensChannels(t).interference < 1) return
    assert.ok(Math.abs(Motion.morphGeometry(t, true) - 0.5) < 1e-12,
      `rects moved during the hold at t=${t}`)
  })
})

test("the seam is marked only while it is travelling", () => {
  // The endpoints carry a float residue from sin(pi), far below anything a
  // single alpha step can paint, so they are read as absent rather than zero.
  const invisible = 1 / 255
  assert.ok(Motion.seamChannels(0).mark < invisible)
  assert.ok(Motion.seamChannels(1).mark < invisible)
  assert.equal(Motion.seamChannels(0).position, 0)
  assert.equal(Motion.seamChannels(1).position, 1)
  assert.ok(Motion.seamChannels(0.5).mark > invisible)
})

// Recorded, not endorsed. Neither reading is drawn between these edges, and
// because the lens holds its geometry at exactly 0.5 for its whole plateau,
// that blank covers the entire hold rather than passing through it. Whether a
// cell mid-exchange should read as nothing is a design question that predates
// this file; the test exists so the answer cannot change by accident.
test("neither label reading is drawn across the crossover gap", () => {
  const lens = Motion.PROJECTION_MORPH.lens
  const blankStart = lens.labelOut[1]
  const blankEnd = lens.labelIn[0]
  assert.ok(blankStart <= blankEnd)
  const middle = Motion.morphLabelChannels((blankStart + blankEnd) / 2)
  assert.ok(middle.source < 1e-12)
  assert.ok(middle.target < 1e-12)
  assert.equal(Motion.morphGeometry(0.5, true), 0.5)
  eachTime((p) => {
    const l = Motion.morphLabelChannels(p)
    if (p < blankStart || p > blankEnd)
      assert.ok(l.source + l.target > 0, `both readings absent at p=${p}`)
  })
})

// The measured defect this substrate exists to make impossible. Holding the
// morph at fixed times and measuring the grid's luminance showed the lens
// dipping about 10% below the settled grid at t=0.25 and t=0.75, because the
// source ink ends at 0.30 while the interference does not reach full strength
// until 0.40 — and symmetrically at the far end. The channels have to hand
// off to each other, so what leaves must be replaced by what arrives.
test("the lens hands off its ink without a trough", { skip: "step 2" }, () => {
  const lens = Motion.PROJECTION_MORPH.lens
  eachTime((t) => {
    const c = Motion.lensChannels(t)
    const carried = c.source + c.target + c.fragment / lens.fragmentInk
    assert.ok(Math.abs(carried - 1) < 1e-9,
      `ink budget was ${carried.toFixed(4)} at t=${t}`)
  })
})
