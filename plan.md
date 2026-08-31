# Omakid — Build Plan

A kid-first Linux distribution for pre-readers, forked from [Omarchy](https://omarchy.org).

**Target:** two old x86_64 laptops, trackpad only, two girls aged 6 and 7 who don't read yet, English and Canadian French.

**Acceptance criterion:** `assets/mockups/first-run-target.png`. If first boot looks like that and the tiles talk, it works.

---

## 0. Design axioms

1. **Nothing requires reading.** Every affordance is a picture that speaks its own name.
2. **One app, fullscreen, always.** Window management is an adult concept.
3. **One way home.** A single physical key returns to the grid, from anywhere, always.
4. **Five tiles maximum.** More choice is not more capability at six years old.
5. **Updates are manual.** No timers, no daemons, nothing to debug at bedtime.
6. **The locks are speed bumps, not walls.** See §11.
7. **Choice creates ownership.** She picks her colour and her animal, and can change them forever. See §7.

---

## 1. Fork points

Omarchy splits into an installer and an ISO builder. Fork the installer, point the builder at your fork with one env var.

```bash
git clone https://github.com/omacom-io/omarchy-iso
cd omarchy-iso
OMARCHY_INSTALLER_REPO="atEverychance/omakid" \
OMARCHY_INSTALLER_REF="master" \
./bin/omarchy-iso-make
```

Output: `./release/omakid-*.iso`. Test without burning: `./bin/omarchy-iso-boot release/omakid-*.iso`

Local builds can skip GitHub entirely with `--local-source`, which uses `$OMARCHY_PATH` instead of cloning.

Keep the plumbing — archinstall, btrfs, Limine, snapper, offline package mirrors, unattended provisioning. Replace the shell entirely, because Omarchy's UX is fuzzy-search text entry, and that's a literacy tax a pre-reader can't pay.

**Hard gates** from `preflight/guard.sh`: x86_64 only, btrfs root mandatory, Limine bootloader, Secure Boot disabled, no pre-existing GNOME/KDE. You're wiping, not converting.

**Skip full-disk encryption.** `Ctrl+C` at the disk confirmation switches to an encryption-less install. A LUKS passphrase on a machine operated by a non-reader is a support ticket every morning. The FDE unlock screen also has no Bluetooth keyboard support.

---

## 2. Repo layout

```
omakid/
├── plan.md                            # this file
├── install/
│   ├── omakid-base.packages           # trimmed from omarchy-base.packages
│   ├── config/
│   │   ├── branding.sh                # their names, their colours
│   │   └── locale.sh                  # en_CA + fr_CA
│   └── post-install/
│       ├── seed-content.sh            # GCompris voices, story mirror
│       └── parental.sh                # DNS, timekpr, chrome policy
├── bin/
│   ├── omakid-apply                   # §11
│   ├── omakid-check                   # §11
│   ├── omakid-launch                  # locale wrapper, §8
│   ├── omakid-me                      # the Me picker, §7
│   ├── omakid-set-identity            # colour/avatar/name, §7
│   ├── omakid-home                    # return to grid
│   ├── omakid-stories                 # kiosk story shelf, §8
│   └── omakid-record-letters          # your voice, §9
├── home/                              # symlinked into her ~
│   ├── .config/hypr/omakid.conf
│   ├── .config/omakid/tiles.json
│   ├── .config/omakid/identity.json   # six colours, six animals
│   ├── .config/omakid/klettresrc.{en,fr}
│   ├── .config/quickshell/omakid/{shell,Tile}.qml
│   └── .config/quickshell/omakid-me/shell.qml
├── system/                            # copied, root-owned
│   ├── etc/opt/chrome/policies/managed/omakid.json
│   └── etc/systemd/resolved.conf.d/omakid-dns.conf
├── themes/omakid-{green,blue,purple,pink,orange,yellow}/colors.toml
├── assets/
│   ├── icons/{paint,letters,games,stories}.png
│   ├── avatars/{fox,owl,whale,bee,cat,horse}.png
│   ├── flags/{en,fr}.png
│   ├── voice/{en,fr}/*.wav
│   ├── klettres/{en-ca,fr-ca}/{alpha,syllab}/*.ogg
│   └── mockups/
└── local/                             # gitignored: names, DNS IDs, secrets
```

**The split is the whole simplification.** `home/` gets symlinked, so editing a tile in the repo is live immediately — no apply, no re-login. Only `system/` needs copying, and that's the only reason `omakid-apply` exists.

---

## 3. Packages

Both anchor apps are in official Arch **Extra**. That's a genuine gift — the ISO won't break when an AUR maintainer walks away.

| Package | Repo | Why |
|---|---|---|
| `gcompris-qt` | **Extra** | 100+ activities, ages 2–10, incl. mouse/keyboard discovery and reading |
| `klettres` | **Extra** | Alphabet→syllables, dedicated kid mode, ships EN and FR sounds by default |
| `tuxpaint` | AUR | Pin the commit |
| `quickshell` | AUR/Extra | The grid |
| `pipewire`, `wireplumber` | Extra | Everything speaks |
| `espeak-ng` | Extra | Fallback TTS only |
| `timekpr-next` | AUR | Screen-time quotas + curfew |
| `brightnessctl` | Extra | Brightness keys |

**Strip from `omarchy-base.packages`:** neovim, docker, lazygit, lazydocker, gh, mise, all dev TUIs. You're deleting roughly half the list. Delete `install/config/git.sh` outright — no seven-year-old needs `git config --global user.email`.

---

## 4. Locales

`install/config/locale.sh`:

```bash
sed -i 's/^#en_CA.UTF-8/en_CA.UTF-8/;s/^#fr_CA.UTF-8/fr_CA.UTF-8/' /etc/locale.gen
locale-gen
```

Both must exist before the language toggle can do anything.

---

## 5. The picture grid

`home/.config/omakid/tiles.json` — adding a tile is a five-line edit:

```json
{
  "tiles": [
    { "id": "paint",   "icon": "paint.png",   "exec": "tuxpaint",
      "label": { "en": "Painting", "fr": "Peinture" } },
    { "id": "letters", "icon": "letters.png", "exec": "klettres",
      "label": { "en": "Letters",  "fr": "Lettres"  } },
    { "id": "games",   "icon": "games.png",   "exec": "gcompris-qt",
      "label": { "en": "Games",    "fr": "Jeux"     } },
    { "id": "stories", "icon": "stories.png", "exec": "omakid-stories",
      "label": { "en": "Stories",  "fr": "Histoires"} }
  ]
}
```

`home/.config/quickshell/omakid/shell.qml`:

```qml
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    property string lang: "en"
    property var tiles: []
    readonly property string assets: Quickshell.env("OMAKID_ASSETS")
                                     || "/usr/share/omakid/assets"

    // --- state: which language ---------------------------------------
    FileView {
        id: langFile
        path: Quickshell.env("HOME") + "/.local/state/omakid/lang"
        watchChanges: true
        onLoaded: root.lang = (text().trim() || "en")
        onFileChanged: reload()
    }

    // --- tile definitions --------------------------------------------
    FileView {
        id: tileFile
        path: Quickshell.env("HOME") + "/.config/omakid/tiles.json"
        watchChanges: true
        onLoaded: {
            try { root.tiles = JSON.parse(text()).tiles }
            catch (e) { console.warn("tiles.json invalid:", e) }
        }
        onFileChanged: reload()
    }

    // --- audio label: pre-recorded wav, not synthesized --------------
    Process { id: speaker; command: [] }

    function speak(id) {
        speaker.running = false
        speaker.command = ["paplay",
            `${root.assets}/voice/${root.lang}/${id}.wav`]
        speaker.running = true
    }

    function launch(exec) {
        Quickshell.execDetached(["omakid-launch", exec])
    }

    function setLang(l) {
        Quickshell.execDetached(["sh", "-c",
            `mkdir -p ~/.local/state/omakid && echo ${l} > ~/.local/state/omakid/lang`])
    }

    PanelWindow {
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        color: "#0f4c4c"

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#0d4a4a" }
                GradientStop { position: 1.0; color: "#17635c" }
            }
        }

        // --- language flags, top right -------------------------------
        RowLayout {
            anchors { top: parent.top; right: parent.right; margins: 32 }
            spacing: 12
            Repeater {
                model: ["en", "fr"]
                Rectangle {
                    width: 76; height: 52; radius: 10
                    color: "transparent"
                    border.width: root.lang === modelData ? 3 : 0
                    border.color: "#ffffff"
                    opacity: root.lang === modelData ? 1.0 : 0.45
                    Image {
                        anchors.fill: parent
                        anchors.margins: 4
                        source: `${root.assets}/flags/${modelData}.png`
                        fillMode: Image.PreserveAspectFit
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setLang(modelData)
                    }
                }
            }
        }

        // --- the grid ------------------------------------------------
        RowLayout {
            anchors.centerIn: parent
            spacing: 64
            Repeater {
                model: root.tiles
                Tile {
                    tileId:  modelData.id
                    iconSrc: `${root.assets}/icons/${modelData.icon}`
                    label:   modelData.label[root.lang]
                    onEntered:   root.speak(modelData.id)
                    onActivated: root.launch(modelData.exec)
                }
            }
        }
    }
}
```

`home/.config/quickshell/omakid/Tile.qml`:

```qml
import QtQuick

Item {
    id: tile
    property string tileId
    property string iconSrc
    property string label

    signal entered()
    signal activated()

    width: 300; height: 380

    Column {
        anchors.centerIn: parent
        spacing: 24

        Rectangle {
            width: 260; height: 260; radius: 40
            color: "transparent"
            border.width: ma.containsMouse ? 6 : 0
            border.color: "#ffffff"
            scale: ma.containsMouse ? 1.06 : 1.0
            Behavior on scale { NumberAnimation { duration: 140 } }

            Image {
                anchors.fill: parent
                source: tile.iconSrc
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tile.label
            color: "#ffffff"
            font { pixelSize: 40; weight: Font.DemiBold }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: tile.entered()
        onClicked: tile.activated()
    }
}
```

Two notes. **Quickshell's API moves** — verify `FileView`, `Process`, and `execDetached` signatures against the installed version; the shapes are right but property names drift. And **pre-record the labels as WAVs rather than synthesizing live.** `espeak-ng` French through a 2012 laptop speaker is a rough introduction to a language.

---

## 6. `home/.config/hypr/omakid.conf`

Sourced *last* from `hyprland.conf` so it wins by load order and survives Omarchy config refreshes:

```
source = ~/.config/hypr/omakid.conf
```

```bash
# ---- every app fullscreen, no exceptions ----------------------------
windowrulev2 = fullscreen, class:.*
windowrulev2 = noborder,   class:.*

# ---- trackpad: tuned for small hands on old hardware ---------------
input {
    sensitivity = -0.3
    accel_profile = flat
    touchpad {
        tap-to-click = true
        tap-and-drag = true
        drag_lock = true
        disable_while_typing = false
        clickfinger_behavior = false
        middle_button_emulation = false
        natural_scroll = false
        scroll_factor = 0.4
    }
}

gestures { workspace_swipe = false }
misc {
    middle_click_paste = false
    disable_hyprland_logo = true
}

# ---- visibility -----------------------------------------------------
env = XCURSOR_SIZE,48
env = GDK_DPI_SCALE,1.3
env = QT_SCALE_FACTOR,1.2

# ---- the only bindings that exist ----------------------------------
bind  = SUPER, code:0, exec, omakid-home    # Super alone = go home
bindl = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_SINK@ 5%+ -l 0.85
bindl = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_SINK@ 5%-
bindl = , XF86MonBrightnessUp,   exec, brightnessctl set 10%+
bindl = , XF86MonBrightnessDown, exec, brightnessctl set 10%-

# no close-window, no exit, no workspaces, no terminal
```

Three settings matter more than the rest:

- **`tap-to-click`** — physical click on a decade-old hinged trackpad needs real force, and small hands drift mid-press.
- **`tap-and-drag` + `drag_lock`** — GCompris has drag activities they'd otherwise be locked out of.
- **`disable_while_typing = false`** — GCompris mixes keyboard and pointer in one activity. A trackpad that dies for 400 ms after a keystroke reads as broken.

`accel_profile = flat` is the quiet win. Acceleration curves are calibrated for adult flick-and-settle motion; flat makes slow deliberate movement land where they aim.

**Volume ceiling at `-l 0.85`.** Everything here is audio. Cap it so headphones can't hurt them.

**Kill idle lock entirely** — hypridle/hyprlock will strand them behind a password field. The machine is supervised in person.

---

## 7. Identity — the Me tile

Omarchy already interviews you three times, and all three are adult-shaped:

| Surface | Asks | Where |
|---|---|---|
| ISO Configurator | keyboard, language, timezone, hostname, user, disk | TTY, pre-desktop |
| `install.sh` prompt | name + email for `git config` | TTY, mid-install |
| Style menu | theme, screensaver logo, About text | `Super + Alt + Space`, adult TUI |

None of them can be reached by a six-year-old. So Omakid adds a fourth, shaped for her.

### Two corrections to the obvious design

**Don't collect data — offer a choice.** A wizard with fields is an adult mental model. A pre-reader can't parse "what is your favourite colour?" as a prompt, but she completely understands *six coloured squares, tap one, the whole screen changes.* Instant cause and effect is the delight. Data entry is not.

**A first-run interview is the wrong shape.** A six-year-old's favourite colour has a half-life of about three weeks. If picking happens once, at install, in a flow that never returns, then the second time she wants purple she needs you — which defeats the premise of the distro.

So invert it. Build a **permanent affordance** and auto-open it once on first boot. Same code, no wizard state machine, no `first_run` flag to get stuck on, infinitely re-runnable. The "first-run interview" is just *the Me picker, which happens to open itself the first time.* Less code, strictly more capable.

### Where it lives

**Not a fifth grid tile** — the grid stays at four, and the mockup stays the acceptance criterion. Instead: **her chosen animal, top-left corner, 88 px.** She taps her own fox to change her fox. The affordance *is* the current state, which is about as legible as an interface gets without text.

### Two screens, six choices, no reading

```
screen 1 — colour    six big swatches; tap and the background becomes it
screen 2 — avatar    six animals; tap and it lands in the corner
```

Both driven by `home/.config/omakid/identity.json`, so adding a colour is a one-line edit. Selection calls `omakid-set-identity`, which writes state and delegates:

```bash
omakid-set-identity colour purple   # -> omarchy-theme-set omakid-purple
omakid-set-identity avatar owl      # -> state + plymouth
omakid-set-identity name "Nora"     # -> figlet -> screensaver.txt
```

**Don't write a theming engine.** Omarchy's already there: `omarchy-theme-set <name>` stages from `themes/<name>/`, overlays `~/.config/omarchy/themes/<name>/`, renders templates from `colors.toml`, writes `current/theme.name`, and notifies the running shell. Ship six palettes, shell out, done. The manual recommends copying an existing theme as a base rather than authoring `colors.toml` from scratch — do that on first build.

### Three rules

- **Instant feedback.** Tap green and the background is green *before* the finger lifts. No confirm, no Apply, no OK.
- **Never blocking.** Tap through randomly, close it, ignore it — defaults apply and the grid loads. Nothing gates the desktop.
- **It speaks.** Your voice, `assets/voice/{en,fr}/colour-*.wav` and `avatar-*.wav`.

### On names

Worth knowing: **writing your own name reliably precedes reading fluency.** Kids master their own name as a shape long before they decode text. So a name field is the one text input a pre-reader can actually complete — and completing it is a point of pride.

Pre-seed both names via `cidata` so nothing depends on it, then leave the field editable. Never require it.

Then spend it somewhere decorative rather than functional. She can't read a greeting on the grid, but she can absolutely recognise her name eight feet tall in animated ASCII:

```bash
figlet -f big "$NAME" > ~/.config/omarchy/branding/screensaver.txt
```

That's Omarchy's existing screensaver pipeline, unmodified — `branding.sh` copies `logo.txt` to `~/.config/omarchy/branding/screensaver.txt`, and TTE animates whatever's in it. The idle screensaver becomes a show-grandparents feature for free. Her animal can go the same route; Omarchy converts an uploaded PNG or SVG to ASCII for both the screensaver and the About screen.

### The part worth doing properly

Propagate the choice to **plymouth and SDDM** — `omarchy plymouth preview` / `set` / `reset` handle a custom boot logo and colours.

Which means: from the instant she presses power, before any desktop exists, the machine is visibly *hers.* Her colour on the boot splash, her fox on the login screen, her name in the screensaver. Two identical salvaged laptops become two obviously different machines. At six and seven, with a sister, that distinction is not a small thing.

**Open question for the girls:** let them name their own six animals. Choosing from a list you invented is a worse version of this feature than choosing from a list they wrote. `identity.json` carries a TODO to that effect.


## 8. The language wrapper

Two flag tiles, top-right, always visible. Tapping one writes `~/.local/state/omakid/lang`; the grid re-renders with the other language's audio labels.

`bin/omakid-launch`:

```bash
#!/usr/bin/env bash
set -euo pipefail
SEL=$(cat ~/.local/state/omakid/lang 2>/dev/null || echo en)

case "$SEL" in
  fr) export LANG=fr_CA.UTF-8 LC_ALL=fr_CA.UTF-8 ;;
  *)  export LANG=en_CA.UTF-8 LC_ALL=en_CA.UTF-8 ;;
esac

# apps that persist locale in their own config get the file swapped
[[ -f ~/.config/omakid/klettresrc.$SEL ]] && \
  cp ~/.config/omakid/klettresrc.$SEL ~/.config/klettresrc

exec "$@"
```

KLettres persists language, level, and mode between runs, so the pre-baked config swap is the reliable path rather than fighting env vars. Ship `klettresrc.en` pinned to Level 1 / kid mode / long keystroke delay, and `klettresrc.fr` likewise.

Better than two user accounts: no logout, no password, no lost work. Language becomes something they *do*.

---

## 9. Content seeding

`install/post-install/seed-content.sh`. Runs at install so the laptops work in the car with no signal.

### GCompris voices and images

Per-locale `.rcc` bundles from KDE's CDN. Use the `-ogg` codec variant on Linux, read the date suffix from the `Contents` file, drop both into the cache dir:

```bash
CDN=https://cdn.kde.org/gcompris/data3
CACHE="$KID_HOME/.cache/KDE/gcompris-qt/data3"

for loc in en fr; do
  mkdir -p "$CACHE/voices-ogg"
  curl -sfL "$CDN/voices-ogg/Contents" -o "$CACHE/voices-ogg/Contents"
  RCC=$(grep -oE "voices-${loc}-[0-9]+\.rcc" "$CACHE/voices-ogg/Contents" | head -1)
  curl -sfL "$CDN/voices-ogg/$RCC" -o "$CACHE/voices-ogg/$RCC"
done

for bundle in words backgroundMusic; do
  mkdir -p "$CACHE/$bundle"
  curl -sfL "$CDN/$bundle/Contents" -o "$CACHE/$bundle/Contents"
  # then fetch the .rcc named inside Contents
done
```

### Storybooks Canada

The find of this project. 40 African Storybook titles with text **and** recorded narration in English, French, and Canada's most widely spoken immigrant and refugee languages, all CC BY 4.0 — and the site code is itself open source. Audio icons beside every paragraph read that line aloud; `en`/`fr` icons switch text language instantly.

Line-level audio with visible text is the most effective pre-reading mechanic that exists.

```bash
wget --mirror --convert-links --adjust-extension --page-requisites \
     --no-parent -P /var/lib/omakid/stories \
     https://www.storybookscanada.ca/
```

`bin/omakid-stories`:

```bash
#!/usr/bin/env bash
python3 -m http.server 8080 \
  -d /var/lib/omakid/stories/www.storybookscanada.ca &
exec chromium --kiosk --no-first-run \
  --disable-features=TranslateUI http://127.0.0.1:8080/
```

Later, wire individual story covers in as their own tiles and skip the site's navigation entirely.

There's an **Indigenous Storybooks** sibling built on the open-source Little Cree Books, with English and French alongside Indigenous languages. Good phase-9 tile.

---

## 10. Your voice

The best feature in this build, and it costs one afternoon.

KLettres' custom sound format is trivially documented: OGG files 1.5–2 seconds long, alphabet sounds in a folder named `alpha/`, syllables in `syllab/`, a `sounds.xml` mapping them. It appears in the Language menu automatically.

```xml
<klettres>
  <language code="ca">
    <alphabet>
      <sound name="A" file="ca/alpha/a.ogg" />
    </alphabet>
    <syllables>
      <sound name="BA" file="ca/syllab/ba.ogg" />
    </syllables>
  </language>
</klettres>
```

**Honest gap this closes:** neither app ships fr_CA. KLettres offers Metropolitan French; GCompris voices are Parisian. Phoneme inventories overlap enough that letter sounds are usable, but the vowels arrive sounding like Radio-Canada in 1962.

`bin/omakid-record-letters`:

```bash
#!/usr/bin/env bash
set -euo pipefail
LOC=${1:?usage: omakid-record-letters <en-ca|fr-ca>}
OUT="assets/klettres/$LOC/alpha"; mkdir -p "$OUT"

for L in {A..Z}; do
  read -rp "Say '$L' — Enter to record, s to skip: " k
  [[ $k == s ]] && continue
  ffmpeg -hide_banner -loglevel error -f pulse -i default -t 2 \
    -af "silenceremove=start_periods=1:start_threshold=-40dB,apad=whole_dur=2" \
    -c:a libvorbis -y "$OUT/$(echo "$L" | tr 'A-Z' 'a-z').ogg"
  echo "  ✓ $L"
done
```

Twenty-six files, one decent mic. Your voice teaching your daughters their letters, in their own accent, shipped inside the operating system. Record the four tile labels while the mic is out. Let the girls record the French set — they'll open Letters purely to hear themselves, which is exactly the outcome you want.

---

## 11. Parental layer — speed bumps, not walls

**Design decision: the kid account keeps sudo.**

This is deliberate. If either of them works out how to escalate and dismantle the filtering, that is a milestone, not a breach. The layer exists to shape the default path, not to win an arms race against people whose curiosity is the entire point of owning them a computer.

What that changes in practice:

- Everything below is **advisory**. Assume it can be defeated, and that one day it will be.
- `omakid-check` stops being a security alarm and becomes a **drift log** — a record of what changed and, by implication, what they figured out. Read it with interest rather than alarm.
- Nothing here should be load-bearing for actual safety. Content filtering at the DNS layer catches accidents, not determination.

Still worth installing, because defaults do most of the work:

- **DNS filtering.** NextDNS or AdGuard via `systemd-resolved`, `chattr +i` on resolv.conf. Do this at the OS layer, not the router, so it follows the laptop to a friend's house.
- **Chrome managed policy** at `/etc/opt/chrome/policies/managed/omakid.json` — forced SafeSearch, extension allowlist, incognito disabled.
- **`timekpr-next`** for daily quotas and hard curfew at the login-session level. Survives reboots, unlike anything in-browser. Set the curfew to respect the 4–8 PM family block from the other side: the laptops should be *off* then.
- **Menu surgery.** Strip terminal, package install, and AUR entries from `omarchy-menu` — not as a lock, but so the grid stays the obvious path rather than a maze.

Real risk that remains, and it's the mundane one: a `pacman -Syu` can reset the Chrome policy, drop the immutability flag, or stop `timekpr`. A broken machine announces itself; a machine that quietly stopped filtering does not. That's what §11 is for.

---

## 12. Apply and check

`bin/omakid-apply` — idempotent, run after pacman or never:

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KID=kid
KID_HOME=$(getent passwd "$KID" | cut -d: -f6)

# her config: symlink, so repo edits are live
while IFS= read -r -d '' src; do
  dest="$KID_HOME/${src#$REPO/home/}"
  mkdir -p "$(dirname "$dest")"
  ln -sfn "$src" "$dest"
done < <(find "$REPO/home" -type f -print0)
chown -R "$KID:$KID" "$KID_HOME/.config" "$KID_HOME/.local" 2>/dev/null || true

# assets: copied to a stable system path
install -d /usr/share/omakid
cp -r "$REPO/assets" /usr/share/omakid/

# system files: root-owned
while IFS= read -r -d '' src; do
  install -Dm644 -o root -g root "$src" "/${src#$REPO/system/}"
done < <(find "$REPO/system" -type f -print0)

# scripts on PATH
install -Dm755 "$REPO"/bin/omakid-* /usr/local/bin/

# re-enforce the advisory layer (kid keeps sudo, by design)
chattr +i /etc/resolv.conf 2>/dev/null || true
systemctl enable --now timekpr systemd-resolved

hyprctl -i 0 reload 2>/dev/null || true

# --- first boot only: let her choose a colour and an animal ----------
# The Me picker is a permanent affordance (her avatar, top-left corner).
# This single line is the only thing that makes it "first-run".
if [[ ! -f "$KID_HOME/.local/state/omakid/colour" ]]; then
  su - "$KID" -c 'omakid-me' &>/dev/null &
fi

echo "applied."
```

`bin/omakid-check` — a drift log, not a gate:

```bash
#!/usr/bin/env bash
ok() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
no() { printf '  \033[33m•\033[0m %s\n' "$1"; }

lsattr /etc/resolv.conf 2>/dev/null | grep -q -- '-i-' \
  && ok "DNS locked" || no "DNS unlocked  <- update, or a daughter"
[[ -O /etc/opt/chrome/policies/managed/omakid.json ]] \
  && ok "chrome policy" || no "chrome policy gone"
systemctl is-active --quiet timekpr && ok "timekpr" || no "timekpr down"
pgrep -f 'quickshell.*omakid' >/dev/null && ok "grid up" || no "GRID DOWN"
wpctl status 2>/dev/null | grep -q 'Sinks:' && ok "audio" || no "NO AUDIO"
```

Grid and audio are the two that actually matter. No grid means no literacy-free way in — the machine is a brick even if every other subsystem is perfect. No audio means the entire interface has gone mute.

**The whole workflow:**

```bash
sudo pacman -Syu && sudo omakid-apply && omakid-check
```

Chain it into a fish abbr — `kidup` — and you're done.

---

## 13. Build and install

```bash
# 1. build
cd omarchy-iso
OMARCHY_INSTALLER_REPO="atEverychance/omakid" ./bin/omarchy-iso-make

# 2. VM test — iterate here, not on the laptops
./bin/omarchy-iso-boot release/omakid-*.iso

# 3. provisioning stick, so both laptops install identically, unattended
mkdir cidata
cp user_configuration.json user_credentials.json cidata/
genisoimage -output cidata.iso -volid cidata -joliet -rock cidata/
```

Two USB sticks per laptop — the ISO plus cidata — and each machine provisions itself in 2–10 minutes with identical config.

Before starting: **disable Secure Boot and TPM in BIOS** on both machines. Keep that USB pair in a drawer afterward — a ten-minute reinstall beats debugging at bedtime.

---

## 14. Phases

| # | Milestone | Done when |
|---|---|---|
| 1 | Trimmed package list + locale gen, builds clean | ISO boots in VM to a Hyprland session |
| 2 | Quickshell grid + 4 tiles + English WAVs | Grid matches the mockup, tiles speak, apps launch fullscreen |
| 2.5 | Me picker + six themes + avatar corner | She picks her own colour and animal, unaided |
| 3 | `omakid.conf` trackpad/keybind layer | She can drive it with a trackpad and never gets stuck |
| 4 | `parental.sh` + `omakid-apply` + `omakid-check` | `kidup` runs clean |
| 5 | Content seeding: GCompris voices, story mirror | Wifi off, everything still works |
| 6 | Flag toggle + French WAVs + `klettresrc.fr` | Both girls switch languages themselves |
| 7 | **Recorded letter sets, your voice** | KLettres speaks in Canadian English and Canadian French |
| 8 | Deploy laptop A, watch a week, then laptop B | Neither asks for help to open Painting |
| 9 | Earned extras: terminal tile, Indigenous Storybooks | When one of them defeats the DNS lock |

Phase 2 is the project; 2.5 is about two hours, since it's the tile grid with a different model. Phases 1 and 3 are an evening each. Phase 7 is the one they'll remember. Phase 9 is the one you're secretly hoping for.

---

## 15. Known risks

- **Quickshell API drift** — pin the package version in the fork. The single most likely thing to break on an update.
- **Old Intel iGPU + Hyprland** — if either laptop stutters, `animations { enabled = false }`. Test before deciding; DHH's own demo ran a 2011 ThinkPad X220 with 2 GB at ~890 MB idle.
- **Verify the Limine boot menu exposes snapper snapshots** on the first build. That's the physical fallback when everything else has failed and someone is crying.
- **fr_CA is a gap you close by hand.** Nobody ships it. §9 is the answer.
- **Resist the sixth tile.** The tile they use most will surprise you. Watch for a month before adding anything.

---

## Sources

- [omacom-io/omarchy-iso](https://github.com/omacom-io/omarchy-iso) — ISO builder, env vars, build/boot/sign scripts
- [basecamp/omarchy](https://github.com/basecamp/omarchy) — installer, install phases, package lists
- [Omarchy installation & guard requirements](https://deepwiki.com/basecamp/omarchy/2-installation-and-setup)
- [Omarchy unattended installs](https://omarchy.org/manual/unattended-installs/)
- [Omarchy on a potato — X220 / 2 GB benchmarks](https://omarchypulse.com/articles/omarchy-on-a-potato)
- [gcompris-qt in Arch Extra](https://archlinux.org/packages/extra/x86_64/gcompris-qt/)
- [klettres in Arch Extra](https://archlinux.org/packages/extra/x86_64/klettres/)
- [GCompris FAQ — offline voice/word .rcc seeding](https://www.gcompris.net/faq-en.html)
- [KLettres Handbook — custom sound sets, sounds.xml](https://docs.kde.org/trunk_kf6/en/klettres/klettres/klettres.pdf)
- [Omarchy theming — theme-set staging flow, colors.toml](https://github.com/basecamp/omarchy/blob/quattro/docs/theming.md)
- [Omarchy branding — plymouth, screensaver, About](https://learn.omacom.io/2/the-omarchy-manual/118/branding)
- [Omarchy branding assets — branding.sh, logo.txt/icon.txt](https://docs.docuwriter.ai/omarchy-user-docs/78804)
- [Making your own theme](https://learn.omacom.io/2/the-omarchy-manual/92/making-your-own-theme)
- [Storybooks Canada](https://www.storybookscanada.ca/) / [usage guide](https://scarfedigitalsandbox.teach.educ.ubc.ca/storybooks-canada/) / [Global Storybooks](https://decoda.ca/global-storybooks/)
