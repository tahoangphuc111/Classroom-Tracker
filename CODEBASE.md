# Classroom Tracker - Codebase & Architecture Guide

Classroom Tracker is a Google Classroom client and widget designed around the Vietnamese school routine—specifically **Báo bài Ngày mai** (prepping for tomorrow's classes). 

The project started as a native Apple app (macOS menu bar/window + iOS/iPadOS with WidgetKit) and is now ported to native Android (Kotlin, Jetpack Compose, Jetpack Glance). Both platforms live in this repository.

---

## 1. Core Concepts & Business Logic

If you work on this codebase, these are the non-negotiable rules and behaviors that define how the app works.

### The "Tomorrow First" Mental Model (Báo bài)

In Vietnamese schools, students pack their schoolbags in the afternoon or evening for the next day. The traditional *sổ báo bài* (assignment notebook) is all about what is due tomorrow. 

- **Today is considered done**: By the time an evening study session happens, homework due today has already been submitted or dealt with at school. Showing today's completed tasks on tomorrow's prep screen just adds clutter.
- **Expired tasks auto-complete (Past Due Considered Done)**: In accordance with the "Tomorrow First" and "Today is considered done" philosophy, when an assignment's deadline has passed (`dueDate < now` / `dueEpochMillis < System.currentTimeMillis()`), the app intentionally evaluates `isCompleted == true`. Once the deadline passes, the task is considered concluded/expired in the context of prep (Báo bài) rather than remaining as an open blocker. This is an intentional architectural invariant on both Apple (`Coursework.swift`) and Android (`Coursework.kt`).
- **The default view is Tomorrow**: Both the main screen and home screen widgets focus on coursework due between the start of tomorrow (`00:00:00`) and the start of the day after (`23:59:59`).
- **Fallback sequence when tomorrow is empty**:
  1. Incomplete tasks due today or nearest upcoming.
  2. Upcoming tasks further out.
  3. Undated tasks.
  4. Empty state ("Ngày mai rảnh rồi!" / All caught up).

Do not change the widgets or main landing screen to default to "Today" or a flat "All Upcoming" list.

### Local Completion Overrides Remote Sync

Students often finish physical worksheets or readings without submitting them on Google Classroom right away. The app gives them a local checkbox to tick things off.

- When a user checks a task off locally (`isCompleted = true` / `status = TURNED_IN`), background sync with Google Classroom **must not** revert it back to `PENDING` or `LATE`.
- If Google Classroom reports a task as completed/turned in remotely, we accept that.
- If Google Classroom reports a task as incomplete, but the user already marked it completed locally, we keep the local completion state.

```kotlin
val finalStatus = if (existingItem?.isCompleted == true && !incomingItem.isCompletedOnGoogle) {
    existingItem.status // preserve local checkmark
} else {
    incomingItem.status
}
```

### No Mock Data on Widgets

The main app shows mock courses and assignments on first launch so users can see what it looks like before signing in. 

Home screen widgets must **never** show mock data. If the user is logged out, the widget must display a simple "Tap to sign in" prompt. Leaking mock data into widgets causes users to think they have real assignments due when they do not.

### Google Classroom API Rate Limits (10 QPS)

Google Classroom API has a strict per-user quota of 10 requests per second. A student enrolled in 10 courses can easily trigger 20+ calls (courses, coursework, student submissions) if fetched concurrently, immediately hitting HTTP 429 `RESOURCE_EXHAUSTED`.

All multi-course queries must be chunked:
- Process courses in batches of 3 (`chunkSize = 3`).
- Add a short delay (~200–250ms) between batches.
- Do not use unbounded parallel `async`/`map` calls across courses.

### Due Date and Timezone Handling

Google Classroom returns due dates in UTC as `{ year, month, day }` and due times as `{ hours, minutes, seconds }`.

1. **Explicit due time**: Parse as UTC, then convert to the device's local timezone.
2. **Missing due time (`dueTime == null`)**: Google Classroom documentation states this means "due by end of day". In the user's local timezone, that is **23:59:59 local time**, not UTC midnight. Parsing null as UTC midnight shifts deadlines by +7 hours in Vietnam, incorrectly pushing tasks into the previous day.
3. **Late night display**: If an assignment is due at 23:55 or later, the UI displays `"Cuối ngày"` (End of Day) instead of an exact time badge like "23:59".

### Visual Design & Theme

- **Light mode only**: The app uses a paper/daylight aesthetic with sky-blue gradients and warm cards.
- The mascot is **Ember** (a hand-drawn flame character).
- Do not add a dark theme toggle or enable Android Material You dynamic wallpaper recoloring. It breaks the contrast on the custom illustration paths and subject badges.

### Subject Classification (`SubjectArtHelper`)

Teachers name Google Classroom courses in arbitrary ways (`"12A1 - Toan"`, `"Chuyen de Vat li 2024"`, `"English 12"`). We use keyword matching to assign subjects, colors, and short codes (`TOÁ`, `LÝ`, `HOÁ`, `VĂN`, etc.).

Watch out for false positives in Vietnamese:
- `"LÝ"` (Physics) must not match `"quản lý"` (management), `"xử lý"` (processing), or `"tâm lý"` (psychology).
- `"HOÁ"` (Chemistry) must not match `"văn hóa"` (culture) or `"hóa đơn"` (invoice).
- `"SỬ"` (History) must not match `"sử dụng"` (use) or `"lịch sự"` (polite).

---

## 2. Android Database & Storage Architecture

The Android app uses three persistence layers:

```
┌────────────────────────────────────────────────────────┐
│                   Room Database                        │
├────────────────────────────┬───────────────────────────┤
│ courses                    │ courseworks               │
│ - id (PK)                  │ - id (PK)                 │
│ - name                     │ - courseId (FK)           │
│ - section                  │ - courseName              │
│ - descriptionHeading       │ - title                   │
│ - room                     │ - description             │
│ - alternateLink            │ - alternateLink           │
│ - isSelectedForWidget      │ - dueEpochMillis          │
│                            │ - status                  │
│                            │ - maxPoints               │
│                            │ - searchIndex             │
└────────────────────────────┴───────────────────────────┘
┌────────────────────────────┬───────────────────────────┐
│         DataStore          │ EncryptedSharedPreferences│
│   (ClassroomPreferences)   │      (TokenStorage)       │
│ - user_email               │ - access_token            │
│ - user_name                │ - refresh_token           │
│ - user_avatar_url          │ - expires_at              │
│ - last_sync_epoch          │ (backed by KeyStore AES)  │
│ - custom OAuth credentials │                           │
└────────────────────────────┴───────────────────────────┘
```

### Room Database (`ClassroomDatabase`)

- **`courses`**: Caches active enrolled courses. `isSelectedForWidget` controls whether a course appears in widget timelines and active filters.
- **`courseworks`**: Caches assignments.
  - `courseName` is denormalized so cards can render instantly without joins.
  - `dueEpochMillis` stores epoch time in milliseconds for sorting (nullable for undated tasks).
  - `searchIndex` stores a lowercase, diacritic-stripped string (combining title, course name, and description) to power fast Vietnamese full-text search.
  - Indexed on `courseId`, `dueEpochMillis`, and `status`.

### Preferences (`ClassroomPreferences`)

Stored via Jetpack DataStore Preferences: user profile details, last sync timestamp, and optional user-supplied OAuth client credentials.

### Secure Token Storage (`TokenStorage`)

Stores OAuth2 tokens in `EncryptedSharedPreferences` backed by the Android KeyStore (`MasterKey.DEFAULT_AES256_GCM_SPEC`). Tokens are automatically refreshed when within 60 seconds of expiration.

---

## 3. Repository Layout

```
classroom/
├── ClassroomApp/          # Apple: macOS and iOS SwiftUI application
├── ClassroomWidget/       # Apple: WidgetKit extensions for iOS and macOS
├── Shared/                # Apple: Shared models, networking, storage, and views
│   ├── Models/            # Course.swift, Coursework.swift
│   ├── Network/           # GoogleOAuthService.swift, ClassroomAPIService.swift
│   ├── Storage/           # ClassroomStorage.swift (App Group JSON cache)
│   └── WidgetViews/       # Ember flame drawing, MediumWidgetView, ChunkyTheme
│
├── android/               # Native Android application
│   ├── gradle/
│   │   └── libs.versions.toml # Version catalog
│   ├── build.gradle.kts
│   ├── settings.gradle.kts
│   └── app/
│       ├── build.gradle.kts   # minSdk 26, targetSdk 34, Java 17
│       └── src/
│           ├── main/
│           │   ├── AndroidManifest.xml
│           │   ├── res/       # Fonts (Be Vietnam Pro, Outfit), drawables, strings
│           │   └── java/com/phucta/classroom/
│           │       ├── data/
│           │       │   ├── local/      # Room DB, DAOs, DataStore, TokenStorage
│           │       │   ├── model/      # Entities and domain models
│           │       │   ├── remote/     # Retrofit service, AppAuth OAuth manager
│           │       │   └── repository/ # ClassroomRepository
│           │       ├── domain/         # Bucketing and date utilities
│           │       ├── ui/
│           │       │   ├── components/ # AssignmentCard, EmberCanvas, SubjectBadge
│           │       │   ├── screens/    # TomorrowScreen, AllUpcomingScreen, SettingsDialog
│           │       │   └── theme/      # Colors, typography, shapes
│           │       ├── widget/         # Glance widgets (ClassroomGlanceWidget)
│           │       └── worker/         # WorkManager 15-minute periodic sync worker
│           └── test/                  # Unit tests (bucketing, dates, search, subjects)
│
├── project.yml            # XcodeGen project specification for Apple builds
├── CODEBASE.md            # This file
└── README.md              # Project introduction
```

---

## 4. Cross-Platform Parity

How key responsibilities map between Apple and Android:

| Feature | Apple (macOS / iOS) | Android |
|---|---|---|
| **UI** | SwiftUI | Jetpack Compose |
| **Widgets** | WidgetKit (`TimelineProvider`) | Jetpack Glance (`GlanceAppWidget`) |
| **Database** | Multi-file JSON cache in App Group | Room (SQLite) with Kotlin `Flow` |
| **Token Storage** | macOS/iOS Keychain | Android KeyStore (`EncryptedSharedPreferences`) |
| **Background Sync** | Background App Refresh + in-app Timer | `WorkManager` (15-min periodic worker) |
| **OAuth** | `ASWebAuthenticationSession` (PKCE) | Custom Tabs + AppAuth PKCE redirect |
| **Ember Mascot** | SwiftUI `Canvas` / `Path` | Jetpack Compose `Canvas` |
| **Vietnamese Search** | `String.normalizedForVietnameseSearch()` | `String.normalizeForVietnameseSearch()` |
| **Theme** | Locked light (`.preferredColorScheme(.light)`) | Locked light (`ChunkyDaylightPalette`) |

---

## 5. Development Notes

- **Building Apple**: Run `xcodegen generate` using `project.yml`, then open `ClassroomTracker.xcodeproj` in Xcode.
  - **macOS Target**: Exclusively macOS 27 (`27.0`).
  - **iOS Target**: iOS 17.0 -> 27.0 (minimum iOS 17.0).
- **Building Android**: Open `android/` in Android Studio or run `./gradlew assembleDebug` / `./gradlew test` from the `android/` directory (requires JDK 17).
- **Build Scripts**:
  - `./scripts/build_pkg.sh`: Builds macOS 27 application and packages into `ClassroomTracker.pkg`.
  - `./scripts/build_ipa.sh`: Archives iOS (17 -> 27) application and packages into `ClassroomTracker.ipa`.
  - `./scripts/build_apk.sh`: Builds signed release APK into `ClassroomTracker.apk`.
  - `./scripts/build_all.sh`: Master build script for all platforms.
- **CI/CD Pipeline (`.github/workflows/build.yml`)**:
  - Builds `.pkg` (macOS 27), `.ipa` (iOS 17 -> 27), and `.apk` (Android) automatically on pushes to `main`, Pull Requests, tags, and manual trigger (`workflow_dispatch`).
  - Automatically publishes assets to GitHub Releases when tagged with `v*`.
- **Unit testing utilities**: Date parsing, Vietnamese text search, subject matching, and Báo bài bucketing have dedicated unit tests in both Swift and Kotlin. Run tests before opening PRs when modifying these components.
