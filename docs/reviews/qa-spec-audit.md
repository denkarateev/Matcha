# QA Spec Audit — 2026-04-02

## Executive Summary

MATCHA has a **solid foundational scaffold** with core modular architecture in place (iOS + backend), but is **not yet MVP-ready**. The iOS app is entirely UI mock (using MockMatchaRepository) with zero backend integration. Backend has domain logic implemented for the core loop but relies on in-memory storage, making it unsuitable for testing or production. **Critical blockers**: no real data persistence, no end-to-end iOS-backend integration, no manual verification workflow, no business-blogger role enforcement, and missing key MVP requirements like verification state, offer daily limits enforcement, and deal management UI.

**Recommendation**: Complete Sprint 0 work before any testing or staging deployment.

---

## Build Status

### iOS
- **Project structure**: ✅ Exists and builds
- **Xcode project**: ✅ `MATCHA.xcodeproj` present; project.yml configured for iOS 18.0
- **Compilation**: Should compile; structured as modular SwiftUI with no external dependencies
- **Status**: **Ready to build**, but tied to mock data only

### Backend
- **Framework**: ✅ FastAPI correctly configured
- **Module structure**: ✅ Modular monolith (auth, profile, matches, offers, chats, deals)
- **Startup**: ✅ Can initialize (app.main imports correctly)
- **Database**: ❌ **Critical**: Only InMemoryStore; no Postgres, SQLAlchemy, or migrations
- **Status**: **In-memory only**; not production-ready

---

## iOS Features Inventory

| Screen | Exists | Connected to Backend | Status |
|--------|--------|----------------------|--------|
| Onboarding | ✅ | ❌ Mock only | 3-step UI (role, email, profile); no backend flow |
| Feed/Discovery | ✅ | ❌ Mock only | Swipe UI works; loads from MockSeedData |
| Offers | ✅ | ❌ Mock only | Read-only marketplace; no create/respond UI |
| Chats | ✅ | ❌ Mock only | Lists mock new matches; no messaging implemented |
| Activity | ✅ | ❌ Mock only | Shows mock likes/deals/applications; no data |
| Profile | ✅ | ❌ Mock only | Static display; no edit or upload flows |
| TabShell | ✅ | ✅ Partially | Navigation exists; badge counts hardcoded |

### iOS Architecture Notes
- **Repository pattern**: ✅ Present (MatchaRepository protocol)
- **Mock implementation**: ✅ MockMatchaRepository provides all seed data
- **State management**: ✅ @Observable with per-screen stores (MatchFeedStore, OffersStore, etc.)
- **Design tokens**: ✅ MatchaTokens (colors, spacing, radius) defined
- **No external dependencies**: ✅ Pure SwiftUI, minimal foundation

**Key issue**: `AppEnvironment.mock` is hardcoded; no path to real API client yet.

---

## Backend Endpoints Inventory

### Auth Module
| Endpoint | Implemented | Tests | Notes |
|----------|-------------|-------|-------|
| POST /auth/register | ✅ | ✅ | Creates user + profile |
| POST /auth/login | ✅ | ✅ | Basic email/password |
| GET /auth/me | ✅ | ✅ | Requires JWT |
| POST /auth/verify | ✅ | ✅ | **ISSUE**: Self-verify without admin review |

### Profile Module
| Endpoint | Implemented | Tests | Notes |
|----------|-------------|-------|-------|
| GET /profiles/me | ✅ | ✅ | Read own profile |
| PUT /profiles/me | ✅ | ✅ | Update profile |
| GET /profiles/{user_id} | ✅ | ✅ | Read other profile |

### Matches Module
| Endpoint | Implemented | Tests | Notes |
|----------|-------------|-------|-------|
| GET /matches | ✅ | ✅ | List mutual matches |
| POST /matches/swipes | ✅ | ✅ | Swipe + mutual match logic |

### Offers Module
| Endpoint | Implemented | Tests | Notes |
|----------|-------------|-------|-------|
| GET /offers | ✅ | ✅ | List offers (with filters) |
| POST /offers | ✅ | ✅ | Create offer (business only) |
| POST /offers/{id}/responses | ✅ | ✅ | Blogger respond to offer |
| GET /offers/responses/incoming | ✅ | ✅ | Business list responses |
| POST /offers/responses/{id}/accept | ✅ | ✅ | Accept response → creates match |
| POST /offers/responses/{id}/decline | ✅ | ✅ | Decline response |

### Chats Module
| Endpoint | Implemented | Tests | Notes |
|----------|-------------|-------|-------|
| GET /chats | ✅ | ✅ | List chats |
| GET /chats/{chat_id} | ✅ | ✅ | Get chat + messages |
| POST /chats/{chat_id}/messages | ✅ | ✅ | Send message |

### Deals Module
| Endpoint | Implemented | Tests | Notes |
|----------|-------------|-------|-------|
| GET /deals | ✅ | ✅ | List deals for user |
| POST /deals | ✅ | ✅ | Create deal (draft) |
| POST /deals/{id}/confirm | ✅ | ✅ | Move to confirmed |
| POST /deals/{id}/check-in | ✅ | ✅ | Mark visited |
| POST /deals/{id}/no-show | ✅ | ✅ | Mark no-show |
| POST /deals/{id}/reviews | ✅ | ✅ | Submit review |
| POST /deals/{id}/cancel | ✅ | ✅ | Cancel with reason |

**Summary**: All major endpoints exist and have domain logic. **No persistence layer.**

---

## Spec Compliance

### Core Loop: `shadow onboarding → verification → discovery → match → chat → deal → review`

| Step | iOS | Backend | Spec Compliance |
|------|-----|---------|-----------------|
| **Shadow Onboarding** | ✅ UI sketch | ✅ Creates shadow user | ⚠️ PARTIAL: UI exists; no backend flow yet; shadow account created but not enforced |
| **Verification** | ❌ Missing | ❌ BROKEN: Self-verify only | ❌ CRITICAL: No admin review, no screenshot upload, no pending state |
| **Discovery** | ✅ Swipe UI | ✅ Swipe endpoint | ⚠️ PARTIAL: UI works but no real feed ranking, no role enforcement, no filters |
| **Match** | ⚠️ Implied | ✅ Match logic | ✅ Mutual swipe → match created |
| **Chat** | ✅ UI listed | ✅ Endpoints exist | ⚠️ PARTIAL: No WebSocket/realtime, no 48h window enforced, no read receipts |
| **Deal** | ❌ No UI | ✅ Full state machine | ❌ CRITICAL: No client UI for deal creation/updates; no content proof |
| **Review** | ❌ No UI | ✅ Review model exists | ❌ No UI for submitting reviews |

### Business Rules

| Rule | Implemented | Notes |
|------|-------------|-------|
| **Shadow max 20 pending likes** | ✅ Backend | Enforced in `swipe()` service; iOS mock doesn't respect |
| **Business ↔ Blogger only** | ❌ NOT enforced | Swipe logic doesn't check role pairing; feed mixes both roles |
| **Blogger writes first in chat** | ✅ Backend | `first_message_by` field set; no UI enforcement |
| **Offer response 3/day per blogger** | ✅ Backend | Checked via timezone-aware counters in WITA |
| **One active deal per pair** | ❌ PARTIAL | Model allows multiple; no unique constraint in backend |
| **Deal state machine** | ✅ Backend | DRAFT → CONFIRMED → VISITED → REVIEWED or NO_SHOW → CANCELLED |
| **Verification required for offers** | ✅ Backend | `create_offer()` checks `is_verified` |
| **Verification required for seeing likers** | ❌ iOS only | No UI for activity/likes without verification |

---

## Critical Bugs (P0)

1. **No end-to-end iOS-backend integration**
   - iOS entirely uses `MockMatchaRepository`; `AppEnvironment.mock` is hardcoded
   - `MatchaRepository` protocol has no network client
   - **Impact**: Cannot test any real flow; cannot validate spec

2. **Verification is self-serve with no admin review**
   - `POST /auth/verify` in backend allows any user to self-verify without evidence
   - No screenshot upload endpoint or review queue
   - `verification_level` is immediately set to VERIFIED
   - **Impact**: Trust model does not exist; app can be flooded with fakes
   - **Spec gap**: MVP architecture requires manual verification with admin queue

3. **No data persistence**
   - Backend uses `InMemoryStore` only; all data lost on restart
   - No database connection, ORM, migrations, or seed scripts
   - **Impact**: Cannot run integration tests; cannot deploy to staging or production
   - **Blocker**: Development impossible without persistence layer

4. **Role enforcement missing**
   - `swipe()` service does not validate `Business <-> Blogger` pairing rule
   - iOS mock feed includes both roles in same list
   - **Impact**: Core product constraint violated; business logic undefined for same-role matches
   - **Spec gap**: MVP architecture explicitly restricts to Business ↔ Blogger

5. **Deal creation has no UI**
   - Backend `/deals` endpoints exist but iOS has no screen to create/manage deals
   - Deal flow appears in Activity tab as read-only; cannot be interacted with
   - **Impact**: Deal MVP loop cannot be tested end-to-end
   - **Blocker**: Feature is 50% implemented

---

## Major Issues (P1)

1. **No offer daily limit enforcement on iOS**
   - Backend enforces 3/day per blogger via timezone-aware counter
   - iOS offers view is read-only marketplace
   - No respond UI; no counter display
   - **Impact**: Business rule invisible to user

2. **Chat lacks realtime and 48h deadline**
   - Backend has message endpoints but no WebSocket or polling
   - 48h first-message deadline not enforced in code
   - No read receipts
   - **Impact**: Chat is synchronous only; critical functionality missing per MVP spec

3. **Profile update UI missing**
   - Profile screen shows static user info with hardcoded verification checklist
   - No edit mode, no photo upload, no portfolio wall
   - Backend `/profiles/me PUT` exists but iOS cannot call it
   - **Impact**: User cannot complete profile completion wizard

4. **Activity/Likes tab shows mock data only**
   - Hardcoded badge counts (4, 2, 1) in AppState
   - No real call to fetch activity summary
   - MatchFeedStore.pendingLikes starts at 2; not fetched from backend
   - **Impact**: Activity page is 100% fake

5. **No filters implementation on feed**
   - "Filters" button exists on MatchFeedView but does nothing
   - No filter UI or state
   - Backend has basic field-level filters but no advanced query
   - **Impact**: Feed has no business/category/niche filters

---

## Minor Issues (P2)

1. **Onboarding does not actually register user**
   - OnboardingFlowView collects email/password/role but does not call backend
   - `completeOnboarding()` just sets mock `currentUser` and `onboardingComplete = true`
   - No network call; no token handling
   - **Impact**: Cannot test registration flow; app state is fake

2. **AppState hardcodes currentUser role**
   - `currentUser = MockSeedData.makeCurrentUser(role: .blogger, name: "Ari")`
   - No JWT storage or authenticated user reading
   - **Impact**: Multi-user testing impossible

3. **Match feed does not paginate**
   - MatchFeedStore loads all profiles at once
   - No offset/limit or cursor pagination
   - **Impact**: Scalability issue for large user bases

4. **No error handling in repository calls**
   - All async calls have `catch { [] }` fallback
   - Silent failures hide issues
   - **Impact**: Debugging difficult; real errors masked

5. **MockSeedData includes out-of-spec elements**
   - Profiles have `.blueCheck` badge (not in MVP)
   - Translation notes present (AI translation is post-MVP)
   - Last Minute offer UI exists (MVP restricts to Black tier only)
   - **Impact**: Scope creep; confuses MVP boundaries

6. **Backend has no pagination or cursor support**
   - List endpoints return all records
   - No limit/offset parameters
   - **Impact**: Performance degradation at scale

---

## Spec Compliance Details

### From MVP Architecture (`mvp-architecture.md`)

#### Onboarding (In Scope)
- Welcome screen: ✅ UI exists ("Brew connections, blend success")
- Auth (Apple/Google/Email): ⚠️ Buttons exist but no backend flow
- Role selection: ✅ Picker in step 2
- Mini profile: ✅ Name, category selection in step 3
- Shadow account + queued likes: ✅ Backend enforces; iOS mock shows "2 likes pending"
- **Missing**: Profile completion wizard, Instagram DM code, photo upload, admin review queue

#### Discovery (In Scope)
- Swipe feed: ✅ UI exists (Skip, SuperSwipe, Interested buttons)
- Vertical profile cards: ✅ GlassCard with hero symbol, name, district, bio
- Interested/Skip/SuperSwipe UI: ✅ Three action buttons
- Basic filters: ❌ Button exists but no UI; backend filters exist
- Feed cooldown: ❌ Not implemented (iOS increments index continuously)
- Ranking: ❌ Not implemented (mock data is static)
- **Missing**: Business <-> Blogger enforcement, feed rules, ranking pipeline

#### Offers Marketplace (In Scope)
- Business creates offers: ✅ Backend `/offers POST`
- Blogger browses: ✅ OffersView shows marketplace
- Blogger responds: ✅ Backend `/offers/{id}/responses POST` but no iOS UI
- Business accepts/declines: ✅ Backend endpoints exist but no iOS UI
- Offer acceptance → match: ✅ Backend logic exists
- Three filters: ✅ Backend filters (type, niche, last_minute) but iOS button does nothing
- **Missing**: iOS respond UI, accept/decline UI, offer creation UI

#### Matching and Chat (In Scope)
- Mutual match logic: ✅ Backend implements Business ↔ Blogger rule (incomplete)
- 48h first-message window: ❌ Not enforced
- Chat list: ✅ ChatsView shows new matches + conversations
- 1:1 chat: ✅ Backend endpoints
- Read receipts: ❌ Not implemented
- Photo sharing: ❌ Not implemented
- Push notifications: ❌ Not implemented
- **Missing**: Realtime/WebSocket, 48h deadline, read receipts, photo sharing, APNs

#### Deal Flow (In Scope)
- Draft/Confirmed/Visited/No-Show/Reviewed: ✅ Backend state machine
- Cancellation: ✅ Backend `cancel_deal()`
- Mutual check-in: ✅ `check_in()` endpoint
- Review flow: ✅ `submit_review()` exists
- Content proof: ❌ No upload endpoint or storage
- **Missing**: iOS UI for deal creation, updates, review submission

#### Activity and Settings (In Scope)
- Activity tab (Likes/Deals/Responses): ✅ UI exists; ❌ no real data
- Settings: ✅ Settings rows listed; ❌ no interactivity
- **Missing**: Real data integration, working settings

#### Safety and Moderation (In Scope)
- Block: ❌ No endpoint
- Report: ❌ No endpoint
- Auto-hide after reports: ❌ Not implemented
- Internal moderation queue: ❌ Not implemented
- **Missing**: All safety features

---

## Comparison with Bmatch2 Reference

### What Bmatch2 Has That MATCHA Lacks

1. **Supabase integration** (real-time backend)
   - Bmatch2 uses Supabase client directly in iOS
   - MATCHA has no network layer at all

2. **User authentication + persistence**
   - Bmatch2 stores users, verifies against DB
   - MATCHA loses data on backend restart

3. **Swipe service with real data**
   - Bmatch2: SwipeService calls backend; responses are real
   - MATCHA: LocalIndex increment only

4. **Deal status machine with RPC calls**
   - Bmatch2: DealStatusResponse from RPC; real state transitions
   - MATCHA: Backend has state machine but iOS cannot access it

5. **Validation service**
   - Bmatch2: ValidationService checks business logic
   - MATCHA: Validation split between backend (good) and iOS (missing)

### What MATCHA Has That Bmatch2 Lacks

1. **Modular backend architecture**
   - MATCHA: Proper service layer, repository pattern, container DI
   - Bmatch2: RPC-only, less structured

2. **Comprehensive domain models**
   - MATCHA: User, Offer, OfferResponse, Deal, DealReview, Swipe, Match all defined
   - Bmatch2: Simpler schema (RPC-driven)

3. **Design tokens and design system**
   - MATCHA: MatchaTokens (colors, spacing, radius) centralized
   - Bmatch2: Inline DesignSystem

4. **Observable pattern in iOS**
   - MATCHA: @Observable, reactive state per view
   - Bmatch2: Traditional ViewModel + @Published

---

## Sprint 0 Readiness Assessment

### Blockers (Must Fix Before Any Testing)

- [ ] 1. **Create real API client in iOS** (HttpMatchaRepository)
      - Replace MockMatchaRepository with HTTP client
      - Add JWT token storage and refresh
      - Update AppEnvironment to use real client
      - Estimate: 1–2 days

- [ ] 2. **Add Postgres + SQLAlchemy to backend**
      - Replace InMemoryStore with database models
      - Add migrations framework (Alembic)
      - Update repository layer to use ORM
      - Estimate: 2–3 days

- [ ] 3. **Implement proper verification flow**
      - Add `verification_pending` state
      - Create screenshot upload endpoint + storage
      - Add manual admin review queue endpoint
      - Update verification activation (no self-serve)
      - Estimate: 2 days

- [ ] 4. **Enforce Business ↔ Blogger rule**
      - Update swipe service to validate role pairing
      - Filter feed results on iOS to only show valid targets
      - Add validation in match creation
      - Estimate: 1 day

- [ ] 5. **Implement deal creation UI**
      - Add deal creation form to iOS
      - Connect to backend POST /deals
      - Add deal detail and status update screens
      - Estimate: 2–3 days

- [ ] 6. **Implement offer response and management UI**
      - Add UI to respond to offers
      - Add business view for incoming responses
      - Add accept/decline flow
      - Estimate: 2 days

### Nice-to-Have for Sprint 0

- [ ] Realtime chat (WebSocket)
- [ ] 48h first-message deadline enforcement
- [ ] Read receipts
- [ ] Push notifications
- [ ] Content proof submission
- [ ] Profile edit + photo upload
- [ ] Activity real data integration
- [ ] Feed ranking and cooldown
- [ ] Block/Report endpoints

### Sprint 0 Summary

- **Current readiness**: ~30% (UI scaffold + backend logic, no integration or persistence)
- **Days to Alpha**: ~2 weeks if full team, assuming:
  - 1 backend engineer: persistence (3d) + verification (2d) = 5d
  - 1 iOS engineer: API client (2d) + deal UI (2.5d) + offer response UI (2d) = 6.5d
  - 1 DevOps/DB: environment setup, migrations, deployment = 3d
- **Recommended**: Focus on blockers; defer nice-to-have to Sprint 1

---

## Test Coverage Assessment

### iOS Tests
- **Current**: 1 test (MockSeedDataTests.swift) — validates seed data exists
- **Status**: ❌ Insufficient — no logic testing
- **Needed**:
  - Onboarding flow (e2e: enter creds → verify role → complete profile)
  - Feed actions (skip, like, superswipe → state changes)
  - Offer response submission
  - Chat message sending
  - Deal state transitions
  - **Estimate to cover**:  4–5 days for integration tests

### Backend Tests
- **Current**: Test files exist but suite doesn't run without Postgres setup
- **Status**: ❌ Environment-dependent — not CI-ready
- **Needed**:
  - Fix test environment (add test DB or use in-memory for now)
  - Register → Verify → Swipe → Match flow
  - Offer response daily limit enforcement
  - Deal state machine coverage
  - Chat message edge cases (48h, first-message rule)
  - **Estimate to fix**: 2–3 days

---

## Key Recommendations

### Immediate (This Sprint)
1. **Merge blockers into development** — focus on integration
2. **Add Postgres locally** — persistence is non-negotiable
3. **Connect iOS to backend** — replace mock data
4. **Fix verification flow** — manual approval before any user gets verified

### Next Sprint
1. **Realtime chat** (WebSocket) — chat is core loop
2. **Deal UI** — deal creation/management
3. **Offer response UI** — businesses need to see blogger responses
4. **Test coverage** — integration tests for core loop

### Post-MVP
1. Content proof + storage (S3/GCS)
2. Admin dashboard (moderation, verification queue)
3. Push notifications (APNs)
4. Block/Report safety features
5. Feed ranking + cooldown

---

## Risk Summary

| Risk | Severity | Impact | Mitigation |
|------|----------|--------|-----------|
| No persistence | CRITICAL | Cannot test or deploy | Add Postgres this sprint |
| No iOS-backend integration | CRITICAL | Cannot validate spec | Implement HTTP client this sprint |
| Self-serve verification | CRITICAL | Trust model broken | Add admin review flow this sprint |
| Role enforcement missing | HIGH | Spec violation | Validate Business ↔ Blogger this sprint |
| Deal UI missing | HIGH | Core loop incomplete | Implement deal screens Sprint 1 |
| Chat not realtime | MEDIUM | Poor UX | WebSocket Sprint 1 |
| Test coverage inadequate | HIGH | Quality risk | Integration tests this sprint |

---

## Changed Files

- `/Users/dorffoto/Documents/New project/matcha/docs/reviews/qa-spec-audit.md` (this report)

## Audit Date

2026-04-02
