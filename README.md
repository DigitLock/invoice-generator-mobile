# Invoice Generator - Mobile App

Flutter mobile app (iOS & Android) for the Invoice Generator system. Companion to the [web dashboard](https://invoice.digitlock.systems), consuming the same REST API.

## Features

- **Authentication** — JWT login shared with Expense Tracker (separate auth service)
- **Dashboard** — Recent invoices overview, quick create
- **Invoice management** — Create, edit, view detail, status transitions, overdue toggle, PDF download
- **Client management** — Create, edit, filter by active/inactive status
- **Company & bank accounts** — Read-only view (managed via web dashboard)
- **Status management** — Bottom sheet with valid transitions, confirmation dialogs, haptic feedback

## Architecture

```
Presentation (Screens + Widgets)
        ↓
State (Riverpod Providers)
        ↓
Data (Repository Pattern)
  ├── Abstract interfaces (lib/data/repositories/)
  └── Remote implementations (lib/data/remote/)  ← Dio + REST API
        ↓
Invoice Generator API (:8081) + Expense Tracker Auth API (:8080)
```

- **Repository pattern** — Abstract interfaces allow swapping remote/local implementations. Planned: SQLite local cache for offline mode.
- **GoRouter** — Declarative routing with auth guard and splash screen
- **Material Design 3** — Custom theme matching web dashboard colors

## Getting Started

```bash
flutter pub get

# Development (both APIs running locally)
flutter run \
  --dart-define=API_URL=http://localhost:8081 \
  --dart-define=AUTH_URL=http://localhost:8080

# Production
flutter run \
  --dart-define=API_URL=https://invoice.digitlock.systems \
  --dart-define=AUTH_URL=https://expense.digitlock.systems
```

## Build

```bash
# Android APK
flutter build apk --release \
  --dart-define=API_URL=https://invoice.digitlock.systems \
  --dart-define=AUTH_URL=https://expense.digitlock.systems

# iOS
flutter build ipa \
  --dart-define=API_URL=https://invoice.digitlock.systems \
  --dart-define=AUTH_URL=https://expense.digitlock.systems
```

## Screenshots

<!-- TODO: Add screenshots after UI polish -->

## Documentation

See [Documentation/invoice-generator-mobile-srs.md](Documentation/invoice-generator-mobile-srs.md) for full SRS.
