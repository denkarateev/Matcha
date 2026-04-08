# QA Regression Audit — 2026-04-04

Ролевая инструкция: `/Users/dorffoto/Documents/New project/matcha/docs/agents/04-QA-ENGINEER.md`

Базовый аудит для сравнения: `/Users/dorffoto/Documents/New project/matcha/docs/reviews/qa-spec-audit.md`

Область проверки:
- deals flow
- build status
- test status
- spec compliance vs accepted MVP

Команды, которыми я проверял текущее состояние:
- `cd "/Users/dorffoto/Documents/New project/matcha/ios" && xcodebuild build -project MATCHA.xcodeproj -scheme MATCHA -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'`
- `cd "/Users/dorffoto/Documents/New project/matcha/ios" && xcodebuild test -project MATCHA.xcodeproj -scheme MATCHA -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'`
- `cd "/Users/dorffoto/Documents/New project/matcha/backend" && python3 -c "from app.main import create_app; print('OK')"`
- `cd "/Users/dorffoto/Documents/New project/matcha/backend" && pytest -q`
- статический аудит через `rg -n`, `sed -n`, `nl -ba`

## Build Status

- iOS build: ✅
  `xcodebuild build` завершился `BUILD SUCCEEDED`.

- iOS tests: ⚠️ формально ✅, фактически с runtime warnings
  `xcodebuild test` завершился `TEST SUCCEEDED`, но во время запуска были:
  - ATS ошибка `NSURLErrorDomain Code=-1022` на `http://188.253.19.166:8842/api/v1/auth/me`
  - warnings `No symbol named 'shield.checkmark.fill'`
  - warnings `No symbol named 'mappin.fill'`
  Покрытие не изменилось по сути: выполнен 1 test, это все еще seed-data smoke.

- Backend startup: ❌
  `python3 -c "from app.main import create_app; print('OK')"` не стартует из-за `ModuleNotFoundError: No module named 'fastapi'`.

- Backend tests: ❌
  `pytest -q` не проходит стадию collection по той же причине: отсутствуют Python-зависимости.

Итог по build/test:
- iOS: green build, but not clean runtime
- Backend: still red at environment/bootstrap level

## Core Loop Status

- Auth: ⚠️ partial
  На iOS появились `AuthService` и `NetworkService`, но debug bootstrap по-прежнему пытается логиниться в live backend даже при `AppEnvironment.mock`.

- Profile: ⚠️ partial
  Есть `/profiles/me`, `/profiles/{user_id}`, `/profiles/me/photos`, а также iOS API wiring. Но feed-контракт на iOS ожидает `GET /profiles`, которого backend не отдает.

- Feed: ❌
  На iOS есть `APIMatchaRepository.fetchMatchFeed()`, но он вызывает несуществующий список профилей `/profiles`. Это ломает переход от mock к реальному discovery.

- Swipe/Match: ⚠️ partial
  Shadow like logic и mutual match по-прежнему есть на backend, но сервер все еще не запрещает same-role swipe. Feed/business-role restriction в accepted MVP не закрыты.

- Chat: ⚠️ partial
  Появились системные сообщения для deals и iOS chat now can launch deal creation/review flow. Но 48h expiry, realtime, read receipts, полноценный conversation sync и safety actions на backend не доведены.

- Deals: ⚠️ strongest improvement, но не ready
  Это зона с самым заметным прогрессом: появились новые backend endpoints, activity summary, deal-related iOS screens и chat entry point. Но flow остается частично локальным и контрактно не доведен end-to-end.

## Deals Flow Audit

### What improved since previous audit

- Backend deals API стал заметно шире:
  - `GET /deals/{deal_id}`
  - `POST /deals/{deal_id}/accept`
  - `POST /deals/{deal_id}/decline`
  - `POST /deals/{deal_id}/review`
  - `POST /deals/{deal_id}/rate`
  - `POST /deals/{deal_id}/content-proof`
  - `POST /deals/{deal_id}/repeat`
  Это уже лучше, чем в прошлом аудите, где deals были только базовым state machine.

- DealService усилился:
  - support нового payload shape `partner_id / you_offer / you_receive`
  - `accept_deal`
  - `decline_deal`
  - `submit_content_proof`
  - `repeat_deal`
  - system messages in chat on status changes

- На iOS появились полноценные deal-focused screens:
  - `CreateDealView`
  - `DealPipelineView`
  - `ReviewDealView`
  - `ContentProofView`
  - `DealDetailView`
  - `DealsView`
  - deal entry point из `ChatConversationView`

### What is still broken or incomplete

- Deal detail screen остается mostly simulated.
  В `DealDetailView` ключевые действия помечены комментариями `In real app: call backend` / `In real app: submit review to backend` / `In real app: upload proof to backend`, то есть экран визуально богатый, но не fully wired.

- Chat-driven deals flow only partially uses backend.
  `ChatConversationView` реально вызывает `submitReview` и `checkInDeal`, но сами сообщения чата и часть состояния остаются локальными mock structures.

- iOS repository covers only part of deals contract.
  Есть `createDeal`, `acceptDeal`, `confirmDeal`, `checkInDeal`, `submitReview`, `cancelDeal`, но нет методов для:
  - `declineDeal`
  - `submitContentProof`
  - `repeatDeal`
  - fetch/render applications from `activity/summary`

- Activity summary on iOS still bypasses the new backend activity endpoint.
  Backend теперь отдает `GET /activity/summary`, но `APIMatchaRepository.fetchActivitySummary()` продолжает дергать `GET /deals` и locally aggregates summary, leaving `likes` and `applications` empty.

- Partner identity in deals/chat remains lossy.
  `APIMatchaRepository.makeLegacyDeal()` uses `participantIds.first` as `partnerName`, а chat preview строится через placeholder partner. Это не соответствует реальному UX/spec quality.

- No true end-to-end deals regression test exists.
  Backend test suite все еще не покрывает `create deal -> accept -> check-in -> content proof -> review -> repeat` even on paper. iOS tests вообще не покрывают deals flow.

## Business Rules

- Shadow account: max 20 pending likes: ✅ backend still enforced
- Shadow likes activate on verification: ✅ backend still enforced
- Role restriction `Business <-> Blogger only`: ❌ still not enforced server-side
- Blogger writes first in swipe-match: ✅ partial backend rule still present
- Offer response limit `3/day` by WITA: ✅ backend logic still present
- Business needs verification for offer creation: ✅ backend logic still present
- One active deal per pair: ✅ partial
  Service blocks second active deal, but persistence/integration guarantees are still weak
- Deal state machine: ✅ improved
  draft -> confirmed/declined/cancelled -> visited/no_show -> reviewed
- Mutual check-in required for `VISITED`: ✅ backend enforced
- SuperSwipe requires verified status: ❌ still not enforced as a dedicated business rule

## Spec Compliance

### Improved since previous audit

- iOS is no longer 100% mock in architecture terms.
  There is now a real `NetworkService`, `AuthService`, and `APIMatchaRepository`.

- Deals slice is materially closer to accepted MVP.
  Backend and iOS both now have recognizable surfaces for create/accept/check-in/review/content proof.

- Backend no longer loses all data strictly on process restart in the same way.
  `InMemoryStore` now persists to `/tmp/matcha_store.pickle`, which is better than pure volatile memory.

### Still non-compliant or only partially compliant

- Accepted MVP requires real Business ↔ Blogger-only product slice.
  Backend still allows same-role swipes and same-role deals structurally.

- Accepted MVP requires real verification funnel and trust workflow.
  `/auth/verify` is still self-serve; no admin verification queue, no evidence review.

- Accepted MVP requires reliable buildable backend/testing path.
  Backend still cannot even start in the current environment without manual dependency setup.

- Accepted MVP core loop still fails end-to-end on iOS.
  The app now has networking code, but discovery contract is broken and launch/bootstrap hits ATS-blocked HTTP.

- Safety/moderation remains mostly visual or absent.
  `BlockReportView` exists in iOS, but there is still no real backend report/block/moderation workflow visible in this audit pass.

## Comparison With Previous Audit

### Resolved or improved

1. Previous issue: `iOS is 100% mock data`
   Status now: partially improved
   There is real API/auth/repository code, though not fully working end-to-end.

2. Previous issue: `No deal creation UI`
   Status now: improved
   Multiple deal screens and chat entry points now exist.

3. Previous issue: `No activity endpoint`
   Status now: improved
   Backend now has `/activity/summary`.

4. Previous issue: `Data lost on restart`
   Status now: partially improved
   In-memory store now persists to a pickle file, but still does not meet accepted Postgres-backed MVP architecture.

### Still unresolved

1. Backend tests fail because dependencies are missing
2. Verification remains self-serve
3. Role restriction still missing
4. 48h first-message deadline still missing
5. Real end-to-end iOS/backend loop still not validated
6. Test coverage still effectively minimal

### New regressions / newly surfaced issues

1. iOS launch path now performs live auth calls even in debug/mock usage.
   This creates ATS failures during test/runtime and makes the mock/live boundary unstable.

2. iOS repository contract does not match backend discovery/profile API.
   `GET /profiles` is expected by iOS but backend only exposes `/profiles/me` and `/profiles/{user_id}`.

3. iOS tests are now green with runtime networking/symbol warnings.
   This is worse from QA confidence perspective than a pure mock app because the suite looks healthy while surfacing hidden runtime misconfigurations.

## New Bugs Found

1. [high] iOS debug app still performs live auth bootstrap even when `AppEnvironment.mock` is selected, causing ATS failures and unstable test/runtime behavior. `/Users/dorffoto/Documents/New project/matcha/ios/MATCHA/App/MATCHAApp.swift:9` `/Users/dorffoto/Documents/New project/matcha/ios/MATCHA/App/AppState.swift:55` `/Users/dorffoto/Documents/New project/matcha/ios/MATCHA/Shared/Services/NetworkService.swift:101`

2. [high] `APIMatchaRepository.fetchMatchFeed()` calls `GET /profiles`, but backend does not expose that endpoint, so live feed integration cannot work. `/Users/dorffoto/Documents/New project/matcha/ios/MATCHA/Shared/Services/APIMatchaRepository.swift:18` `/Users/dorffoto/Documents/New project/matcha/backend/app/modules/profile/router.py:24`

3. [high] Deals UI overstates implementation maturity: `DealDetailView` still leaves cancel/review/content-proof actions as local placeholders, so users can navigate the flow without guaranteed server-side state change. `/Users/dorffoto/Documents/New project/matcha/ios/MATCHA/Features/Activity/DealDetailView.swift:85`

4. [medium] Activity integration is incomplete: backend now has `/activity/summary`, but iOS ignores it and derives partial summary from `/deals`, dropping likes and applications. `/Users/dorffoto/Documents/New project/matcha/backend/app/modules/activity/router.py:21` `/Users/dorffoto/Documents/New project/matcha/ios/MATCHA/Shared/Services/APIMatchaRepository.swift:54`

5. [medium] Same-role restriction is still missing in match logic, so accepted MVP scope is still violated despite new integration work. `/Users/dorffoto/Documents/New project/matcha/backend/app/modules/matches/service.py:25`

6. [medium] Backend persistence remains outside accepted MVP architecture: pickle-backed in-memory state is better than before, but DB repositories/migrations are not wired into the main container. `/Users/dorffoto/Documents/New project/matcha/backend/app/core/container.py:39`

## Regressions

1. Discovery integration regressed from "explicitly mock only" to "appears live-capable but is contract-broken". The previous audit called out missing integration; now the code suggests integration exists, but `fetchMatchFeed()` cannot succeed against current backend routes.

2. Test confidence regressed in quality even though iOS remains green. The suite now boots code paths that hit insecure live HTTP and invalid symbols, so "tests passed" is less trustworthy than it looks.

3. Debug app startup regressed in isolation. The app is configured with `AppEnvironment.mock` in debug, but bootstrap auth ignores that boundary and calls live backend auth anyway.

## Recommendation

Block.

Причина:
- deals flow улучшился сильнее всего, но still not end-to-end reliable
- iOS/backend contracts are not aligned for discovery/activity
- backend build/test status is still red
- new integration work introduced runtime regressions that the current tests do not catch strongly enough

## Next Fixes

1. Make debug/mock mode truly offline-safe.
   `bootstrapIfNeeded()` must respect `AppEnvironment.mock` and avoid live auth/network side effects in test/debug mock runs.

2. Align discovery contract.
   Either add backend `GET /profiles` / dedicated feed endpoint, or change iOS repository to use an actually supported endpoint.

3. Finish deals wiring end-to-end.
   Wire cancel, content-proof, repeat, deal-detail actions to repository/backend; remove placeholder local-only branches.

4. Use `/activity/summary` from iOS.
   Stop reconstructing partial activity from `/deals`.

5. Enforce `Business <-> Blogger only` server-side.

6. Restore backend developer baseline.
   At minimum, make `create_app` importable and `pytest -q` runnable in a documented local environment.

7. Add regression tests for the deal loop.
   Minimum backend path:
   `register -> verify -> match -> create deal -> accept -> check-in -> content proof -> review`

## Changed files

- `/Users/dorffoto/Documents/New project/matcha/docs/reviews/qa-regression-audit-2026-04-04.md`
