#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLASMOID_DIR="$SCRIPT_DIR/plasmoid"
PLUGIN_ID="com.github.nhilo94.pcmonitor"
OLD_PLUGIN_ID="com.asus.batterymonitor"
INSTALL_DIR="$HOME/.local/share/plasma/plasmoids"

echo "=== PC Monitor — KDE Plasma 6 Widget ==="

# Remove old Plasma 5 versions if present
for old in "$OLD_PLUGIN_ID" "$PLUGIN_ID"; do
    if [ -d "$INSTALL_DIR/$old" ]; then
        echo "Removing previous version ($old)..."
        rm -rf "$INSTALL_DIR/$old"
    fi
    rm -rf "$HOME/.local/share/kpackage/generic/$old"
done

# Remove any previous Plasma 6 kpackagetool install
if command -v kpackagetool6 &>/dev/null; then
    echo "Removing previous Plasma 6 install (if any)..."
    kpackagetool6 -t Plasma/Applet -r "$PLUGIN_ID" 2>/dev/null || true
fi

echo "Installing widget..."
kpackagetool6 -t Plasma/Applet -i "$PLASMOID_DIR" 2>/dev/null \
    || {
        echo "Trying direct install..."
        mkdir -p "$INSTALL_DIR"
        cp -r "$PLASMOID_DIR" "$INSTALL_DIR/$PLUGIN_ID"
    }

echo ""
echo "Done! Restart the plasma shell with:"
echo "  kquitapp6 plasmashell && kstart6 plasmashell"
echo ""
echo "Then add the widget:"
echo "  Right-click panel/desktop → Add Widgets → search 'PC Monitor'"
echo ""
echo "To uninstall:"
echo "  kpackagetool6 -t Plasma/Applet -r $PLUGIN_ID"
echo "  # or: rm -rf $INSTALL_DIR/$PLUGIN_ID"
echo ""

# ── Build .plasmoid archive for KDE Store upload ───────────────────────────
if command -v zip &>/dev/null; then
    OUT="$SCRIPT_DIR/pc-monitor.plasmoid"
    rm -f "$OUT"
    (cd "$PLASMOID_DIR" && zip -r "$OUT" . -x "*.git*")
    echo "Package ready for KDE Store: $OUT"
fi
