#!/usr/bin/env bash
# Both locales must exist before the language toggle can work.
set -euo pipefail
sed -i 's/^#en_CA.UTF-8/en_CA.UTF-8/;s/^#fr_CA.UTF-8/fr_CA.UTF-8/' /etc/locale.gen
locale-gen
mkdir -p "$HOME/.local/state/omakid"
echo en > "$HOME/.local/state/omakid/lang"
