#!/usr/bin/env bash
DIR="$HOME/.config/umbriel"
ACTIVE="$DIR/config.toml"
STATE_DIR="$HOME/.config/scripts/state-files"
STATE="$STATE_DIR/umbriel-state"

mkdir -p "$STATE_DIR"

CONFIGS=("$DIR"/configs/config-*.toml)
COUNT=${#CONFIGS[@]}

if [ "$COUNT" -eq 0 ]; then
  echo "No configs found in $DIR/configs"
  exit 1
fi

CURRENT=$(cat "$STATE" 2>/dev/null)
CURRENT=${CURRENT:-0}
NEXT=$(( (CURRENT + 1) % COUNT ))

cp "${CONFIGS[$NEXT]}" "$ACTIVE"
echo "$NEXT" > "$STATE"
echo "Switched to $(basename "${CONFIGS[$NEXT]}")"