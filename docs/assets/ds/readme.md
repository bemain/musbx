# Musician's Toolbox — Design System

A new visual identity for **Musician's Toolbox**, an open-source mobile app (Flutter) that turns any song into practice material: slow it down, change its key, split it into stems, see its chords, tune up, keep time.

The identity here is derived from two sources: the app's own product surfaces (the `bemain/musbx` codebase) and a set of three A2 campaign posters supplied by the client. The posters set the *voice* — near-black field, one loud accent per campaign, condensed uppercase display type, mono labels. The app supplies the *mechanics* — the tools, the icon set, the flat Material 3 surfaces.

## Sources

| Source | Where |
| --- | --- |
| App codebase | https://github.com/bemain/musbx (branch `main`) |
| Campaign posters | `uploads/Musician's Toolbox - Posters.pdf` (A2, 3 posters, EN) |
| Logo | `uploads/Logo blue.svg` → `assets/logo/logo.svg` |

Explore the musbx repository directly for anything this system doesn't cover — screen structure, feature naming, and the real icon inventory all live there, and reading it will make any new design markedly more accurate.

## The products

1. **Mobile app (iOS + Android)** — the actual toolbox. Tools: *Speed & Pitch* (slowdowner), *Demixer* (stem separation), *Chords*, *Tuner*, *Metronome*. Songs load from local files or YouTube.
2. **Marketing website** — the surface being redesigned. It exists to explain the five tools and drive App Store / Google Play installs. This is where the poster language does the most work.

---

## Content fundamentals

**Tone: a workshop, not a product page.** Copy speaks like a tool label or a rehearsal instruction — short, imperative, technically literal. It never sells feelings ("unlock your musicality"); it states function ("Slow it down. Keep the pitch.").

- **Person.** Second person, implied. "Slow any song down" — not "we help you slow songs down". "I" never appears.
- **Casing.** Display headlines are **uppercase**, always, set in condensed heavy grotesque. Labels, eyebrows, buttons and metadata are **uppercase mono**. Body copy is sentence case. Title Case is never used.
- **Sentence shape.** Fragments are fine and preferred in display. Body sentences run 8–18 words. Periods stay, even on fragments — the full stop is part of the rhythm: `ANY SONG. ANY TEMPO. ANY KEY.`
- **Numbers as content.** The brand likes specificity: `-40% SPEED`, `4 STEMS`, `120 BPM`, `A = 440 Hz`. Set them in mono. They double as visual texture — use them where a lesser design would use a decorative graphic.
- **Emoji: never.** Not in product, not in marketing, not in changelogs. Musical symbols (♭ ♯ ♩ ♪) are used instead, set in the notation font.
- **Feature naming.** Tools carry their proper names in caps — SPEED & PITCH, DEMIXER, CHORDS, TUNER, METRONOME. Never pluralise or paraphrase them.

Examples in voice:

> `SLOW IT DOWN.` / *Drop any track to half speed without touching the key. Or move the key without touching the tempo.*

> `PULL IT APART.` / *Vocals, drums, bass, other. Four stems, one tap, on your phone.*

Anti-examples: "Discover your inner musician", "Powerful AI-driven audio separation ✨", "Get Started Today!".

---

## Visual foundations

**The one-sentence version:** near-black paper, one screaming accent, condensed caps set enormous and cropped by the frame, mono labels doing the annotating, and absolutely no ornament.

### Colour
Ink ramp (`--ink-900 … --ink-200`) plus off-white `--paper` (`#F3F1E9`) carry every surface. Exactly **one** accent is live in a given view — acid `#C6FF3A` (Speed & Pitch), cyan `#34E1FF` (Demixer), ember `#FF6A3D` (Chords). Swap by putting `.mt-accent-cyan` / `-ember` / `-acid` on a subtree; every accent-bound token follows. The logo blue `#0F58CF` (app seed `#578CFF`) is reserved for the mark itself and app chrome — it is not a campaign accent. `.mt-paper` inverts a subtree onto poster stock. Never two accents in one composition. Content text uses `--text-primary` or `--text-secondary` only — **`--text-muted` is reserved for disabled states**, since it falls below 4.5:1 on the ink field.

### Type
Three faces, read straight off the posters' embedded fonts: **Big Shoulders** for display (naturally condensed, weight 700, uppercase), **Outfit** for body and UI, **Geist Mono** for labels and data. Chord and pitch symbols use **Andika** (`--font-notation`), matching the app. Display leading is `0.89` — lines lock together as a block — with `-0.015em` tracking. Body runs `1.35`. Four voices, four utility classes: `.mt-display`, `.mt-label`, `.mt-micro`, `.mt-body`.

All four are variable fonts served from Google Fonts — nothing to host. The faces were recovered from the poster PDF's embedded font table (`BigShoulders-Bold`, `Outfit-Regular/Bold`, `GeistMono-Regular/Bold`), so this is the real poster type, not a substitution.

### Space & layout
An 8px base scale (`--space-*`) with a generous poster margin. Layout is a hard left rail: display type, eyebrow, and body all flush left to the same line, with mono metadata pinned to the opposite edge — the poster's tension comes from that asymmetry, not from centring. Full-bleed is the default for hero fields; content columns cap around 60ch. Headlines are allowed to be cropped by the frame; nothing else is.

### Shape, borders, shadow
**No shadows anywhere.** The app is elevation-0 and the posters are flat print; depth is ink-on-ink plus accent fields. The only "elevation" token is `--shadow-lift`, a 1px hairline ring. Radii: cards `32px` (`--radius-lg`, matching the app's FlatCard), controls pill (`999px`), small chips `8px`. Rules are 1px hairlines at 18% ink; the accent frame (`--frame`) is the poster crop line. Cards are flat fills with a hairline, never a shadowed float.

### The ring detail
The posters carry exactly one piece of decoration: **three concentric discs in the accent colour, each at 5% opacity**, stacked so the overlaps step up to 9.8% and 14.3%. It reads as a soft radial glow but is three hard edges — there is no gradient anywhere in this brand. On the A2 sheet the outer disc is 479pt across on a 1191pt page (radius ratio 1 : 0.78 : 0.57), centred 64.6% across and 68.8% down, so it bleeds off the right edge behind the headline. Use `RadialRings` and keep it to one instance per composition.

### Imagery
Cool, high-contrast, near-monochrome — instruments and hands, deep blacks, one accent overprinted as a duotone or as a solid knockout panel. No warm filters, no grain, no stock-smile photography. Where art doesn't exist yet, a solid accent field or a waveform block stands in — `Waveform` bars carry randomised opacity between 0.52 and 0.98, measured off the posters, which is what keeps the block from looking mechanical; album art falls back to `assets/images/default_album_art.svg`.

### Motion
Material 3 easing, inherited from the app: `--ease-standard` `cubic-bezier(.2,0,0,1)`, durations 120 / 200 / 400ms. Motion is functional — cross-fades, tab slides, value scrubs. No bounce, no parallax, no scroll-jacking, no entrance animations on marketing copy.

### States
- **Hover:** colour change only (accent → white on links; fill lightens marginally). No lift, no shadow, `--hover-lift: 0`.
- **Press:** `scale(0.97)` (`--press-scale`) at 120ms. Never a colour flash alone.
- **Focus:** 2px accent ring, 2px offset, from `--focus-ring`.
- **Disabled:** opacity `0.38` (Material 3's value), no colour substitution.

### Transparency & blur
Used sparingly and only for real overlays: `--overlay-scrim` (72% ink) behind modals and sheets, `--blur-scrim` (12px) on the app's floating player bar. Accent tints (`--acid-16` etc.) wash backgrounds behind selected states. Glassmorphism as decoration is out of brand.

---

## Iconography

The app ships its **own icon font**, `CustomIcons.ttf` — copied here to `assets/fonts/` and exposed as `--font-icons` / `MTCustomIcons`. It covers everything music-specific: `metronome`, `tuning_fork`, `snare`, `trumpet`, `guitar_head`, `bass_head`, `microphone`, `crotchet`, `quavers_two`, `quavers_three`, `semiquavers_four`, `accidentals`, and the waveform family (`waveform`, `_sine`, `_square`, `_sawtooth`, `_triangle`). Individual SVGs for each live in `assets/icons/`. Codepoints are in `assets/fonts/CustomIcons.json` and mirrored in `components/media/customIcons.js`.

Everything non-musical uses **Material Symbols Rounded** (the app's Material 3 default), loaded from Google Fonts CDN, weight 600, fill 0 by default. The `Icon` component routes automatically: a name in the custom set renders from the app font, anything else falls through to Material Symbols.

Store badges (`assets/icons/appstore.svg`, `googleplay.svg`) and `youtube.svg` are the official marks — use as supplied, never recoloured. Unicode musical symbols (♩ ♪ ♭ ♯) are legitimate as *typographic* content in the notation font; emoji are not used anywhere.

---

## Components

Built primitives, grouped by concern under `components/`:

**Core** — `Button`, `IconButton`, `Tag`
**Controls** — `Slider`, `Switch`
**Media** — `Icon`, `Waveform`, `StoreBadge`
**Surfaces** — `FlatCard`, `FeatureRow`, `Eyebrow`

Each directory holds `<Name>.jsx`, `<Name>.d.ts`, `<Name>.prompt.md`, and one `@dsCard` HTML showing the variants. Import from the compiled bundle: `const { Button } = window.MusicianSToolboxDesignSystem_332e2c`.

*Intentional additions:* `Icon` (wrapper over the app's two icon systems), `Waveform` (poster/app motif used as art), `StoreBadge` and `Eyebrow` (marketing-side needs with no app counterpart) — none exist as named components in musbx, but each has a direct visual counterpart in the app or posters.

---

## Index

- `styles.css` — the single entry point consumers link. Import list only.
- `tokens/` — `fonts.css`, `colors.css`, `typography.css`, `spacing.css`, `effects.css`, `base.css`
- `guidelines/` — 18 foundation specimen cards (Brand, Colors, Type, Spacing) rendered in the Design System tab
- `components/` — core, controls, media, surfaces (see above)
- `assets/` — `logo/`, `icons/`, `images/`, `fonts/`
- `ui_kits/website/` — the redesigned marketing site (home, tools, pricing, support)
- `thumbnail.html` — the system's homepage tile
- `github.md` — upstream source association for one-click sync
- `SKILL.md` — Agent Skills entry point
