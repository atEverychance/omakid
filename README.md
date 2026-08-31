# Omakid

Omakid is a picture-first, offline-capable child desktop built as a deterministic overlay on reviewed Omarchy Quattro sources. It targets two Dell Inspiron 15-3531 (P28F005) laptops with Intel Bay Trail hardware, 4 GB RAM, 1366×768 displays, trackpads, and mechanical hard drives.

The child surface is four large activities — Painting, Letters, Games, and Stories — with pre-recorded English and Canadian French labels. A chosen animal opens the permanent colour/avatar picker. A lone Super-key release always returns home.

![First-run target](assets/mockups/first-run-target.png)

## Why an overlay

This repository does not copy Omarchy wholesale. `build/prepare.sh` validates three exact upstream revisions, overlays only Omakid-owned files, adds the reviewed Tux Paint and SDL2_Pango package recipes, and patches the current ISO local-source builder contract. Upstream revisions and AUR/source provenance are explicit in `build/upstream.env`; drift fails with an actionable error instead of producing an unreviewed image.

Prepared payload paths are package-owned:

- launcher and assets: `/usr/share/omarchy/shell/omakid`
- offline content: `/usr/share/omarchy/shell/omakid/content`
- user defaults: `/etc/skel` via current `omarchy-settings-dev`
- Chromium policy: `/etc/chromium/policies/managed/omakid.json`

## Bay Trail hardware boundary

The target uses the kernel `i915` driver and modesetting with Mesa OpenGL and the legacy `libva-intel-driver` (`i965`). It does not install the unsupported modern Intel iHD media, oneVPL, or Vulkan stacks. Omakid's four apps require OpenGL, not Vulkan.

## Local validation on macOS

```bash
./test/all
```

A static preparation test against fresh local checkouts can skip the large content mirror:

```bash
./build/prepare.sh \
  --omarchy /path/to/omarchy \
  --iso /path/to/omarchy-iso \
  --pkgs /path/to/omarchy-pkgs \
  --skip-content

OMAKID_PREPARED_OMARCHY=/path/to/omarchy \
OMAKID_PREPARED_ISO=/path/to/omarchy-iso \
OMAKID_PREPARED_PKGS=/path/to/omarchy-pkgs \
  ./test/all
```

`--skip-content` is only for static validation. It must not be used for a release ISO.

## Full x86_64 build

On x86_64 Linux with Docker:

```bash
./build/prepare.sh \
  --omarchy "$PWD/upstream/omarchy" \
  --iso "$PWD/upstream/omarchy-iso" \
  --pkgs "$PWD/upstream/omarchy-pkgs"

cd upstream/omarchy-iso
NO_BOOT_OFFER=1 ./bin/omarchy-iso-make --local-source ../omarchy ../omarchy-pkgs
sha256sum release/*.iso > release/omakid.iso.sha256
```

The GitHub Actions workflow can be run manually once it is registered on the default branch, and it also runs on pushes only to the reviewed `build/omakid-quattro-iso` branch. It has no schedule or pull-request trigger because each build is large and slow. Before it generates the checksum or uploads artifacts, `xorriso` must read the image and report both BIOS and UEFI El Torito boot entries. The workflow does not publish a release. Its local package builder builds the pinned `sdl2_pango` AUR dependency before Tux Paint, installs that exact local artifact into the package-build container for the Tux Paint build, and retains both exact packages in the target's offline mirror.

## Offline content

`build/fetch-content.sh` fails closed unless it obtains and validates:

- current date-stamped English and French GCompris voice RCCs;
- the GCompris words and OGG background-music RCCs;
- at least 40 English and 40 French Storybooks Canada titles plus narration.

Content licensing and source URLs are retained in generated and bundled attribution files.

## Advisory curfew

A native systemd timer evaluates the settled 16:00–20:00 curfew every minute by stopping or starting SDDM. There is deliberately no daily quota and no `timekpr-next` dependency. This is a family default, not a security boundary.

## Documentation

- [PRODUCT.md](PRODUCT.md) — users, purpose, product principles, and accessibility
- [DESIGN.md](DESIGN.md) — current visual and interaction system
- [plan.md](plan.md) — implemented architecture, verification, and remaining real-device work

## License

Omakid code and project documentation are MIT licensed. Bundled and fetched third-party assets retain their upstream licenses; see [assets/ATTRIBUTION.md](assets/ATTRIBUTION.md) and the generated offline-content attribution.
