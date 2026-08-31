#!/usr/bin/env bash
# macOS-only production seed voices. Family recordings may replace these files later.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
command -v say >/dev/null || { echo "macOS say is required" >&2; exit 1; }
command -v ffmpeg >/dev/null || { echo "ffmpeg is required" >&2; exit 1; }
say -v '?' | grep -q '^Samantha ' || { echo "Samantha voice is not installed" >&2; exit 1; }
say -v '?' | grep -q '^Amélie ' || { echo "Amélie fr_CA voice is not installed" >&2; exit 1; }

generate() {
  local locale=$1 voice=$2 id=$3 phrase=$4 tmp
  mkdir -p "$root/assets/voice/$locale"
  tmp=$(mktemp "/tmp/omakid-${locale}-${id}.XXXXXX.aiff")
  say -v "$voice" -r 165 -o "$tmp" "$phrase"
  ffmpeg -hide_banner -loglevel error -y -i "$tmp" -ac 1 -ar 44100 \
    -af "loudnorm=I=-18:LRA=7:TP=-2,apad=pad_dur=0.18" -c:a pcm_s16le \
    "$root/assets/voice/$locale/$id.wav"
  rm -f "$tmp"
}

while IFS='|' read -r id en fr; do
  [[ -n "$id" ]] || continue
  generate en Samantha "$id" "$en"
  generate fr Amélie "$id" "$fr"
done <<'PHRASES'
paint|Painting|Peinture
letters|Letters|Lettres
games|Games|Jeux
stories|Stories|Histoires
me|Me|Moi
colour-pink-light|Light pink|Rose pâle
colour-blue-light|Light blue|Bleu pâle
colour-pink-bright|Bright pink|Rose vif
colour-blue-bright|Bright blue|Bleu vif
colour-purple|Purple|Violet
colour-gold|Gold|Or
avatar-orca|Orca|Orque
avatar-elephant|Elephant|Éléphant
avatar-bunny|Bunny|Lapin
avatar-jellyfish|Jellyfish|Méduse
avatar-panther|Panther|Panthère
avatar-bear|Bear|Ours
PHRASES

printf 'Generated 34 WAV labels with Samantha (en) and Amélie fr_CA (fr).\n'
