# Manga Marketplace

A Japanese-inspired editorial marketplace prototype for buying, selling,
bundling, and trading physical manga. The visual hierarchy follows the supplied
[wireframe](https://tvw96.github.io/mangamarketplace-html/) while the product
and trade flows are adapted to the supplied
[database diagram](https://dbdiagram.io/d/6a3dde47d0074fe75d28a898).

Live site: [tvw96.github.io/Mangamarketplace](https://tvw96.github.io/Mangamarketplace/)

## Included

- Semantic React/HTML structure using `header`, `nav`, `main`, `section`,
  `article`, `aside`, `figure`, `table`, and `footer`
- Responsive editorial layout with no image dependency; cover and street art
  are built in CSS
- Persistent light/dark theme using OKLCH tokens
- WCAG AA contrast calculations and the exact fluid-title derivation in
  [docs/design-system.md](docs/design-system.md)
- Single, collection, and trade UI patterns
- PostgreSQL schema, sale propagation, and atomic trade acceptance in
  [database/migrations/001_marketplace_core.sql](database/migrations/001_marketplace_core.sql)
- Database relationship and API-boundary notes in
  [docs/database-architecture.md](docs/database-architecture.md)

## Run locally

```bash
npm install
npm run dev
```

Production checks:

```bash
npm run lint
npm run build
```

## Fluid title token

```css
--title-size:
  clamp(1.75rem, calc(1.309859rem + 1.877934vw), 3rem);
```

This produces exactly `1.75rem` at 375px and `3rem` at 1440px. The full
calculation and contrast math are documented in
[docs/design-system.md](docs/design-system.md).
