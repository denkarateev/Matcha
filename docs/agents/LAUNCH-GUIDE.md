# MATCHA — Multi-Agent Team Launch Guide

## Команда и модели

| Агент | Модель | Обоснование | Токены/час (прогноз) |
|-------|--------|-------------|---------------------|
| **Team Lead** | `claude-opus-4-6` | Архитектурные решения, координация, code review — нужен максимальный контекст и качество | Низкий (только координация) |
| **Designer** | `claude-sonnet-4-6` | UI/UX код, компоненты, анимации — средняя сложность, много кода | Средний |
| **iOS Developer** | `claude-sonnet-4-6` | Основной объём кода, networking, интеграция — рабочая лошадка | Высокий |
| **Backend Developer** | `claude-sonnet-4-6` | API endpoints, миграции, бизнес-логика — рабочая лошадка | Высокий |
| **QA Engineer** | `claude-haiku-4-5` | Проверки, тесты, регрессии — рутинные задачи | Средний |
| **Marketing/UX** | `claude-haiku-4-5` | Ревью копирайтинга, UX аудит — анализ без кодогенерации | Низкий |

**Экономия:** Haiku для QA и маркетинга даёт ~5x экономию на рутинных задачах vs Opus.

## Запуск через Claude Code

### Вариант 1: Через CLAUDE.md (рекомендуется)

Создайте `/Users/dorffoto/Documents/New project/matcha/CLAUDE.md`:

```markdown
# MATCHA Project

## Multi-Agent Roles

This project uses a multi-agent workflow. Each agent has a specific role prompt in `/docs/agents/`.

When working on this project:
1. Read your role prompt from `/docs/agents/` based on the task
2. Follow the architecture in `/docs/team-lead/mvp-architecture.md`
3. Never break the build — always verify compilation
4. Business logic ONLY on the server side
5. All times in WITA (UTC+8)
```

### Вариант 2: Прямой запуск агентов в терминале

```bash
# === TEAM LEAD (координация) ===
cd "/Users/dorffoto/Documents/New project/matcha"
claude --model claude-opus-4-6 \
  --system-prompt "$(cat docs/agents/00-TEAM-LEAD.md)" \
  "Проанализируй текущее состояние проекта и составь план спринта для Release 0 (Foundation). Разбей на задачи для каждого агента."

# === BACKEND DEVELOPER ===
cd "/Users/dorffoto/Documents/New project/matcha/backend"
claude --model claude-sonnet-4-6 \
  --system-prompt "$(cat ../docs/agents/03-BACKEND-DEVELOPER.md)" \
  "Задача: Мигрировать InMemoryStore на PostgreSQL + SQLAlchemy 2.x. Создай alembic конфигурацию, модели для всех 6 модулей, и начальную миграцию."

# === IOS DEVELOPER ===
cd "/Users/dorffoto/Documents/New project/matcha/ios"
claude --model claude-sonnet-4-6 \
  --system-prompt "$(cat ../docs/agents/02-IOS-DEVELOPER.md)" \
  "Задача: Создать NetworkService.swift — централизованный HTTP клиент с auth token management, generic request method, error handling. Затем создать AuthService.swift для login/register."

# === DESIGNER ===
cd "/Users/dorffoto/Documents/New project/matcha/ios"
claude --model claude-sonnet-4-6 \
  --system-prompt "$(cat ../docs/agents/01-DESIGNER.md)" \
  "Задача: Расширить DesignSystem — добавить MatchaTextField, SkeletonView, EmptyStateView, MatchaAvatar, TagChip, MatchaToast. Обновить MatchaTokens с typography и shadows."

# === QA (после завершения работы девелоперов) ===
cd "/Users/dorffoto/Documents/New project/matcha"
claude --model claude-haiku-4-5 \
  --system-prompt "$(cat docs/agents/04-QA-ENGINEER.md)" \
  "Проведи полный QA аудит: проверь что iOS билдится, backend стартует, все тесты проходят. Составь QA Report."

# === MARKETING (после завершения работы дизайнера) ===
cd "/Users/dorffoto/Documents/New project/matcha"
claude --model claude-haiku-4-5 \
  --system-prompt "$(cat docs/agents/05-MARKETING-UX.md)" \
  "Проведи UX аудит всех iOS экранов. Проверь все 5 marketing findings из предыдущего аудита. Оцени launch readiness."
```

### Вариант 3: Параллельный режим (максимальная скорость)

```bash
# Запуск Backend и iOS параллельно (они независимы на этапе Foundation)
cd "/Users/dorffoto/Documents/New project/matcha"

# Terminal 1 — Backend
claude --model claude-sonnet-4-6 \
  --system-prompt "$(cat docs/agents/03-BACKEND-DEVELOPER.md)" \
  "Release 0: 1) PostgreSQL миграция 2) JWT auth 3) Feed endpoint с ранжированием"

# Terminal 2 — iOS
claude --model claude-sonnet-4-6 \
  --system-prompt "$(cat docs/agents/02-IOS-DEVELOPER.md)" \
  "Release 0: 1) NetworkService 2) AuthService 3) APIMatchaRepository заменяющий Mock"

# Terminal 3 — Designer
claude --model claude-sonnet-4-6 \
  --system-prompt "$(cat docs/agents/01-DESIGNER.md)" \
  "Создай все недостающие компоненты из списка в промпте. Реализуй маркетинговые фиксы 1-5."

# После завершения всех трёх — Terminal 4 — QA
claude --model claude-haiku-4-5 \
  --system-prompt "$(cat docs/agents/04-QA-ENGINEER.md)" \
  "Полная проверка после Release 0. Билд, тесты, core loop, business rules."

# Terminal 5 — Marketing Review
claude --model claude-haiku-4-5 \
  --system-prompt "$(cat docs/agents/05-MARKETING-UX.md)" \
  "Финальный UX аудит. Все ли 5 findings устранены? Launch readiness score."
```

## Sprint Plan: Release 0 (Foundation)

### Неделя 1: Параллельная разработка

| День | Backend (Sonnet) | iOS (Sonnet) | Designer (Sonnet) |
|------|-----------------|--------------|-------------------|
| 1 | PostgreSQL models + alembic | NetworkService | Typography + Shadows tokens |
| 2 | JWT auth + migrations | AuthService + login flow | MatchaTextField, SecureField |
| 3 | Profile repository | Profile integration | SkeletonView, EmptyStateView |
| 4 | Feed endpoint + ranking | Feed API integration | ProfileCard, OfferCard |
| 5 | Offers + Chats repos | Offers + Chat integration | Badges, Avatar, Toast |

### Неделя 2: Интеграция + QA

| День | Все вместе |
|------|------------|
| 6 | Team Lead: code review всех PR |
| 7 | QA: полный аудит, bug report |
| 8 | Все: фикс критических багов |
| 9 | Marketing: UX аудит, copy review |
| 10 | Designer: финальные UX фиксы |

## Правила работы команды

1. **Никогда не ломай билд** — каждый агент проверяет компиляцию после изменений
2. **API контракт первым** — Team Lead определяет JSON schema до имплементации
3. **Feature flags** — незавершённые фичи под флагом, не в production коде
4. **Один агент — один модуль** — не пересекайтесь, работайте параллельно
5. **Коммиты атомарные** — одна фича = один коммит с описанием
6. **Тесты обязательны** — нет теста = фича не считается готовой
7. **Документация решений** — все решения в `/docs/team-lead/decisions/`

## Файловая структура промптов

```
docs/agents/
├── 00-TEAM-LEAD.md        — Opus 4.6 (координация)
├── 01-DESIGNER.md         — Sonnet 4.6 (UI/UX код)
├── 02-IOS-DEVELOPER.md    — Sonnet 4.6 (iOS код)
├── 03-BACKEND-DEVELOPER.md — Sonnet 4.6 (backend код)
├── 04-QA-ENGINEER.md      — Haiku 4.5 (тестирование)
├── 05-MARKETING-UX.md     — Haiku 4.5 (UX ревью)
└── LAUNCH-GUIDE.md        — этот файл
```
