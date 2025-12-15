 # AGENTS: How to work effectively in this codebase
 
 This document is for AI agents and contributors. It explains how this Flutter app is organized, the conventions it follows, and project‑specific rules to respect when implementing changes.
 
 ## 1) Project overview and purpose
 Breakaway365 is a cross‑platform Flutter web app (mobile/desktop/web) connected to Firebase. It provides a learning and coaching experience with:
 - Member and Coach dashboards (distinct shells/navigation)
 - Content Library backed by Firestore (“courses”) with rich filtering and video playback
 - Course detail pages with a Modules panel populated from Firestore references
 - Assessments, scorecards, documents, and in‑app notifications
 - An embedded AI Coach (web iframe) and message/forum experiences
 
 Primary backend: Firebase (Auth, Firestore, Storage). Large file uploads are supported via Google Cloud Storage (GCS) using the googleapis SDK.
 
 ## 2) Key architectural patterns and conventions
 - App entry and routing
   - App initializes Firebase in `main()` using `DefaultFirebaseOptions.currentPlatform` (lib/firebase_options.dart) and launches `MyApp` -> `AuthLandingPage`.
   - Navigation inside major dashboards is stateful and driven by enums (no global router).
     - Member shell: `DashboardPage` uses `NavigationItem` enum.
     - Coach shell: `CoachDashboardShell` uses `CoachNavigationItem` enum.
     - Tabs/subsections are also enums (e.g., `DashboardTab`).
   - For detail views, `Navigator.push` is used selectively (e.g., content details).
 
 - UI composition
   - Most screens and many components live in `lib/main.dart` as private widgets (leading underscore) for locality of reference and encapsulation.
   - Reusable widgets live under `lib/widgets/` (e.g., shimmer skeletons, web embeds) and specific pages under `lib/pages/`.
   - Responsive layouts use `LayoutBuilder` and content paddings that adapt to width.
   - Loading states frequently use the in‑house shimmer utilities (`ShimmerContainer`, `ShimmerGrid`).
 
 - State management
   - Local `StatefulWidget` + `setState()` is the dominant pattern.
   - A lightweight `InheritedWidget` (`_DashboardNavigationProvider`) is used for scoped navigation callbacks within the coach shell.
 
 - Data layer
   - Direct Firebase use in widgets/services: `FirebaseAuth`, `FirebaseFirestore`, and `FirebaseStorage`.
   - Services are plain static classes (no DI):
     - `UsageMetricsService`: logs/aggregates learning sessions and activity per user.
     - `CategoryProgressService`: computes category pie slices from various possible Firestore shapes.
     - `NotificationService`: writes notification docs and ensures welcome notices.
     - `GCSService`: uploads/deletes/list files via Google Cloud Storage API.
   - Firestore timestamps use `FieldValue.serverTimestamp()`; logs use `debugPrint()`.
 
 - Web vs non‑web implementations
   - Conditional exports with `if (dart.library.html)` select web implementations:
     - `lib/pages/aicoach_view.dart` -> stub (launch external) vs web (iframe embed).
     - `lib/widgets/embed_view.dart` -> stub vs web.
   - Web embeds register a unique `HtmlElementView` viewType per instance to prevent iframe caching issues.
 
 - Theming and design
   - Centralized theme in `lib/theme.dart` with Material 3 enabled, Inter fonts, and light/dark color schemes.
   - Use `Color.withValues(alpha: x)` instead of deprecated `withOpacity()`.
   - Many surfaces use low‑elevation, rounded cards and minimalist icons. Subtle gradients are used in select components.
 
 ## 3) Important directories
 - lib/
   - main.dart: The primary UI with most pages and components (member/admin/coach flows, content library, dashboards, notes, forum/messages, etc.).
   - theme.dart: Material 3 theme, color schemes, and typography.
   - pages/
     - aicoach_view_(stub|web).dart: AI Coach view (external launcher vs web iframe).
     - gcs_upload_page.dart: Large‑file upload UI targeting GCS.
     - upload_results_page.dart: Assessment results uploader and value capture.
   - services/
     - gcs_service.dart: Google Cloud Storage operations.
   - widgets/
     - shimmer_skeleton.dart: In‑house shimmer/skeleton system.
     - embed_view_(stub|web).dart: Generic web embed view (iframe on web).
   - firebase_options.dart: FlutterFire config (already populated for this project).
 - assets/images/: App imagery used throughout the UI.
 - web/: PWA assets (icons, manifest) and `index.html`.
 - android/, ios/: Standard Flutter platform scaffolding and Firebase configs.
 - firestore.rules, firestore.indexes.json: Firestore security and indexes.
 
 ## 4) Code style and naming conventions
 - Follow Flutter/Dart null‑safe idioms and prefer `const` where possible.
 - Private widget/classes/methods are prefixed with `_` when scoped to a file.
 - Use `debugPrint()` for all error and diagnostic logs written from app code.
 - Prefer Material 3 components and `TextTheme` roles (e.g., titleLarge, bodyMedium, labelSmall).
 - Colors: Use theme colors where possible; prefer `Colors.<name>` for standard colors; avoid hardcoding unless part of a specific design element. When adjusting global colors, update `theme.dart` instead of scattering literals.
 - Use `Color.withValues(alpha: x)` (not `withOpacity()`).
 - Web embeds must use `dart:ui_web` platformViewRegistry; avoid altering renderer settings.
 
 ## 5) Common patterns for implementing features
 - Adding a new section in a dashboard
   1) Extend the relevant enum (`NavigationItem` or `CoachNavigationItem`).
   2) Add a `case` in the shell’s `switch` that returns your new page/widget.
   3) Add a corresponding entry in the side navigation (see `_SideNavigation` or `_CoachSideNavigation`).
 
 - Creating a new page/component
   - Prefer a standalone widget in `lib/pages/` or `lib/widgets/` if reused.
   - Keep private, page‑local components as `_PrivateWidget` within the same file.
   - Provide loading placeholders with `ShimmerContainer`/`ShimmerGrid` where data loads asynchronously.
 
 - Firestore data access
   - Read directly with `FirebaseFirestore.instance` in widgets or helper services.
   - Use `serverTimestamp` for created/updated times.
   - Handle missing/optional fields defensively using helper readers like `_readString` (see Content Library mapping) and null checks.
   - If adding composite queries, update `firestore.indexes.json` accordingly to avoid runtime index errors.
 
 - Course modules (critical rule)
   - The Course Detail page’s Modules panel is populated only from the course’s `videos` array field (Firestore document references or IDs). The loader tries both collections `video` and `videos` to resolve items by ID and preserves the configured order.
   - Do not “guess” modules via tag/topic queries for the Modules panel; it should reflect the course’s explicit `videos` list.
 
 - Embedded AI Coach / web iframes
   - Use the conditional export pattern (`if (dart.library.html)`) and register unique `HtmlElementView` types per URL.
   - On non‑web platforms, fall back to a stub that opens the URL using `url_launcher`.
 
 - Notifications and usage metrics
   - Use `NotificationService` to write notification docs.
   - Use `UsageMetricsService` to start/stop learning sessions and log daily access.
 
 - GCS uploads
   - Use `GCSService.uploadFile` for small/medium files and `uploadLargeFile` (resumable) for very large files.
   - Store document metadata in Firestore after upload (`documents` collection).
 
 ## 6) Project‑specific rules and constraints
 - Firebase
   - The project is already wired to Firebase using `lib/firebase_options.dart` and platform files (google‑services.json, etc.). Do not alter renderer/platform configs.
   - Collections used prominently: `users`, `courses`, `video` and/or `videos`, `coachingNotes`, `notifications`, `app_settings/announcements`, user subcollections like `learning_sessions`, `activity`.
   - Timestamps must use `FieldValue.serverTimestamp()`; use `DocumentReference` fields when storing references (e.g., `users.coach`).
 
 - Content Library & categorization
   - The library maps Firestore docs into a unified card model. Filtering/search is done in‑memory with normalized tags and keyword synonyms.
   - Category colors are stable and used across charts and labels; keep topic keys consistent (e.g., think, keep, accelerate, transform, abundance, immersive footage/expert series fallbacks).
 
 - UI/UX
   - Minimal elevation, rounded corners, high contrast for icons within buttons, generous spacing, and subtle gradients.
   - Prefer modern bottom sheets/dialogs with smooth transitions when introducing new modal UI.
 
 - Dreamflow constraints
   - Run in CanvasKit (default). Do not change the web renderer.
   - When adding assets, ask the user to upload via Dreamflow’s Assets panel and reference by filename under `assets/images/`.
   - Keep code standard Dart/Flutter; Dreamflow hot‑reloads automatically after changes.
 
 If you’re unsure about a pattern, look at similar existing implementations in `lib/main.dart` (e.g., `_FirestoreCourseGrid`, `_ModulesPanel`, `UsageMetricsService`, `NotificationService`) and mirror their style.