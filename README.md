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
