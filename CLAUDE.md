# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter mobile app (iOS & Android) for Invoice Generator. Two modes: **offline** (local SQLite, no server) and **online** (REST API + JWT auth via Expense Tracker). Mode chosen on Welcome Screen, stored in SharedPreferences. Full SRS is in `Documentation/invoice-generator-mobile-srs.md`.

## Build & Run Commands

```bash
flutter pub get                                          # Install dependencies
flutter run --dart-define=API_URL=http://localhost:8081 --dart-define=AUTH_URL=http://localhost:8080  # Dev
flutter run --dart-define=API_URL=https://invoice.digitlock.systems --dart-define=AUTH_URL=https://expense.digitlock.systems  # Prod
flutter test                                             # Run all tests
flutter test test/widget_test.dart                       # Run single test
flutter analyze                                          # Static analysis
```

## Architecture

**Layered architecture:** Presentation → State (Riverpod) → Data → REST API.

- **`lib/app/`** — Router (GoRouter) and Material 3 theme. Router uses a `ShellRoute` for the 4 bottom-tab screens; detail/form routes live outside the shell for full-screen push navigation.
- **`lib/screens/`** — One file per screen. Screens are thin: they read providers and render widgets.
- **`lib/widgets/`** — Reusable UI components. `shell_scaffold.dart` is the bottom tab bar wrapper used by ShellRoute.
- **`lib/providers/`** — Riverpod providers (state layer). Each domain entity gets its own provider file.
- **`lib/data/`** — Repository pattern: abstract interfaces in `repositories/`, remote (Dio) implementations in `remote/`, local (SQLite) implementations in `local/` (planned). Providers switch between remote/local based on `appModeProvider`.
- **`lib/models/`** — Dart data classes matching API JSON responses.
- **`lib/services/`** — Platform services (ads, storage wrappers).

## Key Conventions

- **State management**: Riverpod only (no setState for async/shared state). App root wraps in `ProviderScope`.
- **Navigation**: GoRouter declarative routing. Routes defined in `lib/app/router.dart`. Use `context.go()` for tab switches, `context.push()` for detail/form screens.
- **Two API base URLs**: `API_URL` (Invoice Generator, default `localhost:8081`) and `AUTH_URL` (Expense Tracker login, default `localhost:8080`). Injected via `--dart-define`. Two separate Dio instances: `dioProvider` (with JWT interceptor) and `authDioProvider` (no interceptor, for login only).
- **Theme colors**: Primary `#2563EB`, Error `#DC2626`, Surface `#FFFFFF` — must match web dashboard's Tailwind palette.
- **Bundle ID**: `systems.digitlock.invoicegenerator` (both platforms).
- **Minimum OS**: iOS 15.0, Android API 26.
- **Monetization packages** (`google_mobile_ads`, `in_app_purchase`) are deferred to Stage 4.6 — do not add them yet.
- **Company/bank account screens are read-only** in online mode (no create/edit/delete). Full CRUD in offline mode.
- **App mode**: `appModeProvider` (`AppMode.offline` / `AppMode.online` / `null`). `null` = first launch → Welcome Screen. Screens guard auth only when `isOnline`.

## Related Projects

- Backend API (Go) and web frontend (Vue.js): `~/Documents/Projects/invoice-generator/`
- Use as reference for API contracts (endpoint shapes, JSON field names) and code style.
