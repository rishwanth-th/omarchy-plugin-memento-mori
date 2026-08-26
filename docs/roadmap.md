# Roadmap

V1 establishes the information architecture and interaction grammar. V2 is an
exploration of motion and tactility—not permission to add product machinery.
Nothing below is promised until a prototype proves that it improves temporal
understanding without disturbing the clock.

## Motion principles

- Motion should explain containment, passage, or focus. Decoration alone is
  not enough.
- The panel and grid envelope remain fixed throughout every transition.
- A short interaction should feel responsive before it feels cinematic.
- Repeated opening must not become tedious.
- Reduced-motion preferences require an immediate, equally coherent state.
- The present remains the semantic anchor even while another cell is inspected.
- Playfulness must not become gamification or urgency.

## Candidate experiments

### 1. LIFE entrance

On first reveal, the LIFE rail could travel from zero through its year ticks
to the current boundary while the grid resolves from birth to the present.
This would make elapsed time feel constructed rather than merely displayed.

Questions to prototype:

- Does a fast sweep explain the scale, or merely delay the answer?
- Should only the present marker travel while lived fill fades in behind it?
- Should the entrance run once per session, every opening, or only after
  configuration changes?
- Can the grid reveal by life-year or grouped intervals rather than animating
  thousands of cells individually?

### 2. Weeks-to-Months morph

The strongest V2 candidate is a real spatial transition between projections:
week cells gather into their corresponding month intervals, and the expanded
month cells inherit their visual mass. Reversing the action should unpack the
same structure back into weeks.

This prototype must preserve exact birth-anchored date semantics. A visually
convincing four-week collapse that implies false calendar grouping is worse
than the stable V1 cross-projection redraw.

### 3. Present-to-hover relationship

Hover could animate a restrained inspection path from the persistent present
landmark to the hovered cell. Plausible treatments include a guide that draws
out, a brief traveling point, or a soft interpolation of the foreground
inspection corner.

The motion must not imply that the present itself moved, and rapid pointer
movement must not create a swarm of queued animations. Distance-aware duration
with immediate cancellation is worth testing.

### 4. Pinned inspection

Clicking a cell currently has no meaning. A V2 prototype may test click as a
temporary pinned inspection so keyboard or pointer movement can leave the
cell without losing its exact interval.

Pinning earns a place only if it enables a real task such as comparison or
accessibility. It should not open journaling, milestones, or a detail product
with no established purpose.

### 5. Viewport movement

Wheel and keyboard navigation could gain a short, cancellable row transition
and clearer edge response. The experiment should retain one-life-year steps,
stable dimensions, and exact stopping positions; inertial scrolling would be
inappropriate if it makes ages harder to land on.

## Evaluation order

1. Prototype the Weeks-to-Months morph because it explains an existing action.
2. Prototype the LIFE entrance with a strict time budget and reduced-motion
   fallback.
3. Test present-to-hover motion only after rapid-hover cancellation is solved.
4. Explore click-to-pin only after naming the user need it serves.
5. Add viewport motion last; it is polish, not core meaning.

Each accepted experiment moves into [Design philosophy](design.md). Rejected
experiments stay here with a short reason so the same ambiguity does not need
to be rediscovered.
