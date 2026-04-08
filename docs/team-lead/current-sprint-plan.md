# MATCHA Current Sprint Plan

> Updated: 2026-04-04  
> Owner: Team Lead MATCHA  
> Sprint intent: привести MVP обратно к целевому core loop `onboarding -> verification -> discovery -> match -> chat -> deal -> review`, не ломая текущую кодовую базу и не раздувая скоуп.

## 1. Reassessment: что уже изменилось с прошлых аудитов

Прошлые аудиты из `docs/reviews` по-прежнему полезны, но часть выводов уже устарела. За последние дни команда добавила базовые куски live-интеграции, однако они пока не собраны в рабочий вертикальный сценарий.

### Что действительно появилось с момента аудитов

- В iOS уже есть каркас live-сетевого слоя: `NetworkService`, `AuthService`, `APIMatchaRepository`.
- Онбординг больше не чисто моковый: `OnboardingFlowView` умеет `login/register`.
- На backend уже есть `GET /matches/feed`, `GET /deals/{id}` и SQLAlchemy-модели/DB-repository-заготовки.
- Bali-first copy в онбординге и части discovery уже подтянута, поэтому маркетинговый аудит теперь надо воспринимать как частично закрытый.

### Что остается фактическим блокером прямо сейчас

- Приложение в `DEBUG` все еще поднимается с `AppEnvironment.mock`, поэтому auth/bootstrap и feature tabs живут в разных режимах.
- `APIMatchaRepository` ходит в несуществующий `GET /profiles` вместо канонического `GET /matches/feed`.
- `EditProfileView` не сохраняет профиль в backend, а имитирует сеть через `sleep`.
- Deal flow в UI частично живой, но местами остается best-effort: локально вставляет success/system messages даже при ошибке API.
- Backend по-прежнему собирается через `InMemory*` репозитории; Postgres-модели есть, но не wired, миграций нет.
- Verification все еще self-serve через `POST /auth/verify`, без pending state, доказательств и review queue.
- Правило `business <-> blogger only` частично есть в feed, но не enforced внутри `swipe()` service.
- Информационная архитектура ушла от spec: вместо таба `Activity` в shell сейчас отдельный таб `Deals`.

### Ключевые артефакты, на которые опирается этот план

- `ios/MATCHA/App/MATCHAApp.swift`
- `ios/MATCHA/Shared/Services/APIMatchaRepository.swift`
- `ios/MATCHA/Features/Profile/EditProfileView.swift`
- `ios/MATCHA/App/Navigation/AppTab.swift`
- `backend/app/core/container.py`
- `backend/app/modules/auth/service.py`
- `backend/app/modules/matches/service.py`
- `backend/migrations/versions/.gitkeep`

## 2. Выводы из референса Bmatch2

Bmatch2 полезен не как продуктовый эталон, а как источник дисциплины для server-owned business rules.

### Что берем

- Server-side enforcement для swipe/deal transitions, а не optimistic business logic на клиенте.
- Валидацию и sanitization до записи данных.
- Простую, но жесткую модель статусов и ограничений на уровне storage/contracts.
- Явную пагинацию и предсказуемые query paths.

### Что не копируем буквально

- Плоский profile experience без внятного verification bridge.
- Слабый deal UX без chat-first collaboration loop.
- Отсутствие полноценного spec-level chat/deal/review orchestration.
- Привязку к generic marketplace UX без MATCHA-specific trust narrative.

## 3. Sprint Goal

За ближайший спринт команда должна доказать один рабочий вертикальный сценарий на live-данных:

1. пользователь логинится/регистрируется;
2. попадает в реальный feed;
3. открывает chat/match;
4. создает deal;
5. подтверждает deal;
6. видит deal progress в personal cabinet;
7. может завершить review path;
8. profile/activity отражают реальное состояние, а не мок/placeholder.

Без этого profile redesign и marketing polish останутся декоративными.

## 4. Приоритизированный execution plan

### P0. Починить live-контур и вернуть deals в рабочее состояние

**Почему это первое:** сейчас deals "как будто есть", но end-to-end сценарий недостоверен из-за смешения mock/live, несовпадения контрактов и локальных fallback-успехов.

**Scope**

- Переключить iOS runtime на единый live/manual-switch режим для debug-сборок.
- Привести `APIMatchaRepository` к реальным backend endpoints и payload shapes.
- Убрать локальный optimistic-success там, где он скрывает реальные API ошибки.
- Зафиксировать один канонический deal contract для chat, deals list и detail.
- Добить минимальный persistence slice под auth/profile/matches/deals, чтобы сценарий не жил только в in-memory store.

**Главные задачи**

- iOS:
  - заменить использование `GET /profiles` на `GET /matches/feed`;
  - синхронизировать paths для create/accept/check-in/review/cancel deal;
  - перестать подменять backend исход локальными system messages;
  - соединить `ChatConversationView`, `CreateDealView`, `DealsView`, `ProfileView` с одним источником правды.
- Backend:
  - wire `Auth/Profile/Match/Deal` DB repositories в контейнер хотя бы для focused MVP slice;
  - создать первую рабочую migration baseline;
  - дотянуть `GET /matches/feed` и deal endpoints до стабильного contract-level поведения;
  - добавить protection на one active deal per pair и cross-role validation внутри swipe/deal entry points.

**Definition of Done**

- В debug/live режиме можно пройти сценарий `register -> feed -> swipe/match -> chat -> create deal -> accept -> check-in -> review`.
- Ни один шаг не зависит от `MockMatchaRepository`, `MockSeedData` или локальной имитации success.
- Падение backend больше не маскируется в UI как успешный deal action.

### P0. Redesign profile/personal cabinet как центральный trust surface

**Почему это второе P0:** profile сейчас визуально сильнее, чем поведенчески полезен. Он не соответствует design brief как "identity + media + verification bridge + settings", а personal cabinet расползся между `Profile` и `Deals`.

**Целевое решение**

- `Profile` остается лицом пользователя.
- `Activity` возвращается как отдельная таб-роль personal cabinet: likes, deals, responses.
- `Profile` фокусируется на identity, media, niches/category, verification bridge, trust signals и settings.
- `Activity` фокусируется на "что требует моего внимания сейчас".

**Scope redesign**

- Вернуть IA к spec: таб `Deals` переименовать и переразложить в `Activity`.
- Пересобрать `Profile` по блокам:
  - identity hero;
  - media/portfolio wall;
  - niches/category/collab preferences;
  - verification progress + unlock narrative;
  - stats/social proof;
  - settings/privacy.
- Сделать отдельные variants для creator и business, но на одном паттерне.
- Перестать держать verification checklist как pseudo-gamification без backend meaning.

**Definition of Done**

- Пользователь может отредактировать профиль и увидеть сохраненный результат после перезапуска.
- Profile объясняет, что еще не заполнено, что это unlock-ит и зачем это нужно.
- Activity отвечает на вопрос: "что мне делать сейчас?" без чтения списка вручную.

### P1. Закрыть spec compliance gaps, которые ломают MVP-смысл

**Критичные несоответствия**

- `Deals` вместо `Activity` в primary navigation.
- Verification без pending/manual review.
- Нет полноценного role enforcement в `swipe()` service.
- Profile edit и media flow не соответствуют design brief.
- Chat/deal path не защищен от invalid states так же строго, как в референсе Bmatch2.

**Scope**

- Зафиксировать canonical MVP rules в контрактах и тестах:
  - только `business <-> blogger`;
  - verification имеет минимум `shadow -> pending -> verified`;
  - deal actions доступны только из валидных состояний;
  - activity/profile/chats читают одно и то же state происхождение.
- Добавить spec matrix для QA на эти правила.

**Definition of Done**

- Все P0/P1 user flows покрыты acceptance matrix.
- Команда перестает обсуждать "как должно быть" по памяти: правила явно лежат в contracts/tests/docs.

### P1. Подготовить следующий спринт, не распыляясь на лишнее

**В этот спринт не расширяем**

- WebSocket/realtime chat
- APNs/push
- S3 media pipeline
- Admin backoffice UI
- Offline outbox

**Но должны подготовить**

- контракты для manual verification queue;
- media API shape для реального photo upload/reorder;
- список feature flags на случай частичной готовности.

## 5. Что делает каждая роль дальше

### Designer

- Сдать новый IA map для `Profile` + `Activity` как единого personal cabinet.
- Разложить profile screen на 5 блоков: identity, media, credibility, verification bridge, settings.
- Подготовить отдельные creator/business variants без расхождения по паттернам.
- Спроектировать states:
  - empty;
  - loading;
  - shadow;
  - pending verification;
  - verified;
  - active deal;
  - completed deal.
- Спроектировать deal visibility в `Activity`: active pipeline, awaiting action, finished history, repeat entry point.
- Зафиксировать microcopy для unlock logic, чтобы verification выглядел как value unlock, а не штраф.

### iOS Developer

- Убрать debug-by-default mock environment для реальных сборок команды.
- Перевести `MatchFeed`, `Chats`, `Deals/Activity`, `Profile` на один live repository path.
- Исправить repository contract mismatches и DTO mapping.
- Подключить реальное сохранение profile edit и обновление state после save.
- Убрать local fake-success из deal actions, оставить только честные optimistic UI, которые rollback-ятся по ошибке.
- Вернуть primary nav к `Activity` и пересобрать экран под spec.
- Добавить технический feature flag или runtime switch для mock/demo режима, если он все еще нужен команде.

### Backend Developer

- Подключить SQLAlchemy/Alembic minimum slice для `users`, `profiles`, `swipes`, `matches`, `deals`.
- Перевести container с `InMemory*` на DB-backed repos хотя бы для sprint focus path.
- Привести verification к pending/manual-review contract вместо self-verify.
- Добавить cross-role enforcement в `swipe()` и на deal creation boundary.
- Уточнить deal state transitions и защитить их тестами.
- Вернуть один канонический feed response, который достаточно богат для iOS без placeholder partner/profile data.
- Подготовить lightweight endpoints или embeds для personal cabinet summary.

### QA / Marketing

- QA:
  - собрать regression matrix по core loop;
  - проверить live scenario на fresh account и repeat session;
  - отдельно проверить error honesty: нет ли ложных success states;
  - зафиксировать spec compliance checklist по navigation, verification, deal states, role rules.
- Marketing / UX:
  - добить Bali-first/trust-first copy consistency на profile, activity, chat-to-deal entry;
  - проверить, что value proposition видна и бизнесу, и creators;
  - сформулировать unlock copy для shadow/pending/verified состояний;
  - проверить, что personal cabinet поддерживает GTM promise: "matches, offers, deals in one place".

## 6. Рекомендуемая последовательность работ внутри спринта

### Track A — Foundation first

1. Зафиксировать canonical contracts для feed/profile/deal/activity summary.
2. Поднять live repository path и persistence slice.
3. Закрыть deal flow end-to-end.

### Track B — Product surface after data truth

1. Вернуть `Activity` в IA.
2. Пересобрать profile/personal cabinet под реальный state.
3. Сверить copy и spec compliance.

### Track C — Validation

1. QA smoke on fresh data.
2. QA regression on existing users/deals.
3. Team Lead review against architecture + design brief.

## 7. Acceptance criteria на конец спринта

- Live build использует один согласованный data path.
- Profile edit реально сохраняется и переживает relaunch.
- `Activity` снова соответствует spec и показывает live deals/responses/likes.
- Deal flow проходит end-to-end без mock fallback.
- Verification больше не self-serve в финальном контракте.
- Cross-role rule enforced не только в UI/feed, но и в backend domain/service layer.
- У каждой роли есть следующий, четко ограниченный пакет работ для следующего спринта, а не расплывчатый backlog.

## 8. Главный риск спринта

Если команда начнет с чисто визуального profile redesign до починки live-контуров и deal contracts, мы снова получим красивый, но недостоверный MVP. Поэтому этот спринт должен быть vertical-slice sprint, а не polish sprint.
