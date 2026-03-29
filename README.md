# Invoice Generator - Mobile App

Flutter mobile app (iOS & Android) for the Invoice Generator system. Supports two modes: **offline** (local SQLite + client-side PDF) and **online** (REST API + server-side PDF). Companion to the [web dashboard](https://invoice.digitlock.systems).

## Features

- **Two modes** — Offline (SQLite + local PDF) and Online (REST API + server PDF), selected on Welcome screen
- **Invoice CRUD** — Create, edit, duplicate, delete, status management (draft/sent/partially_paid/paid/cancelled), overdue toggle
- **Client management** — Create, edit, filter by active/inactive status
- **Company & bank accounts** — Full CRUD (offline), read-only (online)
- **PDF generation** — Client-side with Dart `pdf` package (offline), server-side download (online)
- **Configurable server settings** — Multiple server support, test connection, preset DigitLock Cloud
- **Authentication** — JWT login via Expense Tracker (online mode only)
- **Material Design 3** — Custom theme matching web dashboard (#2563EB primary)
- **UX polish** — Haptic feedback, pull-to-refresh, infinite scroll pagination, swipe-to-delete, bottom sheets

## Screens

| Screen | Description |
|--------|-------------|
| Welcome | Mode selection (offline/online) on first launch |
| Login | JWT authentication (online mode) |
| Dashboard | Recent invoices, quick create, settings access |
| Invoice List | Full history with status filters, search, pagination |
| Invoice Detail | View all sections, change status, PDF download, edit/delete/duplicate |
| Invoice Form | Create/edit with entity dropdowns (+), line items, auto-calculated totals |
| Client List | Filter by active/inactive, create/edit |
| Client Form | Create/edit client with status toggle |
| Company Detail | Read-only (online) or full CRUD (offline) with bank accounts |
| Company Form | Create/edit company (offline mode) |
| Bank Account Form | Add bank account to company (offline mode) |
| Server Settings | Add/edit/delete servers, test connection, switch active |
| Settings | Current mode, switch mode, server config, app version |

## Architecture

```
┌─────────────────────────────────────────────────┐
│              Presentation Layer                   │
│  Screens + Widgets + GoRouter                     │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────┴──────────────────────────────┐
│              State Layer (Riverpod)               │
│  AppModeProvider → switches data path             │
│  AuthProvider, InvoiceProvider, etc.              │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────┴──────────────────────────────┐
│              Data Layer (Repository Pattern)      │
│  Abstract interfaces (lib/data/repositories/)     │
│      ┌──────────────┴──────────────┐              │
│  Remote (Dio)              Local (SQLite)          │
│  lib/data/remote/          lib/data/local/         │
└──────────────────┬──────────────┬────────────────┘
                   │              │
         ┌─────────┘              └─────────┐
   Invoice Generator API            SQLite DB
   (:8081) + Auth API (:8080)    (on device)
```

**AppModeProvider** reads saved mode from SharedPreferences and switches repository implementations:
- `AppMode.offline` → `Local*Repository` (SQLite + local PDF)
- `AppMode.online` → `Remote*Repository` (Dio + REST API)

## Project Structure

```
lib/
├── main.dart
├── app/
│   ├── router.dart                    # GoRouter with auth guard + mode routing
│   └── theme.dart                     # Material 3 theme
├── models/
│   ├── auth.dart                      # LoginRequest, LoginResponse, User
│   ├── invoice.dart                   # Invoice, InvoiceListItem, InvoiceItem
│   ├── company.dart                   # Company
│   ├── client.dart                    # Client
│   ├── bank_account.dart              # BankAccount
│   ├── pagination.dart                # PaginationMeta, PaginatedResponse
│   └── server_config.dart             # ServerConfig
├── data/
│   ├── repositories/                  # Abstract interfaces
│   ├── remote/                        # Online: Dio + REST API
│   ├── local/                         # Offline: SQLite
│   ├── api_client.dart                # Dio instances + JWT interceptor
│   └── auth_repository.dart           # Login/logout/token storage
├── providers/
│   ├── app_mode_provider.dart         # Offline/online mode state
│   ├── auth_provider.dart             # JWT auth state
│   ├── server_config_provider.dart    # Server URL management
│   ├── invoice_provider.dart
│   ├── company_provider.dart
│   ├── client_provider.dart
│   └── bank_account_provider.dart
├── screens/                           # 13 screens (see table above)
├── services/
│   ├── database_service.dart          # SQLite init + schema
│   └── local_pdf_service.dart         # Client-side PDF generation
└── widgets/
    ├── shell_scaffold.dart            # Bottom tab bar
    ├── invoice_card.dart              # Reusable invoice card
    ├── status_badge.dart              # Colored status chip
    ├── overdue_badge.dart             # Red overdue chip
    ├── line_item_row.dart             # Invoice form line item
    ├── loading_indicator.dart
    ├── error_view.dart
    ├── snackbar_helper.dart           # Success/error snackbars
    └── ad_placeholder.dart            # Ad placeholder for Stage 4.6
```

## Getting Started

```bash
flutter pub get

# Offline mode — no backend required
flutter run

# Online mode — with local backend
flutter run \
  --dart-define=API_URL=http://localhost:8081 \
  --dart-define=AUTH_URL=http://localhost:8080
```

On first launch, the Welcome screen lets you choose Offline or Online mode. Server URLs can also be configured in-app via Settings > Server Settings.

## Build

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ipa
```

For online mode with specific server URLs:
```bash
flutter build apk --release \
  --dart-define=API_URL=https://invoice.digitlock.systems \
  --dart-define=AUTH_URL=https://expense.digitlock.systems
```

## Screenshots

<!-- TODO: Add screenshots -->

## QA Testing

See [Documentation/qa-test-plan.md](Documentation/qa-test-plan.md) for the full test plan with 152 test cases.

**Regression smoke test:** 11 checks covering both modes, CRUD, PDF, navigation, and mode switching.

## Documentation

- [SRS](Documentation/invoice-generator-mobile-srs.md) — Full system requirements specification
- [QA Test Plan](Documentation/qa-test-plan.md) — Test cases and regression checklist
