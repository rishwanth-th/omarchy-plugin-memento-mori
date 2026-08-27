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
| `Escape` | Close the popup. While editing LIFE settings, cancel the edit instead. |
| `Tab` / `Shift+Tab` | Open the next or previous visible panel in the same bar region. |
| `Enter` / `Space` | Activate the page's primary return action: today in Calendar, now in LIFE. |
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
| `Up` / `K` | Move the attention viewport one life-year earlier. |
| `Down` / `J` | Move the attention viewport one life-year later. |
| `Left` / `H` | Consumed by the shared catcher; currently no LIFE action. |
| `Right` / `L` | Consumed by the shared catcher; currently no LIFE action. |
| `T`, `Enter`, or `Space` | Return the attention viewport to now. |
| `P` | Toggle the projection between Weeks and Months. |
| `A` | Toggle the session-only projection animation style. |
| `M` | Return to Calendar. |
| `Escape` | Close the popup. |

### Pointer

- Scroll over the grid to move the attention viewport by one life-year.
- Hover a cell to inspect its exact interval and coordinate guides.
- Hover an axis or its unit to emphasize that scale.
- Click the `M →` projection cue to toggle Weeks and Months.
- Triple-click an otherwise inert part of the grid to toggle projection
  animation style.
- Click the back action to return to Calendar.
- Click the now action, when visible, to restore the present-centered viewport.
- Single and double clicks on ordinary grid cells currently have no committed
  product action.

## Current key budget

The following constraints apply before adding another interaction:

- `M`, `T`, `P`, and `A` are active LIFE mnemonics.
- `Escape`, `Tab`, arrows, `H/J/K/L`, `Enter`, `Space`, and `X` are intercepted
  by the shared catcher before ordinary text-key routing.
- `H/L` are available semantically in LIFE but require replacing their current
  consumed no-op behavior.
- `J/K` already own viewport movement. A keyboard cell cursor must absorb that
  responsibility and keep the viewport following the cursor rather than add a
  second movement model.
- Number keys are intentionally free; `1` / `2` / `3` were retired when
  projection and animation became the reversible `P` and `A` actions.
- Pointer multi-click is reserved only for secondary, session-only behavior;
  primary actions must remain immediate on one click.

## Proposed temporal-distance pin grammar

The following is a design candidate for DAZ-277, not implemented behavior:

1. LIFE gains one keyboard inspection cursor, initialized at the present.
2. `H/L` or Left/Right move one projected interval; `J/K` or Up/Down move one
   life-year row while the viewport follows at its edges.
3. `Enter` pins the focused interval, retargets the existing pin, or clears it
   when focused on the same interval.
4. Pointer click performs the same single-pin action.
5. `Escape` clears an active pin first and closes the popup only when no pin
   remains.
6. `T` returns inspection to now without changing the exact meaning of a pin.

Before implementation, the experiment must decide whether `Space` mirrors
`Enter` or remains a return-to-now action, and whether `X` should remain inert
or become an explicit clear-pin key. No multi-pin accumulation or numeric
delta is part of the first proof of concept.
