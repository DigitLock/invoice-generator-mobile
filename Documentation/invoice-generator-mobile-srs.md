# Invoice Generator — Mobile App System Requirements Specification

---

# 1. Introduction

This System Requirements Specification (SRS) document provides detailed technical requirements for the **Invoice Generator mobile application** (Stage 4) — a Flutter app for iOS and Android that enables authenticated users to create invoices, manage clients, and track invoice statuses on the go.

**Document Version:** 0.3

### Change Log

| Version | Date | Changes |
|---------|------|---------|
| 0.1 | 2026-03-27 | Initial draft aligned with PRD v0.4 Stage 4 requirements |
| 0.2 | 2026-03-28 | Add repository strategy, monetization (ads + IAP), update API base URL |
| 0.3 | 2026-03-28 | Add offline mode, welcome screen, server settings, app modes |

**Document Purpose**

This document defines the mobile app architecture, navigation structure, screen specifications, API integration layer, and platform-specific requirements for the Flutter implementation.

**Scope**

The mobile app is a companion to the web dashboard (Stage 3). It supports two modes: **online mode** consuming the REST API (Stage 2) with JWT authentication, and **offline mode** with local SQLite storage and client-side PDF generation.

- **Core Functionality**: Invoice creation, invoice history with filters, status management (5 statuses + isOverdue), client management (view, create, change status), company/bank account management, offline mode with local SQLite storage, online mode with configurable server
- **Monetization**: Free with ads (Google AdMob), with in-app purchase to remove ads
- **Out of Scope**: Company/bank account editing in online mode (MO-05), guest invoice creation, registration (users register via Expense Tracker), data sync between offline and online modes
- **Distribution**: TestFlight (iOS) and APK sideload (Android) for initial testing, then public release on App Store and Google Play

**Target Audience**

- Flutter developer implementing the mobile app
- Business stakeholder for requirement validation
- Portfolio reviewers for system analysis demonstration

**Related Documents**

- **PRD: Invoice Generator v0.4** — Product Requirements Document (S4-01 through S4-10, MO-01 through MO-05)
- **Invoice Generator SRS v0.2** — Backend API specification (all endpoints consumed by the mobile app)
- **Expense Tracker** — Reference for shared JWT authentication

## 1.1 Repository and Distribution Strategy

### 1.1.1 Separate Repository

The mobile app lives in a **separate Git repository** (`invoice-generator-mobile`), not in the `invoice-generator` monorepo. Rationale:

- The mobile app will be published to App Store and Google Play as a standalone product with its own release cycle
- App store review processes (Apple App Review, Google Play review) require independent versioning, changelogs, and build pipelines
- Flutter project structure (ios/, android/, lib/) does not share any code with the Vue.js frontend or Go backend
- Separate CI/CD pipelines: the web app deploys via Docker, the mobile app deploys via Fastlane/Xcode/Gradle
- The only shared dependency is the REST API contract, which is documented in the backend SRS

### 1.1.2 Monetization Model

**Model:** Free with ads + in-app purchase to remove ads.

| Tier | Price | Features |
|------|-------|---------|
| Free | $0 | Full functionality, banner ads on list screens, interstitial ad after PDF download |
| Ad-Free | One-time purchase (~$4.99) | All ads removed permanently |

**Ad Placement Strategy:**

| Placement | Ad Type | Screen | Frequency |
|-----------|---------|--------|-----------|
| List footer | Banner (320x50) | Invoice List, Client List, Dashboard | Always visible |
| Post-action | Interstitial (full screen) | After PDF download | Every download |
| Post-action | Interstitial (full screen) | After invoice creation | Every 3rd invoice |

**Architecture Impact:**

The monetization model adds the following to the architecture:

- **Ad provider wrapper** (`lib/services/ad_service.dart`): initializes AdMob, loads/shows banner and interstitial ads, respects purchase state
- **Purchase state management** (`lib/providers/purchase_provider.dart`): tracks whether user has purchased ad-free tier, persists via `flutter_secure_storage` + receipt validation
- **Conditional UI**: all ad widgets wrapped in a consumer that checks `isPurchased` — when purchased, ad containers collapse to zero height
- **Purchase screen**: accessible from app settings, shows "Remove Ads" option with price, handles StoreKit (iOS) / Google Play Billing (Android) flow

**Required packages:**

- `google_mobile_ads` — AdMob banner and interstitial ads
- `in_app_purchase` — cross-platform in-app purchase (wraps StoreKit + Google Play Billing)

**Revenue considerations:**

- AdMob requires privacy disclosures (GDPR consent dialog, App Tracking Transparency on iOS)
- In-app purchase requires App Store / Google Play developer accounts ($99/year Apple, $25 one-time Google)
- Receipt validation can be done client-side for MVP; server-side validation is a future improvement

## 1.2 App Modes

The app supports two operating modes, selected on first launch via the Welcome Screen and stored in `SharedPreferences`. The mode can be changed later via Settings.

### 1.2.1 Offline Mode

Full invoicing functionality without a server connection. All data is stored locally on the device.

| Aspect | Detail |
|--------|--------|
| Storage | SQLite database via `sqflite` |
| Authentication | None required — single-user local mode |
| Invoice CRUD | Full create, read, update, delete |
| Client management | Full CRUD (create, edit, change status) |
| Company management | Full CRUD (user manages their own company and bank accounts) |
| PDF generation | Client-side using Dart `pdf` package |
| Data isolation | Offline data is completely separate from any server |
| Sync | Not supported — offline and online are independent |

### 1.2.2 Online Mode

Connected to a configurable Invoice Generator server. Requires JWT authentication via Expense Tracker.

| Aspect | Detail |
|--------|--------|
| Storage | Server-side via REST API |
| Authentication | JWT login via Expense Tracker auth service |
| Invoice CRUD | Full create, read, update, delete via API |
| Client management | Create, edit, change status via API |
| Company management | Read-only on mobile (MO-05) — managed via web dashboard |
| PDF generation | Server-side — download and open with system viewer |
| Server configuration | User-configurable API URL and Auth URL via Server Settings |

### 1.2.3 Mode Selection and Switching

1. On first launch, the Welcome Screen presents two options: "Use Offline" and "Connect to Server"
2. Selected mode is persisted in `SharedPreferences` (`app_mode` key: `offline` or `online`)
3. Mode can be switched via the Settings screen at any time
4. Switching modes does not delete data — offline data persists, online data is on the server
5. When switching to online, the user must configure a server and authenticate

**Technology Stack**

- **Framework**: Flutter 3.x (Dart)
- **State Management**: Riverpod (recommended — see section 2.1 rationale)
- **HTTP Client**: `dio` with interceptor for JWT injection
- **Local Storage**: `flutter_secure_storage` for JWT token, `shared_preferences` for user preferences
- **Navigation**: GoRouter (declarative, supports deep linking)
- **UI**: Material Design 3 with custom theme matching web app colors
- **PDF Viewing**: `open_file` or `url_launcher` to open server-generated PDFs
- **Local Database**: `sqflite` for offline mode SQLite storage
- **PDF Generation**: `pdf` (Dart) for client-side PDF generation in offline mode
- **File System**: `path_provider` for accessing temporary and documents directories
- **Ads**: `google_mobile_ads` (AdMob banners + interstitials)
- **In-App Purchase**: `in_app_purchase` (StoreKit for iOS, Google Play Billing for Android)
- **Build**: Flutter CLI, Fastlane (optional for CI/CD)
- **Minimum OS**: iOS 15.0+, Android API 26+ (Android 8.0)

---

# 2. Functional Requirements

## 2.1 App Architecture

### 2.1.1 Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                  Flutter App                      │
│                                                   │
│  ┌─────────────────────────────────────────────┐ │
│  │              Presentation Layer               │ │
│  │  Screens (pages) + Widgets (components)       │ │
│  │  GoRouter for navigation                      │ │
│  └──────────────────┬──────────────────────────┘ │
│                     │                              │
│  ┌──────────────────┴──────────────────────────┐ │
│  │              State Layer (Riverpod)           │ │
│  │  Providers for auth, invoices, companies,     │ │
│  │  clients, bank accounts                       │ │
│  └──────────────────┬──────────────────────────┘ │
│                     │                              │
│  ┌──────────────────┴──────────────────────────┐ │
│  │              Data Layer                       │ │
│  │  ApiClient (dio) → REST API (/api/v1/)         │ │
│  │  SecureStorage → JWT token persistence        │ │
│  │  Models (Dart classes matching API responses)  │ │
│  └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
                      │
                      ▼
        ┌─────────────────────────┐
        │   Invoice Generator API  │
        │   invoice.digitlock.     │
        │   systems/api/v1/...     │
        └─────────────────────────┘
```

### 2.1.2 State Management: Riverpod

**Rationale:** Riverpod is chosen over Provider and BLoC for the following reasons:

- **Compile-safe**: providers are global and dependency injection is resolved at compile time
- **No BuildContext dependency**: providers can be accessed from anywhere, simplifying API calls
- **Fine-grained rebuilds**: `ref.watch` scopes rebuilds to individual widgets
- **AsyncValue**: built-in loading/error/data states for API calls, eliminating boilerplate
- **Testability**: providers can be overridden in tests without widget trees

**Provider structure:**

| Provider | Type | Purpose |
|----------|------|---------|
| `authProvider` | `StateNotifierProvider` | JWT token, user info, login/logout |
| `invoiceListProvider` | `FutureProvider.family` | Paginated invoice list with filters |
| `invoiceDetailProvider` | `FutureProvider.family` | Single invoice with all relations |
| `companyListProvider` | `FutureProvider` | All companies (for dropdown selection) |
| `clientListProvider` | `FutureProvider.family` | Clients with optional status filter |
| `bankAccountListProvider` | `FutureProvider.family` | Bank accounts for a given company |

### 2.1.3 Project Structure

```
lib/
├── main.dart                          # App entry, ProviderScope, MaterialApp.router
├── app/
│   ├── router.dart                    # GoRouter configuration
│   └── theme.dart                     # Material Design 3 theme
├── models/
│   ├── invoice.dart                   # Invoice, InvoiceListItem, InvoiceItem
│   ├── company.dart                   # Company
│   ├── client.dart                    # Client
│   ├── bank_account.dart              # BankAccount
│   ├── auth.dart                      # LoginResponse, User
│   └── pagination.dart                # PaginationMeta, PaginatedResponse
├── data/
│   ├── repositories/                  # Abstract interfaces (Repository pattern)
│   │   ├── invoice_repository.dart
│   │   ├── company_repository.dart
│   │   ├── client_repository.dart
│   │   └── bank_account_repository.dart
│   ├── remote/                        # Online mode: REST API via Dio
│   │   ├── remote_invoice_repository.dart
│   │   ├── remote_company_repository.dart
│   │   ├── remote_client_repository.dart
│   │   └── remote_bank_account_repository.dart
│   ├── local/                         # Offline mode: SQLite
│   │   ├── local_invoice_repository.dart
│   │   ├── local_company_repository.dart
│   │   ├── local_client_repository.dart
│   │   └── local_bank_account_repository.dart
│   ├── api_client.dart                # Dio instance with JWT interceptor
│   ├── auth_repository.dart           # login(), logout(), token storage
│   ├── invoice_repository.dart        # Provider + re-exports abstract type
│   ├── company_repository.dart        # Provider + re-exports abstract type
│   ├── client_repository.dart         # Provider + re-exports abstract type
│   └── bank_account_repository.dart   # Provider + re-exports abstract type
├── services/
│   ├── ad_service.dart                # AdMob initialization, banner/interstitial management
│   ├── database_service.dart          # SQLite initialization and migrations
│   └── local_pdf_service.dart         # Client-side PDF generation (offline mode)
├── providers/
│   ├── auth_provider.dart
│   ├── app_mode_provider.dart         # Offline/online mode state
│   ├── invoice_provider.dart
│   ├── company_provider.dart
│   ├── client_provider.dart
│   ├── bank_account_provider.dart
│   └── purchase_provider.dart         # IAP state, ad-free purchase tracking
├── screens/
│   ├── welcome_screen.dart            # First launch: choose offline or online
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── invoice_list_screen.dart
│   ├── invoice_detail_screen.dart
│   ├── invoice_form_screen.dart
│   ├── client_list_screen.dart
│   ├── client_form_screen.dart
│   ├── company_detail_screen.dart
│   ├── server_settings_screen.dart    # Configure server URL for online mode
│   ├── settings_screen.dart           # App settings, mode switch
│   └── purchase_screen.dart           # "Remove Ads" IAP flow
└── widgets/
    ├── status_badge.dart
    ├── overdue_badge.dart
    ├── invoice_card.dart
    ├── line_item_row.dart
    ├── ad_banner.dart                 # Conditional banner ad (hidden when purchased)
    ├── loading_indicator.dart
    ├── error_view.dart
    └── snackbar_helper.dart           # Success/error snackbar utilities
```

---

## 2.2 Navigation Structure

### 2.2.1 Navigation Pattern: Bottom Tab Bar

**Rationale:** Bottom tab bar is chosen over navigation drawer because:

- The app has 4 primary destinations (a natural fit for bottom tabs)
- Bottom tabs provide one-tap access to all sections without hiding navigation
- Consistent with Material Design 3 guidelines for mobile
- Users don't need to open a drawer to switch contexts

### 2.2.2 Tab Bar Configuration

| Tab | Icon | Label | Screen | Notes |
|-----|------|-------|--------|-------|
| 1 | `Icons.dashboard` | Dashboard | `DashboardScreen` | Default tab on launch |
| 2 | `Icons.receipt_long` | Invoices | `InvoiceListScreen` | Full history with filters |
| 3 | `Icons.people` | Clients | `ClientListScreen` | Client management |
| 4 | `Icons.business` | Company | `CompanyDetailScreen` | Read-only company info |

### 2.2.3 Navigation Flow

```
Welcome Screen (first launch or mode not set)
    ├── "Use Offline" → Bottom Tab Bar Shell (offline mode)
    └── "Connect to Server" → Server Settings → Login Screen
                                                     │
                                                     ▼
Bottom Tab Bar Shell (online mode)
    ├── Tab 1: Dashboard
    │       └── Tap invoice → Invoice Detail
    │                            ├── Edit → Invoice Form
    │                            └── PDF → Open in system viewer
    │
    ├── Tab 2: Invoices
    │       ├── FAB → Invoice Form (create)
    │       └── Tap invoice → Invoice Detail
    │                            ├── Edit → Invoice Form
    │                            ├── Status change (bottom sheet)
    │                            └── PDF → Open in system viewer
    │
    ├── Tab 3: Clients
    │       ├── FAB → Client Form (create)
    │       └── Tap client → Client Form (edit)
    │
    └── Tab 4: Company
            └── Read-only view of company + bank accounts
```

### 2.2.4 Route Table

| Route | Screen | Auth Required | Notes |
|-------|--------|---------------|-------|
| `/welcome` | WelcomeScreen | No | First launch, mode selection |
| `/login` | LoginScreen | No (online only) | Redirect to `/` if authenticated |
| `/server-settings` | ServerSettingsScreen | No | Configure server URL |
| `/settings` | SettingsScreen | No | App settings, mode switch |
| `/` | DashboardScreen | Yes (online) / No (offline) | Tab 1 |
| `/invoices` | InvoiceListScreen | Yes / No | Tab 2 |
| `/invoices/new` | InvoiceFormScreen | Yes / No | Create mode |
| `/invoices/:id` | InvoiceDetailScreen | Yes / No | Read-only with actions |
| `/invoices/:id/edit` | InvoiceFormScreen | Yes / No | Edit mode |
| `/clients` | ClientListScreen | Yes / No | Tab 3 |
| `/clients/new` | ClientFormScreen | Yes / No | Create mode |
| `/clients/:id/edit` | ClientFormScreen | Yes / No | Edit mode |
| `/company` | CompanyDetailScreen | Yes / No | Tab 4, read-only (online) / editable (offline) |

---

## 2.3 Screen Specifications

### 2.3.0 Welcome Screen

**Purpose:** First-launch mode selection. Allows user to choose between offline and online mode.

**UI Elements:**

- App logo (receipt icon) + "Invoice Generator" title centered
- Subtitle: "Choose how you'd like to use the app"
- "Use Offline" button (full width, outlined) — starts offline mode immediately, navigates to Dashboard
- "Connect to Server" button (full width, filled primary) — navigates to Server Settings, then Login
- Below buttons: if online mode was previously configured, show current server name + connection status indicator (green dot = reachable, red dot = unreachable)
- App version at the bottom

**Behavior:**

1. Shown on first launch (when `app_mode` key not in SharedPreferences)
2. Also accessible via Settings → "Switch Mode"
3. "Use Offline" → save `app_mode=offline` → navigate to `/` (Dashboard, no auth required)
4. "Connect to Server" → navigate to `/server-settings` → after server saved, navigate to `/login`
5. If a mode is already saved, app skips Welcome and goes directly to the appropriate flow

**No authentication** in offline mode.

### 2.3.1 Login Screen (S4-02)

**Purpose:** Authenticate user with Expense Tracker credentials.

**UI Elements:**

- App logo/title centered at top
- Email text field (keyboard type: email)
- Password text field (obscured)
- "Sign In" button (full width, primary color)
- Error message display below button
- "Invoice Generator" branding at bottom

**Behavior:**

1. User enters email and password
2. On submit: call `POST /api/v1/auth/login` (via Expense Tracker shared auth)
3. On success: store JWT in `flutter_secure_storage`, navigate to Dashboard
4. On error: display error message, clear password field
5. On app launch: check stored JWT validity, skip login if valid

**No registration flow** — users register via Expense Tracker (AU-03).

### 2.3.2 Dashboard Screen (S4-03)

**Purpose:** Overview of recent invoices with quick actions.

**UI Elements:**

- App bar with title "Dashboard" and user avatar/logout menu
- "New Invoice" prominent button at top
- "Recent Invoices" section: list of last 10 invoices as cards
- Each invoice card shows: invoice number, client name, date, total + currency, status badge, overdue badge

**API Calls:**

- `GET /api/v1/invoices?page=1&page_size=10&sort_by=created_at&sort_order=desc`

**Actions:**

- Tap invoice card → navigate to Invoice Detail
- Tap "New Invoice" → navigate to Invoice Form (create)

### 2.3.3 Invoice List Screen (S4-05)

**Purpose:** Full invoice history with filtering and search.

**UI Elements:**

- App bar with title "Invoices" and search icon
- Filter chips row: All, Draft, Sent, Partially Paid, Paid, Cancelled
- Scrollable list of invoice cards (same card widget as Dashboard)
- Pull-to-refresh
- Infinite scroll pagination (load more on scroll to bottom)
- FAB: "+" to create new invoice
- Empty state: "No invoices found" with create button

**API Calls:**

- `GET /api/v1/invoices?page={n}&page_size=20&status={filter}&search={query}`

**Actions:**

- Tap filter chip → reload list with status filter
- Tap search icon → show search bar, search on submit
- Tap invoice card → navigate to Invoice Detail
- Tap FAB → navigate to Invoice Form (create)
- Pull down → refresh current page

### 2.3.4 Invoice Detail Screen (S4-06, S3-08, S3-09)

**Purpose:** View complete invoice details with status management.

**UI Elements:**

- App bar with invoice number as title, overflow menu (Edit, Delete)
- Status badge + overdue badge below title
- "Change Status" button (visible when transitions are available)
- "Download PDF" button
- Scrollable content:
  - Dates section: issue date, due date, contract/external references
  - "From" card: company details (name, contact, address, VAT, reg)
  - "Bill To" card: client details
  - Line items table: description, qty, unit price, total
  - Totals: subtotal, VAT (rate + amount), total
  - Payment details: bank name, address, IBAN, SWIFT
  - Notes (if present)

**API Calls:**

- `GET /api/v1/invoices/{id}` (returns denormalized company, client, bank_account, items)
- `PATCH /api/v1/invoices/{id}/status` (status change)
- `PATCH /api/v1/invoices/{id}/overdue` (overdue toggle)
- `GET /api/v1/invoices/{id}/pdf` (PDF download)

**Status Management (S4-06):**

- "Change Status" button opens a bottom sheet with valid next statuses
- Allowed transitions follow the same rules as web:
  - draft → sent, cancelled
  - sent → partially_paid, paid, cancelled
  - partially_paid → paid, cancelled
  - paid, cancelled → (no transitions, button hidden)
- Overdue toggle: switch widget, disabled for draft invoices
- Confirmation dialog before status change

**PDF Download (S3-09):**

- Fetch PDF blob from `GET /api/v1/invoices/{id}/pdf`
- Save to temporary directory
- Open with system PDF viewer via `open_file` or `share_plus`

### 2.3.5 Invoice Form Screen (S4-04, MO-01)

**Purpose:** Create or edit an invoice.

**UI Elements (scrollable form):**

- **Entity selection section:**
  - Company dropdown (loaded from `GET /api/v1/companies`)
  - Client dropdown (loaded from `GET /api/v1/clients?status=active`)
  - Bank account dropdown (loaded from `GET /api/v1/companies/{id}/bank-accounts` after company selection)
- **Invoice details section:**
  - Invoice number (read-only in create: "Auto-generated"; editable in edit)
  - Issue date picker
  - Due date picker
  - Currency selector (EUR / RSD)
  - VAT rate input
  - Contract reference (optional)
  - External reference (optional)
- **Line items section:**
  - List of item rows (description, quantity, unit price, calculated total)
  - "Add Item" button (max 10)
  - Swipe-to-delete on each item row
- **Totals section (read-only, auto-calculated):**
  - Subtotal, VAT amount, Total
- **Notes** text area
- **Save button** (app bar action or sticky bottom button)

**API Calls:**

- Create: `POST /api/v1/invoices`
- Edit: `GET /api/v1/invoices/{id}` (load), then `PUT /api/v1/invoices/{id}` (save)
- Supporting: `GET /api/v1/companies`, `GET /api/v1/clients?status=active`, `GET /api/v1/companies/{id}/bank-accounts`

**Validation:**

- Company, client, bank account required
- At least 1 line item with description
- Due date >= issue date
- All amounts must be valid numbers

### 2.3.6 Client List Screen (S4-07, MO-04)

**Purpose:** View and manage clients.

**UI Elements:**

- App bar with title "Clients"
- Filter chips: All, Active, Inactive
- Scrollable list of client cards showing: name, status badge, address, contract reference
- FAB: "+" to create new client
- Empty state message

**API Calls:**

- `GET /api/v1/clients` or `GET /api/v1/clients?status={filter}`

**Actions:**

- Tap client card → navigate to Client Form (edit)
- Tap FAB → navigate to Client Form (create)

### 2.3.7 Client Form Screen (MO-04)

**Purpose:** Create or edit a client.

**UI Elements (scrollable form):**

- Name (required)
- Contact person
- Email
- Address (required)
- VAT number
- Registration number
- Contract reference
- Contract notes (multiline)
- Status toggle: Active / Inactive

**API Calls:**

- Create: `POST /api/v1/clients`
- Edit: `GET /api/v1/clients/{id}` (load), then `PUT /api/v1/clients/{id}` (save)

### 2.3.8 Company Detail Screen (S4-08, MO-05)

**Purpose:** Read-only view of company and bank account information.

**UI Elements:**

- App bar with title "Company"
- Company selector (if user has multiple companies) or single company display
- Company info card: name, contact person, address, phone, VAT, registration number
- "Bank Accounts" section: list of bank account cards showing bank name, IBAN, SWIFT, currency, default badge
- No edit/delete actions (read-only per MO-05)

**API Calls (online mode):**

- `GET /api/v1/companies`
- `GET /api/v1/companies/{id}/bank-accounts`

**Offline mode:** Full CRUD for companies and bank accounts via local SQLite.

### 2.3.9 Server Settings Screen

**Purpose:** Configure server connections for online mode.

**UI Elements:**

- App bar with title "Server Settings"
- List of saved servers, each showing:
  - Server name (e.g., "digitlock.systems")
  - API URL
  - Auth URL
  - Connection status indicator (green/red dot)
  - Radio button for active server selection
- "Add Server" button → expands to form:
  - Name text field (required)
  - API URL text field (required, e.g., `https://invoice.digitlock.systems`)
  - Auth URL text field (required, e.g., `https://expense.digitlock.systems`)
  - "Test Connection" button — performs `GET /health` on API URL
  - "Save" button
- Swipe-to-delete on saved servers
- Preset server: "digitlock.systems" pre-populated with production URLs

**Storage:**

- Server list persisted in `SharedPreferences` as JSON array
- Active server ID stored separately
- Selected server's API URL and Auth URL are used by `dioProvider` and `authDioProvider` base URLs

**Behavior:**

1. On first visit from Welcome Screen, the preset server is shown
2. User can add custom servers (e.g., local dev `http://localhost:8081`)
3. "Test Connection" hits `GET {apiUrl}/health` and shows success/failure
4. Selecting a server updates the active Dio instances' base URLs
5. Changes take effect immediately (providers are invalidated)

### 2.3.10 Settings Screen

**Purpose:** App-level settings and mode management.

**UI Elements:**

- App bar with title "Settings"
- **Mode section:**
  - Current mode display: "Offline Mode" or "Online Mode" with icon
  - "Switch to Online/Offline" button → confirmation dialog → navigates to Welcome Screen
- **Server section (visible only in online mode):**
  - Current server name and URL
  - "Server Settings" button → navigates to Server Settings screen
- **About section:**
  - App version
  - "View SRS" link (opens documentation)

**Access:** Settings icon in Dashboard app bar (gear icon), or via navigation.

---

## 2.4 API Integration Layer

### 2.4.1 API Client Configuration

**Online mode only.** The API is accessed using the `/api/v1/` path prefix. Two separate base URLs are used:

- **API URL** — Invoice Generator backend (invoices, companies, clients, bank accounts)
- **Auth URL** — Expense Tracker backend (login endpoint)

API URLs are configurable via Server Settings (section 2.3.9), stored in `SharedPreferences`. Default values from `--dart-define=API_URL` and `--dart-define=AUTH_URL` are used as fallback when no server is configured.

```dart
// Dio instance with base URL and JWT interceptor
// Base URL includes the /api/v1 prefix — all endpoints are relative
final dio = Dio(BaseOptions(
  baseUrl: '$apiBaseUrl/api/v1',  // e.g. https://invoice.digitlock.systems/api/v1
  connectTimeout: Duration(seconds: 10),
  receiveTimeout: Duration(seconds: 30),
  headers: {'Content-Type': 'application/json'},
));

// JWT interceptor adds Authorization header to every request
// On 401 response: clear stored token, navigate to login
```

**Usage:** Endpoints are called relative to the base URL:

```dart
// GET https://invoice.digitlock.systems/api/v1/invoices?page=1
final response = await dio.get('/invoices', queryParameters: {'page': 1});

// POST https://invoice.digitlock.systems/api/v1/clients
final response = await dio.post('/clients', data: clientData);
```

### 2.4.2 Endpoints Consumed

| Feature | Method | Endpoint | Mobile Usage |
|---------|--------|----------|-------------|
| Login | POST | `/api/v1/auth/login` | Login screen |
| List companies | GET | `/api/v1/companies` | Invoice form dropdown, company tab |
| Get company | GET | `/api/v1/companies/{id}` | Company detail |
| List bank accounts | GET | `/api/v1/companies/{id}/bank-accounts` | Invoice form dropdown, company tab |
| List clients | GET | `/api/v1/clients?status={s}` | Client list, invoice form dropdown |
| Get client | GET | `/api/v1/clients/{id}` | Client form (edit load) |
| Create client | POST | `/api/v1/clients` | Client form |
| Update client | PUT | `/api/v1/clients/{id}` | Client form |
| List invoices | GET | `/api/v1/invoices?page={n}&page_size={n}&status={s}` | Dashboard, invoice list |
| Get invoice | GET | `/api/v1/invoices/{id}` | Invoice detail, invoice form (edit load) |
| Create invoice | POST | `/api/v1/invoices` | Invoice form |
| Update invoice | PUT | `/api/v1/invoices/{id}` | Invoice form |
| Delete invoice | DELETE | `/api/v1/invoices/{id}` | Invoice detail |
| Change status | PATCH | `/api/v1/invoices/{id}/status` | Invoice detail |
| Toggle overdue | PATCH | `/api/v1/invoices/{id}/overdue` | Invoice detail |
| Download PDF | GET | `/api/v1/invoices/{id}/pdf` | Invoice detail |

### 2.4.3 Endpoints NOT Consumed

| Endpoint | Reason |
|----------|--------|
| `POST /api/v1/companies` | Company management is read-only on mobile (MO-05) |
| `PUT /api/v1/companies/{id}` | Read-only |
| `DELETE /api/v1/companies/{id}` | Read-only |
| `POST /api/v1/companies/{id}/bank-accounts` | Read-only |
| `PUT /api/v1/bank-accounts/{id}` | Read-only |
| `DELETE /api/v1/bank-accounts/{id}` | Read-only |
| `DELETE /api/v1/clients/{id}` | Client deletion not in mobile requirements (MO-04) |

---

## 2.5 Offline Mode

### 2.5.1 Local Database Schema

Offline mode uses SQLite (via `sqflite`) with tables mirroring the server database:

| Table | Columns | Notes |
|-------|---------|-------|
| `companies` | id (autoincrement), name, contact_person, address, phone, vat_number, reg_number, created_at, updated_at | Full CRUD in offline |
| `clients` | id, name, contact_person, email, address, vat_number, reg_number, contract_reference, contract_notes, status, created_at, updated_at | Full CRUD |
| `bank_accounts` | id, company_id (FK), bank_name, bank_address, account_holder, iban, swift, currency, is_default, created_at, updated_at | Full CRUD |
| `invoices` | id, company_id (FK), client_id (FK), bank_account_id (FK), invoice_number, issue_date, due_date, currency, status, is_overdue, vat_rate, subtotal, vat_amount, total, contract_reference, external_reference, notes, created_at, updated_at | Full CRUD + status management |
| `invoice_items` | id, invoice_id (FK), description, quantity, unit_price, total, created_at, updated_at | Managed as part of invoice |

### 2.5.2 Local Repository Implementations

Each abstract repository interface (section 2.1.3) has a local SQLite implementation:

- `LocalInvoiceRepository` — CRUD, status transitions, invoice number generation (local counter)
- `LocalCompanyRepository` — Full CRUD (unlike online mode which is read-only)
- `LocalClientRepository` — Full CRUD with status filter
- `LocalBankAccountRepository` — CRUD by company

Providers switch between Remote and Local implementations based on `appModeProvider`:

```dart
final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final mode = ref.watch(appModeProvider);
  if (mode == AppMode.offline) {
    return LocalInvoiceRepository(db: ref.watch(databaseServiceProvider));
  }
  return RemoteInvoiceRepository(dio: ref.watch(dioProvider));
});
```

### 2.5.3 Client-Side PDF Generation

In offline mode, PDFs are generated on-device using the Dart `pdf` package:

- Layout matches server-generated PDF format
- Includes: company header, client details, line items table, totals, bank account details, notes
- Saved to temporary directory, opened with system PDF viewer via `open_file`
- `LocalPdfService` handles layout and generation

### 2.5.4 Data Isolation

- Offline and online data are **completely separate** — no synchronization
- Offline data persists in SQLite on the device
- Online data lives on the configured server
- Switching modes does not affect either data store
- Future enhancement: optional export/import between modes

### 2.5.5 Online Mode — Network Errors

When in online mode and the network is unavailable:

- API calls fail with "No internet connection" error
- User sees error message with retry button
- No data is cached locally (except JWT token and user preferences)
- App does not fall back to offline mode automatically

---

# 3. Non-Functional Requirements

## 3.1 UI/UX Guidelines

### 3.1.1 Design System

**Material Design 3** with custom theme to match the web app:

| Token | Web (Tailwind) | Mobile (Material 3) |
|-------|---------------|---------------------|
| Primary | `blue-600` (#2563EB) | `ColorScheme.primary` |
| Error | `red-600` (#DC2626) | `ColorScheme.error` |
| Surface | `white` (#FFFFFF) | `ColorScheme.surface` |
| Border | `gray-200` (#E5E7EB) | `ColorScheme.outlineVariant` |
| Text primary | `gray-900` (#111827) | `ColorScheme.onSurface` |
| Text secondary | `gray-500` (#6B7280) | `ColorScheme.onSurfaceVariant` |

### 3.1.2 Status Badge Colors

Consistent with web app:

| Status | Background | Text |
|--------|-----------|------|
| Draft | `gray-100` | `gray-700` |
| Sent | `blue-100` | `blue-700` |
| Partially Paid | `orange-100` | `orange-700` |
| Paid | `green-100` | `green-700` |
| Cancelled | `red-100` | `red-700` |
| Overdue | `red-100` | `red-700` |

### 3.1.3 Typography

- Use Material Design 3 default type scale (Roboto)
- Consistent with web app's Tailwind text sizes:
  - Page titles: `headlineMedium` (≈ text-2xl)
  - Section headers: `titleMedium` (≈ text-lg)
  - Body text: `bodyMedium` (≈ text-sm)
  - Labels: `labelSmall` (≈ text-xs)

### 3.1.4 Interaction Patterns

- **Pull-to-refresh** on all list screens
- **Swipe-to-delete** on line items in invoice form
- **Bottom sheets** for status change selection (not dialogs — bottom sheets are more mobile-native)
- **Confirmation dialogs** for destructive actions (delete, status change)
- **Snackbar notifications** for success feedback ("Invoice created", "Status updated")
- **Haptic feedback** on status change and delete confirmations

## 3.2 Performance

| Metric | Target |
|--------|--------|
| Cold start to login screen | < 2s |
| Login to dashboard (including API call) | < 3s |
| Invoice list load (20 items) | < 2s |
| Invoice form save | < 3s |
| PDF download and open | < 5s |

## 3.3 Security

- JWT token stored in `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences on Android)
- No sensitive data in `shared_preferences` or plain text storage
- Token cleared on logout and on 401 response
- Certificate pinning: not required for MVP (Cloudflare Tunnel handles HTTPS)
- No biometric authentication in MVP (future roadmap)

---

# 4. Platform-Specific Requirements

## 4.1 iOS (S4-09)

| Requirement | Detail |
|-------------|--------|
| Minimum version | iOS 15.0 |
| Distribution | TestFlight (testing) → App Store (public release) |
| Bundle ID | `systems.digitlock.invoicegenerator` |
| Signing | Apple Developer account required ($99/year) |
| Permissions | `NSUserTrackingUsageDescription` (App Tracking Transparency for AdMob) |
| App Transport Security | HTTPS only (satisfied by Cloudflare Tunnel) |
| StoreKit | Required for in-app purchase (remove ads) |

**Deployment phases:**

1. **Testing**: Build IPA (`flutter build ipa`), upload to App Store Connect, distribute via TestFlight
2. **Public release**: Submit to App Store review with AdMob and IAP configured, privacy disclosures, and App Tracking Transparency prompt

## 4.2 Android (S4-10)

| Requirement | Detail |
|-------------|--------|
| Minimum SDK | API 26 (Android 8.0) |
| Target SDK | Latest stable (API 34+) |
| Distribution | APK sideload (testing) → Google Play (public release) |
| Package name | `systems.digitlock.invoicegenerator` |
| Signing | Debug keystore for development, release keystore for distribution |
| Permissions | `INTERNET` (auto-granted), `com.google.android.gms.permission.AD_ID` (AdMob) |
| Google Play Billing | Required for in-app purchase (remove ads) |

**Deployment phases:**

1. **Testing**: Build APK (`flutter build apk --release`), sideload to device
2. **Public release**: Build AAB (`flutter build appbundle --release`), upload to Google Play Console with AdMob and billing configured, content rating questionnaire, and data safety form

---

# 5. Build and Deployment

## 5.1 Development Setup

```bash
# Prerequisites
flutter doctor                    # Verify Flutter installation
flutter --version                 # Requires Flutter 3.x

# Project setup
flutter create --org systems.digitlock invoice_generator_mobile
cd invoice_generator_mobile

# Dependencies (pubspec.yaml)
flutter pub add flutter_riverpod
flutter pub add dio
flutter pub add flutter_secure_storage
flutter pub add shared_preferences
flutter pub add go_router
flutter pub add open_file
flutter pub add intl                  # Date formatting
flutter pub add google_mobile_ads     # AdMob banners + interstitials
flutter pub add in_app_purchase       # Remove ads IAP

# Run
flutter run                           # Debug on connected device
flutter run --release                 # Release mode testing
```

## 5.2 Environment Configuration

The API is accessed via a single domain with the `/api/v1/` path prefix. The base URL (without path) is configured per environment:

| Environment | Base URL | Full API path |
|-------------|----------|---------------|
| Development | `http://localhost:8081` | `http://localhost:8081/api/v1/...` |
| Production | `https://invoice.digitlock.systems` | `https://invoice.digitlock.systems/api/v1/...` |

Use `--dart-define=API_URL=...` at build time or a `.env` file with `flutter_dotenv`.

```bash
# Development build
flutter run --dart-define=API_URL=http://localhost:8081

# Production build
flutter build apk --release --dart-define=API_URL=https://invoice.digitlock.systems
```

## 5.3 Build Commands

```bash
# iOS (TestFlight → App Store)
flutter build ipa --dart-define=API_URL=https://invoice.digitlock.systems

# Android (APK for testing)
flutter build apk --release --dart-define=API_URL=https://invoice.digitlock.systems

# Android (AAB for Google Play)
flutter build appbundle --release --dart-define=API_URL=https://invoice.digitlock.systems

# Both platforms
flutter test                                           # Run unit tests
flutter analyze                                        # Static analysis
```

---

# 6. Acceptance Criteria Summary

| ID | Requirement | Acceptance Criteria |
|----|-------------|-------------------|
| S4-01 | Mobile project setup | Flutter project builds and runs on both iOS and Android |
| S4-02 | Mobile authentication | User can login with Expense Tracker credentials, JWT persisted across app restarts |
| S4-03 | Mobile dashboard | Shows last 10 invoices with status badges, tap navigates to detail |
| S4-04 | Mobile invoice creation | User can select company/client/bank, add items, save invoice via API |
| S4-05 | Mobile invoice history | Paginated list with status filter, pull-to-refresh, infinite scroll |
| S4-06 | Mobile status management | User can change status (valid transitions only) and toggle overdue |
| S4-07 | Mobile client management | User can view clients, create new, change status (active/inactive) |
| S4-08 | Read-only company view | User can view company and bank account details but cannot edit |
| S4-09 | iOS build and TestFlight | IPA builds and installs via TestFlight |
| S4-10 | Android build and testing | APK builds and installs on Android device |
| MO-01 | Create invoices on mobile | Full invoice creation flow with entity selection and line items |
| MO-02 | View invoice history | Filterable, scrollable invoice list |
| MO-03 | Change invoice status | Bottom sheet with valid transitions, confirmation dialog |
| MO-04 | Manage clients | Create, edit, change status; no delete |
| MO-05 | Company read-only | Company/bank account info displayed, no edit/delete buttons (online mode) |
| OFF-01 | Offline mode | User can create/manage invoices without server connection |
| OFF-02 | Local PDF generation | PDF generated on device matches server format |
| OFF-03 | Mode selection | Welcome screen allows choosing offline/online, persisted across restarts |
| OFF-04 | Server settings | User can add, test, and switch between multiple server configurations |
| OFF-05 | Settings screen | User can view current mode, switch modes, access server settings |
