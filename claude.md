# CLAUDE.md — Codarling

## Project Overview
**Codarling** is a couple's daily photo diary app for long-distance relationships. The core idea: feel connected despite distance by sharing one meaningful photo per day.

**Tech Stack:** Flutter + Riverpod + Clean Architecture + Supabase

## Core Concept
- Each couple shares **one photo + caption per day**
- **Lock mechanic**: You can't see your partner's photo until you post yours
- **Daily prompts** (voluntary): Fun/thoughtful questions both partners can answer
- **Shared album**: Auto-built from daily photos — a growing memory book
- **Reactions**: Emoji reactions on photos and prompt replies
- Future: Goodnight ritual, inside jokes / shared memories

## Architecture

### Clean Architecture Layers (per feature)
```
lib/
├── core/
│   ├── constants/         # App-wide constants, API keys, enums
│   ├── theme/             # Colors, typography, app theme
│   ├── utils/             # Helpers, formatters, validators
│   ├── errors/            # Failure classes, exceptions
│   └── router/            # GoRouter navigation setup
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/   # Supabase auth calls
│   │   │   ├── models/        # JSON serialization models
│   │   │   └── repositories/  # Repository implementations
│   │   ├── domain/
│   │   │   ├── entities/      # Pure Dart classes (User)
│   │   │   ├── repositories/  # Abstract repository interfaces
│   │   │   └── usecases/      # SignIn, SignUp, SignOut
│   │   └── presentation/
│   │       ├── providers/     # Riverpod providers
│   │       ├── screens/       # Full page widgets
│   │       └── widgets/       # Reusable UI components
│   ├── couple/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── photo/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── prompt/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── reaction/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── main.dart
```

### Layer Rules
- **domain/** has ZERO dependencies on Flutter, Supabase, or any package. Pure Dart only.
- **data/** implements domain interfaces. All Supabase calls live here.
- **presentation/** depends on domain (via usecases) and uses Riverpod providers for state.
- Never import `data/` directly from `presentation/`. Always go through `domain/`.

## Database Schema (Supabase PostgreSQL)

### users
| Column | Type | Notes |
|---|---|---|
| id | uuid (PK) | Supabase auth UID |
| email | text | From auth |
| display_name | text | |
| avatar_url | text? | Nullable |
| created_at | timestamptz | Default now() |

### couples
| Column | Type | Notes |
|---|---|---|
| id | uuid (PK) | |
| user_id_1 | uuid (FK → users) | Creator |
| user_id_2 | uuid? (FK → users) | Nullable until partner joins |
| invite_code | text (unique) | e.g. "LOVE-7X2K" |
| status | text | 'pending' / 'active' |
| anniversary | date? | Optional, their real-life date |
| couple_name | text? | Pet name for the couple |
| created_at | timestamptz | Default now() |

### photos
| Column | Type | Notes |
|---|---|---|
| id | uuid (PK) | |
| couple_id | uuid (FK → couples) | |
| user_id | uuid (FK → users) | Who posted |
| image_url | text | Supabase Storage path |
| caption | text? | One-line caption |
| date | date | Calendar date (one photo per user per day) |
| created_at | timestamptz | Default now() |

**Constraint:** UNIQUE(couple_id, user_id, date) — enforces one photo per user per day.

### prompts
| Column | Type | Notes |
|---|---|---|
| id | uuid (PK) | |
| couple_id | uuid (FK → couples) | |
| question_text | text | The daily question |
| date | date | Which day this prompt is for |
| created_at | timestamptz | Default now() |

### prompt_replies
| Column | Type | Notes |
|---|---|---|
| id | uuid (PK) | |
| prompt_id | uuid (FK → prompts) | |
| user_id | uuid (FK → users) | |
| reply_text | text | |
| created_at | timestamptz | Default now() |

### reactions
| Column | Type | Notes |
|---|---|---|
| id | uuid (PK) | |
| user_id | uuid (FK → users) | Who reacted |
| target_type | text | 'photo' or 'prompt_reply' |
| target_id | uuid | FK to photos.id or prompt_replies.id |
| emoji | text | The emoji used |
| created_at | timestamptz | Default now() |

## Lock Mechanic Logic
```
To check if partner's photo is unlocked for today:
1. Query: SELECT * FROM photos WHERE couple_id = X AND user_id = me AND date = today
2. If exists → show partner's photo
3. If not → show lock screen, prompt user to post first
```

## Key Features (MVP Priority Order)
1. **Auth** — Google OAuth via Supabase
2. **Couple pairing** — Generate invite code → partner enters code → paired
3. **Daily photo** — Camera/gallery → upload to Supabase Storage → save to photos table
4. **Lock mechanic** — Can't see partner's photo until you post yours
5. **Shared album** — Chronological grid of all past photos
6. **Daily prompt** — Show a voluntary daily question, both can reply
7. **Reactions** — Emoji reactions on photos and prompt replies

## Coding Conventions
- **Language:** Dart (Flutter)
- **State management:** Riverpod (flutter_riverpod)
- **Navigation:** GoRouter (go_router)
- **Naming:** snake_case for files, PascalCase for classes, camelCase for variables
- **Entities** are immutable (use `final` fields + `copyWith`)
- **Models** (data layer) handle JSON serialization with `fromJson` / `toJson`
- **UseCases** have a single `call()` method
- **Providers** use `StateNotifier` or `AsyncNotifier` pattern
- **Error handling:** Use `Either<Failure, T>` pattern (dartz package) or sealed Result classes
- Keep widgets small — extract when a widget exceeds ~80 lines
- Write comments for non-obvious business logic only

## Supabase Setup Notes
- Use Supabase free tier (sufficient for 2 users)
- Storage bucket: `photos` (private, RLS enabled)
- Enable Row Level Security on ALL tables
- RLS policy: users can only read/write data for their own couple
- Auth: Google OAuth provider

## Future Features (Post-MVP)
- Goodnight ritual (flexible format TBD)
- Inside jokes / shared memories wall
- Anniversary countdown / D-day counter
- Streak counter with rewards
- Push notifications ("Your partner posted today!")
- Theming / customization per couple
