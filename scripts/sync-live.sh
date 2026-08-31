#!/usr/bin/env bash
# Put the committed state of this checkout onto the live shell, and prove the
# running component is that state.
#
# Two things this exists to get right:
#
# 1. Use Omarchy's own update path. The installed plugin is a git clone whose
#    origin is this checkout, so `omarchy plugin update` fast-forwards it.
#    Copying files over that clone leaves it permanently "locally modified",
#    which BLOCKS `omarchy plugin update` from then on. Do not copy.
#
# 2. Always restart the shell. `rescanPlugins` does not reload changed
#    bar-widget QML — the shell logs "Local plugin changed, reloading" and
#    then keeps serving the old component, so a probe or screenshot reports
#    the OLD behaviour while the files on disk are new. Nothing in the probe
#    output reveals it. A restart replaces the process, so it always loads
#    from disk. See docs/development.md.
set -euo pipefail

PLUGIN_ID="rishwanth.memento-mori"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${HOME}/.config/omarchy/plugins/${PLUGIN_ID}"

[ -d "$DEST" ] || { echo "FAIL: no installed plugin at $DEST"; exit 1; }

if [ -n "$(git -C "$SRC" status --porcelain)" ]; then
  echo "FAIL: checkout has uncommitted changes."
  echo "      plugin update pulls commits, so commit first."
  git -C "$SRC" status --short
  exit 1
fi

echo "==> omarchy plugin update"
omarchy plugin update "$PLUGIN_ID" --yes 2>&1 | sed 's/^/    /'

echo "==> installed revision"
SRC_REV="$(git -C "$SRC" rev-parse HEAD)"
DEST_REV="$(git -C "$DEST" rev-parse HEAD)"
echo "    checkout  ${SRC_REV:0:7}"
echo "    installed ${DEST_REV:0:7}"
[ "$SRC_REV" = "$DEST_REV" ] || { echo "FAIL: installed revision does not match"; exit 1; }
[ -z "$(git -C "$DEST" status --porcelain)" ] || {
  echo "FAIL: installed clone is dirty — plugin update will keep refusing."
  echo "      recover with: git -C \"$DEST\" reset --hard && git -C \"$DEST\" clean -fd"
  exit 1
}

echo "==> restart shell (rescan does not reload bar-widget QML)"
omarchy restart shell >/dev/null 2>&1
for _ in $(seq 1 30); do
  sleep 0.5
  omarchy-shell "$PLUGIN_ID" interactionState >/dev/null 2>&1 && break
done

echo "==> probe"
STATE="$(omarchy-shell "$PLUGIN_ID" interactionState 2>/dev/null || true)"
case "$STATE" in ''|'{}'|*'not found'*) echo "FAIL: plugin did not come back up"; exit 1 ;; esac
STATE="$STATE" python3 -c '
import json, os
d = json.loads(os.environ["STATE"])
print("    live: projection=%s grid=%sx%.1f cell=%.2f"
      % (d["projection"], d["gridWidth"], d["gridHeight"], d["cellWidth"]))
'

echo "==> QML errors since restart"
PID="$(pgrep -f 'quickshell -n -p /usr/share/omarchy/shell' | head -1 || true)"
if [ -n "$PID" ]; then
  ERR="$(journalctl _PID="$PID" --since '-40s' --no-pager 2>/dev/null \
    | grep -iE 'TypeError|ReferenceError|is not a function|binding loop' || true)"
  [ -z "$ERR" ] || { echo "FAIL: QML errors"; echo "$ERR"; exit 1; }
fi
echo "    none"
echo "OK: live plugin is ${SRC_REV:0:7}"
