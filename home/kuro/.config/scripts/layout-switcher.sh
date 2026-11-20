#!/usr/bin/env bash
DIR="$HOME/.config/noctalia"
ACTIVE="$DIR/settings.toml"
L1="$DIR/layouts/layout-1.toml"
L2="$DIR/layouts/layout-2.toml"

if cmp -s "$ACTIVE" "$L1"; then
  cp "$L2" "$ACTIVE"
  echo "Switched to layout 2"
else
  cp "$L1" "$ACTIVE"
  echo "Switched to layout 1"
fi