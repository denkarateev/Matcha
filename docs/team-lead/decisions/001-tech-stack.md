# ADR-001: Tech Stack Decisions

> Status: Accepted | Date: 2026-04-02 | Author: Tech Lead Agent

---

## Context

MATCHA is a two-sided marketplace (bloggers + businesses) launching in Bali. We need to ship an MVP that validates the core collaboration loop: onboarding, verification, discovery, match, chat, deal, review. The team is 4 agents working in parallel. We need a stack that supports fast iteration, parallel development, and a clean path from prototype to production.

---

## Decision 1: iOS-only, no cross-platform

**Decision:** Native iOS with SwiftUI, targeting iOS 18+.

**Rationale:**
- Bali creator market is iPhone-dominant
- SwiftUI + Observation framework provides the best developer experience for rapid UI iteration
- No need to maintain two platforms before product-market fit
- Cross-platform frameworks (React Native, Flutter) add complexity without helping us validate faster
- iOS 18+ gives us access to latest SwiftUI APIs, Observation framework, and async/await patterns

**Tradeoffs:**
- Excludes Android users until post-MVP
- Limits total addressable market initially
- Acceptable because Bali launch is a controlled cohort

---

## Decision 2: No third-party iOS runtime dependencies (except Lottie)

**Decision:** Use only Apple frameworks + Lottie for animations. No Alamofire, no SDWebImage, no third-party state management.

**Rationale:**
- URLSession with async/await is sufficient for all networking needs
- `@Observable` macro replaces Combine/RxSwift for state management
- Fewer dependencies = faster build times, smaller binary, no supply chain risk
- Lottie is the only exception because custom animations are core to brand experience and reimplementing a Lottie player is not justified

**Tradeoffs:**
- More boilerplate for image caching (will need custom implementation or AsyncImage)
- No automatic retry/interceptor chain (will build a thin `APIClient` wrapper)
- Acceptable because the networking surface is well-defined and small

---

## Decision 3: FastAPI modular monolith (not microservices)

**Decision:** Single FastAPI application organized as domain modules, deployed as one process.

**Rationale:**
- Expected scale for first 3 months: 500-2,000 users
- One deployment unit is simpler to operate, debug, and deploy
- Module boundaries (auth, profile, matches, offers, chats, deals) are already clean
- Service-to-service calls within the monolith are just function calls, no network overhead
- Clean extraction path: if chat needs to become its own service later, the repository interface already isolates it

**Tradeoffs:**
- All modules share one database connection pool
- A bug in one module can take down the whole API
- Acceptable at current scale; we add health checks and circuit breakers later

---

## Decision 4: PostgreSQL as primary database (replacing InMemoryStore)

**Decision:** PostgreSQL 16 via SQLAlchemy 2.x with Alembic migrations.

**Rationale:**
- The current InMemoryStore loses all data on restart -- not viable beyond prototyping
- PostgreSQL handles all our data patterns: relational (users, profiles, matches), semi-structured (JSONB for niches, badges, photo_urls), and time-series (messages)
- SQLAlchemy 2.x provides async support and clean ORM patterns
- Alembic gives us versioned, repeatable migrations
- PostgreSQL's UNIQUE constraints enforce business rules like one-match-per-pair and one-active-deal-per-pair at the database level

**Alternatives considered:**
- MongoDB: rejected because our data is highly relational (users -> profiles, matches -> chats -> messages -> deals)
- SQLite: insufficient for concurrent backend access
- Supabase: adds an external dependency we don't need; we want direct database control

---

## Decision 5: Repository protocol pattern for data access

**Decision:** Keep the existing Protocol-based repository pattern. Each module defines a repository Protocol, and we provide InMemory (for tests) and PostgreSQL (for prod) implementations.

**Rationale:**
- Already implemented and working for all 6 modules
- Enables unit testing without database
- Makes the InMemory -> PostgreSQL migration incremental (one repo at a time)
- Clean separation between domain logic (services) and persistence

**Tradeoffs:**
- Slightly more boilerplate than direct ORM usage in services
- Worth it for testability and the migration path

---

## Decision 6: Dev-token auth now, JWT later

**Decision:** Keep the current `dev-token:{user_id}` format for Sprint 0. Migrate to JWT (with refresh tokens) in Sprint 1.

**Rationale:**
- The current auth works and lets us test the full flow
- JWT implementation (signing, refresh, revocation) is non-trivial and would delay Sprint 0
- The auth layer is already abstracted behind `parse_access_token()` and `create_access_token()`, so swapping to JWT is a localized change
- iOS stores the token in Keychain regardless of format

**Tradeoffs:**
- Dev tokens are not secure (no expiry, no signing)
- Acceptable because Sprint 0 is internal-only; no production deployment

---

## Decision 7: REST-first, WebSocket for chat in Sprint 1+

**Decision:** All Sprint 0 communication is REST. WebSocket for real-time chat delivery is deferred to Sprint 1.

**Rationale:**
- REST is simpler to implement, test, and debug
- Chat polling at reasonable intervals (every 5s when chat is open) is acceptable for Sprint 0
- WebSocket adds complexity: connection lifecycle, reconnection, authentication, message ordering
- The chat service already has clean boundaries; adding WebSocket is additive, not disruptive

**Tradeoffs:**
- Chat won't feel "instant" in Sprint 0
- No typing indicators or live read receipts yet
- Acceptable for internal testing

---

## Decision 8: Pydantic v2 for all API schemas

**Decision:** Use Pydantic v2 BaseModel for all request/response schemas with `model_validate()` and `ConfigDict(from_attributes=True)`.

**Rationale:**
- Already in use across all 6 modules
- Pydantic v2 is 5-17x faster than v1
- `from_attributes=True` enables direct conversion from dataclass domain models
- Field-level validation (min_length, ge, le) catches invalid input before it reaches services

---

## Decision 9: DI via AppContainer dataclass (not a framework)

**Decision:** Use the existing `AppContainer` dataclass for dependency injection. No DI framework (no dependency-injector, no python-inject).

**Rationale:**
- The container is simple: 6 services, 6 repositories, 1 settings object
- A DI framework adds configuration complexity that doesn't pay off at this scale
- The container is built once at startup in `build_container()` and accessed via `request.app.state.container`
- Easy to understand, easy to extend

---

## Decision 10: Dark-first design system with design tokens

**Decision:** All UI is dark-mode first. Colors, spacing, and radii are defined in `MatchaTokens`. Light mode is not supported in v1.

**Rationale:**
- Brand identity is built around the dark aesthetic (#050505 background, #B8FF43 accent)
- Supporting both modes doubles the design and QA surface
- The design token system (`MatchaTokens.Colors`, `.Spacing`, `.Radius`) is already implemented and used consistently across all views
- `.preferredColorScheme(.dark)` is set at the app root

**Design tokens:**
- Background: #050505
- Surface: #101314
- Elevated: #171C1B
- Accent (luminous lime): #B8FF43
- Text primary: white
- Text secondary: white @ 72% opacity
- Card radius: 24pt
- Button radius: 18pt

---

## Decision 11: Bcrypt for password hashing (replacing SHA256)

**Decision:** Replace the current SHA256 password hashing with bcrypt before any user-facing deployment.

**Rationale:**
- SHA256 is fast and not salted -- trivially crackable via rainbow tables
- bcrypt is the standard for password storage: slow by design, auto-salted
- The `passlib` library provides a clean bcrypt implementation
- The change is localized to `AuthService._hash_password()` and login verification

**Timeline:** Must be done in Sprint 0 P0 before any real user data enters the system.

---

## Decision 12: Feature flags via backend config endpoint

**Decision:** Backend serves feature flags through `GET /api/v1/config`. iOS fetches on launch and caches locally.

**Rationale:**
- Simple to implement (one endpoint, one response)
- No external service dependency (no LaunchDarkly, no Firebase Remote Config)
- Backend is source of truth for what features are available
- iOS never hardcodes feature access -- always checks flags
- Can be extended to per-user flags later (A/B testing)

**Tradeoffs:**
- No real-time flag updates (requires app restart or background refresh)
- No user targeting in v1
- Acceptable for MVP scale
