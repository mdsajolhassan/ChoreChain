# ChoreChain
**Tagline:** *Empowering families through shared responsibilities and financial literacy.*

ChoreChain is a comprehensive family chore management and allowance-tracking application. It bridges the gap between household responsibilities and financial education by allowing parents to assign tasks, set weekly budgets, and approve chore completions, while children can manage their chores, track their earnings, and request approvals in a gamified, safe environment.

---

## 🛠️ Tech Stack & Packages
ChoreChain is built entirely on the Flutter framework and powered by Google's Firebase ecosystem.

**Core Technologies:**
* **Frontend:** Flutter (Dart) 
* **Backend:** Firebase (Authentication, Cloud Firestore)
* **Platforms Supported:** Android, iOS, and Flutter Web

**Key Dependencies (`pubspec.yaml`):**
* `firebase_core` & `cloud_firestore`: Backend database management and real-time syncing.
* `firebase_auth` & `google_sign_in`: Seamless and secure user authentication.
* `shared_preferences`: Persistent local storage for user preferences (Theme & Language).
* `google_fonts` & `cupertino_icons`: UI typography and iconography.
* `intl`: Date, time, and currency formatting.

---

## 🏗️ Core Architecture & Folder Structure
The codebase follows a modular, feature-based architecture separating UI screens, core configurations, and business logic services.

```text
lib/
├── main.dart                       # App entry point, Theme/Locale State management
├── firebase_options.dart           # Auto-generated Firebase multi-platform configs
├── core/
│   ├── app_theme.dart              # Custom Material 3 Light/Dark mode configurations
│   └── app_translations.dart       # State-based multi-language dictionary (EN, BN, HI)
├── services/
│   └── auth_service.dart           # Encapsulated Firebase Auth & Google Sign-In logic
└── screens/
    ├── splash_screen.dart          # Initial loading & auth-state routing
    ├── login_screen.dart           # Google Auth UI and Web GIS bypass logic
    ├── role_selection_screen.dart  # Onboarding Role Chooser (Parent/Child) & Code Gen
    ├── parent_main_screen.dart     # Parent Dashboard & Weekly Reset Logic
    ├── child_main_screen.dart      # Child Dashboard & Task View
    ├── add_task_screen.dart        # Task creation (One-time vs. Recurring)
    ├── family_members_screen.dart  # FIFO-sorted Family List & Deletion Approvals
    ├── allowance_settings_screen.dart # Weekly budget management
    ├── profile_settings_screen.dart # Child settings (Request Deletion, Localization)
    ├── settings_screen.dart        # Parent settings (Invite Code Fallback, Localization)
    └── task_detail_screen.dart     # Granular task view & Approval logic
```

---

## 👥 Feature List by Role

### 👨‍👩‍👧 Parent Role
* **Family Management:** Generate a unique 6-character alphanumeric `familyId` to securely invite children to the network.
* **Dashboard & Metrics:** View at-a-glance household progress, pending approvals, and total weekly payouts.
* **Task Management:** Create One-Time or Recurring (Weekly) chores, assign them to specific children, and set custom reward amounts.
* **Approvals System:** Review chores marked "completed" by children and officially approve them to trigger payouts.
* **Allowance Control:** Set strict Weekly Budgets per child to cap maximum earnings and prevent over-spending.
* **Account Moderation:** Approve or Reject account deletion requests initiated by children (ensuring safe data lifecycle).

### 👦👧 Child Role
* **Secure Onboarding:** Link directly to a parent's account by entering the unique 6-character Family Invite Code.
* **Personalized Dashboard:** View assigned chores categorized by status (Pending, Completed, Approved).
* **Task Execution:** Mark chores as complete, sending an automatic approval request to the Parent.
* **Wallet & Earnings:** Track current balance, total earnings, and view progress toward the parent-defined Weekly Budget.
* **Account Privacy:** Request account deletion securely (requires Parent approval to execute).

### 🌍 Universal Features (Both Roles)
* **Multi-Language Support:** Instant, state-driven localization supporting English, Bengali, and Hindi.
* **Dark/Light Mode:** Dynamic theming driven by `ValueNotifier` and persisted locally via `shared_preferences`.
* **Cross-Platform Google Sign-In:** One-click authentication optimized for both Mobile and Web platforms.

---

## 🔐 Key Security & Advanced Logic

### 1. Web-Native Google Identity Services (GIS) Bypass
To ensure seamless Google Sign-In across all platforms, ChoreChain intelligently bypasses the restrictive `renderButton` requirement on Flutter Web. It uses a `kIsWeb` conditional check to dynamically route web users through `FirebaseAuth.instance.signInWithPopup()`, maintaining a native feel without breaking the mobile build.

### 2. Parent-Approved Deletion (Spark Plan Workaround)
Since ChoreChain operates on the Firebase Spark Plan (no Cloud Functions), it features a highly secure, client-side deletion protocol:
1. **Request Phase:** Child requests deletion. Firestore sets `deletionRequested: true`.
2. **Approval Phase:** Parent reviews the request in the UI and sets `deletionApproved: true`. The child is immediately hidden from the Parent's UI via client-side `.where` filters.
3. **Execution Phase:** Upon the child's next login attempt (or via a stream listener), the app intercepts the session. It purges the Firestore document *first*, executes `FirebaseAuth.instance.currentUser?.delete()` *second*, and forcefully signs the child out, preventing "ghost" logins.

### 3. Strict Weekly Reset Engine
To maintain accurate weekly chore cycles without a centralized cron server:
* `parent_main_screen.dart` evaluates a strict `_checkWeeklyReset()` function on every load.
* It verifies if the current date has crossed into a new week (Saturday 00:00:00).
* If true, it recursively resets all children's weekly balances to `0`, deletes completed One-Time tasks, and reverts recurring tasks to a "Pending" status, ensuring a fresh start.

### 4. Client-Side FIFO Sorting
To prevent Firebase from demanding strict composite indexes (which can cause deployment friction on the Spark plan), ChoreChain leverages intelligent client-side sorting. Children lists are pulled linearly and sorted in-memory using `createdAt` (First-In-First-Out), ensuring predictable UI ordering without backend overhead.

### 5. Hardened Firestore Security Rules
The database is locked down with strict rules ensuring data isolation:
* `allow read: if isAuthenticated();` (Allows secure onboarding lookups).
* `allow delete: if isAuthenticated() && request.auth.uid == userId;` (Secures the self-deletion protocol).
* Write operations are strictly bounded to verify the user is a designated 'Parent' or modifying their own authorized fields.
