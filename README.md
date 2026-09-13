# 🌳 Budget Tree

A Flutter app that turns personal budgeting into a tree-growing game. Your **budget is a tree**, expense categories are its **branches**, and your savings goals are **saplings** that grow as money is allocated to them over each pay cycle. The whole app wears a cozy **16-bit pixel-game skin** (Stardew/GBA era): parchment canvas, hard-outlined cards, solid offset shadows, and animated pixel-art trees. The goal of this project was to get comfortable with working with AI agents to deleiver a product and learn about backend security. This project went through many iterations, applying fundamental software design principle. The App incorporates an AI assistant using Claude API.

## Features

- **Budgets as trees.** Each budget has income sources and expense categories (branches); branches can be linked to savings goals. Income and bills each carry their own **rhythm** (weekly, biweekly, monthly, or a custom interval), converted to the budget's cycle so a biweekly paycheck and a monthly rent line up like-for-like.
- **Goals as saplings.** Capped goals grow through visual stages; uncapped goals keep growing forever through size tiers on a log curve. All visual growth is derived from the amount saved, never stored.
- **Pay-cycle engine.** A scheduler works out how many whole pay periods have elapsed and automatically credits each branch's allocation to its linked goals, respecting target caps. A background sweep funds every budget, not just the one you happen to open.
- **Acorn, the AI coach.** An NPC squirrel powered by Claude (via a Supabase edge function, so the API key stays server-side) writes smart budget plans, goal watering plans, weekly reflections, and answers questions in a chat. All arithmetic is computed locally; the model only writes the prose.
- **Consistency, not just balances.** Pay-day and watering **check-ins** feed a 0 to 100 tree-health score that grows one of **sixteen status trees** (eight earned by consistency, eight prestige tiers earned by staying healthy over time). Acorn's Hub shows your canopy score as an XP bar, your streak, check-in history, and plan-versus-reality charts.
- **Social layer.** Claim a username, add friends (your "party"), and share individual goals. Friends see your live status tree, your shared saplings, likes, and 1:1 messages. Presence shows who is active now.
- **Retention & engagement.** Contribution ledger, weekly streaks, achievement badges, week/month comparisons, allocation suggestions, and timezone-aware local notifications (budget warnings, streak reminders, weekly summaries, goal-watering reminders).
- **Offline-first with cloud sync.** Works fully offline; syncs to Supabase when signed in. Guest mode lets you try everything before creating an account.
- **Theming, i18n & accessibility.** Light/dark themes, text scaling, reduced-motion support, optional sound, and full localization in **English, Français, and Español**.
- **Hands-on guided tour.** First-launch onboarding that narrates *and* hands you real screens, detecting task completion as you go.

## Tech stack

- **Flutter** 3.44+ / **Dart** SDK ^3.11.5
- **Supabase** (Postgres + email/password auth with email verification) as the source of truth, with `shared_preferences` as an offline-first write-through cache
- **Anthropic Claude** (`claude-sonnet-4-6`) reached through a Supabase **edge function**, never from the app binary
- `flutter_local_notifications` + `timezone` for scheduled reminders
- `google_fonts` for the three-font system: **Pixelify Sans** (display), **Silkscreen** (labels/stats), **Nunito** (body)
- `gen-l10n` for localization; `image_picker` for avatars
- No state-management, routing, or DI packages: plain imperative `Navigator` and a `ChangeNotifier` settings singleton

## Getting started

Credentials are supplied at run time and never committed. Keep them in a gitignored `env.json`:

```json
{ "SUPABASE_URL": "https://xxxx.supabase.co", "SUPABASE_ANON_KEY": "eyJ..." }
```

```bash
flutter pub get                                  # install dependencies
flutter run --dart-define-from-file=env.json     # run on the default device/emulator
flutter run -d chrome --dart-define-from-file=env.json   # run in the browser
```

Without dart-defines the app degrades to local-only mode (no auth, no AI, no social).

### Common commands

```bash
flutter analyze                                  # static analysis / lint (flutter_lints)
flutter test                                     # run all tests
flutter test --plain-name "substring"            # run tests whose name matches
flutter gen-l10n                                 # regenerate localizations after editing lib/l10n/*.arb
flutter build apk|ios|web|macos                  # release builds
```

### Backend (Supabase)

Schema is managed with the Supabase CLI (migrations in `supabase/migrations/`). The AI coach runs as an edge function with the Anthropic key set as a server-side secret:

```bash
supabase db push                                 # apply pending migrations
supabase functions deploy ai-coach               # deploy the coach
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
```

## Project structure

All source lives under [`lib/`](lib/):

| Path | What's there |
|------|--------------|
| `lib/main.dart` | Entry point; loads settings, Supabase, auth, and sync before `runApp` |
| `lib/screens/` | Screens (home, dashboard, forest, goals, budget tree, Acorn's Hub, chat, profile, friends, settings, auth, …) |
| `lib/models/` | Domain models: budget, goal, category, achievement, check-in |
| `lib/services/` | Repositories, the pay-cycle engine, tree-health & check-ins, AI coach, and the social/retention services |
| `lib/data/` | Pay-frequency, rhythm, and watering-cadence reference data |
| `lib/theme/` | Token-driven pixel theming (`app_tokens`, `app_theme`, shadows, leaf ramps) |
| `lib/widgets/pixel/` | The 16-bit pixel component kit (boxes, buttons, bars, chips, scenes, sprites) |
| `lib/widgets/` | Trees, mascot, cards, charts, and other reusable pieces |
| `lib/l10n/` | ARB translation files (en/fr/es) and generated localizations |
| `lib/tutorial/` | Guided onboarding tour |
| `supabase/` | Database migrations and the `ai-coach` edge function |

See [CLAUDE.md](CLAUDE.md) for a deeper architecture overview.

## License

Single-author CS project. All rights reserved unless stated otherwise.
