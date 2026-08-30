#!/usr/bin/env bash
# Install this checkout into the live Omarchy plugin directory and prove the
# running component is the one just installed.
#
# Why this exists: `omarchy-shell shell rescanPlugins` does NOT reliably reload
# changed QML. The previously loaded component keeps running, so a probe or a
# screenshot reports the OLD behaviour while the files on disk are new. That
# has produced false "verified live" conclusions more than once. A full shell
# restart replaces the process, so it always loads from disk — this script
# therefore always restarts and never trusts a rescan.
set -euo pipefail

PLUGIN_ID="rishwanth.memento-mori"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${HOME}/.config/omarchy/plugins/${PLUGIN_ID}"
FILES=(LifeView.qml LifeRail.qml Panel.qml BarWidget.qml MorphingLabel.qml Model.js manifest.json)

[ -d "$DEST" ] || { echo "FAIL: no installed plugin at $DEST"; exit 1; }

echo "==> install"
for f in "${FILES[@]}"; do
  install -m 0644 "$SRC/$f" "$DEST/$f"
done

echo "==> byte parity"
for f in "${FILES[@]}"; do
  cmp -s "$SRC/$f" "$DEST/$f" || { echo "FAIL: $f differs after install"; exit 1; }
done
echo "    all ${#FILES[@]} files identical"

echo "==> restart shell (rescan alone is not sufficient)"
omarchy restart shell >/dev/null 2>&1
for _ in $(seq 1 30); do
  sleep 0.5
  if omarchy-shell "$PLUGIN_ID" interactionState >/dev/null 2>&1; then
    break
  fi
done

echo "==> probe"
STATE="$(omarchy-shell "$PLUGIN_ID" interactionState 2>/dev/null || true)"
case "$STATE" in
  ''|'{}'|*'not found'*) echo "FAIL: plugin did not come back up"; exit 1 ;;
esac
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
echo "OK: live plugin matches this checkout"
