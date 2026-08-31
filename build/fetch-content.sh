#!/usr/bin/env bash
# Fetch validated offline payloads into a prepared Omarchy source tree.
set -euo pipefail

out=${1:?usage: fetch-content.sh OUTPUT_DIRECTORY}
case "$out" in /|"") echo "unsafe output directory: $out" >&2; exit 2 ;; esac
command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }
command -v wget >/dev/null || { echo "wget is required" >&2; exit 1; }
command -v openssl >/dev/null || { echo "openssl is required" >&2; exit 1; }

parent=$(dirname "$out")
mkdir -p "$parent"
tmp=$(mktemp -d "$parent/.omakid-content.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
cdn=https://cdn.kde.org/gcompris/data3

md5_file() {
  openssl dgst -md5 "$1" | awk '{print $NF}'
}

fetch_from_contents() {
  local section=$1 pattern=$2 destination=$3
  local contents="$tmp/gcompris/$section/Contents"
  mkdir -p "$(dirname "$contents")"
  curl --fail --silent --show-error --location "$cdn/$section/Contents" -o "$contents"

  local filename expected actual
  filename=$(grep -Eo "$pattern" "$contents" | head -n 1 || true)
  [[ -n "$filename" ]] || { echo "No file matching $pattern in $section/Contents" >&2; exit 1; }
  expected=$(awk -v name="$filename" '$2 == name { print $1; exit }' "$contents")
  [[ $expected =~ ^[0-9a-fA-F]{32}$ ]] || { echo "No MD5 for $section/$filename" >&2; exit 1; }

  mkdir -p "$tmp/gcompris/$destination"
  curl --fail --silent --show-error --location "$cdn/$section/$filename" -o "$tmp/gcompris/$destination/$filename"
  actual=$(md5_file "$tmp/gcompris/$destination/$filename" | tr '[:upper:]' '[:lower:]')
  expected=$(printf '%s' "$expected" | tr '[:upper:]' '[:lower:]')
  [[ $actual == "$expected" ]] || { echo "Checksum mismatch for $section/$filename" >&2; exit 1; }
}

# Current Contents names are date-stamped through seconds; do not assume a bare numeric suffix.
fetch_from_contents voices-ogg 'voices-en-[0-9]{4}(-[0-9]{2}){5}\.rcc' voices-ogg
fetch_from_contents voices-ogg 'voices-fr-[0-9]{4}(-[0-9]{2}){5}\.rcc' voices-ogg
fetch_from_contents words 'words-webp-[0-9]{4}(-[0-9]{2}){5}\.rcc' words
fetch_from_contents backgroundMusic 'backgroundMusic-ogg-[0-9]{4}(-[0-9]{2}){5}\.rcc' backgroundMusic

mkdir -p "$tmp/stories"
# Mirror the complete target-language shelf, narration, images, and site runtime.
# The upstream site's all-language editions/PDF corpus exceeds 7 GB and is not
# part of the Omakid English/French kiosk; filtering keeps the ISO build bounded.
story_accept='^https://www\.storybookscanada\.ca/($|stories/(en|fr)(/.*)?$|audio/(en|fr)/.*|images/.*|css/.*|js/.*|files/.*|favicon.*|apple-touch-icon.*|site\.webmanifest.*)'
wget --mirror --convert-links --adjust-extension --page-requisites --no-parent \
  --domains www.storybookscanada.ca --accept-regex "$story_accept" \
  --directory-prefix "$tmp/stories" --quiet \
  https://www.storybookscanada.ca/ https://www.storybookscanada.ca/stories/fr/

story_root="$tmp/stories/www.storybookscanada.ca"
[[ -s "$story_root/index.html" ]] || { echo "Storybooks mirror has no index.html" >&2; exit 1; }
en_count=$(find "$story_root/stories/en" -mindepth 2 -maxdepth 2 -name index.html -type f | wc -l | tr -d ' ')
fr_count=$(find "$story_root/stories/fr" -mindepth 2 -maxdepth 2 -name index.html -type f | wc -l | tr -d ' ')
audio_count=$(find "$story_root/audio" -type f \( -name '*.mp3' -o -name '*.ogg' \) | wc -l | tr -d ' ')
(( en_count >= 40 )) || { echo "Storybooks mirror incomplete: only $en_count English stories" >&2; exit 1; }
(( fr_count >= 40 )) || { echo "Storybooks mirror incomplete: only $fr_count French stories" >&2; exit 1; }
(( audio_count >= 80 )) || { echo "Storybooks mirror incomplete: only $audio_count audio files" >&2; exit 1; }

cat > "$tmp/ATTRIBUTION.md" <<'ATTRIBUTION'
# Offline content attribution

- GCompris data bundles are fetched from KDE's GCompris CDN and verified against the MD5 values in each published `Contents` file. GCompris is licensed under GPL-3.0-or-later; individual data may retain additional author notices inside the bundles. Source: https://cdn.kde.org/gcompris/data3/
- The complete English/French Storybooks Canada shelf, narration, images, and site runtime are mirrored from https://www.storybookscanada.ca/. The unrelated all-language PDF/edition export corpus is intentionally excluded from the child kiosk. Stories are published under Creative Commons Attribution 4.0 unless an individual story states otherwise. Story and illustrator credits remain in each mirrored page. Project source and usage details: https://www.storybookscanada.ca/about/ and https://creativecommons.org/licenses/by/4.0/
ATTRIBUTION

rm -rf "$out"
mv "$tmp" "$out"
trap - EXIT
printf 'Offline content ready: %s English stories, %s French stories, %s audio files.\n' "$en_count" "$fr_count" "$audio_count"
