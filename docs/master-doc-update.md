# Budget Tree — Master Document

> *Status: reflects the codebase as of the current build (v1.0.0+2). "Budget Tree" is a personal-finance app that reframes budgeting as growing a tree, with savings goals as saplings.*

---

## Part A — Requirements / Feature Specification

### A.1 Vision
Budget Tree turns personal budgeting into a living, hand-illustrated metaphor: a **budget is a tree**, expense categories are its **branches**, and **savings goals are saplings** that grow over time as money is allocated to them across pay cycles. The aim is to make budgeting feel approachable, rewarding, and a little playful rather than spreadsheet-like.

### A.2 Target users
- Individuals (students, young earners, families) who want a low-friction, motivating way to track income, allocate expenses, and save toward goals.
- People who respond to gamification (streaks, badges, visible growth) more than to numbers alone.

### A.3 Functional requirements (feature list)

**Accounts & onboarding**
- Email + password sign-up / sign-in (Supabase auth).
- Mandatory onboarding for every new account: the user must claim a unique **username** (and optional display name) before entering the app, guided by the **Acorn** mascot.
- First-launch interactive guided tour (Acorn coaches the user through creating a budget on real screens).

**Budgets ("trees")**
- Create a budget via a 3-step flow: income sources → expense branches → name + pay schedule.
- Quick-pick presets for common income sources and expense categories.
- Live "canopy meter" showing allocated vs. remaining income, with over-budget warnings.
- View, edit, and manage existing budgets ("the Forest").

**Goals ("saplings")**
- Create savings goals, either **capped** (fixed target) or **uncapped** ("grow forever" through size tiers).
- Deposit/withdraw to a goal; every transaction is recorded in a dated contribution ledger.
- Visual growth: the sapling and a savings thermometer grow with progress.
- **Completion is a permanent trophy**: when a goal first reaches its target it's marked completed (golden border, trophy badge) and stays completed even if funds are later withdrawn.
- Filter goals to show only completed ones.
- Category tagging with color-tinted leaves.

**Pay-cycle automation**
- A pay schedule (frequency + first pay date) drives automatic allocation: on each elapsed pay period, each branch's share is credited to its linked goals, respecting caps.

**Social layer (online-only)**
- Add friends by unique username; send/accept/decline requests.
- Friends accessible from a **swipe-in sidebar** on the dashboard (swipe from the right edge or tap the handle) — not a separate screen.
- **Per-goal privacy**: goals are private by default; the user opts individual goals into being visible to friends. Budgets are never shared.
- View a friend's shared goals as a read-only "garden" of saplings.
- **Status emoji** next to each friend, derived from their shared goals' progress, using a mode the friend chooses for themselves (best / average / worst / a specific goal).
- **Feature a completed goal** on your profile to highlight it to friends (golden "Featured" ribbon, sorted first in your garden).

**Engagement & retention**
- Weekly saving **streaks**.
- Week-over-week / month-over-month savings **comparisons**.
- **Achievements/badges** unlocked from the contribution ledger.
- Allocation **suggestions**.
- Local **notifications**: budget warnings, streak reminders, weekly summary (each individually toggleable and scheduled).
- Optional sound/haptic feedback.

**Personalization**
- Theme **palette** (Forest Dark / Midnight / Twilight) that recolors the entire app.
- Text scaling and a reduced-motion option (accessibility).
- Per-type notification preferences.

### A.4 User stories (representative)
- *As a new user,* I'm guided to pick a username so my account is set up and friends can find me.
- *As a budgeter,* I can enter my income and expenses and see at a glance whether I'm over-allocated.
- *As a saver,* I can set a goal and watch a sapling grow as I deposit toward it.
- *As a goal-setter,* I can mark which goals are shareable so only those are visible to friends.
- *As a friend,* I can see a status emoji and a garden of my friends' shared goals.
- *As a returning user,* I can open the app and read my data instantly, even with a poor connection.

### A.5 Non-functional requirements
- **Offline-first**: core data (budgets, goals, categories, achievements) reads instantly from a local cache and syncs to the backend in the background; the app remains usable without connectivity. (Social features require connectivity by design.)
- **Privacy/security**: per-user data isolation and per-goal sharing enforced server-side by Postgres Row-Level Security, so the client cannot bypass it.
- **Performance**: hand-painted scenes use repaint boundaries, precise repaint conditions, and cached layout to stay smooth.
- **Platforms**: built with Flutter (iOS is the current distribution target via TestFlight; the codebase also targets Android/web/desktop).

### A.6 Out of scope (current build)
- Bank/account integrations or transaction import.
- Per-transaction spend tracking (budget "warnings" measure allocation vs. income, not actual spend).
- Tax estimation (previously prototyped, **removed**).
- Public social feed / messaging.

---

## Part B — Technical Design

### B.1 Technology stack
- **Language/Framework**: Dart (SDK `^3.11.5`), Flutter (developed against 3.44+).
- **Backend**: Supabase — Postgres database, email/password authentication, Row-Level Security.
- **Local cache**: `shared_preferences` (write-through, offline-first).
- **Notifications**: `flutter_local_notifications`.
- **Type/UI**: `google_fonts`; UI is heavily custom `CustomPainter` artwork.
- **Deliberately no** router, state-management, or dependency-injection packages — navigation is imperative `Navigator.push`; app-wide state is held in `ChangeNotifier` singletons.

### B.2 High-level architecture
- **Entry / boot** (`main.dart`): loads settings, initializes notifications, Supabase, auth, and the sync engine, then runs the app wrapped so theme/scale changes rebuild globally.
- **Gating**: `AuthGate` → shows login until signed in → `OnboardingGate` forces username creation → the main app.
- **Main flow**: animated launch screen → first-run guided tour → **Dashboard** ("four-leaf menu") routing to the four pillars: **Create Budget, Forest, Goals, Settings**. Friends live in a swipe-in sidebar on the dashboard.

### B.3 Persistence & synchronization (offline-first)
- Source of truth is **Supabase**; `shared_preferences` is a local write-through cache so reads are instant.
- The seam is a generic `SyncedStore<T>`: reads return cache immediately then refresh from the backend; writes hit cache first, then upsert/delete to Supabase. When offline, writes are queued in a per-collection pending list and replayed on reconnect.
- Four repositories delegate to a `SyncedStore`: **Budgets, Goals, Categories, Achievements**.
- `SyncEngine` handles first-login migration (push local rows up, then pull), flush-on-resume/reconnect, and cache-clearing on sign-out. `AuthService` wraps Supabase auth as a singleton.
- With no backend credentials configured, the app degrades gracefully to **local-only** mode.

### B.4 Backend data model
- Each cached collection maps to a Supabase table keyed `(user_id, id)` with the entire model stored in a `data jsonb` column under per-user RLS. *(Implication: adding a model field requires no schema migration — only updating `toJson`/`fromJson` with a fallback.)*
- **Social tables use real columns** (not the jsonb pattern):
  - `profiles` — one per user: unique `username`, `display_name`, status-mode fields, and a `featured_goal_id`.
  - `friendships` — `(requester, addressee, status)`.
- **Privacy via RLS**: an additive policy lets an accepted friend read only the goals the owner explicitly marked shared (`sharedWithFriends`). Budgets are never shared.

### B.5 Domain model
- **BudgetModel** (tree): income sources + expense categories (branches); a branch links to goals via `linkedGoalIds`; derived totals (income, allocated, remaining).
- **Goal** (sapling): capped vs. uncapped; visual growth derives from progress/stage/tier (never stored); a dated **contribution ledger** is the source of truth for streaks, comparisons, and achievements; durable completion (`completedAt`); `sharedWithFriends` flag.
- **TreeCategory**: user tag shared by budgets and goals; drives leaf color.
- **Achievement**: badge definitions + aggregate stats the unlock logic evaluates.

### B.6 Core business logic (services)
- **PayScheduler**: computes whole pay periods elapsed since last processed and credits each branch's allocation share to linked goals, respecting caps — the financial engine.
- **Retention services**: StreakService (weekly streaks), ComparisonService (period deltas), SuggestionService (allocation tips), AchievementService (badge evaluation), NotificationContent/Scheduler/Service (what to schedule + OS wrapper), SoundService.

### B.7 Authentication & onboarding
- Email/password via Supabase. Sign-up collects only email + password; **username is claimed in a forced onboarding step** so every account has a profile.
- Onboarding is offline-aware: once completed it's cached locally so returning users aren't blocked by a network check; a profile-fetch failure shows a retry rather than locking the user out.

### B.8 Theming & rendering
- Palette-driven: `AppPalettes` returns gradients/colors switched on the active palette (Forest Dark / Midnight / Twilight); the whole app is theme-reactive. Full-screen scenes paint a palette gradient behind decorative `CustomPainter`s so every screen follows the theme.
- Performance idioms: `RepaintBoundary`, precise `shouldRepaint`, cached per-size layout; idle animations respect the reduced-motion setting.

### B.9 Build & deployment
- Backend credentials injected at build time via `--dart-define-from-file=env.json` (Supabase URL + anon key); the anon key is public and safe to ship, protected by RLS.
- Database schema managed by Supabase CLI migrations (`supabase db push`).
- iOS beta distribution via **TestFlight** (Apple Developer Program required); bundle id `com.fabian.budgetAppProject`, display name "Budget Tree".

### B.10 Testing
- Unit tests cover pure logic (e.g., friend-status emoji rules, durable goal completion, retention/comparison math, synced-store round-trips) plus a boot smoke test. *(Current suite: ~40 passing tests.)*

---

## Part C — Marketing *(TEMPLATE — to be completed)*

> *This section is a structural placeholder matching the format above. Replace the bracketed prompts with real content. Keep the heading depth consistent with Parts A/B when you paste into the master doc.*

### C.1 Positioning statement
*[One sentence: For **[target audience]** who **[need/problem]**, Budget Tree is a **[category]** that **[key benefit / differentiator]**.]*

### C.2 Value proposition
- *[Primary benefit — e.g., "Makes saving feel rewarding by turning progress into a tree you grow."]*
- *[Secondary benefit]*
- *[Secondary benefit]*

### C.3 Target audience & personas
- **Persona 1 — [name/role]**: *[goals, frustrations, why Budget Tree fits]*
- **Persona 2 — [name/role]**: *[…]*

### C.4 Key differentiators
- *[What sets it apart from spreadsheets / other budgeting apps — e.g., the growth metaphor, hand-painted scenes, social saving.]*

### C.5 Go-to-market / channels
- *[e.g., App Store / TestFlight beta → word of mouth → social media → school showcase.]*

### C.6 Messaging & taglines
- Tagline options: *[“Grow your money like a tree.” / …]*
- Key messages: *[…]*

### C.7 Metrics for success
- *[e.g., beta tester retention over 2 weeks, goals created per user, weekly streak rate, qualitative feedback.]*
