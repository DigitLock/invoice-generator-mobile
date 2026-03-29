# QA Test Plan — Invoice Generator Mobile App

**Version:** 1.0
**Date:** 2026-03-29
**Related:** [SRS](invoice-generator-mobile-srs.md) Section 6 — Acceptance Criteria

---

## 1. Test Environment

| Parameter | Value |
|-----------|-------|
| iOS | Simulator — iPhone 16e (iOS 18.x) |
| Android | Physical device (API 26+) |
| Backend — Invoice Generator | `http://localhost:8081` (`--dart-define=API_URL`) |
| Backend — Expense Tracker Auth | `http://localhost:8080` (`--dart-define=AUTH_URL`) |
| Test credentials | `demo@example.com` / `Demo123!` |
| Flutter | 3.x, debug mode |

**Launch command:**
```bash
flutter run --dart-define=API_URL=http://localhost:8081 --dart-define=AUTH_URL=http://localhost:8080
```

---

## 2. Test Cases

### 2.1 Welcome Screen

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-001 | First launch shows Welcome | Fresh install (clear app data) | Launch app | Splash briefly → Welcome screen with logo, "Create Invoice Offline", "Connect to Server" | |
| QA-002 | Choose Offline mode | On Welcome screen | Tap "Create Invoice Offline" | Dashboard shown, no login required, bottom tabs visible | |
| QA-003 | Choose Online mode | On Welcome screen | Tap "Connect to Server" | Splash → Login screen shown | |
| QA-004 | Persisted mode — Offline | QA-002 completed | Kill app, relaunch | Dashboard shown directly (no Welcome) | |
| QA-005 | Persisted mode — Online | QA-003 completed + logged in | Kill app, relaunch | Splash → Dashboard (if token valid) or Login | |

### 2.2 Login Screen (Online Mode)

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-010 | Successful login | Online mode, on Login screen | Enter demo@example.com / Demo123!, tap "Sign In" | Loading spinner → Dashboard with invoices | |
| QA-011 | Invalid password | On Login screen | Enter demo@example.com / wrong, tap "Sign In" | Error message: "Invalid email or password" | |
| QA-012 | Empty fields | On Login screen | Tap "Sign In" without entering anything | Validation errors on email and password fields | |
| QA-013 | Choose different mode | On Login screen | Tap "← Choose different mode" | Welcome screen shown | |
| QA-014 | Server info visible | On Login screen | Observe below Sign In button | Server name or "Using default server" shown with Change/Configure link | |
| QA-015 | Change server from Login | On Login screen | Tap "Change" next to server info | Server Settings screen opens | |
| QA-016 | Token persistence | Logged in, kill app | Relaunch app | Dashboard shown without re-login | |
| QA-017 | Logout | On Dashboard (online) | Tap logout icon → "Logout" | Confirmation dialog → Login screen, token cleared | |

### 2.3 Dashboard

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-020 | Empty dashboard | No invoices exist | Navigate to Dashboard | "New Invoice" button + "No invoices yet" message | |
| QA-021 | Dashboard with invoices | Invoices exist | Navigate to Dashboard | Last 10 invoices as cards with number, client, date, total, status badge | |
| QA-022 | New Invoice button | On Dashboard | Tap "New Invoice" | Invoice Form opens in create mode | |
| QA-023 | Tap invoice card | On Dashboard with invoices | Tap any invoice card | Invoice Detail screen opens | |
| QA-024 | Settings icon | On Dashboard | Tap gear icon | Settings screen opens | |
| QA-025 | Pull to refresh | On Dashboard | Pull down | Invoices reload, spinner shown | |
| QA-026 | Logout button (online) | Dashboard, online mode | Observe app bar | Logout icon visible | |
| QA-027 | No logout button (offline) | Dashboard, offline mode | Observe app bar | No logout icon, only settings | |

### 2.4 Invoice List

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-030 | Filter — All | On Invoice List | Tap "All" chip | All invoices shown | |
| QA-031 | Filter — Draft | Invoices with draft status exist | Tap "Draft" chip | Only draft invoices shown | |
| QA-032 | Filter — Paid | Invoices with paid status exist | Tap "Paid" chip | Only paid invoices shown | |
| QA-033 | Search | On Invoice List | Tap search icon, type invoice number, submit | Matching invoices shown | |
| QA-034 | Clear search | Searching | Tap back arrow in search bar | Full list restored | |
| QA-035 | FAB → New Invoice | On Invoice List | Tap "+" FAB | Invoice Form opens, after save → list refreshes with new invoice | |
| QA-036 | Tap invoice → Detail | On Invoice List | Tap invoice card | Invoice Detail opens with back button | |
| QA-037 | Pagination | >20 invoices exist | Scroll to bottom of list | Loading indicator → next page loads | |
| QA-038 | Pull to refresh | On Invoice List | Pull down | List reloads from page 1 | |
| QA-039 | Empty state | No invoices, or filter has no results | Apply filter | "No invoices found" + "Create Invoice" button | |

### 2.5 Invoice Detail

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-040 | All sections displayed | Invoice with company, client, bank, items, notes | Open invoice detail | Dates, From card, Bill To card, Items table, Totals, Payment Details, Notes all visible | |
| QA-041 | Status badge | Invoice with any status | Open detail | Correct status badge color and label | |
| QA-042 | Overdue badge | Invoice with isOverdue=true | Open detail | Red "Overdue" badge next to status | |
| QA-043 | Due date null | Invoice without due date | Open detail | Due Date row not shown | |
| QA-044 | Change Status — draft→sent | Invoice in draft status | Tap "Change Status" → select "Sent" → Confirm | Status updates to Sent, snackbar "Status updated", haptic feedback | |
| QA-045 | Change Status — invalid | Invoice in paid status | Observe | "Change Status" button hidden | |
| QA-046 | Overdue toggle | Invoice in sent status | Toggle overdue switch | Switch updates, invoice refreshes | |
| QA-047 | Overdue disabled for draft | Invoice in draft status | Observe | Overdue switch not shown | |
| QA-048 | Download PDF (online) | Online mode, invoice exists | Tap "Download PDF" | "Downloading PDF..." snackbar → PDF opens in system viewer | |
| QA-049 | Download PDF (offline) | Offline mode, invoice exists | Tap "Download PDF" | PDF generated locally → opens in system viewer | |
| QA-050 | Edit invoice | On Invoice Detail | Menu → Edit | Invoice Form opens with pre-filled data, save returns to detail | |
| QA-051 | Delete invoice | On Invoice Detail | Menu → Delete → Confirm | Invoice deleted, navigate back to list, haptic feedback | |
| QA-052 | Duplicate invoice | On Invoice Detail | Menu → Duplicate | Invoice Form with copied data, new invoice number, save creates new invoice | |
| QA-053 | Back navigation | On Invoice Detail (pushed) | Tap back arrow | Returns to previous screen (list or dashboard) | |
| QA-054 | Back navigation (no stack) | Invoice Detail opened via deep link | Tap back arrow | Goes to Dashboard | |

### 2.6 Invoice Form

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-060 | Create mode — defaults | Open new invoice form | Observe | Invoice number auto-generated, issue date = today, due date empty, currency EUR, VAT 0 | |
| QA-061 | Company dropdown + "+" | On invoice form | Tap "+" next to Company | Company Form opens, after save → dropdown refreshes with new company | |
| QA-062 | Client dropdown + "+" | On invoice form | Tap "+" next to Client | Client Form opens, after save → dropdown refreshes with new client | |
| QA-063 | Bank Account dropdown + "+" | Company selected | Tap "+" next to Bank Account | Bank Account Form opens, after save → dropdown refreshes | |
| QA-064 | Bank Account depends on Company | No company selected | Observe | Bank Account dropdown not shown | |
| QA-065 | Date picker — Issue Date | On invoice form | Tap Issue Date field | Date picker opens, selection updates field | |
| QA-066 | Date picker — Due Date | On invoice form | Tap Due Date field | Date picker opens, selection updates field with clear button | |
| QA-067 | Clear Due Date | Due date selected | Tap "×" clear button | Due date resets to "Select date" | |
| QA-068 | Add line item | On invoice form | Tap "Add Item" | New item row appears (max 10) | |
| QA-069 | Swipe to delete item | Multiple items | Swipe item left | Item removed | |
| QA-070 | Totals auto-calculate | Add items with qty/price | Observe totals section | Subtotal, VAT, Total update in real time | |
| QA-071 | Validation — missing fields | No company/client/bank selected | Tap save | Error snackbar "Please select company, client, and bank account" | |
| QA-072 | Save create → navigate to detail | Fill all required fields | Tap save (checkmark) | Invoice created, snackbar, navigate to Invoice Detail | |
| QA-073 | Save edit → pop to detail | Edit existing invoice | Change a field, save | Invoice updated, snackbar, return to detail | |
| QA-074 | Invoice number editable | On invoice form | Edit auto-generated number | Number accepted, saved with custom value | |

### 2.7 Client List

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-080 | Filter — All | Clients exist | Tap "All" chip | All clients shown | |
| QA-081 | Filter — Active | Active clients exist | Tap "Active" chip | Only active clients shown | |
| QA-082 | Filter — Inactive | Inactive clients exist | Tap "Inactive" chip | Only inactive clients shown | |
| QA-083 | FAB → New Client | On Client List | Tap "+" FAB | Client Form opens in create mode | |
| QA-084 | Tap client → Edit | On Client List | Tap client card | Client Form opens with pre-filled data | |
| QA-085 | Empty state | No clients | Observe | "No clients found" + "Create Client" button | |
| QA-086 | Pull to refresh | On Client List | Pull down | Client list reloads | |

### 2.8 Client Form

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-090 | Create client | On Client Form (create) | Fill name + address, tap save | Client created, snackbar, pop to list, list refreshes | |
| QA-091 | Edit client | On Client Form (edit) | Change name, tap save | Client updated, snackbar, pop to list | |
| QA-092 | Validation — name required | On Client Form | Leave name empty, tap save | "Name is required" validation error | |
| QA-093 | Validation — address required | On Client Form | Leave address empty, tap save | "Address is required" validation error | |
| QA-094 | Status toggle | On Client Form | Toggle Active/Inactive switch | Subtitle updates "Active"/"Inactive" | |

### 2.9 Company Detail

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-100 | Online — read only | Online mode, company exists | Open Company tab | Company info + bank accounts shown, no edit/add buttons | |
| QA-101 | Online — empty state | Online mode, no companies | Open Company tab | "Create one via the web dashboard" message | |
| QA-102 | Offline — CRUD | Offline mode | Open Company tab | FAB "+", edit icon on company card, "Add" for bank accounts | |
| QA-103 | Offline — create company | Offline mode, Company tab | Tap FAB "+" | Company Form, save creates company, list refreshes | |
| QA-104 | Offline — edit company | Offline mode, company exists | Tap edit icon on company card | Company Form pre-filled, save updates company | |
| QA-105 | Offline — add bank account | Offline mode, company exists | Tap "Add" in Bank Accounts section | Bank Account Form, save adds account, list refreshes | |
| QA-106 | Company selector | Multiple companies | Open Company tab | Dropdown to select company, bank accounts update on selection | |
| QA-107 | Bank account default badge | Bank account with is_default=true | Observe | "Default" badge shown on card | |

### 2.10 Server Settings

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-110 | Preset suggestion | No servers configured | Open Server Settings | "Suggested" section with DigitLock Cloud + "Add" button | |
| QA-111 | Add preset | QA-110 | Tap "Add" on preset | Server added to list, selected as active | |
| QA-112 | Add custom server | On Server Settings | Tap "Add Custom Server", fill form, tap Save | Server added to list | |
| QA-113 | URL validation | Adding custom server | Enter URL without http:// | "Must start with http:// or https://" error | |
| QA-114 | Test connection — success | Server running | Fill API URL, tap "Test" | Green checkmark icon | |
| QA-115 | Test connection — failure | Wrong URL | Fill invalid API URL, tap "Test" | Red X icon | |
| QA-116 | Edit server | Server exists | Tap edit icon on server | Form pre-filled, save updates server | |
| QA-117 | Delete server (inactive) | Multiple servers, not active | Swipe server left → Confirm | Server removed from list | |
| QA-118 | Delete server (active) | Active server | Swipe server left | "Deselect server first" error | |
| QA-119 | Switch active server | Multiple servers, online mode | Tap radio on different server | Server selected, user logged out, redirected to login | |
| QA-120 | Continue to Login | From Welcome → Server Settings | Add server, tap "Continue to Login" | Mode set to online, login screen shown | |

### 2.11 Settings Screen

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-130 | Display offline mode | Offline mode active | Open Settings | "Offline Mode" with cloud_off icon, "Data stored locally on device" | |
| QA-131 | Display online mode | Online mode active | Open Settings | "Online Mode" with cloud_done icon, server section visible | |
| QA-132 | Switch to Online | Offline mode | Tap "Switch to Online" → Confirm | Welcome screen shown | |
| QA-133 | Switch to Offline | Online mode | Tap "Switch to Offline" → Confirm | Welcome screen shown | |
| QA-134 | Server Settings link | Online mode | Tap "Server Settings" | Server Settings screen opens | |
| QA-135 | Clear server config | Settings → Debug | Tap "Clear Server Config" → Confirm | Servers cleared, snackbar shown | |
| QA-136 | App version | On Settings | Observe About section | "Invoice Generator v1.0.0" | |

### 2.12 Cross-Cutting Concerns

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-140 | Offline — full invoice CRUD | Offline mode | Create company → client → bank account → invoice → view detail → edit → delete | All operations work with SQLite, no network calls | |
| QA-141 | Online — full invoice CRUD | Online mode, logged in | Create invoice → view detail → edit → change status → delete | All operations work via API | |
| QA-142 | PDF — offline | Offline mode, invoice exists | Tap "Download PDF" on detail | PDF generated locally, sections match: header, from/to, items, totals, payment, notes | |
| QA-143 | PDF — online | Online mode, invoice exists | Tap "Download PDF" on detail | PDF downloaded from server, opens in system viewer | |
| QA-144 | Haptic feedback | Various actions | Create invoice / change status / delete | Medium haptic on success | |
| QA-145 | Success snackbar | Various success actions | Create/update/delete entities | Green snackbar with white text | |
| QA-146 | Error snackbar | Various error cases | Trigger validation error or API failure | Red snackbar with white text | |
| QA-147 | Tab navigation | On any tab screen | Tap each tab (Dashboard, Invoices, Clients, Company) | Correct screen shown, state preserved | |
| QA-148 | Back navigation | Deep in navigation stack | Tap back repeatedly | Returns through stack to tab screen | |
| QA-149 | Data isolation | Use offline, then switch to online | Create data in offline → switch to online → check | Offline data not visible in online mode, and vice versa | |
| QA-150 | 401 token expiry | Online mode, token expired | Navigate to any screen | "Session expired" message, redirect to login | |
| QA-151 | No internet (online) | Online mode, disable network | Try to load data | "No internet connection" error with retry button | |
| QA-152 | Pull-to-refresh on all lists | Dashboard / Invoice List / Client List | Pull down on each | Data reloads | |

---

## 3. Regression Checklist

Quick smoke test after any code change:

- [ ] App launches → correct screen (Welcome / Dashboard / Login based on saved mode)
- [ ] Offline: Create company → Create client → Create bank account → Create invoice → View detail
- [ ] Offline: Download PDF from invoice detail
- [ ] Online: Login with demo@example.com / Demo123!
- [ ] Online: Dashboard shows invoices
- [ ] Online: Create invoice → navigate to detail
- [ ] Online: Change invoice status
- [ ] Online: Download PDF
- [ ] Tab navigation works (all 4 tabs)
- [ ] Settings → Switch mode → Welcome screen
- [ ] Back buttons work throughout the app

---

## 4. Traceability Matrix

| Acceptance Criteria | Test Cases |
|---------------------|------------|
| S4-01 — Project setup | QA-001 |
| S4-02 — Authentication | QA-010, QA-011, QA-016, QA-017 |
| S4-03 — Dashboard | QA-020 through QA-027 |
| S4-04 — Invoice creation | QA-060 through QA-074 |
| S4-05 — Invoice history | QA-030 through QA-039 |
| S4-06 — Status management | QA-044, QA-045, QA-046, QA-047 |
| S4-07 — Client management | QA-080 through QA-094 |
| S4-08 — Company view | QA-100 through QA-107 |
| MO-01 — Mobile invoice creation | QA-060, QA-072 |
| MO-02 — Invoice history | QA-030, QA-037 |
| MO-03 — Status change | QA-044 |
| MO-04 — Client management | QA-083, QA-090 |
| MO-05 — Company read-only | QA-100 |
| OFF-01 — Offline mode | QA-002, QA-140 |
| OFF-02 — Local PDF | QA-142 |
| OFF-03 — Mode selection | QA-001 through QA-005 |
| OFF-04 — Server settings | QA-110 through QA-120 |
| OFF-05 — Settings screen | QA-130 through QA-136 |
