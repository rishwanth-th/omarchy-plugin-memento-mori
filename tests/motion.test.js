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

test("the rects travel without ever stalling mid-morph", () => {
  // Conservation governs how much of the grid is present. It must not also
  // govern pace: the rects used to be pinned for 40% of the lens's clock, on
  // the ink's own edges, which read as arrival-hurry, stop, hurry. A morph
  // moves throughout, so its speed is never zero except at the two ends.
  for (const usesLens of [false, true]) {
    const step = 1 / (SAMPLES - 1)
    for (let i = 1; i < SAMPLES; i++) {
      const t = i * step
      if (t < 0.05 || t > 0.95) continue
      const speed = (Motion.morphGeometry(t, usesLens)
        - Motion.morphGeometry(t - step, usesLens)) / step
      assert.ok(speed > 0.05, `rects stalled at t=${t.toFixed(3)}`)
    }
  }
})

test("both treatments move with the same character", () => {
  // They were shaped in different places — the seam by the QML animation's
  // easing curve, the lens by edges in the table — and so moved differently
  // for no stated reason.
  eachTime((t) => {
    assert.equal(Motion.morphGeometry(t, false), Motion.morphGeometry(t, true))
    assert.equal(Motion.seamChannels(t).position, Motion.morphGeometry(t, false))
  })
})

test("the fold rises and falls as one gesture", () => {
  // Still at both ends and still again at the top, with no corner between:
  // a trapezoid would arrive, wait and leave as three separate events.
  assert.equal(Motion.bell(0), 0)
  assert.equal(Motion.bell(1), 0)
  assert.ok(Math.abs(Motion.bell(0.5) - 1) < 1e-12)
  eachTime((t) => {
    assert.ok(Math.abs(Motion.bell(t) - Motion.bell(1 - t)) < 1e-12,
      `the breath was asymmetric at t=${t}`)
  })
  const step = 1 / (SAMPLES - 1)
  let rising = true
  for (let i = 1; i < SAMPLES; i++) {
    const t = i * step
    const slope = Motion.bell(t) - Motion.bell(t - step)
    if (rising && slope < 0) rising = false
    // Once it turns over it must not rise again: one breath, not several.
    else if (!rising) assert.ok(slope <= 1e-12, `the fold rose twice, at t=${t}`)
  }
  assert.ok(!rising, "the fold never came back down")
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

// The same conservation the grid's ink obeys. A cell denotes a definite range
// of dates at every instant of a morph, so it is never nameless; only the
// granularity of the name changes. An axis that goes blank while the grid
// underneath is showing both lattices is the ink trough again, in a channel
// where it reads as the view losing its nerve rather than as dimming.
test("a whole label is present at every instant", () => {
  eachTime((p) => {
    const l = Motion.morphLabelChannels(p)
    assert.ok(Math.abs(l.source + l.target - 1) < 1e-12,
      `label budget was ${(l.source + l.target).toFixed(4)} at p=${p}`)
  })
  assert.equal(Motion.morphLabelChannels(0).source, 1)
  assert.equal(Motion.morphLabelChannels(1).target, 1)
  // The lens pins its geometry at exactly 0.5 for its whole hold, so this is
  // the reading that stands for that entire stretch: both, at half strength.
  const held = Motion.morphLabelChannels(Motion.morphGeometry(0.5, true))
  assert.ok(Math.abs(held.source - 0.5) < 1e-12)
  assert.ok(Math.abs(held.target - 0.5) < 1e-12)
})

// The measured defect this substrate exists to make impossible. Holding the
// morph at fixed times and measuring the grid's luminance showed the lens
// dipping about 10% below the settled grid at t=0.25 and t=0.75, because the
// source ink ends at 0.30 while the interference does not reach full strength
// until 0.40 — and symmetrically at the far end. The channels have to hand
// off to each other, so what leaves must be replaced by what arrives.
test("the lens hands off its ink without a trough", () => {
  const lens = Motion.PROJECTION_MORPH.lens
  eachTime((t) => {
    const c = Motion.lensChannels(t)
    const carried = c.source + c.target + c.fragment / lens.fragmentInk
    assert.ok(Math.abs(carried - 1) < 1e-9,
      `ink budget was ${carried.toFixed(4)} at t=${t}`)
  })
})

test("speed is the ease's own derivative, not a curve resembling it", () => {
  // If it were merely shaped like the motion it would drift out of step with
  // it. Checked against the ease it is supposed to be the speed of.
  const step = 1e-6
  eachTime((t) => {
    if (t < 0.01 || t > 0.99) return
    const measured = (Motion.morphGeometry(t + step, true)
      - Motion.morphGeometry(t - step, true)) / (2 * step)
    assert.ok(Math.abs(measured - Motion.speed(t)) < 1e-4,
      `speed disagreed with the ease at t=${t}`)
  })
  // Still at both ends, half again as fast as average in the middle.
  assert.equal(Motion.speed(0), 0)
  assert.equal(Motion.speed(1), 0)
  assert.ok(Math.abs(Motion.speed(0.5) - 1.5) < 1e-12)
})

test("a morph travels exactly one journey, so speed averages one", () => {
  let total = 0
  const step = 1 / (SAMPLES - 1)
  eachTime((t) => { total += Motion.speed(t) * step })
  assert.ok(Math.abs(total - 1) < 1e-3, `travelled ${total.toFixed(4)}`)
})
