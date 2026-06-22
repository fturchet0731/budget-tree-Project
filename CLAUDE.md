# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

"Budget Tree" — a Flutter app (single-author CS project) that turns personal budgeting into a tree-growing metaphor: budgets are trees with expense "branches", and savings goals are "saplings" that grow as money is allocated to them over pay cycles. Heavy emphasis on hand-painted `CustomPainter` scenes (trunks, canopies, grass, leaves, weather) rather than off-the-shelf widgets.

## Commands

```bash
flutter pub get                 # install deps (run after changing pubspec.yaml)
flutter run                     # run on the default attached device/emulator
flutter run -d chrome           # run in the browser
flutter analyze                 # static analysis / lint (flutter_lints, see analysis_options.yaml)
flutter test                    # run all tests
flutter test test/widget_test.dart            # run a single test file
flutter test --plain-name "substring"         # run tests whose name matches
flutter build apk|ios|web|macos               # release builds
```

Requires Flutter 3.44+ / Dart SDK ^3.11.5.

Run against Supabase with credentials from a gitignored `env.json`:

```bash
flutter run --dart-define-from-file=env.json   # injects SUPABASE_URL + SUPABASE_ANON_KEY
```

Database schema is managed with the Supabase CLI (migrations in `supabase/migrations/`, project linked to ref `uxfmisgzrprdzagfhcke`):

```bash
supabase migration new <name>   # scaffold a migration, then write SQL into it
supabase db push                # apply pending migrations to the linked remote DB
supabase migration list         # compare local vs remote
```

## Architecture

All real source lives under [lib/](lib/). (The top-level `services/` and `widgets/` directories are stray leftovers — the empty top-level `services/auth_service.dart` is **not** the real one, which is `lib/services/auth_service.dart` — ignore the top-level dirs; do not add code there.)

**Entry & navigation.** [lib/main.dart](lib/main.dart) loads `AppSettings` before `runApp`, then wraps `MaterialApp` in an `AnimatedBuilder` on `AppSettings.instance` so theme/text-scale changes rebuild the whole app. Flow: [HomeScreen](lib/screens/home_screen.dart) (animated launch screen) → first launch plays the [GuidedTour](lib/tutorial/tutorial_tour.dart) → [DashboardScreen](lib/screens/dashboard_screen.dart) (the "four-leaf menu") which routes to the four pillars: Create Budget, Forest (view budgets), Goals, Settings. Navigation is plain imperative `Navigator.push` with `MaterialPageRoute`; there is no router package and no DI/state-management package. `main.dart` also calls `NotificationService.init()` before `runApp` and fires `NotificationScheduler.rescheduleAll()` unawaited on boot so first paint isn't blocked. It also calls `SupabaseConfig.init()`, `AuthService.instance.start()`, and `SyncEngine.init()` before `runApp`, and the app's `home` is an [AuthGate](lib/widgets/auth_gate.dart) that shows the email/password [LoginScreen](lib/screens/auth/login_screen.dart) until signed in, then enters the HomeScreen flow above.

**Persistence — offline-first cache synced to Supabase.** Source of truth is **Supabase** (Postgres + email/password auth); `shared_preferences` is a local **write-through cache** so reads stay instant. The seam is [SyncedStore<T>](lib/services/synced_store.dart): reads return cache immediately then refresh in the background; writes hit cache first, then upsert/delete to Supabase (queued in a per-collection pending list when offline). The four stores keep their original static API (`loadAll`/`saveNew`/`update`/`delete`) and local cache keys, each delegating to a `SyncedStore`:
- [BudgetRepository](lib/services/budget_repository.dart) — cache `budget_tree_v1`, table `budgets`
- [GoalRepository](lib/services/goal_repository.dart) — cache `goals_v1`, table `goals`
- [CategoryRepository](lib/services/category_repository.dart) — cache `tree_categories_v1`, table `categories`
- [AchievementService](lib/services/achievement_service.dart) — cache `ach_unlocks_v1`, table `achievements`

Each Supabase table is keyed `(user_id, id)` with the whole model in a `data jsonb` column under per-user RLS, so **the toJson/fromJson rule still governs: when you add a model field, update both and keep the fallback** — it maps straight into `data`, no schema change needed. [AuthService](lib/services/auth_service.dart) (`AuthService.instance`, mirrors AppSettings) wraps Supabase auth; [SyncEngine](lib/services/sync_engine.dart) handles first-login migration (push local rows up, then pull), flush-on-resume/reconnect, and clear-caches-on-signout. No dart-defines → everything degrades to local-only mode. Schema lives in [supabase/migrations/](supabase/migrations/).

**App-wide settings.** [AppSettings](lib/services/app_settings.dart) is a `ChangeNotifier` singleton (`AppSettings.instance`) persisting palette, text scale, reduced-motion, the tutorial-seen flag, a `soundEnabled` toggle, and notification preferences (per-type toggles for budget warnings / streak reminders / weekly summary, plus the scheduled hour/minute/weekday for each). Each setting has its own `settings_*_v1` key. UI reads `palette`/`textScaleFactor`/`motionMultiplier` from it; the whole app is theme-reactive through the listener in `main.dart`. Changing a notification setting should re-run `NotificationScheduler.rescheduleAll()`.

**Theming is palette-driven.** [lib/theme/app_theme.dart](lib/theme/app_theme.dart): `AppColors` holds fixed brand colors; `AppPalettes` returns gradients/colors switched on the active `AppPalette` (forestDark / midnight / twilight). Alongside `app_theme.dart`, the theme folder has `leaf_palette.dart` (a 4-stop leaf color ramp derived from an accent via HSL — drives category-tinted leaves), `app_shadows.dart` (reusable card/pill/glow shadow recipes), and `category_icons.dart` (category→icon map). Most painted scenes also define a local palette-aware color set (e.g. `_LaunchTheme` in home_screen.dart). When adding a visual surface, pull colors from `AppPalettes` so the Settings palette toggle affects it. Respect `AppSettings.instance.motionFull` — gate idle animations on it (see `_onSettings` in home_screen.dart) so reduced-motion actually stops them.

### Domain model

- **Budget** ([budget_model.dart](lib/models/budget_model.dart)): `BudgetModel` (tree) → `IncomeSource`s + `ExpenseCategory`s (branches). An `ExpenseCategory` holds `linkedGoalIds` connecting a branch to goals. Derived getters: `totalIncome`, `totalAllocated`, `remaining`, `percentageFor`.
- **Goal** ([goal_model.dart](lib/models/goal_model.dart)): a sapling. `targetAmount <= 0` means **uncapped** (`isUncapped`) — it grows forever through size `tier`s (1–6) on a log curve; capped goals use linear `progress` 0..1 and a `stage` 0–5. Visual growth/scale (`progress`, `stage`, `tier`, `tierScale`, `stageName`) all derive from these — don't store visual state. Every deposit/withdrawal is recorded in `contributions` (`List<Contribution>`, each dated and sourced: manual / auto / adjustment) — this ledger is the source of truth for streaks, comparisons, and achievements. The legacy `currentAmount` field still persists for back-compat; keep both in sync.
- **TreeCategory** ([category_model.dart](lib/models/category_model.dart)): user tag shared by budgets and goals; its `colorValue` drives leaf color.
- **Achievement** ([achievement.dart](lib/models/achievement.dart)): badge definition + `AchievementStats` (aggregate facts unlock tests read) + `AchievementCatalog` (predefined badges the service evaluates).

### Pay-cycle engine

[PayScheduler](lib/services/pay_scheduler.dart) is the core financial logic. `runUpdate(budget)` figures out how many whole pay periods elapsed since `budget.lastProcessedAt` (using `payFrequency` from [pay_frequency.dart](lib/data/pay_frequency.dart)) and credits each branch's allocation share to its linked goals, respecting target caps, then advances `lastProcessedAt` by exactly the processed periods (not to "now") and persists touched goals/budget. [TaxCalculator](lib/services/tax_calculator.dart) does bracket-based net-income estimation from [tax_data.dart](lib/data/tax_data.dart) jurisdictions. These are pure-ish static utilities — keep new financial math here, not in widgets.

### Retention & engagement

A cluster of static-utility services drives streaks, badges, and reminders off the goal contribution ledger — keep this logic here, not in widgets:
- **StreakService** — weekly contribution streaks from the ledger.
- **ComparisonService** — week-over-week / month-over-month savings & allocation deltas.
- **SuggestionService** — allocation suggestions surfaced to the user.
- **AchievementService** — evaluates `AchievementCatalog` against `AchievementStats` and persists unlocks.
- **NotificationContent** — pure copy + severity logic. Note: a "budget warning" measures allocation-vs-income (there is no per-category spend log).
- **NotificationScheduler** — decides *what* to schedule (budget warnings, daily streak reminder, weekly summary); **NotificationService** is the thin OS wrapper over `flutter_local_notifications` (channels: budget_warnings, streak_reminders, weekly_summary) that degrades failures to no-ops.
- **SoundService** — tactile/audible feedback, gated on `AppSettings.soundEnabled`.

### Painted scenes & tutorial

Screens are visually heavy: a single screen file often contains many private `CustomPainter` classes for the scene (trunk, canopy, grass blades, clouds, particles). Reusable painted pieces live in [lib/widgets/](lib/widgets/) (tree drawings, mascot, cards). Performance idioms in use: wrap animated painters in `RepaintBoundary`, implement `shouldRepaint` precisely, and cache per-size layout (see `_BladeCache` in home_screen.dart). The hands-on onboarding lives in [lib/tutorial/](lib/tutorial/) — `GuidedTour` narrates *and* hands the user real screens, watching the repositories to detect task completion.
