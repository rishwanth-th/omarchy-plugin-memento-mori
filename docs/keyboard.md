# Keyboard and interaction manual

This is the source of truth for Memento Mori's active keyboard and pointer
contract. It records both plugin behavior and keys consumed by Omarchy's
shared `PanelKeyCatcher`, including consumed keys that currently do nothing.
Future interactions must update this manual before claiming a shortcut.

## Opening the plugin

The bar clock owns the popup:

- Left click toggles Calendar.
- Right click cycles the configured clock-label format.
- Middle click opens Omarchy's timezone picker.

The plugin exposes IPC entry points for profile-owned shortcuts:

```bash
omarchy-shell rishwanth.memento-mori toggle
omarchy-shell rishwanth.memento-mori showCalendar
omarchy-shell rishwanth.memento-mori showLife
```

Omarchy's stock `Super+Ctrl+Alt+D` binding targets `omarchy.clock`. Replacing
that widget does not retarget the Hyprland binding automatically. The Omarchy
profile should bind one of the commands above if a global Memento Mori summon
key is wanted; the plugin does not own a system-wide key itself.

## Shared panel keys

These keys are intercepted by Omarchy before Calendar or LIFE receives text:

| Key | Active behavior |
| --- | --- |
| `Escape` | Close the popup. While editing LIFE settings, cancel the edit instead; in LIFE, clear an active temporal pin first. |
| `Tab` / `Shift+Tab` | Open the next or previous visible panel in the same bar region. |
| `Enter` / `Space` | Activate the page action. Both return to today in Calendar; LIFE distinguishes pin (`Enter`) from now (`Space`). |
| Arrow keys | Send directional movement to the active page. |
| Lowercase `H/J/K/L` | Vim equivalents for Left/Down/Up/Right. |
| `X` | Consumed as a shared delete action; Memento Mori currently has no delete handler. |

Uppercase `H/J/K/L` are not directional aliases. Text-entry fields block the
shared catcher and receive normal editing keys.

## Calendar

### Keyboard

| Key | Action |
| --- | --- |
| `Left` / `H` | Previous month. |
| `Right` / `L` | Next month. |
| `Up` / `K` | Previous year. |
| `Down` / `J` | Next year. |
| `[` / `]` | Previous / next month. |
| `{` / `}` | Previous / next year. |
| `T`, `Enter`, or `Space` | Return to the current month. |
| `W` | Toggle the configured first day of the week. |
| `M` | Enter LIFE; if no birth date exists, open LIFE settings. |

### Pointer

- Scroll over the month grid to move one month backward or forward.
- Click the hero date after browsing to return to the current month.
- Click the left or right chevron to move one month.
- Click the `W` heading to toggle the first day of the week.
- Click the LIFE rail to enter Memento Mori.
- Double-click the year-progress rail to edit birth date and horizon.
- Calendar day cells are read-only; they are not date-picker controls.

## LIFE settings editor

| Key | Action |
| --- | --- |
| `Tab` / `Shift+Tab` | Move between birth date and horizon; select the destination value. |
| `Enter` | Validate, normalize, save both values, and leave the editor. |
| `Escape` | Discard the current edit and leave the editor. |

Birth date uses `YYYY-MM-DD`. Horizon is a number of weeks and defaults to
`4000`. Pointer selection and ordinary text-editing keys remain native to the
fields.

## LIFE

### Keyboard

| Key | Action |
| --- | --- |
| `Up` / `K` | Move the inspection cursor one life-year earlier; the viewport follows. |
| `Down` / `J` | Move the inspection cursor one life-year later; the viewport follows. |
| `Left` / `H` | Move the inspection cursor one projected interval earlier. |
| `Right` / `L` | Move the inspection cursor one projected interval later. |
| `Enter` | Pin the inspected interval, retarget the one pin, or clear it when already on that interval. The present itself is not pinnable. |
| `T` or `Space` | Return the viewport and inspection cursor to now without changing an existing pin. |
| `P` | Toggle the projection between Weeks and Months. |
| `A` | Toggle the session-only projection animation style. |
| `M` | Return to Calendar. |
| `Escape` | Clear an active temporal pin first; close the popup when no pin remains. |

### Pointer

- Scroll over the grid to move the attention viewport by one life-year.
- Hover a cell to inspect its exact interval and coordinate guides.
- Click a non-present cell to pin it, click another to retarget the one pin,
  or click the pinned cell or present to clear it.
- Hover an axis or its unit to emphasize that scale.
- Click the `M →` projection cue to toggle Weeks and Months.
- Triple-click an otherwise inert part of the grid to toggle projection
  animation style.
- Click the back action to return to Calendar.
- Click the now action, when visible, to restore the present-centered viewport.
- The pin is session-only. Leaving LIFE clears it; it is never written to
  settings.

## Current key budget

The following constraints apply before adding another interaction:

- `M`, `T`, `P`, and `A` are active LIFE mnemonics.
- `Escape`, `Tab`, arrows, `H/J/K/L`, `Enter`, `Space`, and `X` are intercepted
  by the shared catcher before ordinary text-key routing.
- `H/J/K/L` and arrows now belong to one LIFE inspection cursor. The viewport
  follows that cursor instead of maintaining a second keyboard movement model.
- Number keys are intentionally free; `1` / `2` / `3` were retired when
  projection and animation became the reversible `P` and `A` actions.
- Pointer multi-click is reserved only for secondary, session-only behavior;
  primary actions must remain immediate on one click.

## Runtime routing check

Omarchy's shared `PanelKeyCatcher` translates arrows and lowercase `H/J/K/L`
into one `(dx, dy)` movement signal. Calendar maps that signal to month/year
stepping; LIFE maps all four directions to its inspection cursor. LIFE must not
retain the old mapping where only Up/Down pan the viewport and Left/Right are
no-ops.

The active plugin exposes a read-only probe for verifying that routing:

```bash
omarchy-shell rishwanth.memento-mori interactionState
```

If installed files contain `moveInspection` but the command reports `Function
not found`, Omarchy is still holding a stale plugin component. Rescan first,
then restart the shell only if the stale instance survives:

```bash
omarchy-shell shell rescanPlugins
omarchy restart shell
```

## Temporal-distance pin proof of concept

DAZ-277 currently implements this deliberately bounded grammar:

1. LIFE has one keyboard inspection cursor, initialized from the present on
   first movement.
2. `H/L` or Left/Right move one projected interval; `J/K` or Up/Down move one
   life-year row while the viewport follows at its edges.
3. `Enter` pins the focused interval, retargets the existing pin, or clears it
   when focused on the same interval.
4. Pointer click performs the same single-pin action.
5. `Escape` clears an active pin first and closes the popup only when no pin
   remains.
6. `T` and `Space` return inspection to now without changing the exact meaning
   of a pin.
7. The pinned identity is an exact date. Weeks and Months map that date into
   their containing interval without replacing it, so projection round trips
   cannot drift.
8. Pointer hover and keyboard inspection are live temporal measures. Every
   non-present inspected interval shows its exact projection-aware distance
   from now for as long as that probe remains active.
9. The pin is a held spatial measure, not frozen hover. Its quiet grid and LIFE
   geometry remains while inspection moves elsewhere; hovering the held cell
   or LIFE span recalls its full delta through the same inspection readout.

`X` remains consumed and inert. No multi-pin accumulation, persisted state, or
personal-history annotation is part of this proof of concept.
