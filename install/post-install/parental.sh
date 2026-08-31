#!/usr/bin/env bash
# Advisory parental layer. Speed bumps, not walls.
#
# DESIGN DECISION: the kid account keeps sudo. If either of them works out
# how to escalate and dismantle this, that is a milestone, not a breach.
# Nothing here should be load-bearing for actual safety.
set -euo pipefail

# --- DNS filtering at the OS layer, so it follows the laptop --------
# Set your resolver in system/etc/systemd/resolved.conf.d/omakid-dns.conf
systemctl enable --now systemd-resolved
chattr +i /etc/resolv.conf 2>/dev/null || true

# --- screen time + curfew -------------------------------------------
# Curfew respects the 4-8pm family block: laptops should be OFF then.
systemctl enable --now timekpr 2>/dev/null || true

# --- menu surgery ----------------------------------------------------
# Not a lock. Keeps the grid the obvious path rather than a maze.
echo "TODO: strip terminal / pkg-install / AUR entries from omarchy-menu"

echo "parental layer applied (advisory)."
