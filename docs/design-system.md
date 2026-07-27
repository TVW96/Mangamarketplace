# Manga Marketplace design system

## Direction

The page keeps the supplied wireframe's editorial rhythm—issue strip, centered
masthead, asymmetric feature, fresh listings, market ledger, field notes, and a
newsletter—but moves marketplace actions into the foreground with explicit
single-item, collection, and trade patterns.

The palette was informed by four current official manga/anime experiences:

- [VIZ](https://www.viz.com/home) uses a light neutral base, heavy black type,
  image-led hero areas, and a bright red brand block.
- [MANGA Plus by SHUEISHA](https://mangaplus.shueisha.co.jp/updates) uses an
  almost-black reading surface, white text, and red for urgency.
- [Crunchyroll Store](https://store.crunchyroll.com/collections/manga/) pairs
  black navigation with a warm light catalogue surface and vivid orange calls
  to action.
- [BookWalker](https://bookwalker.com/) uses a warm off-white catalogue,
  near-black type, and small cyan/coral moments around a dense product grid.

Those references suggested a paper/ink foundation with one hot acquisition
color. Manga Marketplace uses vermilion rather than copying any source brand,
then adds electric cyan for informational links and trade status.

## OKLCH tokens

```css
:root {
  --background: oklch(0.965 0.012 85);
  --surface: oklch(0.985 0.008 85);
  --surface-raised: oklch(1 0 0);
  --text: oklch(0.205 0.025 255);
  --text-muted: oklch(0.43 0.02 255);
  --accent: oklch(0.5 0.185 28);
  --on-accent: oklch(0.98 0.01 85);
  --info: oklch(0.43 0.075 235);
  --line: oklch(0.78 0.018 85);
}

:root[data-theme='dark'] {
  --background: oklch(0.165 0.018 255);
  --surface: oklch(0.205 0.018 255);
  --surface-raised: oklch(0.245 0.02 255);
  --text: oklch(0.93 0.015 85);
  --text-muted: oklch(0.73 0.018 85);
  --accent: oklch(0.72 0.17 35);
  --on-accent: oklch(0.165 0.018 255);
  --info: oklch(0.74 0.12 205);
  --line: oklch(0.34 0.018 255);
}
```

### Why those lightness levels work

OKLCH `L` is perceptual lightness on a 0–1 scale, but **WCAG contrast is not
calculated by subtracting two OKLCH lightness values**. The guarantee comes
from converting each OKLCH color to sRGB, calculating WCAG relative luminance
`Y`, then applying:

```text
contrast = (lighter Y + 0.05) / (darker Y + 0.05)
```

For this palette, the important converted relative-luminance values are:

| Token | Light mode Y | Dark mode Y |
|---|---:|---:|
| Background | 0.898639 | 0.004504 |
| Main text | 0.008635 | 0.804349 |
| Muted text | 0.079677 | 0.388983 |
| Vermilion accent | 0.109073 | 0.345379 |
| Cyan info | 0.081481 | 0.426230 |

The resulting text/background contrast ratios are:

| Pair | Ratio | WCAG AA |
|---|---:|---|
| Light main text / background | 16.18:1 | Pass |
| Light muted text / background | 7.32:1 | Pass |
| Light accent text / background | 5.96:1 | Pass |
| Light info text / background | 7.22:1 | Pass |
| Light button text / accent | 6.23:1 | Pass |
| Dark main text / background | 15.68:1 | Pass |
| Dark muted text / background | 8.05:1 | Pass |
| Dark accent text / background | 7.25:1 | Pass |
| Dark info text / background | 8.74:1 | Pass |
| Dark button text / accent | 7.25:1 | Pass |

WCAG AA requires 4.5:1 for normal text and 3:1 for large text. The chosen
background/text `L` gaps—`0.965 → 0.205` in light mode and `0.165 → 0.93` in
dark mode—leave enough room for chroma and hue to move without pushing any
semantic text pair near the threshold. Decorative cover colors are not relied
upon for body copy.

## Fluid main title

```css
--title-size:
  clamp(1.75rem, calc(1.309859rem + 1.877934vw), 3rem);
```

Assuming the browser default `1rem = 16px`:

1. Minimum: `1.75rem × 16 = 28px` at a `375px` viewport.
2. Maximum: `3rem × 16 = 48px` at a `1440px` viewport.
3. Size range: `48 - 28 = 20px`.
4. Viewport range: `1440 - 375 = 1065px`.
5. Linear slope: `20 / 1065 = 0.0187793px` of font growth per viewport pixel.
6. Because `1vw` is 1% of the viewport, the `vw` coefficient is
   `0.0187793 × 100 = 1.87793vw`.
7. Intercept at zero viewport width:
   `28 - (0.0187793 × 375) = 20.9577px`.
8. Convert the intercept to rem:
   `20.9577 / 16 = 1.30986rem`.

Endpoint checks:

```text
375px:  20.9577px + (1.87793 × 3.75px) = 28px = 1.75rem
1440px: 20.9577px + (1.87793 × 14.4px) = 48px = 3rem
```

The outer `clamp()` stops the linear expression below 375px and above 1440px.
