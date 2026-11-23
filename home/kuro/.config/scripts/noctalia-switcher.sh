#!/usr/bin/env bash
DIR="$HOME/.config/noctalia"
ACTIVE="$DIR/settings.toml"
STATE_DIR="$HOME/.config/scripts/state-files"
STATE="$STATE_DIR/noctalia-state"

mkdir -p "$STATE_DIR"

LAYOUTS=("$DIR"/layouts/layout-*.toml)
COUNT=${#LAYOUTS[@]}

if [ "$COUNT" -eq 0 ]; then
  echo "No layouts found in $DIR/layouts"
  exit 1
fi

CURRENT=$(cat "$STATE" 2>/dev/null)
CURRENT=${CURRENT:-0}
NEXT=$(( (CURRENT + 1) % COUNT ))

cp "${LAYOUTS[$NEXT]}" "$ACTIVE"
echo "$NEXT" > "$STATE"
echo "Switched to $(basename "${LAYOUTS[$NEXT]}")"