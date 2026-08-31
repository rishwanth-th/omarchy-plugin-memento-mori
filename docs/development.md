# Development

How to get this checkout onto the running shell, and why the loop is shaped
the way it is. Interaction and keyboard contract lives in
[keyboard.md](keyboard.md); design decisions in [design.md](design.md).

## The loop

```bash
npm test          # model tests
npm run sync      # put this checkout on the live shell, verified
```

`npm run sync` is three commands plus their guards:

1. `omarchy plugin update rishwanth.memento-mori` — the installed plugin at
   `~/.config/omarchy/plugins/rishwanth.memento-mori` is a git clone whose
   origin is this checkout, so an update fast-forwards it. **Never copy files
   into that directory.** A copied-over clone counts as locally modified and
   `omarchy plugin update` then refuses outright (`cannot fast-forward; you
   have local changes`). Recover with `git -C <plugin-dir> reset --hard` and
   `git clean -fd`.
2. `omarchy restart shell` — see below; nothing lighter reliably works.
3. Verification — refuses a dirty checkout, asserts the installed revision
   matches this one, waits for the plugin to answer, and fails on QML errors.

Because it pulls commits, work has to be committed before it can be synced.

### Never trust a rescan

`omarchy-shell shell rescanPlugins` does **not** reliably reload changed QML.
The previously loaded component keeps running, so a probe or a screenshot
reports the OLD behaviour while the files on disk are already new. This has
produced false "verified live" conclusions more than once: an edit appears to
have no effect, or a fix appears to work when the old code is still running.
Nothing in the probe output reveals it.

Measured, not inferred. Changing `targetSemanticColumnGap` and watching the
`semanticColumnGap` the probe reports:

| action | result |
| --- | --- |
| install the file, wait 12s | unchanged |
| `omarchy-shell shell rescanPlugins`, wait 16s | unchanged |
| `omarchy restart shell` | picks up the new value |

The shell does notice — it logs `Local plugin changed, reloading:
rishwanth.memento-mori` — so both the watcher and the reload trigger fire.
The reload simply does not end in fresh QML.

The exact upstream cause is **not** pinned. The strongest candidate is
`shell.qml:712`, where `syncPluginWidgets` finds the entry-point URL unchanged
and re-registers the *cached* `existing.component` instead of building a new
one; there is also a `scanning` / `pluginReloadPending` guard that can defer a
reload. That short-circuit lives only in `syncPluginWidgets`, which is
bar-widget specific, so it would affect any bar-widget plugin rather than this
one — but that generality is unconfirmed while the cause is unconfirmed.

An earlier version of this note blamed `unloadPluginWidgets` for leaving
mounted instances alive. That was wrong: the bar slot's `registryComponent` is
a binding on `barWidgetRegistry.widgets`, so unregistering does unload the
mounted item. Recorded here because the wrong explanation is plausible enough
to be re-derived.

A full shell restart replaces the process, so it always loads from disk.

The installed plugin is a git clone whose origin is this checkout, so the
intended way to move code onto the shell is `omarchy plugin update`, which
fast-forwards it. Do **not** copy files into that directory: a copied-over
clone is permanently "locally modified", and `omarchy plugin update` then
refuses to run at all (`cannot fast-forward; you have local changes`). If that
has already happened, recover with `git -C <plugin-dir> reset --hard` and
`git clean -fd`.

The whole loop is therefore: commit, update, restart. `npm run sync` does
exactly that and then verifies it — it refuses a dirty checkout, asserts the
installed revision matches, restarts, waits for the plugin to answer, and
fails loudly on QML errors:

```bash
npm run sync
```

### The skill documents this differently

Omarchy's own agent skill (`skills/omarchy/plugins.md`) states:

> Saving a file anywhere under `~/.config/omarchy/plugins/` reloads plugin
> code automatically. If a change somehow fails to apply, force a reload with
> `omarchy-shell shell rescanPlugins`.

Neither half held for this plugin when measured, and the test wrote directly
into `~/.config/omarchy/plugins/` — the skill's own in-place workflow — so
this is not a consequence of developing out of tree. The skill does not
mention `omarchy restart shell` for plugin code anywhere.

Expect a future agent to arrive believing the skill. That is the trap: the
documented mechanism is the one that silently does nothing.

Tracked upstream — omacom/omarchy#6981 is the fullest write-up,
omacom/omarchy#8555 covers bar widgets specifically, and omacom/omarchy#9251
reports the same symptom. The cause is that `shell.qml` guards its cache clear
with `typeof Qt.clearComponentCache === "function"`, and
`QQmlEngine::clearComponentCache()` is a C++-only method that has never been
bound to the QML `Qt` object in Qt 5 or Qt 6, so the guard is always false.

### Why not the faster reload

`Quickshell.reload(false)` does pick up edited plugin QML in-process — verified
here: same PID, changed value, no restart. It is much faster than restarting
the shell, and omacom/omarchy#8766 proposes it as the upstream fix.

Do not use it in this loop on quickshell 0.3.1. That release has a confirmed
use-after-free at the `EngineGeneration` teardown boundary
(quickshell-mirror/quickshell#956). On the PR, a reviewer built 0.3.1 twice —
once with the upstream teardown fix `2d3b3e9`, once without — and the unpatched
build crashed in five of six runs when a plugin watcher drove real edits
through that path. The symbolized traces run through
`IpcHandler::updateRegistration()`, and this plugin registers an `IpcHandler`,
so it sits directly on the crashing path.

A full restart is slower and safe. Revisit once a quickshell release carrying
that teardown fix is packaged.

Never conclude anything from a rescan alone.

## Live review entry points

Projection, animation style and inspection movement are otherwise keyboard-only,
which makes them unreachable while capturing the very motion they produce.
Driving them over IPC is what makes a finding reproducible rather than a matter
of eye:

```bash
omarchy-shell rishwanth.memento-mori toggleProjection
omarchy-shell rishwanth.memento-mori toggleAnimation
omarchy-shell rishwanth.memento-mori moveInspection <dx> <dy>
omarchy-shell rishwanth.memento-mori interactionState   # read-only probe
```
