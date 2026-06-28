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

Pins Dart SDK `^3.11.5` (in `pubspec.yaml`); developed against Flutter 3.44+.

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

## Workflow

After implementing any feature (major or minor), update this CLAUDE.md to reflect the change — new services/screens, added model fields, architectural shifts — then commit and `git push` to the current branch. Keep doc edits in the same commit as the feature when practical.

## Architecture

All real source lives under [lib/](lib/). (The top-level `services/` and `widgets/` directories are stray leftovers — the empty top-level `services/auth_service.dart` is **not** the real one, which is `lib/services/auth_service.dart` — ignore the top-level dirs; do not add code there. The empty `lib/blocs/` and `lib/components/` dirs are likewise unused — reusable pieces live in `lib/widgets/`, not there.)

**Entry & navigation.** [lib/main.dart](lib/main.dart) loads `AppSettings` before `runApp`, then wraps `MaterialApp` in an `AnimatedBuilder` on `AppSettings.instance` so theme/text-scale changes rebuild the whole app. Flow: [HomeScreen](lib/screens/home_screen.dart) (animated launch screen) → first launch plays the [GuidedTour](lib/tutorial/tutorial_tour.dart) → [DashboardScreen](lib/screens/dashboard_screen.dart) (the "four-leaf menu") which routes to the four pillars: Create Budget, Forest (view budgets), Goals, Settings. Friends are **not** a pillar/screen — they live in a swipe-in `endDrawer` on the dashboard (swipe from the right edge or tap the bobbing right-edge handle), hosting [FriendsScreen](lib/screens/friends_screen.dart) with its `onClose` set so it shows an X instead of a back button. Navigation is plain imperative `Navigator.push` with `MaterialPageRoute`; there is no router package and no DI/state-management package. `main.dart` also calls `NotificationService.init()` before `runApp` and fires `NotificationScheduler.rescheduleAll()` unawaited on boot so first paint isn't blocked. It also calls `SupabaseConfig.init()`, `AuthService.instance.start()`, and `SyncEngine.init()` before `runApp`, and the app's `home` is an [AuthGate](lib/widgets/auth_gate.dart) that shows the email/password [LoginScreen](lib/screens/auth/login_screen.dart) until signed in, then routes through `OnboardingGate` (in auth_gate.dart) before the HomeScreen flow above. Sign-up is just email+password; **every account must claim a username**, so the gate sends any signed-in user without a profile through the forced [OnboardingScreen](lib/screens/onboarding_screen.dart) (username + optional display name) before the app opens — where **Acorn** (the `AcornMascot`) greets them in a speech bubble whose line reacts to the form state (welcome / busy / error). It's offline-first: once a user onboards, `ProfileService.markOnboardedLocally()` records their id locally (`onboarded_user_id_v1`) so later launches skip the network profile lookup; a profile-fetch failure shows a retry rather than locking the user out.

**Persistence — offline-first cache synced to Supabase.** Source of truth is **Supabase** (Postgres + email/password auth); `shared_preferences` is a local **write-through cache** so reads stay instant. The seam is [SyncedStore<T>](lib/services/synced_store.dart): reads return cache immediately then refresh in the background; writes hit cache first, then upsert/delete to Supabase (queued in a per-collection pending list when offline). The four stores keep their original static API (`loadAll`/`saveNew`/`update`/`delete`) and local cache keys, each delegating to a `SyncedStore`:
- [BudgetRepository](lib/services/budget_repository.dart) — cache `budget_tree_v1`, table `budgets`
- [GoalRepository](lib/services/goal_repository.dart) — cache `goals_v1`, table `goals`
- [CategoryRepository](lib/services/category_repository.dart) — cache `tree_categories_v1`, table `categories`
- [AchievementService](lib/services/achievement_service.dart) — cache `ach_unlocks_v1`, table `achievements`

Each Supabase table is keyed `(user_id, id)` with the whole model in a `data jsonb` column under per-user RLS, so **the toJson/fromJson rule still governs: when you add a model field, update both and keep the fallback** — it maps straight into `data`, no schema change needed. [AuthService](lib/services/auth_service.dart) (`AuthService.instance`, mirrors AppSettings) wraps Supabase auth; [SyncEngine](lib/services/sync_engine.dart) handles first-login migration (push local rows up, then pull), flush-on-resume/reconnect, and clear-caches-on-signout. No dart-defines → everything degrades to local-only mode. Schema lives in [supabase/migrations/](supabase/migrations/).

**Social layer — friends & shared goals (online-only).** Distinct from the four offline-first stores: the social services talk to Supabase **directly** and no-op when unconfigured/signed-out (they gate on `SupabaseConfig.isConfigured && AuthService.instance.isSignedIn`, surfacing an "online required" UI). Two extra tables (real columns, *not* the `data jsonb` pattern): `profiles` (one per user — unique `username`, plus `status_mode`/`status_goal_id` controlling how the user's status emoji is derived, and `featured_goal_id` pinning one completed goal to show off) and `friendships` (`(requester, addressee, status)`). Privacy is **per-goal**: `Goal.sharedWithFriends` (default false) gates an *additive* `"friends read shared goals"` SELECT policy on the `goals` table — an accepted friend can read only goals the owner marked shared. **Budgets are never shared.** A user can **feature** one completed goal (`ProfileService.setFeaturedGoal`) which `FriendGardenScreen` highlights with a golden "Featured" ribbon and sorts first; featuring also flips the goal to shared so friends can see it. Services: [ProfileService](lib/services/profile_service.dart) (claim username, search, set status mode, set featured goal), [FriendsService](lib/services/friends_service.dart) (requests, accept/remove, a friend's shared goals + assembled `FriendSummary`), and the pure [FriendStatus](lib/services/friend_status.dart) util (goals → one status emoji via the friend's `FriendStatusMode`). Screens: [FriendsScreen](lib/screens/friends_screen.dart) (reached from a Friends button on the dashboard) and read-only [FriendGardenScreen](lib/screens/friend_garden_screen.dart) (reuses `SaplingView`). Username is claimed during onboarding (the forced [OnboardingScreen](lib/screens/onboarding_screen.dart) behind `OnboardingGate`) — required for **every** account, not just those who want friends. `ProfileService.claimUsername` accepts an optional `displayName` and marks the user onboarded locally on success; `FriendsScreen` still carries a `_ClaimUsername` fallback for the unconfigured-then-configured edge.

**App-wide settings.** [AppSettings](lib/services/app_settings.dart) is a `ChangeNotifier` singleton (`AppSettings.instance`) persisting palette, text scale, reduced-motion, the tutorial-seen flag, a `soundEnabled` toggle, and notification preferences (per-type toggles for budget warnings / streak reminders / weekly summary, plus the scheduled hour/minute/weekday for each). Each setting has its own `settings_*_v1` key. UI reads `palette`/`textScaleFactor`/`motionMultiplier` from it; the whole app is theme-reactive through the listener in `main.dart`. Changing a notification setting should re-run `NotificationScheduler.rescheduleAll()`. It also holds the app `locale` (`settings_locale_v1`, null = follow device) used by a Language picker in Settings — see Localization below.

**Localization (i18n).** Flutter `gen-l10n`: strings live in ARB files under [lib/l10n/](lib/l10n/) (`app_en.arb` is the template, plus `app_fr.arb`, `app_es.arb`); `flutter gen-l10n` (or any build) regenerates `AppLocalizations` (also in `lib/l10n/`, committed). `main.dart` wires `localizationsDelegates`/`supportedLocales` and `locale: AppSettings.instance.locale`, so the Settings language picker (English / Français / Español / System) flips the whole app live. In widgets read strings via `AppLocalizations.of(context).<key>` (non-null getter). **To add a string: add the key to all three ARB files, run `flutter gen-l10n`, then reference it.** The **whole app is localized** — every screen, dialog, the Acorn tutorial dialogue, achievements, allocation suggestions, and notifications. Patterns to reuse: data/model labels live in `lib/l10n/` extension helpers (`goal_labels.dart`, `achievement_labels.dart`, `preset_labels.dart`); background code with no `BuildContext` (notifications) resolves strings via `appLocalizations()` in `app_localizations_resolver.dart`; pure services/data functions that produce copy take an `AppLocalizations` param (e.g. `SuggestionService.forBudget`, the `tutorial_content.dart` functions). **Never hardcode user-facing copy, and never use dashes in it** (em-dashes/hyphens read as AI — reword; ranges become "3 to 20", clauses become separate sentences). Mandatory French grammar hyphens (e.g. `Connectez-vous`) are the only exception.

**Theming is palette-driven.** [lib/theme/app_theme.dart](lib/theme/app_theme.dart): `AppColors` holds fixed brand colors; `AppPalettes` returns gradients/colors switched on the active `AppPalette` (forestDark / midnight / twilight). Alongside `app_theme.dart`, the theme folder has `leaf_palette.dart` (a 4-stop leaf color ramp derived from an accent via HSL — drives category-tinted leaves), `app_shadows.dart` (reusable card/pill/glow shadow recipes), and `category_icons.dart` (category→icon map). Most painted scenes also define a local palette-aware color set (e.g. `_LaunchTheme` in home_screen.dart). When adding a visual surface, pull colors from `AppPalettes` so the Settings palette toggle affects it — never hardcode a full-screen background gradient. The established pattern for a painted scene is: paint `AppPalettes.deepForest()` (interior) or `AppPalettes.sky()` (outdoor) on a `Container` behind the `CustomPaint`, and have the painter add only palette-tinted glow/silhouettes on top (see `_NatureBgPainter` in createbudget_screen.dart and `_GoalSkyPainter` in create_goal_screen.dart). Respect `AppSettings.instance.motionFull` — gate idle animations on it (see `_onSettings` in home_screen.dart) so reduced-motion actually stops them.

### Domain model

- **Budget** ([budget_model.dart](lib/models/budget_model.dart)): `BudgetModel` (tree) → `IncomeSource`s + `ExpenseCategory`s (branches). An `ExpenseCategory` holds `linkedGoalIds` connecting a branch to goals. Derived getters: `totalIncome`, `totalAllocated`, `remaining`, `percentageFor`.
- **Goal** ([goal_model.dart](lib/models/goal_model.dart)): a sapling. `targetAmount <= 0` means **uncapped** (`isUncapped`) — it grows forever through size `tier`s (1–6) on a log curve; capped goals use linear `progress` 0..1 and a `stage` 0–5. Visual growth/scale (`progress`, `stage`, `tier`, `tierScale`, `stageName`) all derive from these — don't store visual state. Every deposit/withdrawal is recorded in `contributions` (`List<Contribution>`, each dated and sourced: manual / auto / adjustment) — this ledger is the source of truth for streaks, comparisons, and achievements. The legacy `currentAmount` field still persists for back-compat; keep both in sync. **Completion is a durable trophy**: `isComplete` is the live "at/over target" check, but `completedAt` is stamped once (via `stampCompletionIfReached()`) and **never cleared** — `isCompleted` (`completedAt != null`) stays true even after a withdrawal and drives the golden card border + "Completed" filter on GoalsScreen and profile featuring. `sharedWithFriends` (default false) opts the goal into the social read policy (see the Social layer above).
- **TreeCategory** ([category_model.dart](lib/models/category_model.dart)): user tag shared by budgets and goals; its `colorValue` drives leaf color.
- **Achievement** ([achievement.dart](lib/models/achievement.dart)): badge definition + `AchievementStats` (aggregate facts unlock tests read) + `AchievementCatalog` (predefined badges the service evaluates).

### Pay-cycle engine

[PayScheduler](lib/services/pay_scheduler.dart) is the core financial logic. `runUpdate(budget)` figures out how many whole pay periods elapsed since `budget.lastProcessedAt` (using `payFrequency` from [pay_frequency.dart](lib/data/pay_frequency.dart)) and credits each branch's allocation share to its linked goals, respecting target caps, then advances `lastProcessedAt` by exactly the processed periods (not to "now") and persists touched goals/budget. It's a pure-ish static utility — keep new financial math here, not in widgets. (There is **no tax feature** — tax estimation was removed; `BudgetModel.age`/`location` linger only for back-compat and are no longer collected.)

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

Screens are visually heavy: a single screen file often contains many private `CustomPainter` classes for the scene (trunk, canopy, grass blades, clouds, particles). Reusable painted pieces live in [lib/widgets/](lib/widgets/) (tree drawings, mascot, cards). Performance idioms in use: wrap animated painters in `RepaintBoundary`, implement `shouldRepaint` precisely, and cache per-size layout (see `_BladeCache` in home_screen.dart). The hands-on onboarding lives in [lib/tutorial/](lib/tutorial/) — `GuidedTour` narrates *and* hands the user real screens. The in-screen `AcornCoach` (the draggable "Acorn's tip" panel) can be swiped off the left/right edge to tuck away (leaving an edge handle to tap/swipe back), and re-opens itself when its `lessonKey` changes.

**Planting a tree — the "planted" signal.** Completion is reported up the navigation chain, not inferred by re-counting (counting raced with the background Supabase pull and used to make the tutorial's Create step restart). On a brand-new tree's first save, `BudgetTreeScreen` pops with `true`; `CreateBudgetScreen._plantTree` forwards that `true` up; the dashboard's `_openCreate` then lands back on the four-leaf menu and shows the "new tree in your forest" snackbar, and `GuidedTour` treats the `true` as authoritative completion (falling back to a repo count). Updates to an already-saved tree (opened from the forest) keep the old snackbar + `popUntil(isFirst)` path — the new-vs-update split is `budget.savedAt == null` captured before stamping.
