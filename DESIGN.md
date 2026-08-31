---
name: Omakid
description: A calm, picture-first desktop for pre-readers.
colors:
  light-pink: "#F9C3D9"
  light-blue: "#A8D8F0"
  bright-pink: "#DE1C84"
  bright-blue: "#1668E0"
  purple: "#7B2FBE"
  gold: "#E0A32A"
  ink: "#1F1B24"
  white: "#FFFFFF"
typography:
  label:
    fontFamily: "Noto Sans, sans-serif"
    fontSize: "32px"
    fontWeight: 600
    lineHeight: 1.15
rounded:
  focus: "28px"
  identity: "32px"
  avatar: "999px"
spacing:
  edge: "24px"
  grid-row: "20px"
  grid-column: "64px"
components:
  activity-tile:
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.focus}"
    width: "320px"
    height: "250px"
  identity-choice:
    rounded: "{rounded.identity}"
    width: "190px"
    height: "190px"
---

# Design System: Omakid

## Overview

**Creative North Star: "The Favourite Toy Shelf"**

Omakid is a full-frame, picture-first product surface: four familiar activities arranged like treasured objects on a low shelf. The chosen colour fills the room rather than decorating a dashboard, while the chosen animal quietly marks ownership. Density stays low, state changes are immediate, and no visual layer competes with the activity being launched.

The system explicitly rejects adult Omarchy surfaces, generic educational dashboards, reward-loop clutter, gradients, glassmorphism, and identical card grids. At 1366×768 the complete home and identity flows must remain visible without scrolling.

**Key Characteristics:**
- Four large picture targets in a fixed responsive 2×2 rhythm.
- Flat colour, crisp silhouette artwork, and visible focus outlines.
- One persistent avatar affordance and two flag controls.
- Brief state feedback; no decorative choreography.

## Colors

Six child-selected colours are complete backgrounds, each paired with either Ink or White for legibility. Their values are normative in the frontmatter.

### Primary
- **Chosen Room Colour:** Any one of Light Pink, Light Blue, Bright Pink, Bright Blue, Purple, or Gold fills the home and identity surface.

### Neutral
- **Storybook Ink:** Used on light backgrounds, focus outlines, and labels.
- **Clear White:** Used on bright/dark backgrounds, focus outlines, and labels.

**The Exact Choice Rule.** A colour swatch and the resulting desktop use the same token; never show a softened preview.

**The No Decoration Rule.** Never add gradients, translucent glass, or extra accent colours. Identity colour is meaning, not ornament.

## Typography

**Display Font:** Noto Sans (sans-serif)
**Body Font:** Noto Sans (sans-serif)

**Character:** Familiar, sturdy, and secondary to illustration and audio. Text supports recognition but never carries a core instruction by itself.

### Hierarchy
- **Label** (600, 32px, 1.15): Optional activity names under each icon; short enough to remain on one line in both languages.

**The Literacy-Optional Rule.** Removing every visible label must not make the core flow unusable.

## Elevation

The system is flat by default. Depth is conveyed through scale and a high-contrast focus outline during interaction, never through persistent cards or shadows.

**The Flat Shelf Rule.** Surfaces are transparent at rest. Focus creates the only temporary boundary.

## Components

### Activity Tiles
- **Shape:** A 320×250 hit region with a 196×176 image area and gently curved focus boundary (28px).
- **Colour:** Transparent at rest; current foreground token for label and focus outline.
- **Hover / Focus:** A 6px outline and 1.035 scale transition over 140ms; entering speaks the localized WAV label.
- **Activation:** Home hides before the application process starts.

### Identity Choices
- **Shape:** Six 190×190 choices in a 3×2 layout.
- **Colour choices:** The exact resulting background token.
- **Animal choices:** White image surfaces for silhouette clarity.
- **State:** A 7px foreground outline and 1.04 scale response; selection applies immediately and advances after a short visible pause.

### Navigation
- **Avatar:** Circular 88px control at the top left; it speaks “Me” and opens identity mode in the same shell window.
- **Language flags:** Two 76×52 controls at the top right. The active language receives a 4px foreground outline and full opacity.
- **Home:** A physical Super-key release returns to the launcher from any application.

## Do's and Don'ts

### Do:
- **Do** preserve the complete 2×2 home grid and 3×2 identity choices inside 1366×768.
- **Do** provide real pre-recorded English and Canadian French audio for every core choice.
- **Do** keep interaction feedback between 120–220ms and honor reduced motion.
- **Do** hide the home layer before launching an application.

### Don't:
- **Don't** introduce adult Omarchy surfaces: command palettes, terminal-first navigation, dense menus, status bars, or keyboard chords.
- **Don't** use text-dependent navigation, setup forms, confirmation dialogs, or password gates in the child's normal path.
- **Don't** imitate generic educational dashboards, reward-loop clutter, mascot chatter, gradients, glassmorphism, or identical card grids.
- **Don't** add decorative animation or novelty that delays an action.
- **Don't** add a fifth activity without a separate product decision.
