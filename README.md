# MATCHA

MVP workspace for the MATCHA iOS-first networking platform.

This repository is organized as a mono-workspace:

- `ios/` — SwiftUI application scaffold
- `backend/` — FastAPI service scaffold
- `docs/team-lead/` — architecture and MVP decisions
- `docs/design/` — product design brief and UX guidance
- `docs/marketing/` — go-to-market package for the Bali MVP

Product spec source:

- `/Users/dorffoto/Downloads/Telegram Desktop/MATCHA_Product_Spec_v3.3.md`

Current goal:

- ship a coherent MVP foundation for onboarding, matching, offers, chats, deals, and profile management
- keep the backend modular and ready to scale with Postgres, Redis, background workers, and push pipelines
- keep the iOS client native with modern SwiftUI and no third-party dependencies

Each subdirectory contains its own setup notes where appropriate.

## Quickstart

Backend:

```bash
make backend-setup
make backend-test
make backend-run
```

iOS:

```bash
make ios-project
make ios-build
```

Key planning docs:

- `docs/team-lead/mvp-architecture.md`
- `docs/design/mvp-design-brief.md`
- `docs/marketing/mvp-go-to-market.md`

---

## What's shipped (as of Apr 16, 2026)

### iOS
- **Onboarding** — Welcome → Registration → About You (Nationality / Residence / Gender / Birthday) → Mini Profile → Category (business: MapKit place search + contact info)
- **Match feed** — swipe cards, multi-photo carousel with segmented bar indicator + `1/N` counter, scrollable profile info, filter sheet (role, niches, districts, followers chips, collab type)
- **Offers** — unified top bar (search toggle + slider filter + Deals CRM + New Offer), filter sheet with type/niches/last-minute, client-side multi-niche filtering
- **Likes** — minimal intro card ("People who liked you"), Like Back button, premium blur for free businesses
- **Chats** — Primary / Deals / Requests tabs, swipe-to-delete, Instagram-style header
- **Deal pipeline** — progress ring timer, status colours/icons, swipe actions
- **Profile** — hero photo, sections (about, social, niches, stats, portfolio), Plan section (Upgrade banner + current tier), Reset Swipes dev tool
- **EditProfile preview** — carousel showing exactly how the profile appears in match feed
- **Terminology** — "Creators" → "Influencers" across the whole app
- **Icons** — `slider.horizontal.3` used consistently for every filter entry point

### Backend (FastAPI)
- **Profile** — `nationality`, `residence`, `gender`, `birthday` fields in domain model + schemas; seed profiles now carry 4–5 photos each
- **Offers** — 15 seeded active offers covering every filter niche (food, travel, lifestyle, fitness, fashion, beauty, music, health, sports, cooking, photography, business, art), mix of barter + paid
- **Filters** — `/matches/feed` and `/offers` accept query params (case-insensitive niche match)
- **Admin** — `/admin/reset-swipes/{user_id}` for resetting likes

### Infra
- Server: `188.253.19.166:8842` (`uvicorn app.main:app`)
- Auto-deploy: scp + restart via SSH
- GitHub: https://github.com/denkarateev/Matcha (main)

### Test accounts
- `dev@matcha.app` / `Password123!` — blogger (PRO)
- `hello@thelawncanggu.com` / `Password123!` — business (BLACK)
- `hello@motelmexicola.com` / `Password123!` — business
