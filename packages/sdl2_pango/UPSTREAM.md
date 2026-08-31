AUR source: https://aur.archlinux.org/packages/sdl2_pango
Reviewed AUR commit: 12ec613e4e9bf14859f213e60c062604ac3b33d5
Reviewed: 2026-08-31
Upstream source: https://github.com/markuskimius/SDL2_Pango
Pinned upstream commit: 3afd884fddf8d81dbe2c140135deea0c79de31c1 (SDL2_Pango 2.1.5)
License: LGPL-2.1-only; upstream `COPYING` at the pinned commit has SHA256 `a190dc9c8043755d90f8b0a75fa66b9e42d4af4c980bf5ddc633f0124db3cee7`.
Contributors: AUR packaging contributors are retained verbatim in `PKGBUILD`; upstream authors and Debian/SDL2 port contributors remain in `AUTHORS` at the pinned source commit.
Review notes: The recipe is the pinned AUR recipe with only checksum hardening and explanatory comments. makepkg does not checksum VCS sources, so that entry remains `SKIP`; the source URL uses the exact 40-character commit in both `_commit` and `#commit=`, while the vendored `freetype2.patch` uses its real SHA256.
