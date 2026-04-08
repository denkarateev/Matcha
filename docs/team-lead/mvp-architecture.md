# MATCHA MVP Architecture -- Sprint 0 Technical Spec

> Last updated: 2026-04-02 | Author: Tech Lead Agent

---

## 1. Current State Assessment

### What exists

**iOS app** -- a SwiftUI prototype with:
- 5-tab shell (Offers, Activity, Match, Chats, Profile) working with mock data
- `@Observable` stores per feature, repository protocol (`MatchaRepository`) with mock implementation
- 3-step onboarding flow (welcome, credentials, profile) -- purely client-side, no network calls
- Design system: `MatchaTokens` (colors, spacing, radius), `GlassCard`, 3 button styles
- Models: `UserProfile`, `Offer`, `Deal`, `ChatPreview`, `ChatHome`, `ActivitySummary`, `OfferApplication`
- All data comes from `MockSeedData` -- no networking layer, no Codable conformances, no API client

**Backend** -- a FastAPI modular monolith with:
- 6 modules: auth, profile, matches, offers, chats, deals
- Each module has: router, schemas (Pydantic v2), service, repository protocol, domain models, InMemory repository
- Fully functional business logic for: register/login, verification, swipe/match, offer CRUD + responses, chat + messaging, deal lifecycle with reviews
- DI container (`AppContainer`) wired through `build_container()`
- Dev-token auth (no JWT yet), SHA256 password hashing (placeholder)
- All storage is `InMemoryStore` -- no database, no persistence

### What is broken or missing

1. **No networking layer on iOS** -- models are not `Codable`, no `APIClient`, no `URLSession` integration
2. **No database on backend** -- `InMemoryStore` loses all data on restart; no SQLAlchemy, no migrations
3. **iOS/backend model mismatch** -- iOS `UserProfile` has `heroSymbol`, `audience` as display strings; backend `Profile` has `audience_size` as int, `photo_urls` as list. These need alignment.
4. **No auth flow on iOS** -- onboarding writes to `AppState` directly, no token storage, no Keychain
5. **No error handling on iOS** -- stores catch errors silently (`catch { offers = [] }`)
6. **No feature flags** -- no mechanism for backend or client feature gating
7. **No push notifications** -- no device token registration, no APNs
8. **No WebSocket** -- chat is REST-only
9. **No media upload** -- no S3 integration, no presigned URLs
10. **No pagination** -- all list endpoints return everything
11. **Missing feed endpoint** -- the match feed on backend returns matches, not a ranked candidate feed

---

## 2. API Contract Definitions

All endpoints are prefixed with `/api/v1`. Authentication via `Authorization: Bearer {token}` header.

### 2.1 Auth Module

#### POST /api/v1/auth/register

```yaml
Request:
  Body:
    email: string (email format, required)
    password: string (min 8 chars, required)
    role: "blogger" | "business" (required)
    full_name: string (1-50 chars, required)
    primary_photo_url: string (required)
    category: string | null (required if role=business)
Response:
  201:
    access_token: string
    token_type: "bearer"
    user:
      id: string (uuid)
      email: string
      role: "blogger" | "business"
      full_name: string
      is_active: boolean
      verification_level: 0 | 1 | 2
      plan_tier: "free" | "pro" | "black"
      offer_credits: integer
      created_at: string (ISO 8601)
      updated_at: string (ISO 8601)
  409: { detail: string, error_code: "conflict" }
```

#### POST /api/v1/auth/login

```yaml
Request:
  Body:
    email: string (email format)
    password: string (min 8 chars)
Response:
  200:
    access_token: string
    token_type: "bearer"
    user: <UserRead>
  401: { detail: string, error_code: "unauthorized" }
```

#### GET /api/v1/auth/me

```yaml
Request:
  Headers: Authorization: Bearer {token}
Response:
  200: <UserRead>
  401: { detail: string, error_code: "unauthorized" }
```

#### POST /api/v1/auth/verify

```yaml
Request:
  Headers: Authorization: Bearer {token}
  Body:
    instagram_handle: string (required)
    tiktok_handle: string | null
    audience_size: integer (>= 1)
Response:
  200: <UserRead>
  401: { detail: string, error_code: "unauthorized" }
```

### 2.2 Profile Module

#### GET /api/v1/profiles/me

```yaml
Request:
  Headers: Authorization: Bearer {token}
Response:
  200: <ProfileRead>
  404: { detail: string, error_code: "not_found" }
```

#### PUT /api/v1/profiles/me

```yaml
Request:
  Headers: Authorization: Bearer {token}
  Body (all fields optional):
    display_name: string (1-50)
    photo_urls: [string]
    primary_photo_url: string
    country: string
    instagram_handle: string
    tiktok_handle: string
    audience_size: integer (>= 1)
    category: string
    district: string
    website: string (URL)
    niches: [string]
    languages: [string]
    bio: string (max 150)
    description: string (max 200)
    what_we_offer: string (max 200)
    collab_type: string
Response:
  200:
    user_id: string
    display_name: string
    photo_urls: [string]
    primary_photo_url: string
    country: string | null
    instagram_handle: string | null
    tiktok_handle: string | null
    audience_size: integer | null
    category: string | null
    district: string | null
    website: string | null
    niches: [string]
    languages: [string]
    bio: string | null
    description: string | null
    what_we_offer: string | null
    collab_type: string
    badges: [string]
    verified_visits: integer
    rating: float | null
    review_count: integer
    created_at: string (ISO 8601)
    updated_at: string (ISO 8601)
```

#### GET /api/v1/profiles/{user_id}

```yaml
Response:
  200: <ProfileRead>
  404: { detail: string, error_code: "not_found" }
```

### 2.3 Matches Module

#### GET /api/v1/matches

```yaml
Request:
  Headers: Authorization: Bearer {token}
Response:
  200:
    - id: string
      user_ids: [string, string]
      source: "swipe" | "offer"
      first_message_by: string | null
      created_at: string (ISO 8601)
```

#### POST /api/v1/matches/swipes

```yaml
Request:
  Headers: Authorization: Bearer {token}
  Body:
    target_id: string (uuid)
    direction: "left" | "right" | "super"
Response:
  200:
    swipe:
      id: string
      actor_id: string
      target_id: string
      direction: "left" | "right" | "super"
      delivered: boolean
      created_at: string (ISO 8601)
    match: <MatchRead> | null
  409: { detail: string, error_code: "conflict" }
```

#### GET /api/v1/matches/feed (NEW -- does not exist yet)

```yaml
Request:
  Headers: Authorization: Bearer {token}
  Query:
    limit: integer (default 10, max 20)
Response:
  200:
    profiles:
      - user_id: string
        display_name: string
        primary_photo_url: string
        audience_size: integer | null
        district: string | null
        niches: [string]
        bio: string | null
        collab_type: string
        badges: [string]
        verified_visits: integer
        rating: float | null
    pending_likes_count: integer
Business Rules:
  - Returns profiles the user has NOT swiped on
  - Excludes blocked users
  - Only returns cross-role matches (blogger sees businesses, business sees bloggers)
  - Ranked by: freshness, niche overlap, profile completeness, verification status
```

### 2.4 Offers Module

#### GET /api/v1/offers

```yaml
Request:
  Query:
    type: "barter" | "paid" | null
    niche: string | null
    last_minute_only: boolean (default false)
Response:
  200:
    - id: string
      business_id: string
      title: string
      type: "barter" | "paid"
      blogger_receives: string
      business_receives: string
      slots_total: integer
      slots_remaining: integer
      photo_url: string
      expires_at: string | null
      preferred_blogger_niche: string | null
      min_audience: string | null
      guests: string | null
      special_conditions: string | null
      is_last_minute: boolean
      status: "active" | "closed" | "expired"
      created_at: string (ISO 8601)
      updated_at: string (ISO 8601)
```

#### POST /api/v1/offers

```yaml
Request:
  Headers: Authorization: Bearer {token}
  Body:
    title: string (1-60)
    type: "barter" | "paid"
    blogger_receives: string (1-200)
    business_receives: string (1-200)
    slots_total: integer (1-10)
    photo_url: string
    expires_at: string | null
    preferred_blogger_niche: string | null
    min_audience: string | null
    guests: string | null
    special_conditions: string | null
    is_last_minute: boolean
Response:
  201: <OfferRead>
  403: { detail: string, error_code: "forbidden" }
  409: { detail: string, error_code: "conflict" }
Business Rules:
  - Only verified businesses can create
  - is_last_minute requires Black tier
  - Costs 1 offer credit
```

#### POST /api/v1/offers/{offer_id}/responses

```yaml
Request:
  Headers: Authorization: Bearer {token}
  Body:
    message: string | null (max 300)
Response:
  201:
    id: string
    offer_id: string
    business_id: string
    blogger_id: string
    status: "pending" | "accepted" | "declined"
    message: string | null
    created_at: string (ISO 8601)
    updated_at: string (ISO 8601)
Business Rules:
  - Only verified bloggers can respond
  - Max 3 responses per day per blogger
  - Cannot double-respond to same offer
```

#### GET /api/v1/offers/responses/incoming

```yaml
Request:
  Headers: Authorization: Bearer {token}
Response:
  200: [<OfferResponseRead>]
Business Rules:
  - Only businesses see their incoming responses
```

#### POST /api/v1/offers/responses/{response_id}/accept

```yaml
Response:
  200: <OfferResponseRead>
Business Rules:
  - Decrements slots_remaining
  - Creates match + chat automatically
```

#### POST /api/v1/offers/responses/{response_id}/decline

```yaml
Response:
  200: <OfferResponseRead>
```

### 2.5 Chats Module

#### GET /api/v1/chats

```yaml
Request:
  Headers: Authorization: Bearer {token}
Response:
  200:
    - id: string
      participant_ids: [string, string]
      match_id: string | null
      muted_user_ids: [string]
      created_at: string (ISO 8601)
      updated_at: string (ISO 8601)
```

#### GET /api/v1/chats/{chat_id}

```yaml
Response:
  200:
    id: string
    participant_ids: [string, string]
    match_id: string | null
    muted_user_ids: [string]
    created_at: string (ISO 8601)
    updated_at: string (ISO 8601)
    messages:
      - id: string
        chat_id: string
        sender_id: string
        text: string
        media_urls: [string]
        created_at: string (ISO 8601)
```

#### POST /api/v1/chats/{chat_id}/messages

```yaml
Request:
  Headers: Authorization: Bearer {token}
  Body:
    text: string (1-1000)
    media_urls: [string] (default [])
Response:
  201: <MessageRead>
Business Rules:
  - first_message_by rule: blogger writes first in swipe matches
```

### 2.6 Deals Module

#### GET /api/v1/deals

```yaml
Request:
  Headers: Authorization: Bearer {token}
Response:
  200: [<DealRead>]
```

#### POST /api/v1/deals

```yaml
Request:
  Headers: Authorization: Bearer {token}
  Body:
    counterparty_id: string
    type: "barter" | "paid"
    offered_text: string (1-200)
    requested_text: string (1-200)
    guests: string (default "solo")
    scheduled_for: string | null (ISO 8601)
    content_deadline: string | null (ISO 8601)
Response:
  201: <DealRead>
Business Rules:
  - One active deal per pair at a time
  - Creates/reuses chat between participants
```

#### Deal State Transitions

```
POST /deals/{id}/confirm   -- DRAFT -> CONFIRMED (by counterparty only)
POST /deals/{id}/check-in  -- CONFIRMED -> VISITED (when both check in)
POST /deals/{id}/no-show   -- CONFIRMED -> NO_SHOW (by checked-in party)
POST /deals/{id}/reviews   -- VISITED|NO_SHOW -> REVIEWED
POST /deals/{id}/cancel    -- DRAFT|CONFIRMED -> CANCELLED
```

#### DealRead schema

```yaml
  id: string
  chat_id: string
  participant_ids: [string, string]
  initiator_id: string
  type: "barter" | "paid"
  offered_text: string
  requested_text: string
  guests: string
  scheduled_for: string | null
  content_deadline: string | null
  status: "draft" | "confirmed" | "visited" | "no_show" | "reviewed" | "cancelled"
  checked_in_user_ids: [string]
  reviews:
    - reviewer_id: string
      reviewee_id: string
      punctuality: integer | null (1-5)
      offer_match: integer | null (1-5)
      communication: integer | null (1-5)
      comment: string | null
      created_at: string (ISO 8601)
  cancellation_reason: string | null
  created_at: string (ISO 8601)
  updated_at: string (ISO 8601)
```

---

## 3. Error Handling Strategy

### Backend error hierarchy

All domain errors extend `DomainError` and are caught by the global exception handler:

| Exception | HTTP Status | error_code |
|-----------|-------------|------------|
| `DomainError` | 400 | `domain_error` |
| `UnauthorizedError` | 401 | `unauthorized` |
| `ForbiddenError` | 403 | `forbidden` |
| `NotFoundError` | 404 | `not_found` |
| `ConflictError` | 409 | `conflict` |

### Standard error response shape

```json
{
  "detail": "Human-readable error message",
  "error_code": "machine_readable_code"
}
```

### iOS error handling strategy

```swift
enum MatchaAPIError: Error, LocalizedError {
    case unauthorized           // 401 -> redirect to login
    case forbidden(String)      // 403 -> show inline message
    case notFound               // 404 -> show empty state
    case conflict(String)       // 409 -> show inline message
    case networkError(Error)    // no connectivity
    case serverError(Int)       // 5xx -> show retry
    case decodingError(Error)   // JSON parse failure

    var errorDescription: String? { ... }
}
```

Rules:
- 401 always clears token and navigates to login
- 409 shows the `detail` string to the user as inline feedback
- 5xx shows a generic retry prompt
- Network errors trigger offline queue for idempotent writes (swipes, check-ins)
- All errors are logged with request context

---

## 4. Feature Flag Approach

### Backend

Add a `/api/v1/config` endpoint that returns flags at app launch:

```json
{
  "feature_flags": {
    "chat_enabled": true,
    "deals_enabled": true,
    "offers_enabled": true,
    "super_swipe_enabled": false,
    "last_minute_offers_enabled": false,
    "paid_plans_enabled": false,
    "push_notifications_enabled": false
  },
  "limits": {
    "max_queued_likes": 20,
    "max_daily_offer_responses": 3,
    "max_offer_slots": 10
  }
}
```

### iOS

```swift
@Observable
final class FeatureFlags {
    var chatEnabled = true
    var dealsEnabled = true
    var offersEnabled = true
    var superSwipeEnabled = false
    // ...

    func refresh() async { ... }
}
```

- Loaded at app launch, cached locally
- Checked before showing UI sections
- Backend is source of truth; iOS never hardcodes access rules

---

## 5. iOS/Backend Model Alignment

### Key mismatches to resolve

| iOS model | Backend model | Resolution |
|-----------|---------------|------------|
| `UserProfile.heroSymbol` (SF Symbol) | Not on server | iOS-only computed from role/category |
| `UserProfile.audience` (display string) | `Profile.audience_size` (int) | iOS formats from int |
| `UserProfile.secondaryLine` | Computed from category | Keep as iOS computed property |
| `Offer.rewardSummary` / `deliverableSummary` | `blogger_receives` / `business_receives` | Rename iOS to match API |
| `Offer.expiryText` | `expires_at` (datetime) | iOS formats from datetime |
| `Offer.creator` (embedded UserProfile) | `business_id` (string) | iOS fetches profile separately or uses enriched list endpoint |
| `ChatPreview` (display model) | `Chat` + last message query | iOS computes from chat + messages |
| `Deal.partnerName` / `scheduledDateText` | `participant_ids` / `scheduled_for` | iOS resolves from profile cache |

### Required iOS networking types (Codable)

These will mirror backend Pydantic schemas exactly:

- `APIUserRead` -> maps to `UserRead`
- `APIProfileRead` -> maps to `ProfileRead`
- `APIMatchRead` -> maps to `MatchRead`
- `APISwipeOutcomeRead` -> maps to `SwipeOutcomeRead`
- `APIOfferRead` -> maps to `OfferRead`
- `APIChatRead` -> maps to `ChatRead`
- `APIChatDetailRead` -> maps to `ChatDetailRead`
- `APIMessageRead` -> maps to `MessageRead`
- `APIDealRead` -> maps to `DealRead`

---

## 6. Database Migration Plan (InMemory -> PostgreSQL)

### Phase 1 (Sprint 0)

1. Add SQLAlchemy 2.x + Alembic to backend dependencies
2. Create SQLAlchemy models for all 6 modules
3. Implement PostgreSQL repository classes behind existing protocol interfaces
4. Wire `build_container()` to accept a `database_url` config
5. Create initial Alembic migration

### Tables

```
users
  id UUID PK
  email VARCHAR UNIQUE NOT NULL
  password_hash VARCHAR NOT NULL
  role VARCHAR NOT NULL
  full_name VARCHAR(50) NOT NULL
  is_active BOOLEAN DEFAULT TRUE
  verification_level SMALLINT DEFAULT 0
  plan_tier VARCHAR DEFAULT 'free'
  offer_credits INTEGER DEFAULT 0
  created_at TIMESTAMPTZ NOT NULL
  updated_at TIMESTAMPTZ NOT NULL

profiles
  user_id UUID PK FK(users.id)
  display_name VARCHAR(50) NOT NULL
  photo_urls JSONB DEFAULT '[]'
  primary_photo_url VARCHAR NOT NULL
  country VARCHAR
  instagram_handle VARCHAR
  tiktok_handle VARCHAR
  audience_size INTEGER
  category VARCHAR
  district VARCHAR
  website VARCHAR
  niches JSONB DEFAULT '[]'
  languages JSONB DEFAULT '[]'
  bio VARCHAR(150)
  description VARCHAR(200)
  what_we_offer VARCHAR(200)
  collab_type VARCHAR DEFAULT 'both'
  badges JSONB DEFAULT '[]'
  verified_visits INTEGER DEFAULT 0
  rating FLOAT
  review_count INTEGER DEFAULT 0
  created_at TIMESTAMPTZ NOT NULL
  updated_at TIMESTAMPTZ NOT NULL

swipes
  id UUID PK
  actor_id UUID FK(users.id) NOT NULL
  target_id UUID FK(users.id) NOT NULL
  direction VARCHAR NOT NULL
  delivered BOOLEAN NOT NULL
  created_at TIMESTAMPTZ NOT NULL
  INDEX (actor_id, target_id)
  INDEX (target_id, actor_id)

matches
  id UUID PK
  user_a_id UUID FK(users.id) NOT NULL
  user_b_id UUID FK(users.id) NOT NULL
  source VARCHAR NOT NULL
  first_message_by UUID FK(users.id)
  created_at TIMESTAMPTZ NOT NULL
  UNIQUE (user_a_id, user_b_id)

offers
  id UUID PK
  business_id UUID FK(users.id) NOT NULL
  title VARCHAR(60) NOT NULL
  type VARCHAR NOT NULL
  blogger_receives VARCHAR(200) NOT NULL
  business_receives VARCHAR(200) NOT NULL
  slots_total SMALLINT NOT NULL
  slots_remaining SMALLINT NOT NULL
  photo_url VARCHAR NOT NULL
  expires_at TIMESTAMPTZ
  preferred_blogger_niche VARCHAR
  min_audience VARCHAR
  guests VARCHAR
  special_conditions VARCHAR
  is_last_minute BOOLEAN DEFAULT FALSE
  status VARCHAR DEFAULT 'active'
  created_at TIMESTAMPTZ NOT NULL
  updated_at TIMESTAMPTZ NOT NULL

offer_responses
  id UUID PK
  offer_id UUID FK(offers.id) NOT NULL
  business_id UUID FK(users.id) NOT NULL
  blogger_id UUID FK(users.id) NOT NULL
  status VARCHAR DEFAULT 'pending'
  message VARCHAR(300)
  created_at TIMESTAMPTZ NOT NULL
  updated_at TIMESTAMPTZ NOT NULL

chats
  id UUID PK
  user_a_id UUID FK(users.id) NOT NULL
  user_b_id UUID FK(users.id) NOT NULL
  match_id UUID FK(matches.id)
  muted_user_ids JSONB DEFAULT '[]'
  created_at TIMESTAMPTZ NOT NULL
  updated_at TIMESTAMPTZ NOT NULL
  UNIQUE (user_a_id, user_b_id)

messages
  id UUID PK
  chat_id UUID FK(chats.id) NOT NULL
  sender_id UUID FK(users.id) NOT NULL
  text TEXT NOT NULL
  media_urls JSONB DEFAULT '[]'
  created_at TIMESTAMPTZ NOT NULL
  INDEX (chat_id, created_at)

deals
  id UUID PK
  chat_id UUID FK(chats.id) NOT NULL
  user_a_id UUID FK(users.id) NOT NULL
  user_b_id UUID FK(users.id) NOT NULL
  initiator_id UUID FK(users.id) NOT NULL
  type VARCHAR NOT NULL
  offered_text VARCHAR(200) NOT NULL
  requested_text VARCHAR(200) NOT NULL
  guests VARCHAR DEFAULT 'solo'
  scheduled_for TIMESTAMPTZ
  content_deadline TIMESTAMPTZ
  status VARCHAR DEFAULT 'draft'
  checked_in_user_ids JSONB DEFAULT '[]'
  cancellation_reason VARCHAR
  created_at TIMESTAMPTZ NOT NULL
  updated_at TIMESTAMPTZ NOT NULL

deal_reviews
  id UUID PK
  deal_id UUID FK(deals.id) NOT NULL
  reviewer_id UUID FK(users.id) NOT NULL
  reviewee_id UUID FK(users.id) NOT NULL
  punctuality SMALLINT
  offer_match SMALLINT
  communication SMALLINT
  comment VARCHAR(300)
  created_at TIMESTAMPTZ NOT NULL
  UNIQUE (deal_id, reviewer_id)
```

---

## 7. Architecture Diagram (text)

```
iOS App (SwiftUI)
  |
  |-- URLSession APIClient
  |     |-- Auth endpoints
  |     |-- Profile endpoints
  |     |-- Match/Feed endpoints
  |     |-- Offer endpoints
  |     |-- Chat endpoints (REST)
  |     |-- Deal endpoints
  |     |-- Config/flags endpoint
  |
  |-- Keychain (token storage)
  |-- Offline outbox (future)
  |
  v
FastAPI Backend (/api/v1)
  |
  |-- Auth Router    --> AuthService    --> AuthRepository    --> PostgreSQL
  |-- Profile Router --> ProfileService --> ProfileRepository --> PostgreSQL
  |-- Match Router   --> MatchService   --> MatchRepository   --> PostgreSQL
  |-- Offer Router   --> OfferService   --> OfferRepository   --> PostgreSQL
  |-- Chat Router    --> ChatService    --> ChatRepository    --> PostgreSQL
  |-- Deal Router    --> DealService    --> DealRepository    --> PostgreSQL
  |
  |-- DomainError exception handler (global)
  |-- AppContainer (DI)
  |-- Settings (env-based config)
```
