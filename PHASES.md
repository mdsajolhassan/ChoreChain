# ChoreChain - Development Phases

## Phase 1: Project Setup & Authentication
* Initialized Flutter project and configured cross-platform builds (Android, Web, Windows).
* Integrated Firebase Auth and Cloud Firestore.
* Implemented Google Sign-In with a custom `kIsWeb` bypass for seamless web popups without GIS restrictions.

## Phase 2: Role-Based Architecture & Family Onboarding
* Developed Role Selection flow (Parent vs. Child).
* Implemented secure 6-character alphanumeric family invite code generation for Parents.
* Created the child onboarding workflow to seamlessly link with the parent's account using the invite code.

## Phase 3: Core Features (Task & Wallet Management)
* **Parents:** Enabled assigning One-Time/Recurring tasks, setting weekly budgets, and approving completed chores to release payouts.
* **Children:** Built the interactive dashboard to view assigned chores, execute tasks, and track wallet earnings against the budget.

## Phase 4: Advanced State & Logic Implementation
* Developed strict Weekly Reset logic (triggers every Saturday at 00:00:00) to automatically clear balances and rotate recurring tasks without needing a backend cron job.
* Implemented client-side FIFO sorting to bypass Firebase composite index limits on the Spark plan.
* Added state-driven Multi-Language Support (English, Bengali, Hindi) using `shared_preferences` for instant UI updates.
* Integrated dynamic Light/Dark mode toggling.

## Phase 5: Security & Account Lifecycle
* Engineered a highly secure client-side account deletion flow for the Firebase Spark Plan.
* Implemented Parent-approved account deletion logic for child accounts.
* Prevented "ghost" logins by safely destroying Auth and Firestore data simultaneously upon deletion approval.
