#!/usr/bin/env bash
set -euo pipefail

# Locales are generated target-side; user state is initialized in user/omakid.sh.
sed -i -E 's/^#(en_CA\.UTF-8 UTF-8)/\1/; s/^#(fr_CA\.UTF-8 UTF-8)/\1/' /etc/locale.gen
locale-gen

systemctl enable NetworkManager.service systemd-resolved.service sddm.service
systemctl enable power-profiles-daemon.service systemd-oomd.service
systemctl enable omakid-curfew.timer
systemctl mask NetworkManager-wait-online.service

# The trimmed target has neither Docker nor LocalSend, so use a minimal policy
# instead of Quattro's ufw-docker integration.
ufw default deny incoming
ufw default allow outgoing
sed -i 's/^ENABLED=.*/ENABLED=yes/' /etc/ufw/ufw.conf
systemctl enable ufw.service

# These adult/background services are not part of the Omakid target.
systemctl disable cups.service avahi-daemon.service docker.socket 2>/dev/null || true
