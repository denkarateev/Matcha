# MATCHA Sprint 0 Plan

> Sprint duration: 2 weeks | Goal: connect iOS to real backend, persist data, prove auth-to-feed flow

---

## Sprint 0 Priorities

### P0: Auth + Networking Foundation

**Goal:** A user can register, login, and receive a token. iOS stores the token and uses it for subsequent requests.

**Backend Developer:**
- Add SQLAlchemy 2.x models for `users` and `profiles` tables
- Add Alembic, create initial migration
- Implement `PostgresAuthRepository` and `PostgresProfileRepository`
- Add `database_url` to Settings, wire into `build_container()`
- Replace SHA256 password hashing with bcrypt
- Add `/api/v1/config` endpoint returning feature flags and limits
- Keep InMemory repos as fallback for tests

**iOS Developer:**
- Create `APIClient` class wrapping URLSession with: base URL, auth header injection, JSON decoding, error mapping
- Create `AuthService` with `register()`, `login()`, `me()` methods
- Create `KeychainManager` for secure token storage
- Create Codable DTOs: `APIUserRead`, `APIAuthTokenRead`, `APIRegisterRequest`, `APILoginRequest`
- Create `SessionManager` (Observable) that holds current user state and token
- Wire `MATCHAApp` to check token on launch, route to onboarding or tab shell
- Connect `OnboardingFlowView` to real register endpoint

**Designer:**
- Finalize onboarding screen designs (3 steps) with all states: loading, error, success
- Design login screen (email/password + Apple/Google placeholders)
- Design error banner component for inline API errors
- Design loading state for all list views

```yaml
Feature: Registration
Endpoint: POST /api/v1/auth/register
Request:
  Headers: Content-Type: application/json
  Body: { email: string, password: string, role: string, full_name: string, primary_photo_url: string, category: string? }
Response:
  201: { access_token: string, token_type: "bearer", user: UserRead }
  409: { detail: string, error_code: "conflict" }
iOS Integration:
  Service method: func register(_ request: RegisterRequest) async throws -> AuthTokenResponse
  View binding: OnboardingStore -> OnboardingFlowView
Business Rules:
  - Email must be unique
  - Password min 8 characters
  - role must be "blogger" or "business"
  - Creates user + empty profile in one transaction
```

```yaml
Feature: Login
Endpoint: POST /api/v1/auth/login
Request:
  Headers: Content-Type: application/json
  Body: { email: string, password: string }
Response:
  200: { access_token: string, token_type: "bearer", user: UserRead }
  401: { detail: string, error_code: "unauthorized" }
iOS Integration:
  Service method: func login(_ request: LoginRequest) async throws -> AuthTokenResponse
  View binding: SessionManager -> MatchaAppView (routes to tab shell)
Business Rules:
  - Returns same token shape as register
  - Inactive users get 401
```

```yaml
Feature: Current User
Endpoint: GET /api/v1/auth/me
Request:
  Headers: Authorization: Bearer {token}
Response:
  200: UserRead
  401: { detail: string, error_code: "unauthorized" }
iOS Integration:
  Service method: func me() async throws -> UserRead
  View binding: SessionManager (called on app launch to validate token)
Business Rules:
  - Used to restore session from stored token
```

---

### P1: Profile CRUD

**Goal:** User can view and edit their profile. Profile data persists across app restarts.

**Backend Developer:**
- Implement `PostgresProfileRepository` with upsert, get, increment_visits, apply_review_score
- Add profile completeness calculation (percentage)
- Add `GET /api/v1/profiles/me/completeness` endpoint

**iOS Developer:**
- Create Codable DTOs: `APIProfileRead`, `APIProfileUpdateRequest`
- Create `ProfileService` with `getMyProfile()`, `updateMyProfile()`, `getProfile(userId:)`
- Refactor `ProfileView` and `ProfileStore` to load from API
- Add edit profile form (display name, bio, niches, district, photo placeholder)
- Show verification status and completeness percentage

**Designer:**
- Design edit profile screen
- Design profile completeness indicator (progress ring or bar)
- Design verification badge states (shadow, verified)

```yaml
Feature: Get My Profile
Endpoint: GET /api/v1/profiles/me
Request:
  Headers: Authorization: Bearer {token}
Response:
  200: ProfileRead
  404: { detail: string, error_code: "not_found" }
iOS Integration:
  Service method: func getMyProfile() async throws -> ProfileRead
  View binding: ProfileStore -> ProfileView
Business Rules:
  - Profile is created automatically during registration
```

```yaml
Feature: Update Profile
Endpoint: PUT /api/v1/profiles/me
Request:
  Headers: Authorization: Bearer {token}
  Body: { display_name?: string, bio?: string, niches?: [string], district?: string, ... }
Response:
  200: ProfileRead
iOS Integration:
  Service method: func updateMyProfile(_ request: ProfileUpdateRequest) async throws -> ProfileRead
  View binding: EditProfileStore -> EditProfileView
Business Rules:
  - Only provided fields are updated (PATCH semantics over PUT)
  - Validation: display_name 1-50 chars, bio max 150
```

---

### P2: Match Feed (Discovery)

**Goal:** Users see a ranked feed of other-role profiles and can swipe. Shadow users queue likes.

**Backend Developer:**
- Add `GET /api/v1/matches/feed` endpoint returning profiles the user has not swiped on
- Filter by opposite role, exclude blocked users
- Simple ranking: freshness + profile completeness + verification status
- Implement `PostgresMatchRepository` with swipe storage and feed query
- Add pending likes count to feed response

**iOS Developer:**
- Create Codable DTOs: `APIFeedResponse`, `APISwipeRequest`, `APISwipeOutcomeRead`
- Create `MatchFeedService` with `fetchFeed()`, `swipe(targetId:direction:)`
- Refactor `MatchFeedView` and `MatchFeedStore` to use API
- Show real pending likes count
- Handle swipe outcomes (show match animation if match returned)
- Handle 409 errors (queue limit reached)

**Designer:**
- Design match animation overlay
- Design queue-full state for shadow users
- Design swipe feedback (card slide animation specs)

```yaml
Feature: Match Feed
Endpoint: GET /api/v1/matches/feed
Request:
  Headers: Authorization: Bearer {token}
  Query: limit=10
Response:
  200: { profiles: [FeedProfileRead], pending_likes_count: integer }
iOS Integration:
  Service method: func fetchFeed(limit: Int) async throws -> FeedResponse
  View binding: MatchFeedStore -> MatchFeedView
Business Rules:
  - Cross-role only: bloggers see businesses, businesses see bloggers
  - Excludes already-swiped profiles
  - Shadow users see feed but likes are queued (delivered=false)
  - Max 20 queued likes for shadow users
```

```yaml
Feature: Swipe
Endpoint: POST /api/v1/matches/swipes
Request:
  Headers: Authorization: Bearer {token}
  Body: { target_id: string, direction: "left" | "right" | "super" }
Response:
  200: { swipe: SwipeRead, match: MatchRead? }
  409: { detail: string, error_code: "conflict" }
iOS Integration:
  Service method: func swipe(targetId: String, direction: SwipeDirection) async throws -> SwipeOutcome
  View binding: MatchFeedStore -> MatchFeedView (skip/interested/super buttons)
Business Rules:
  - "left" = skip, "right" = interested, "super" = super swipe
  - If both parties swiped right/super and both delivered, creates match
  - Shadow swipes are queued (delivered=false)
  - 409 if shadow user exceeds 20 queued likes
```

---

### P3: Offers Marketplace

**Goal:** Businesses can create offers. Bloggers can browse and respond. Responses can be accepted/declined.

**Backend Developer:**
- Implement `PostgresOfferRepository`
- Add expiry check logic (mark expired offers on read)
- Ensure offer credit deduction is transactional

**iOS Developer:**
- Create Codable DTOs for offers
- Create `OfferService` with `listOffers()`, `respondToOffer()`, `createOffer()`
- Refactor `OffersView` and `OffersStore` to use API
- Add offer detail view
- Add offer response form (blogger side)
- Add create offer form (business side)
- Add incoming responses list (business side)

```yaml
Feature: List Offers
Endpoint: GET /api/v1/offers
Request:
  Query: type?, niche?, last_minute_only?
Response:
  200: [OfferRead]
iOS Integration:
  Service method: func listOffers(type: String?, niche: String?, lastMinuteOnly: Bool) async throws -> [OfferRead]
  View binding: OffersStore -> OffersView
Business Rules:
  - Only active offers returned
  - Filters are optional, combinable
```

```yaml
Feature: Respond to Offer
Endpoint: POST /api/v1/offers/{offer_id}/responses
Request:
  Headers: Authorization: Bearer {token}
  Body: { message?: string }
Response:
  201: OfferResponseRead
  403: { detail: string, error_code: "forbidden" }
  409: { detail: string, error_code: "conflict" }
iOS Integration:
  Service method: func respondToOffer(offerId: String, message: String?) async throws -> OfferResponseRead
  View binding: OfferDetailStore -> OfferDetailView
Business Rules:
  - Only verified bloggers
  - Max 3 per day
  - Cannot respond twice to same offer while pending
```

---

### P4: Chat (REST)

**Goal:** Matched users can send and read messages in 1:1 chats.

**Backend Developer:**
- Implement `PostgresChatRepository`
- Add pagination to messages endpoint (cursor-based)
- Add last_message and unread_count to chat list response (enriched)

**iOS Developer:**
- Create Codable DTOs for chats and messages
- Create `ChatService` with `listChats()`, `getChat()`, `sendMessage()`
- Refactor `ChatsView` and `ChatsStore` to use API
- Build chat detail view with message list and input
- Show last message preview and timestamp in chat list
- Handle first_message_by rule (show prompt to correct user)

```yaml
Feature: List Chats
Endpoint: GET /api/v1/chats
Request:
  Headers: Authorization: Bearer {token}
Response:
  200: [ChatRead]
iOS Integration:
  Service method: func listChats() async throws -> [ChatRead]
  View binding: ChatsStore -> ChatsView
Business Rules:
  - Returns all chats where user is participant
  - Ordered by updated_at descending
```

```yaml
Feature: Send Message
Endpoint: POST /api/v1/chats/{chat_id}/messages
Request:
  Headers: Authorization: Bearer {token}
  Body: { text: string, media_urls?: [string] }
Response:
  201: MessageRead
  409: { detail: string, error_code: "conflict" }
iOS Integration:
  Service method: func sendMessage(chatId: String, text: String, mediaUrls: [String]) async throws -> MessageRead
  View binding: ChatDetailStore -> ChatDetailView
Business Rules:
  - First message in swipe-match must come from blogger
  - Text 1-1000 chars
```

---

### P5: Deal Lifecycle

**Goal:** Users can propose, confirm, check-in, review, and cancel deals through the chat context.

**Backend Developer:**
- Implement `PostgresDealRepository`
- Add deal state machine validation
- Ensure one-active-deal-per-pair constraint at database level

**iOS Developer:**
- Create Codable DTOs for deals
- Create `DealService` with all deal operations
- Build deal card component (shown in chat and activity)
- Build deal creation form
- Build review submission form
- Refactor `ActivityView` to load deals from API

```yaml
Feature: Create Deal
Endpoint: POST /api/v1/deals
Request:
  Headers: Authorization: Bearer {token}
  Body: { counterparty_id: string, type: string, offered_text: string, requested_text: string, guests?: string, scheduled_for?: string, content_deadline?: string }
Response:
  201: DealRead
  409: { detail: string, error_code: "conflict" }
iOS Integration:
  Service method: func createDeal(_ request: DealCreateRequest) async throws -> DealRead
  View binding: DealCreateStore -> DealCreateView (from chat context)
Business Rules:
  - One active deal per pair
  - Creates/reuses chat
  - Initial status is "draft"
```

---

## Task Assignment Summary

### Designer
| Priority | Task |
|----------|------|
| P0 | Onboarding screens: all 3 steps with loading/error/success states |
| P0 | Login screen design |
| P0 | Error banner and loading state components |
| P1 | Edit profile screen, completeness indicator |
| P2 | Match animation, queue-full state, swipe feedback |
| P3 | Offer detail view, offer response form, create offer form |
| P4 | Chat detail view with message bubbles and input |
| P5 | Deal card component, deal creation form, review form |

### iOS Developer
| Priority | Task |
|----------|------|
| P0 | `APIClient` (URLSession, auth headers, error mapping) |
| P0 | `KeychainManager` for token storage |
| P0 | `SessionManager` (Observable, token check on launch) |
| P0 | Codable DTOs for auth module |
| P0 | Connect onboarding to register endpoint |
| P0 | Login screen + connect to login endpoint |
| P1 | Profile service, edit profile, completeness display |
| P2 | Feed service, refactor MatchFeedView to API |
| P2 | Swipe action connected to API |
| P3 | Offers service, list/detail/respond/create flows |
| P4 | Chat service, chat list, chat detail with messaging |
| P5 | Deal service, deal card, create/confirm/review flows |
| P5 | Activity view connected to API |

### Backend Developer
| Priority | Task |
|----------|------|
| P0 | Add SQLAlchemy 2.x + Alembic, initial migration |
| P0 | `PostgresAuthRepository` + `PostgresProfileRepository` |
| P0 | Replace SHA256 with bcrypt |
| P0 | `/api/v1/config` endpoint (feature flags) |
| P0 | Wire database into `build_container()` |
| P1 | Profile completeness endpoint |
| P2 | `GET /api/v1/matches/feed` endpoint (new) |
| P2 | `PostgresMatchRepository` |
| P3 | `PostgresOfferRepository` + expiry logic |
| P4 | `PostgresChatRepository` + pagination + enriched list |
| P5 | `PostgresDealRepository` + state machine + DB constraint |

### QA/Marketing
| Priority | Task |
|----------|------|
| P0 | Set up local test environment (backend + iOS simulator) |
| P0 | Write smoke test checklist for auth flow |
| P0 | Verify error responses match spec |
| P1 | Test profile CRUD edge cases |
| P2 | Test swipe flow: shadow queueing, match creation |
| P3 | Test offer lifecycle: create, respond, accept, decline |
| P4 | Test chat: first-message rule, message delivery |
| P5 | Test deal state machine: all valid and invalid transitions |
| P5 | App Store metadata draft |

---

## Exit Criteria for Sprint 0

1. A new user can register via iOS, receive a token, and see it persisted across app restarts
2. User can view and edit their profile, data persists in PostgreSQL
3. User can see a ranked feed of opposite-role profiles
4. User can swipe right/left, see match when mutual
5. Matched users can open a chat and exchange messages
6. All backend data persists in PostgreSQL (no more InMemoryStore in prod config)
7. All API errors return the standard `{ detail, error_code }` shape
8. Feature flags endpoint responds and iOS reads it on launch
