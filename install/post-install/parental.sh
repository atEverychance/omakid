#!/usr/bin/env bash
# Compatibility entrypoint; package install stages own the advisory layer.
set -euo pipefail
systemctl enable systemd-resolved.service omakid-curfew.timer
printf 'Omakid advisory defaults are package-owned and enabled.\n'
