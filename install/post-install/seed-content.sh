#!/usr/bin/env bash
# Seed offline content so the laptops work in the car with no signal.
set -euo pipefail
KID=${OMAKID_USER:-kid}
KID_HOME=$(getent passwd "$KID" | cut -d: -f6)

# --- GCompris voices + words + music (per-locale .rcc bundles) ------
CDN=https://cdn.kde.org/gcompris/data3
CACHE="$KID_HOME/.cache/KDE/gcompris-qt/data3"

mkdir -p "$CACHE/voices-ogg"
curl -sfL "$CDN/voices-ogg/Contents" -o "$CACHE/voices-ogg/Contents"
for loc in en fr; do
  RCC=$(grep -oE "voices-${loc}-[0-9]+\.rcc" "$CACHE/voices-ogg/Contents" | head -1)
  [[ -n "$RCC" ]] && curl -sfL "$CDN/voices-ogg/$RCC" -o "$CACHE/voices-ogg/$RCC"
done

for bundle in words backgroundMusic; do
  mkdir -p "$CACHE/$bundle"
  curl -sfL "$CDN/$bundle/Contents" -o "$CACHE/$bundle/Contents"
  RCC=$(grep -oE "[a-zA-Z]+-(webp|ogg|mp3)-[0-9]+\.rcc" "$CACHE/$bundle/Contents" | head -1)
  [[ -n "$RCC" ]] && curl -sfL "$CDN/$bundle/$RCC" -o "$CACHE/$bundle/$RCC"
done
chown -R "$KID:$KID" "$KID_HOME/.cache"

# --- Storybooks Canada mirror (CC BY 4.0, EN+FR line-level audio) ---
mkdir -p /var/lib/omakid/stories
wget --mirror --convert-links --adjust-extension --page-requisites \
     --no-parent -q -P /var/lib/omakid/stories \
     https://www.storybookscanada.ca/ || \
  echo "WARN: story mirror incomplete, rerun when online"

echo "content seeded."
