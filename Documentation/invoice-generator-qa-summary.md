# Invoice Generator — QA Phase Complete Summary

**Date:** March 31, 2026
**Author:** Igor Kudinov (DigitLock)
**Purpose:** Handoff document for deployment and publication phase

---

## What Was Done in QA Phase (March 30-31, 2026)

### QA Test Plan
- Created QA Test Plan v2.0 (238 test cases) from original v1.0 (132 mobile-only)
- Added 99 web tests: Guest mode, Authorized mode, Responsive/Cross-cutting
- Added 7 additional mobile tests: missing filters, validations, offline CRUD gaps
- Renumbered for logical grouping with reserved gaps
- Updated to v2.1 with all execution results — **NOT YET COMMITTED** (forgot to add to last commit)

### QA Execution Results
- **238 tests executed, 238 PASS/SKIP, 0 open blockers**
- 13 bugs found and fixed
- 9 improvements added during QA
- 2 known non-blocking issues deferred to v1.1

### Bugs Fixed (13)

**Backend (3):**
1. Invoice List SQL: added `status`, `search`, `is_overdue` query params to ListInvoices + CountInvoices
2. Search: extended to match `cl.name ILIKE` (client name), not just invoice_number
3. Due date validation: added `validateDueDate()` helper in handlers, returns 400 before DB constraint fires

**Mobile (7):**
4. Client Form stale cache: replaced Riverpod `ref.watch` with direct `repo.getById()` in `initState()`
5. Company Form stale cache: same pattern
6. Company delete: added `delete()` to abstract interface + local repo + UI with confirmation dialog
7. Bank Account edit: added `getById()`, `update()` to repos, edit mode in form, new route
8. Bank Account delete: added `delete()` to repos + UI with confirmation dialog
9. Invoice Form "+" buttons: hidden for Company/Bank Account in online mode (MO-05 compliance)

**Web (3):**
10. Login: separated `VITE_AUTH_URL` (→:8080) from `VITE_API_URL` (→:8081), added `.env.development`
11. Login response: unwrap `body.data` envelope, fix UUID types (`string` not `number`), `expires_in` not `expires_at`
12. Due date: removed `required` attribute, send `null` for empty, redirect to detail after create

### Improvements Added (9)

1. **Duplicate invoice** — button on detail page, loads via `?duplicate={id}` query param
2. **Save & Download PDF** — second button on invoice form, triggers PDF after save
3. **Overdue filter** — full stack: SQL `is_overdue` param → repo → handler → API → UI checkbox
4. **Line items responsive** — stacked cards on mobile 375px, table on sm+
5. **Nav order** — Dashboard → Invoices → Clients → Companies (matching mobile)
6. **Preview modal** — landing page image opens in Teleport modal, not new tab
7. **Status dropdown reset** — on Cancel in confirm dialog, `defineExpose({ reset })`
8. **Due date validation** — human-readable "Due date must be on or after issue date"
9. **API error details** — `ApiRequestError` now builds message from `details[]` array (global fix)

### Known Issues (v1.1 Backlog)

| # | Issue | Priority | Component |
|---|-------|----------|-----------|
| 1 | Server Settings redirect after save (QA-137/141) | Low | Mobile |
| 2 | GlobalKey conflict logs on server switch (QA-144) | Low | Mobile |
| 3 | Guest form due date validation missing (QA-219) | Medium | Web |
| 4 | Invoice number not editable in create mode (QA-376) | Low | Web |
| 5 | Mobile overdue filter chip | Low | Mobile |
| 6 | Landing page mobile layout order (QA-400) | Low | Web |
| 7 | CORS config needs .env.production for deploy | Medium | Backend |

---

## Current State of All Components

### 1. Backend (Go)
- **Repo:** `github.com/DigitLock/invoice-generator` → `backend/`
- **Status:** All QA fixes committed, binary builds clean
- **Port:** 8081 (dev), shared JWT with Expense Tracker on 8080
- **DB:** PostgreSQL on homelab `192.168.13.30`, database `invoice_generator`
- **Migrations:** 8 total (007: JWT int→string, 008: nullable due_date)
- **Key changes from QA:** invoice list filtering (status/search/is_overdue), due date validation, CORS config
- **NOT deployed to VPS** — runs on Mac Mini M4 only

### 2. Web Frontend (Vue.js 3)
- **Repo:** `github.com/DigitLock/invoice-generator` → `frontend/`
- **Status:** All QA fixes + 9 improvements committed
- **Dev port:** 5174 (Expense Tracker frontend on 5173)
- **Production:** Docker nginx on VPS `46.224.29.194:8083` via Cloudflare Tunnel at `invoice.digitlock.systems`
- **Key changes from QA:** auth URL separation, response parsing, duplicate/save&PDF, overdue filter, responsive, modal preview, error display
- **`.env.development`** added: `VITE_API_URL=http://localhost:8081`, `VITE_AUTH_URL=http://localhost:8080`
- **VPS deployment needs:** `.env.production` with production URLs, rebuild Docker image

### 3. Mobile App (Flutter)
- **Repo:** `github.com/DigitLock/invoice-generator-mobile`
- **Status:** All QA fixes committed, 13/13 smoke tests + 139/139 QA tests pass
- **Tested on:** iOS Simulator (iPhone 16e) + Physical iPhone (iOS 26.3)
- **Key changes from QA:** stale cache fixes (direct fetch pattern), offline CRUD complete, online mode restrictions
- **Android APK:** builds successfully
- **iOS signing:** configured with Apple Development team RS66FM85BB
- **Google Play Console:** account created under "DigitLock", pending verification

### 4. Documentation
- **QA Test Plan v2.1** — 238 tests with results, NOT YET in repo (commit separately)
- **PRD v0.4** — in `invoice-generator/Documentation/`
- **SRS v0.2** — in `invoice-generator/Documentation/`
- **Mobile SRS v0.3** — in `invoice-generator-mobile/Documentation/`
- **Project Summary** — in `invoice-generator-mobile/Documentation/`

---

## Infrastructure

| Component | Location | Status |
|-----------|----------|--------|
| Web Frontend (prod) | VPS `46.224.29.194:/opt/invoice-generator` | Docker nginx, port 8083, **OUTDATED** (pre-QA) |
| Cloudflare Tunnel | `invoice.digitlock.systems` → localhost:8083 | Active, frontend only |
| Backend (dev only) | Mac Mini M4 | Go binary, port 8081, **NOT on VPS** |
| Expense Tracker (auth) | Mac Mini M4 | Go binary, port 8080 |
| PostgreSQL | Homelab `192.168.13.30` | Database: `invoice_generator` |
| GitHub | `DigitLock/invoice-generator` | Public, last commit: QA fixes |
| GitHub | `DigitLock/invoice-generator-mobile` | Public, last commit: QA fixes |
| Google Play Console | DigitLock account | Created, pending verification |

---

## What's Next (Deployment & Publication Chat)

### Phase 2: Backend Deploy to VPS
1. **Commit QA test plan v2.1** to `invoice-generator/Documentation/`
2. **Create `.env.production`** for web frontend with production URLs
3. **Dockerize backend** — add Dockerfile, add to docker-compose.yml on VPS
4. **PostgreSQL decision:** use homelab DB (accessible from VPS?) or set up PostgreSQL on VPS
5. **Run migrations** on production DB
6. **Cloudflare Tunnel routing:** `/api/` → backend container, `/` → frontend container
7. **CORS:** configure `CORS_ALLOWED_ORIGINS` for production domain
8. **Expense Tracker auth:** needs to be accessible from VPS for JWT validation (shared SECRET_KEY)
9. **Rebuild frontend Docker image** with production env vars
10. **Test end-to-end** on production URL

### Phase 3: Publication
1. **Final Android APK/AAB build** with production API URLs
2. **Google Play Store listing** — screenshots, description, content rating
3. **iOS TestFlight** (if Apple Developer account active)
4. **Landing page** for `digitlock.systems` (separate chat)
5. **Update mobile app Server Settings** preset to point to working production URL

### Key Decisions Needed
- PostgreSQL: homelab vs VPS? (homelab means VPS needs network access to 192.168.13.30)
- Expense Tracker auth: deploy to VPS too? Or keep on homelab with tunnel?
- Domain routing: `invoice.digitlock.systems/api/` for backend, or separate subdomain `api.invoice.digitlock.systems`?
- Mobile default server: DigitLock Cloud preset URL needs to match actual production

---

## Dev Environment Quick Reference

```bash
# Expense Tracker
cd ~/Documents/Projects/expense-tracker
# Frontend: port 5173
npm run dev
# Backend: port 8080
go run ./cmd/server/

# Invoice Generator
cd ~/Documents/Projects/invoice-generator
# Frontend: port 5174
cd frontend && npx vite --host --port 5174
# Backend: port 8081
cd backend && go run ./cmd/server/

# Mobile (simulator)
cd ~/Documents/Projects/invoice-generator-mobile
flutter run --dart-define=API_URL=http://localhost:8081 --dart-define=AUTH_URL=http://localhost:8080

# Mobile (physical iPhone)
flutter run -d 00008140-000A2D662E39801C --dart-define=API_URL=http://192.168.13.101:8081 --dart-define=AUTH_URL=http://192.168.13.101:8080
```

**Credentials:** `demo@example.com` / `Demo123!`
**Mac Mini ETH:** `192.168.13.101` | **Wi-Fi:** `192.168.13.102`
**Homelab PostgreSQL:** `192.168.13.30`
**VPS:** `46.224.29.194` (Hetzner)
**Domain:** `digitlock.systems` (Cloudflare DNS/Tunnels)
