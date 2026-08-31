#!/usr/bin/env bash
set -euo pipefail

state="${XDG_STATE_HOME:-$HOME/.local/state}/omakid"
content=/usr/share/omarchy/shell/omakid/content
cache="$HOME/.cache/KDE/gcompris-qt/data3"

mkdir -p "$state" "$cache"
[[ -s "$state/lang" ]] || printf 'en\n' > "$state/lang"

if [[ ! -d "$content/gcompris" ]]; then
  echo "Omakid offline GCompris content is missing: $content/gcompris" >&2
  exit 1
fi
cp -a "$content/gcompris/." "$cache/"

stories="$content/stories/www.storybookscanada.ca"
if [[ ! -s "$stories/index.html" ]]; then
  echo "Omakid offline Stories content is missing: $stories/index.html" >&2
  exit 1
fi
