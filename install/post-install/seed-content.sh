#!/usr/bin/env bash
# Compatibility validator. Content is fetched before packaging by build/fetch-content.sh.
set -euo pipefail
root=/usr/share/omarchy/shell/omakid/content
[[ -d "$root/gcompris/voices-ogg" ]] || { echo "missing packaged GCompris content" >&2; exit 1; }
[[ -s "$root/stories/www.storybookscanada.ca/index.html" ]] || { echo "missing packaged Storybooks mirror" >&2; exit 1; }
printf 'Packaged offline content is present.\n'
