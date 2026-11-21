#!/usr/bin/env bash
# Install airglass for the current user: script, systemd user unit, example config.
set -euo pipefail
cd "$(dirname "$0")"

BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/airglass"

install -Dm755 airglass "$BIN_DIR/airglass"
install -Dm755 airglass-hid "$BIN_DIR/airglass-hid"
mkdir -p "$UNIT_DIR"
sed "s|@BIN@|$BIN_DIR/airglass|" airglass.service >"$UNIT_DIR/airglass.service"
sed "s|@HID@|$BIN_DIR/airglass-hid|" airglass-hid.service >"$UNIT_DIR/airglass-hid.service"
if [[ ! -f "$CONF_DIR/config" ]]; then
    install -Dm644 config.example "$CONF_DIR/config"
    echo "wrote $CONF_DIR/config"
fi
systemctl --user daemon-reload
echo "installed $BIN_DIR/airglass"
echo
"$BIN_DIR/airglass" doctor || echo "fix the FAIL lines above, then: airglass start"
