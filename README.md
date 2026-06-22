# 🌳 Budget Tree

A Flutter app that turns personal budgeting into a tree-growing metaphor. Your **budget is a tree**, expense categories are its **branches**, and your savings goals are **saplings** that grow as money is allocated to them over each pay cycle. The UI leans heavily on hand-painted `CustomPainter` scenes — trunks, canopies, grass, leaves, and weather — rather than off-the-shelf widgets.

## Features

- **Budgets as trees.** Each budget has income sources and expense categories (branches); branches can be linked to savings goals.
- **Goals as saplings.** Capped goals grow through visual stages 0–5; uncapped goals keep growing forever through size tiers 1–6 on a log curve. All visual growth is derived from the amount saved — nothing visual is stored.
- **Pay-cycle engine.** A scheduler figures out how many whole pay periods have elapsed and automatically credits each branch's allocation share to its linked goals, respecting target caps.
- **Tax-aware income.** Bracket-based net-income estimation across configurable jurisdictions.
- **Retention & engagement.** Contribution ledger, weekly streaks, achievement badges, week/month comparisons, allocation suggestions, and local notifications (budget warnings, streak reminders, weekly summaries).
- **Palette theming & accessibility.** Switchable palettes (forest dark / midnight / twilight), text scaling, reduced-motion support, and optional sound feedback.
- **Hands-on guided tour.** First-launch onboarding that narrates *and* hands you real screens, watching your progress to detect task completion.

## Tech stack

- **Flutter** 3.44+ / **Dart** SDK ^3.11.5
- Local persistence via `shared_preferences` (no backend or database — each model is JSON-serialized under a versioned key)
- `flutter_local_notifications` + `timezone` for scheduled reminders
- `google_fonts` for typography
- No state-management, routing, or DI packages — plain imperative `Navigator` and a `ChangeNotifier` settings singleton

## Getting started

```bash
flutter pub get          # install dependencies
flutter run              # run on the default attached device/emulator
flutter run -d chrome    # run in the browser
```

### Common commands

```bash
flutter analyze                                 # static analysis / lint (flutter_lints)
flutter test                                    # run all tests
flutter test --plain-name "substring"           # run tests whose name matches
flutter build apk|ios|web|macos                 # release builds
```

## Project structure

All source lives under [`lib/`](lib/):

| Path | What's there |
|------|--------------|
| `lib/main.dart` | Entry point; loads settings and initializes notifications before `runApp` |
| `lib/screens/` | Screens (home, dashboard, budgets, forest, goals, settings, …) |
| `lib/models/` | Domain models: budget, goal, category, achievement |
| `lib/services/` | Repositories + financial engine (pay scheduler, tax calculator) + retention/notification services |
| `lib/data/` | Pay-frequency and tax-bracket reference data |
| `lib/theme/` | Palette-driven theming, leaf color ramps, shadows, category icons |
| `lib/tutorial/` | Guided onboarding tour |
| `lib/widgets/` | Reusable painted pieces (tree drawings, mascot, cards) |

See [CLAUDE.md](CLAUDE.md) for a deeper architecture overview.

## License

Single-author CS project — all rights reserved unless stated otherwise.
