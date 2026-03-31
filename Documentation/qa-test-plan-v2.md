# QA Test Plan — Invoice Generator (Web + Mobile)

**Version:** 2.0
**Date:** 2026-03-30
**Related:** [PRD v0.4](invoice-generator-prd.md), [SRS v0.2](invoice-generator-srs.md), [Mobile SRS v0.3](invoice-generator-mobile-srs.md)

---

## 1. Test Environment

### 1.1 Mobile App

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

### 1.2 Web App

| Parameter | Value |
|-----------|-------|
| Browser | Chrome (latest), Firefox (latest), Safari (latest) |
| Guest mode URL | `https://invoice.digitlock.systems` |
| Authorized mode URL | `https://invoice.digitlock.systems` (same app, Sign In) |
| Backend | `http://localhost:8081` (backend NOT yet on VPS — test locally) |
| Test credentials | `demo@example.com` / `Demo123!` |
| Dev URL | `http://localhost:5173` |

**Note:** For authorized mode testing, use local dev environment (`localhost:5173` → `localhost:8081`) since backend is not deployed to VPS yet.

---

## 2. Numbering Convention

- **QA-001 → QA-159**: Mobile App tests
- **QA-160 → QA-199**: Additional mobile tests (v2.0)
- **QA-200 → QA-299**: Web App — Guest Mode tests
- **QA-300 → QA-399**: Web App — Authorized Mode tests
- **QA-400 → QA-499**: Web App — Cross-cutting & Responsive tests

Gaps within ranges are reserved for future test cases.

---

## 3. Mobile App Test Cases

### 3.1 Welcome Screen

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-001 | First launch shows Welcome | Fresh install (clear app data) | Launch app | Splash briefly → Welcome screen with logo, "Create Invoice Offline", "Connect to Server" | Pass |
| QA-002 | Choose Offline mode | On Welcome screen | Tap "Create Invoice Offline" | Dashboard shown, no login required, bottom tabs visible | Pass |
| QA-003 | Choose Online mode | On Welcome screen | Tap "Connect to Server" | Splash → Login screen shown | Pass |
| QA-004 | Persisted mode — Offline | QA-002 completed | Kill app, relaunch | Dashboard shown directly (no Welcome) | Pass |
| QA-005 | Persisted mode — Online | QA-003 completed + logged in | Kill app, relaunch | Splash → Dashboard (if token valid) or Login | Pass |

### 3.2 Login Screen (Online Mode)

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

### 3.3 Dashboard

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

### 3.4 Invoice List

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-030 | Filter — All | On Invoice List | Tap "All" chip | All invoices shown | |
| QA-031 | Filter — Draft | Invoices with draft status exist | Tap "Draft" chip | Only draft invoices shown | |
| QA-032 | Filter — Sent | Invoices with sent status exist | Tap "Sent" chip | Only sent invoices shown | |
| QA-033 | Filter — Partially Paid | Invoices with partially_paid status exist | Tap "Partially Paid" chip | Only partially paid invoices shown | |
| QA-034 | Filter — Paid | Invoices with paid status exist | Tap "Paid" chip | Only paid invoices shown | |
| QA-035 | Filter — Cancelled | Invoices with cancelled status exist | Tap "Cancelled" chip | Only cancelled invoices shown | |
| QA-036 | Search | On Invoice List | Tap search icon, type invoice number, submit | Matching invoices shown | |
| QA-037 | Clear search | Searching | Tap back arrow in search bar | Full list restored | |
| QA-038 | FAB → New Invoice | On Invoice List | Tap "+" FAB | Invoice Form opens, after save → list refreshes with new invoice | |
| QA-039 | Tap invoice → Detail | On Invoice List | Tap invoice card | Invoice Detail opens with back button | |
| QA-040 | Pagination | >20 invoices exist | Scroll to bottom of list | Loading indicator → next page loads | |
| QA-041 | Pull to refresh | On Invoice List | Pull down | List reloads from page 1 | |
| QA-042 | Empty state | No invoices, or filter has no results | Apply filter | "No invoices found" + "Create Invoice" button | |

### 3.5 Invoice Detail

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-050 | All sections displayed | Invoice with company, client, bank, items, notes | Open invoice detail | Dates, From card, Bill To card, Items table, Totals, Payment Details, Notes all visible | |
| QA-051 | Status badge | Invoice with any status | Open detail | Correct status badge color and label | |
| QA-052 | Overdue badge | Invoice with isOverdue=true | Open detail | Red "Overdue" badge next to status | |
| QA-053 | Due date null | Invoice without due date | Open detail | Due Date row not shown | |
| QA-054 | Change Status — draft→sent | Invoice in draft status | Tap "Change Status" → select "Sent" → Confirm | Status updates to Sent, snackbar "Status updated", haptic feedback | |
| QA-055 | Change Status — draft→cancelled | Invoice in draft status | Tap "Change Status" → select "Cancelled" → Confirm | Status updates to Cancelled | |
| QA-056 | Change Status — sent→partially_paid | Invoice in sent status | Tap "Change Status" → select "Partially Paid" → Confirm | Status updates to Partially Paid | |
| QA-057 | Change Status — sent→paid | Invoice in sent status | Tap "Change Status" → select "Paid" → Confirm | Status updates to Paid | |
| QA-058 | Change Status — sent→cancelled | Invoice in sent status | Tap "Change Status" → select "Cancelled" → Confirm | Status updates to Cancelled | |
| QA-059 | Change Status — partially_paid→paid | Invoice in partially_paid status | Tap "Change Status" → select "Paid" → Confirm | Status updates to Paid | |
| QA-060 | Change Status — partially_paid→cancelled | Invoice in partially_paid status | Tap "Change Status" → select "Cancelled" → Confirm | Status updates to Cancelled | |
| QA-061 | Change Status — paid (no transitions) | Invoice in paid status | Observe | "Change Status" button hidden or disabled | |
| QA-062 | Change Status — cancelled (no transitions) | Invoice in cancelled status | Observe | "Change Status" button hidden or disabled | |
| QA-063 | Overdue toggle — sent | Invoice in sent status | Toggle overdue switch | Switch updates, invoice refreshes, overdue badge appears/disappears | |
| QA-064 | Overdue toggle — partially_paid | Invoice in partially_paid status | Toggle overdue switch | Switch updates, overdue badge appears/disappears | |
| QA-065 | Overdue toggle — paid | Invoice in paid status | Toggle overdue switch | Switch updates (tracks "paid late") | |
| QA-066 | Overdue toggle — cancelled | Invoice in cancelled status | Toggle overdue switch | Switch updates (tracks "cancelled after due") | |
| QA-067 | Overdue disabled for draft | Invoice in draft status | Observe | Overdue switch not shown | |
| QA-068 | Download PDF (online) | Online mode, invoice exists | Tap "Download PDF" | "Downloading PDF..." snackbar → PDF opens in system viewer | |
| QA-069 | Download PDF (offline) | Offline mode, invoice exists | Tap "Download PDF" | PDF generated locally → opens in system viewer | |
| QA-070 | Edit invoice | On Invoice Detail | Menu → Edit | Invoice Form opens with pre-filled data, save returns to detail | |
| QA-071 | Delete invoice | On Invoice Detail | Menu → Delete → Confirm | Invoice deleted, navigate back to list, haptic feedback | |
| QA-072 | Duplicate invoice | On Invoice Detail | Menu → Duplicate | Invoice Form with copied data, new invoice number, status reset to draft, all line items copied | |
| QA-073 | Back navigation | On Invoice Detail (pushed) | Tap back arrow | Returns to previous screen (list or dashboard) | |
| QA-074 | Back navigation (no stack) | Invoice Detail opened via deep link | Tap back arrow | Goes to Dashboard | |

### 3.6 Invoice Form

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-080 | Create mode — defaults | Open new invoice form | Observe | Invoice number auto-generated, issue date = today, due date empty, currency EUR, VAT 0 | |
| QA-081 | Company dropdown + "+" | On invoice form | Tap "+" next to Company | Company Form opens, after save → dropdown refreshes with new company | |
| QA-082 | Client dropdown + "+" | On invoice form | Tap "+" next to Client | Client Form opens, after save → dropdown refreshes with new client | |
| QA-083 | Bank Account dropdown + "+" | Company selected | Tap "+" next to Bank Account | Bank Account Form opens, after save → dropdown refreshes | |
| QA-084 | Bank Account depends on Company | No company selected | Observe | Bank Account dropdown not shown or disabled | |
| QA-085 | Date picker — Issue Date | On invoice form | Tap Issue Date field | Date picker opens, selection updates field | |
| QA-086 | Date picker — Due Date | On invoice form | Tap Due Date field | Date picker opens, selection updates field with clear button | |
| QA-087 | Clear Due Date | Due date selected | Tap "×" clear button | Due date resets to "Select date" | |
| QA-088 | Add line item | On invoice form | Tap "Add Item" | New item row appears | |
| QA-089 | Max 10 line items | 10 items already added | Tap "Add Item" | Button disabled or hidden, no 11th item added | |
| QA-090 | Swipe to delete item | Multiple items | Swipe item left | Item removed | |
| QA-091 | Totals auto-calculate | Add items with qty/price | Observe totals section | Subtotal, VAT, Total update in real time | |
| QA-092 | Validation — missing entities | No company/client/bank selected | Tap save | Error snackbar "Please select company, client, and bank account" | |
| QA-093 | Validation — no line items | All entities selected, no items | Tap save | Error: at least 1 line item required | |
| QA-094 | Validation — due date < issue date | Set due date before issue date | Tap save | Error: due date must be >= issue date | |
| QA-095 | Currency selector | On invoice form | Tap currency field | EUR and RSD options available | |
| QA-096 | Save create → navigate to detail | Fill all required fields | Tap save (checkmark) | Invoice created, snackbar, navigate to Invoice Detail | |
| QA-097 | Save edit → pop to detail | Edit existing invoice | Change a field, save | Invoice updated, snackbar, return to detail | |
| QA-098 | Invoice number editable | On invoice form | Edit auto-generated number | Number accepted, saved with custom value | |

### 3.7 Client List

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-100 | Filter — All | Clients exist | Tap "All" chip | All clients shown | |
| QA-101 | Filter — Active | Active clients exist | Tap "Active" chip | Only active clients shown | |
| QA-102 | Filter — Inactive | Inactive clients exist | Tap "Inactive" chip | Only inactive clients shown | |
| QA-103 | FAB → New Client | On Client List | Tap "+" FAB | Client Form opens in create mode | |
| QA-104 | Tap client → Edit | On Client List | Tap client card | Client Form opens with pre-filled data | |
| QA-105 | Empty state | No clients | Observe | "No clients found" + "Create Client" button | |
| QA-106 | Pull to refresh | On Client List | Pull down | Client list reloads | |

### 3.8 Client Form

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-110 | Create client | On Client Form (create) | Fill name + address, tap save | Client created, snackbar, pop to list, list refreshes | |
| QA-111 | Edit client | On Client Form (edit) | Change name, tap save | Client updated, snackbar, pop to list | |
| QA-112 | Validation — name required | On Client Form | Leave name empty, tap save | "Name is required" validation error | |
| QA-113 | Validation — address required | On Client Form | Leave address empty, tap save | "Address is required" validation error | |
| QA-114 | Status toggle | On Client Form | Toggle Active/Inactive switch | Subtitle updates "Active"/"Inactive" | |

### 3.9 Company Detail

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-120 | Online — read only | Online mode, company exists | Open Company tab | Company info + bank accounts shown, no edit/add buttons | |
| QA-121 | Online — empty state | Online mode, no companies | Open Company tab | "Create one via the web dashboard" message | |
| QA-122 | Offline — CRUD | Offline mode | Open Company tab | FAB "+", edit icon on company card, "Add" for bank accounts | |
| QA-123 | Offline — create company | Offline mode, Company tab | Tap FAB "+" | Company Form, save creates company, list refreshes | |
| QA-124 | Offline — edit company | Offline mode, company exists | Tap edit icon on company card | Company Form pre-filled, save updates company | |
| QA-125 | Offline — delete company | Offline mode, company exists, no invoices | Delete company | Company removed from list | |
| QA-126 | Offline — add bank account | Offline mode, company exists | Tap "Add" in Bank Accounts section | Bank Account Form, save adds account, list refreshes | |
| QA-127 | Offline — edit bank account | Offline mode, bank account exists | Tap edit on bank account | Bank Account Form pre-filled, save updates account | |
| QA-128 | Offline — delete bank account | Offline mode, bank account exists | Delete bank account | Account removed from list | |
| QA-129 | Company selector | Multiple companies | Open Company tab | Dropdown to select company, bank accounts update on selection | |
| QA-130 | Bank account default badge | Bank account with is_default=true | Observe | "Default" badge shown on card | |

### 3.10 Server Settings

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-135 | Preset suggestion | No servers configured | Open Server Settings | "Suggested" section with DigitLock Cloud + "Add" button | |
| QA-136 | Add preset | QA-135 | Tap "Add" on preset | Server added to list, selected as active | |
| QA-137 | Add custom server | On Server Settings | Tap "Add Custom Server", fill form, tap Save | Server added to list | |
| QA-138 | URL validation | Adding custom server | Enter URL without http:// | "Must start with http:// or https://" error | |
| QA-139 | Test connection — success | Server running | Fill API URL, tap "Test" | Green checkmark icon | |
| QA-140 | Test connection — failure | Wrong URL | Fill invalid API URL, tap "Test" | Red X icon | |
| QA-141 | Edit server | Server exists | Tap edit icon on server | Form pre-filled, save updates server | |
| QA-142 | Delete server (inactive) | Multiple servers, not active | Swipe server left → Confirm | Server removed from list | |
| QA-143 | Delete server (active) | Active server | Swipe server left | "Deselect server first" error | |
| QA-144 | Switch active server | Multiple servers, online mode | Tap radio on different server | Server selected, user logged out, redirected to login | |
| QA-145 | Continue to Login | From Welcome → Server Settings | Add server, tap "Continue to Login" | Mode set to online, login screen shown | |

### 3.11 Settings Screen

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-150 | Display offline mode | Offline mode active | Open Settings | "Offline Mode" with cloud_off icon, "Data stored locally on device" | |
| QA-151 | Display online mode | Online mode active | Open Settings | "Online Mode" with cloud_done icon, server section visible | |
| QA-152 | Switch to Online | Offline mode | Tap "Switch to Online" → Confirm | Welcome screen shown | |
| QA-153 | Switch to Offline | Online mode | Tap "Switch to Offline" → Confirm | Welcome screen shown | |
| QA-154 | Server Settings link | Online mode | Tap "Server Settings" | Server Settings screen opens | |
| QA-155 | Clear server config | Settings → Debug | Tap "Clear Server Config" → Confirm | Servers cleared, snackbar shown | |
| QA-156 | App version | On Settings | Observe About section | "Invoice Generator v1.0.0" | |

### 3.12 Cross-Cutting Concerns (Mobile)

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-160 | Offline — full invoice CRUD | Offline mode | Create company → client → bank account → invoice → view detail → edit → delete | All operations work with SQLite, no network calls | |
| QA-161 | Online — full invoice CRUD | Online mode, logged in | Create invoice → view detail → edit → change status → delete | All operations work via API | |
| QA-162 | PDF — offline content | Offline mode, invoice exists | Tap "Download PDF" on detail | PDF generated locally, sections match: header, from/to, items, totals, payment, notes | |
| QA-163 | PDF — online | Online mode, invoice exists | Tap "Download PDF" on detail | PDF downloaded from server, opens in system viewer | |
| QA-164 | Haptic feedback | Various actions | Create invoice / change status / delete | Medium haptic on success | |
| QA-165 | Success snackbar | Various success actions | Create/update/delete entities | Green snackbar with white text | |
| QA-166 | Error snackbar | Various error cases | Trigger validation error or API failure | Red snackbar with white text | |
| QA-167 | Tab navigation | On any tab screen | Tap each tab (Dashboard, Invoices, Clients, Company) | Correct screen shown, state preserved | |
| QA-168 | Back navigation | Deep in navigation stack | Tap back repeatedly | Returns through stack to tab screen | |
| QA-169 | Data isolation | Use offline, then switch to online | Create data in offline → switch to online → check | Offline data not visible in online mode, and vice versa | |
| QA-170 | 401 token expiry | Online mode, token expired | Navigate to any screen | "Session expired" message, redirect to login | |
| QA-171 | No internet (online) | Online mode, disable network | Try to load data | "No internet connection" error with retry button | |
| QA-172 | Pull-to-refresh on all lists | Dashboard / Invoice List / Client List | Pull down on each | Data reloads | |
| QA-173 | Splash screen display | App launch | Observe splash | App logo shown briefly, transitions to correct screen | |

### 3.13 Additional Mobile Tests (v2.0)

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-180 | Offline — company form validation | Offline mode, Company Form | Leave name empty, tap save | Validation error: name required | |
| QA-181 | Offline — bank account form validation | Offline mode, Bank Account Form | Leave IBAN empty, tap save | Validation error: IBAN required | |
| QA-182 | Invoice form — amount validation | On invoice form, add line item | Enter negative quantity or non-numeric price | Validation error or field rejected | |
| QA-183 | Invoice form — empty description | On invoice form, add line item | Leave description empty, tap save | Validation error: description required | |
| QA-184 | Server settings — empty name | Adding custom server | Leave server name empty, tap save | Validation error | |
| QA-185 | Server settings — missing Auth URL | Adding custom server | Fill API URL only, leave Auth URL empty | Validation error or default used | |

---

## 4. Web App Test Cases

### 4.1 Guest Mode — Landing Page

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-200 | Landing page loads | None | Navigate to invoice.digitlock.systems | Two-column layout: invoice preview (left) + action buttons (right) | |
| QA-201 | Invoice preview is clickable | On landing page | Click the preview image | Invoice form opens (guest mode) | |
| QA-202 | "Create Invoice" button | On landing page | Click "Create Invoice" | Invoice form opens in guest mode (no auth) | |
| QA-203 | "Sign In" button | On landing page | Click "Sign In" | Login screen shown | |
| QA-204 | EXAMPLE watermark | On landing page | Observe preview image | "EXAMPLE" watermark visible on preview PDF | |

### 4.2 Guest Mode — Invoice Form

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-210 | Form loads with empty fields | Click "Create Invoice" from landing | Observe form | All 7 sections visible: seller, buyer, items, payment, dates, totals, notes | |
| QA-211 | Fill seller information | On guest form | Enter company name, contact, address, phone, VAT, reg no | All fields accept input | |
| QA-212 | Fill buyer information | On guest form | Enter client name, contact, email, address, VAT, reg no | All fields accept input | |
| QA-213 | Add line items | On guest form | Add 3 items with description, qty, unit price | Items added, totals calculate in real time | |
| QA-214 | Max 10 line items | 10 items added | Try to add 11th item | "Add Item" button hidden or disabled | |
| QA-215 | Remove line item | Multiple items exist | Click remove button on item | Item removed, totals recalculate | |
| QA-216 | Payment details | On guest form | Enter bank name, bank address, IBAN, SWIFT | All fields accept input | |
| QA-217 | Invoice number manual | On guest form | Enter custom invoice number | Field accepts input | |
| QA-218 | Issue date | On guest form | Select date | Date picker works, field updates | |
| QA-219 | Due date | On guest form | Select due date | Date picker works, field updates | |
| QA-220 | Currency selection — EUR | On guest form | Select EUR from dropdown | Currency set to EUR | |
| QA-221 | Currency selection — RSD | On guest form | Select RSD from dropdown | Currency set to RSD | |
| QA-222 | Currency — custom | On guest form | Enter custom 3-letter code (e.g., USD) | Currency accepted | |
| QA-223 | VAT rate | On guest form | Enter VAT rate (e.g., 20%) | VAT amount auto-calculates | |
| QA-224 | VAT rate default | On guest form | Observe VAT field | Default 0% | |
| QA-225 | Contract reference | On guest form | Enter contract reference | Field accepts input | |
| QA-226 | External reference | On guest form | Enter external reference | Field accepts input | |
| QA-227 | Notes field | On guest form | Enter notes/payment terms | Field accepts multiline input | |
| QA-228 | Totals auto-calculation | Add items with qty and price | Observe totals section | Subtotal = sum of items, VAT = subtotal × rate, Total = subtotal + VAT | |

### 4.3 Guest Mode — PDF Generation

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-230 | Generate PDF — complete form | All fields filled | Click "Generate PDF" | PDF downloads, contains all entered data | |
| QA-231 | PDF content — header | PDF generated | Open downloaded PDF | Invoice number, issue date, due date, contract/external reference present | |
| QA-232 | PDF content — seller | PDF generated | Observe | Company name, contact, address, phone, VAT, reg number | |
| QA-233 | PDF content — buyer | PDF generated | Observe | Client name, contact, email, address, VAT, reg number | |
| QA-234 | PDF content — items | PDF generated | Observe | All line items with description, qty, unit price, total | |
| QA-235 | PDF content — totals | PDF generated | Observe | Subtotal, VAT (rate + amount), Grand Total correct | |
| QA-236 | PDF content — payment | PDF generated | Observe | Bank name, address, IBAN, SWIFT | |
| QA-237 | PDF — Unicode/Serbian | Fill form with Serbian characters (ćčžšđ) | Generate PDF | Characters render correctly (Roboto font) | |
| QA-238 | PDF — no data saved | Generate PDF in guest mode | Navigate away, return to landing | No data persisted — form resets | |
| QA-239 | IBAN validation | On guest form | Enter invalid IBAN format | Validation warning shown | |
| QA-240 | SWIFT validation | On guest form | Enter invalid SWIFT format (not 8 or 11 chars) | Validation warning shown | |
| QA-241 | Email validation | On guest form | Enter invalid email format in buyer email | Validation warning shown | |

### 4.4 Web — Authorized Mode — Authentication

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-300 | Login page loads | Click "Sign In" from landing | Observe | Email + password fields, "Sign In" button, branding | |
| QA-301 | Successful login | On login page | Enter demo@example.com / Demo123! | Redirect to Dashboard | |
| QA-302 | Invalid credentials | On login page | Enter wrong password | Error message shown, password field cleared | |
| QA-303 | Empty fields | On login page | Click "Sign In" without input | Validation errors on both fields | |
| QA-304 | JWT persistence | Logged in, close tab | Reopen app URL | Dashboard shown (no re-login) | |
| QA-305 | Logout | On Dashboard | Click logout button | Redirect to landing page, JWT cleared | |
| QA-306 | Route guard — unauthorized | Not logged in | Navigate to /invoices directly | Redirect to login page | |

### 4.5 Web — Authorized Mode — Dashboard

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-310 | Dashboard loads | Logged in | Navigate to Dashboard | Recent invoices displayed with status badges | |
| QA-311 | Create New Invoice | On Dashboard | Click "Create New Invoice" | Invoice form opens | |
| QA-312 | Company management link | On Dashboard | Navigate to Companies | Company management page opens | |
| QA-313 | Client management link | On Dashboard | Navigate to Clients | Client management page opens | |

### 4.6 Web — Authorized Mode — Company Management

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-320 | Company list | Logged in, companies exist | Navigate to /companies | Company cards/list shown | |
| QA-321 | Create company | On company page | Click "Add Company", fill name + contact + address, save | Company created, list refreshes | |
| QA-322 | Edit company | Company exists | Click edit on company | Form pre-filled, save updates company | |
| QA-323 | Delete company | Company with no invoices | Click delete → Confirm | Company soft-deleted, removed from list | |
| QA-324 | Delete company — with invoices | Company has non-draft invoices | Click delete | Error: cannot delete company with invoices | |
| QA-325 | Add bank account | Company exists | Click "Add Bank Account" in company | Form opens, save adds bank account | |
| QA-326 | Edit bank account | Bank account exists | Click edit on bank account | Form pre-filled, save updates | |
| QA-327 | Delete bank account | Bank account not on invoices | Click delete → Confirm | Bank account removed | |
| QA-328 | Set default bank account | Multiple accounts exist | Click "Set as Default" | Only one default per company, badge updates | |
| QA-329 | Company validation — name required | On company form | Leave name empty, save | Validation error | |
| QA-330 | Company validation — address required | On company form | Leave address empty, save | Validation error | |
| QA-331 | Bank account validation — IBAN | On bank account form | Enter invalid IBAN | Validation error | |
| QA-332 | Bank account validation — SWIFT | On bank account form | Enter SWIFT with wrong length | Validation error | |

### 4.7 Web — Authorized Mode — Client Management

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-340 | Client list | Logged in, clients exist | Navigate to /clients | Client list with status indicators | |
| QA-341 | Filter — Active | Active clients exist | Filter by Active | Only active clients shown | |
| QA-342 | Filter — Inactive | Inactive clients exist | Filter by Inactive | Only inactive clients shown | |
| QA-343 | Create client | On client page | Click "Add Client", fill name + address, save | Client created, list refreshes | |
| QA-344 | Edit client | Client exists | Click edit on client | Form pre-filled, save updates client | |
| QA-345 | Delete client | Client with no invoices | Click delete → Confirm | Client soft-deleted | |
| QA-346 | Delete client — with invoices | Client has non-draft invoices | Click delete | Error: cannot delete client with invoices | |
| QA-347 | Toggle status | Active client exists | Toggle to Inactive | Status changes, client still visible in list | |
| QA-348 | Client validation — name required | On client form | Leave name empty, save | Validation error | |
| QA-349 | Client validation — address required | On client form | Leave address empty, save | Validation error | |

### 4.8 Web — Authorized Mode — Invoice Management

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-360 | Invoice list loads | Logged in, invoices exist | Navigate to /invoices | Table with invoice number, company, client, date, amount, status, overdue badge | |
| QA-361 | Filter by status — all 5 | Invoices in various statuses | Select each status filter | Only matching invoices shown | |
| QA-362 | Filter by overdue | Overdue invoices exist | Check overdue filter | Only overdue invoices shown | |
| QA-363 | Search by invoice number | Invoices exist | Type invoice number in search | Matching invoices shown | |
| QA-364 | Search by client name | Invoices exist | Type client name in search | Matching invoices shown | |
| QA-365 | Pagination | >20 invoices | Navigate pages | Pagination controls work, correct page shown | |
| QA-366 | Create invoice | Company + client + bank exist | Click "Create New Invoice", fill form, save | Invoice created with auto-generated number, redirect to detail | |
| QA-367 | Edit invoice | Invoice exists | Click edit, modify field, save | Invoice updated | |
| QA-368 | Delete invoice | Invoice exists | Click delete → Confirm | Invoice soft-deleted, removed from list | |
| QA-369 | Invoice detail view | Invoice exists | Click invoice number | Detail view: all sections, status badge, action buttons | |
| QA-370 | PDF download (auth) | Invoice exists | Click PDF download | PDF downloaded, opens in browser/viewer | |
| QA-371 | Status change — web | Invoice in draft status | Change status to Sent via edit form or action | Status updates, reflected in list | |
| QA-372 | Overdue toggle — web | Invoice in sent status | Toggle overdue flag | Flag updates, badge appears | |
| QA-373 | Duplicate invoice — web | Invoice exists | Click Duplicate | New invoice form with copied data, new number | |
| QA-374 | Create invoice — inactive client blocked | Inactive client exists | Try to create invoice selecting inactive client | Client not shown in dropdown (filtered to active only) | |
| QA-375 | Invoice form — bank account linked to company | Invoice form open | Select company → observe bank account dropdown | Bank accounts filtered to selected company | |
| QA-376 | Invoice auto-number format | Create new invoice | Observe invoice number | Format INV-DDMMYYYY-NNN | |
| QA-377 | Invoice — Save & PDF | Fill form completely | Click "Save & PDF" | Invoice saved + PDF generated in one action | |

### 4.9 Web — Cross-Cutting & Responsive

| ID | Description | Preconditions | Steps | Expected Result | Status |
|----|-------------|---------------|-------|-----------------|--------|
| QA-400 | Responsive — landing page (mobile width) | Chrome DevTools, 375px width | Open landing page | Stacks vertically: preview above, buttons below | |
| QA-401 | Responsive — invoice form (mobile width) | Chrome DevTools, 375px width | Open guest invoice form | Form fields stack vertically, usable on mobile | |
| QA-402 | Responsive — dashboard (tablet width) | Chrome DevTools, 768px width | Open dashboard (auth) | Layout adapts, no horizontal scrolling | |
| QA-403 | Browser — Firefox | Firefox latest | Complete guest PDF generation flow | Form works, PDF downloads correctly | |
| QA-404 | Browser — Safari | Safari latest | Complete guest PDF generation flow | Form works, PDF downloads correctly | |
| QA-405 | PDF — Unicode in all browsers | Chrome, Firefox, Safari | Generate PDF with Serbian chars (ćčžšđ) | Characters render correctly in all browsers | |
| QA-406 | Auth mode — full CRUD cycle | Logged in | Create company → bank account → client → invoice → view → edit → change status → PDF → delete | All operations work via API | |
| QA-407 | Guest → Sign In transition | On guest form with data | Click "Sign In" from navigation | Login page shown (guest data not persisted is expected) | |
| QA-408 | Deep link — invoice detail | Logged in | Navigate directly to /invoices/{id} | Invoice detail loads correctly | |
| QA-409 | Deep link — unauthorized | Not logged in | Navigate directly to /invoices | Redirect to login | |
| QA-410 | Server-side PDF content match | Invoice with all fields | Download PDF via API | PDF contains all sections: header, from, to, items, totals, payment, notes | |

---

## 5. Regression Checklist

Quick smoke test after any code change:

### Mobile
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

### Web
- [ ] Landing page loads with preview + buttons
- [ ] Guest: Fill form → Generate PDF → PDF downloads
- [ ] Guest: PDF contains Serbian characters correctly
- [ ] Auth: Login → Dashboard loads
- [ ] Auth: Create invoice → detail view
- [ ] Auth: Download PDF from detail
- [ ] Auth: Company and client CRUD
- [ ] Responsive: Landing page on 375px width

---

## 6. Traceability Matrix

### Mobile — SRS Acceptance Criteria → Test Cases

| Acceptance Criteria | Test Cases |
|---------------------|------------|
| S4-01 — Project setup | QA-001 |
| S4-02 — Authentication | QA-010, QA-011, QA-016, QA-017 |
| S4-03 — Dashboard | QA-020 through QA-027 |
| S4-04 — Invoice creation | QA-080 through QA-098 |
| S4-05 — Invoice history | QA-030 through QA-042 |
| S4-06 — Status management | QA-054 through QA-067 |
| S4-07 — Client management | QA-100 through QA-114 |
| S4-08 — Company view | QA-120 through QA-130 |
| MO-01 — Mobile invoice creation | QA-080, QA-096 |
| MO-02 — Invoice history | QA-030, QA-040 |
| MO-03 — Status change | QA-054 through QA-062 |
| MO-04 — Client management | QA-103, QA-110 |
| MO-05 — Company read-only (online) | QA-120 |
| OFF-01 — Offline mode | QA-002, QA-160 |
| OFF-02 — Local PDF | QA-162 |
| OFF-03 — Mode selection | QA-001 through QA-005 |
| OFF-04 — Server settings | QA-135 through QA-145 |
| OFF-05 — Settings screen | QA-150 through QA-156 |

### Web — PRD Requirements → Test Cases

| PRD Requirement | Test Cases |
|-----------------|------------|
| LP-01, LP-02, LP-04 — Landing page | QA-200 through QA-204 |
| PF-01 through PF-13 — Invoice form | QA-210 through QA-228 |
| AU-01, AU-02 — Auth | QA-300 through QA-306 |
| DA-01 through DA-06 — Dashboard | QA-310 through QA-313 |
| CO-01 through CO-07 — Company mgmt | QA-320 through QA-332 |
| CL-01 through CL-07 — Client mgmt | QA-340 through QA-349 |
| IN-01 through IN-15 — Invoice mgmt | QA-360 through QA-377 |
| S1-14 — Responsive design | QA-400 through QA-402 |

---

## 7. Test Summary

| Section | ID Range | Count |
|---------|----------|-------|
| **Mobile** | | |
| Welcome Screen | QA-001 → QA-005 | 5 |
| Login Screen | QA-010 → QA-017 | 8 |
| Dashboard | QA-020 → QA-027 | 8 |
| Invoice List | QA-030 → QA-042 | 13 |
| Invoice Detail | QA-050 → QA-074 | 25 |
| Invoice Form | QA-080 → QA-098 | 19 |
| Client List | QA-100 → QA-106 | 7 |
| Client Form | QA-110 → QA-114 | 5 |
| Company Detail | QA-120 → QA-130 | 11 |
| Server Settings | QA-135 → QA-145 | 11 |
| Settings Screen | QA-150 → QA-156 | 7 |
| Cross-Cutting (Mobile) | QA-160 → QA-173 | 14 |
| Additional Mobile (v2.0) | QA-180 → QA-185 | 6 |
| **Mobile Subtotal** | | **139** |
| **Web** | | |
| Guest — Landing Page | QA-200 → QA-204 | 5 |
| Guest — Invoice Form | QA-210 → QA-228 | 19 |
| Guest — PDF Generation | QA-230 → QA-241 | 12 |
| Auth — Authentication | QA-300 → QA-306 | 7 |
| Auth — Dashboard | QA-310 → QA-313 | 4 |
| Auth — Company Management | QA-320 → QA-332 | 13 |
| Auth — Client Management | QA-340 → QA-349 | 10 |
| Auth — Invoice Management | QA-360 → QA-377 | 18 |
| Cross-Cutting & Responsive | QA-400 → QA-410 | 11 |
| **Web Subtotal** | | **99** |
| **TOTAL** | | **238** |
