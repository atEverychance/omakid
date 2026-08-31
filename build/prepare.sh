#!/usr/bin/env bash
# Apply the bounded Omakid overlay to exact, fresh upstream checkouts.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck disable=SC1091
source "$root/build/upstream.env"
omarchy=
iso=
pkgs=
fetch_content=1
check_revisions=1

usage() {
  cat <<'USAGE'
Usage: build/prepare.sh --omarchy PATH --iso PATH --pkgs PATH [--skip-content] [--skip-revision-check]

The three paths are disposable upstream checkouts. They are modified in place.
--skip-content exists only for static overlay tests; an ISO prepared that way is incomplete.
USAGE
}

while (( $# )); do
  case "$1" in
    --omarchy) omarchy=${2:-}; shift 2 ;;
    --iso) iso=${2:-}; shift 2 ;;
    --pkgs) pkgs=${2:-}; shift 2 ;;
    --skip-content) fetch_content=0; shift ;;
    --skip-revision-check) check_revisions=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

for value in omarchy iso pkgs; do
  path=${!value}
  git -C "$path" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "$value is not a git checkout: $path" >&2
    exit 1
  }
done

verify_revision() {
  local checkout=$1 expected=$2 name=$3 actual
  actual=$(git -C "$checkout" rev-parse HEAD)
  [[ $actual == "$expected" ]] || {
    echo "$name revision mismatch: expected $expected, got $actual" >&2
    echo "Review upstream drift and update build/upstream.env deliberately." >&2
    exit 1
  }
}

if (( check_revisions )); then
  verify_revision "$omarchy" "$OMARCHY_REF" omarchy
  verify_revision "$iso" "$OMARCHY_ISO_REF" omarchy-iso
  verify_revision "$pkgs" "$OMARCHY_PKGS_REF" omarchy-pkgs
fi

for required in \
  "$omarchy/config/hypr/hyprland.lua" \
  "$omarchy/install/omarchy-base.packages" \
  "$omarchy/install/provisioning/setup-form.sh" \
  "$iso/builder/build-iso.sh" \
  "$iso/builder/build-omarchy-packages.sh" \
  "$pkgs/pkgbuilds/omarchy-dev/PKGBUILD"; do
  [[ -f "$required" ]] || { echo "upstream contract missing: $required" >&2; exit 1; }
done

# User defaults: settings package seeds these through /etc/skel and keeps the
# same tree under /usr/share/omarchy/config for explicit refreshes.
cp -a "$root/home/.config/." "$omarchy/config/"

# Runtime package payload. QML lives both in the source overlay and this stable,
# package-owned execution path; assets are never resolved through a repo checkout.
rm -rf "$omarchy/shell/omakid"
mkdir -p "$omarchy/shell/omakid"
cp -a "$root/home/.config/quickshell/omakid/." "$omarchy/shell/omakid/"
cp -a "$root/assets" "$omarchy/shell/omakid/assets"

cp -a "$root"/bin/omakid-* "$omarchy/bin/"
chmod 0755 "$omarchy"/bin/omakid-*
cp -a "$root/themes/." "$omarchy/themes/"

# Quattro target stages and bounded Dell hardware/package manifests.
cp "$root/install/omakid-base.packages" "$omarchy/install/omarchy-base.packages"
cp "$root/install/omakid-other.packages" "$omarchy/install/omarchy-other.packages"
cp "$root/install/config/all.sh" "$omarchy/install/config/all.sh"
cp "$root/install/config/omakid.sh" "$omarchy/install/config/omakid.sh"
cp "$root/install/user/all.sh" "$omarchy/install/user/all.sh"
cp "$root/install/user/omakid.sh" "$omarchy/install/user/omakid.sh"
cp "$root/install/hardware/all.sh" "$omarchy/install/hardware/all.sh"
chmod 0755 "$omarchy/install/config/omakid.sh" "$omarchy/install/user/omakid.sh"

# Package-owned system policy and timers. omarchy-settings copies source etc/.
cp -a "$root/system/etc/." "$omarchy/etc/"

if (( fetch_content )); then
  "$root/build/fetch-content.sh" "$omarchy/shell/omakid/content"
else
  echo "WARNING: content fetch skipped; this prepared tree must not be used to build a release ISO." >&2
fi

# Reviewed AUR recipes are built in dependency order in the ISO container and
# inserted into its local offline mirror alongside local-source Omarchy packages.
for package_name in sdl2_pango tuxpaint; do
  rm -rf "$pkgs/pkgbuilds/$package_name"
  mkdir -p "$pkgs/pkgbuilds/$package_name"
  cp -a "$root/packages/$package_name/." "$pkgs/pkgbuilds/$package_name/"
done

patch="$root/build/patches/omarchy-iso-local-packages.patch"
if git -C "$iso" apply --check "$patch" 2>/dev/null; then
  git -C "$iso" apply "$patch"
elif git -C "$iso" apply --reverse --check "$patch" 2>/dev/null; then
  : # already prepared
else
  echo "omarchy-iso builder contract drifted; patch no longer applies cleanly: $patch" >&2
  exit 1
fi

printf 'Prepared Omakid local sources:\n  omarchy: %s\n  iso: %s\n  packages: %s\n' "$omarchy" "$iso" "$pkgs"
