# Omakid ISO — implemented build plan

## Outcome

Maintain Omakid as a bounded overlay on reviewed Omarchy Quattro source, ISO-builder, and package-repository revisions. Build a bootable x86_64 ISO plus SHA256 and full VM install acceptance evidence in GitHub Actions for Dell Inspiron 15-3531 Bay Trail laptops.

## Implemented architecture

1. **Pinned upstream contract.** `build/upstream.env` records reviewed source revisions. `build/prepare.sh` validates each checkout and required Quattro paths before changing disposable upstream trees.
2. **Overlay, not fork import.** Home defaults, runtime scripts, themes, assets, system policy, install stages, and a small ISO-builder patch remain Omakid-owned files in this repository.
3. **Current Quattro integration.** The session uses `hyprland.lua` and the current `hl`/`o` Lua helpers. It does not load `default.hypr.omarchy`, so adult bindings, shell startup, lock surface, menus, and first-run toasts never start.
4. **Single shell lifecycle.** One package-owned Quickshell process contains home plus both identity screens. Its one `PanelWindow` is visible only in home/identity modes and becomes hidden before app launch.
5. **Bounded geometry.** Home is 2×2 with 320×250 targets; identity is 3×2 with 190×190 targets. Both fit fully within 1366×768, including the 88px avatar and 76×52 flag controls. The sole window explicitly owns the overlay layer and exclusive focus while visible.
6. **Stable payload.** Runtime QML, assets, and fetched offline content live under `/usr/share/omarchy/shell/omakid`. User defaults are seeded through current `omarchy-settings-dev` packaging and `/etc/skel`; scripts contain no fixed account name.
7. **Real localized assets.** Canada and Québec SVG flags are bundled. Thirty-four mono 44.1 kHz PCM WAV labels were generated with local macOS Samantha and Amélie `fr_CA` voices: four activities, Me, six colours, and six animals in each language.
8. **Offline content.** Build-time fetching parses current full date-time RCC filenames, verifies KDE-published MD5 values, and requires complete English/French Storybooks counts and audio before packaging.
9. **Offline Tux Paint chain.** The reviewed Tux Paint AUR recipe at commit `d77a0cdd57b3651a85cb719c195c4dc77fba6a89` and `sdl2_pango` recipe at AUR commit `12ec613e4e9bf14859f213e60c062604ac3b33d5` are overlaid into `omarchy-pkgs`; SDL2_Pango source is fixed to commit `3afd884fddf8d81dbe2c140135deea0c79de31c1`. The local-source builder builds `sdl2_pango` first, installs its exact artifact into the package-build container before Tux Paint dependency resolution, and retains both exact artifacts in the offline mirror while excluding both from online resolution.
10. **Native curfew.** A systemd timer enforces only the settled 16:00–20:00 advisory window. `timekpr-next` and unspecified daily quotas are absent.
11. **Trimmed target.** The target manifest retains the four apps, Hyprland/Quickshell, SDDM, NetworkManager, audio, portals, fonts, brightness, zram, and the small set of commands Quattro's current system/user finalizers execute. Bay Trail graphics use kernel `i915`/modesetting, Mesa OpenGL, and legacy i965 VA-API; unsupported iHD, oneVPL, and Vulkan packages and stages are absent. Adult development tools and irrelevant hardware service setup are removed from the target path; the firewall uses a minimal native UFW policy rather than the omitted Docker integration.
12. **Arch Chromium policy.** Policy is package-owned at `/etc/chromium/policies/managed/omakid.json`; localhost Stories is explicitly allowed.
13. **CI.** `.github/workflows/build-iso.yml` supports manual dispatch once registered on the default branch and branch-scoped pushes only for the reviewed `build/omakid-quattro-iso` branch, with no schedule or pull-request trigger; checks out exact fresh upstream revisions; prepares content/overlays; runs tests before and after preparation; builds through upstream Docker `--local-source`; uses `xorriso` to require a readable ISO with BIOS and UEFI El Torito entries before SHA256 generation; runs a mandatory KVM-backed upstream `omarchy-iso-test --install-only` gate at 4096 MiB UEFI boot; and uploads ISO, checksum, VM result JSON, harness log, and proof screenshot. It does not publish a release.

## Commands

Static local validation:

```bash
./test/all
```

Disposable source preparation without the large content mirror:

```bash
./build/prepare.sh --omarchy /path/to/omarchy --iso /path/to/omarchy-iso \
  --pkgs /path/to/omarchy-pkgs --skip-content
```

Release preparation omits `--skip-content`. Full ISO building requires x86_64 Linux and Docker; this Mac cannot provide that proof.

## Verification gates

- Shell and JSON syntax; optional WAV codec inspection with `ffprobe`.
- Required flags/audio and exact clip inventory.
- Bare package manifests, the bounded Bay Trail Mesa/i965 stack, and absence of unsupported modern Intel graphics/media packages.
- An ISO workflow supporting manual dispatch once registered on the default branch plus pushes only to `build/omakid-quattro-iso`, with no schedule or pull-request trigger, with `xorriso` BIOS and UEFI El Torito gates before checksum/upload, and a mandatory 4096 MiB KVM/UEFI `omarchy-iso-test --install-only` VM gate whose pass artifacts are uploaded with the ISO (result JSON, harness log, screenshot).
- Current Quattro Lua wiring, locked Home/media/brightness bindings, one PanelWindow, and bounded geometry.
- Stable paths, current Chromium policy path, RCC date-time matching, pinned Tux Paint/SDL2_Pango provenance, and no unresolved markers in shipped paths.
- Prepared-source contracts for runtime payload, setup form, package manifests, SDL2_Pango-before-Tux-Paint build/install handoff, exact offline artifact retention, online-resolution filtering, and fetched offline content.
- `git diff --check` and repository status review.

## Remaining physical gates

These cannot be claimed until an authorized CI build and the two laptops are available:

1. Build and boot the ISO; verify installer completion and SHA256.
2. Confirm Bay Trail iGPU rendering, trackpad tap/drag behavior, Wi-Fi/audio/brightness keys, SDDM autologin, and Super-only Home on both keyboards.
3. Audit the actual 1366×768 launcher and identity screens visually on-device.
4. Disable Wi-Fi and open all four activities, English/French audio, and representative Storybooks narration.
5. Observe HDD boot/app-launch latency and memory pressure for a week on laptop A before installing laptop B.

## Non-goals

- No commit, push, CI dispatch, release, or publication from the implementation pass.
- No password-dependent child flow, full-disk-encryption decision, or daily screen-time quota.
- No claim of real-device performance before physical testing.
