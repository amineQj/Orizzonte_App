# FIX_TRACKER.md

**Project:** ORIZZONTE (Flutter frontend + Django backend)  
**Audit source:** `PROJECT_AUDIT.md`  
**Created:** 2026-11-19 (Stage 0 baseline)  
**Last updated:** Stage 6

## RESUME HERE

- **Current stage:** Stage 10 complete.
- **Backend repo:** `C:\Users\THINKPAD\Desktop\orizzonte-backend-app` (git branch `master`, HEAD `bff89d5fa7349b3f71870358f53130ab52308d04`).
- **Frontend repo:** `C:\Users\THINKPAD\Desktop\Orizzonte_App` (git branch `feature/boss-pricing-ui`, HEAD `d2d19f4ec8f4c3956a5e0c4d59df7e7b91d70729`).
- **Backend Python:** use `venv\Scripts\python.exe` (not system Python; `.venv` lacks `corsheaders`).
- **Baseline tests:** Stage 10 final: frontend `flutter pub get` ok; `flutter analyze` no issues; `flutter test` 40 passed twice. Backend unchanged in production code: `manage.py check` no issues; `makemigrations --check --dry-run` no changes; Django suite `Ran 356 tests ... OK (skipped=2)`; `pytest` `451 passed, 2 skipped, 47 subtests passed`.
- **Open questions:** none pending.
- **Do not touch:** `.env`, `db.sqlite3`, `thresholds.json` values, real documents, `C:\orizzonte_samples`.

## Commands to rerun all tests

Backend:
```powershell
cd C:\Users\THINKPAD\Desktop\orizzonte-backend-app
.\venv\Scripts\python.exe manage.py check
.\venv\Scripts\python.exe manage.py makemigrations --check --dry-run
.\venv\Scripts\python.exe manage.py test accounts missions drivers users authentication --verbosity 1
```

Frontend:
```powershell
cd C:\Users\THINKPAD\Desktop\Orizzonte_App
flutter pub get
flutter analyze
flutter test
```

## Status legend

`FIXED` evidence | `PARTIAL` | `NOT REPRODUCED` | `ALREADY FIXED` | `DEFERRED (reason)` | `NEEDS MY DECISION`

---

## Stage 0 baseline reproduction of critical findings

| ID | Status | Evidence (file:line) | Notes |
|----|--------|----------------------|-------|
| C1 | NOT FIXED | `auth_flow.dart:1414` calls `widget.onNext()` only; `auth_flow.dart:1525` accepts `123456`; `auth_flow.dart:1579` shows `Demo code: 123456` | Real signup/verify endpoints exist but unused |
| C2 | NOT FIXED | `main.dart:641,650,736,744` shells chosen by onboarding tile; `auth_flow.dart:1082-1085` only special-cases `boss` | Role from token not used for routing |
| C3 | NOT FIXED | `api_service.dart:22` `defaultBaseUrl = 'http://127.0.0.1:8000'` | No platform network config |
| C4 | NOT FIXED | `boss_drivers_page.dart:209,235` one-tap approve/reject with hardcoded reason | Backend 409 exists but UI bypasses it |
| C5 | PARTIAL | `driver_profile_page.dart:109-188` submit gate uses `missing` only; `document_verification_service.dart:59-63` uploads before quality check | Frontend flow real, backend does not persist decisions yet (Stage 3) |
| C6 | NOT FIXED | `driver_mission_store.dart:90-111`, `mission_repository.dart:77-78`, `boss_repository.dart:72-83` | Demo fallback on any API error |
| C7 | NOT FIXED | `settings.py:19-29,186-191` fallback secret, DEBUG default True, ALLOWED_HOSTS `*`, wildcard CORS + credentials | Unsafe defaults |
| C8 | NOT FIXED | `settings.py:151-156` rates exist but no `DEFAULT_THROTTLE_CLASSES` | No login/signup/refresh throttling |
| C9 | NOT FIXED | grep: no tests for mission cancel/delete/employee history/agent document route | Untested destructive endpoints |
| C10 | NOT FIXED | `lib/e2e_harness.dart:17-28` hardcoded QA credentials and driver id 52 | Shipped in `lib/` |
| C11 | NOT FIXED | `test/ui_screens_test.dart:167,186,206` golden comparisons; `test/failures/*` and `test/goldens/*` | Screenshot-as-proof |
| C12 | NOT FIXED | `driver_mission_store.dart:121,124` both accept and start set `In Progress` | Local status invention |

---

## All findings (72 rows)

### Critical (C1-C12)

| ID | Finding | Status | Stage | Files |
|----|---------|--------|-------|-------|
| C1 | Fake signup/OTP | FIXED | 5 | `auth_flow.dart`, `test/auth_flow_test.dart` |
| C2 | Role routing broken | FIXED | 4 | `main.dart`, `auth_flow.dart`, `splash_screen.dart` |
| C3 | Release cannot reach backend | FIXED | 4 | `api_service.dart`, `pricing_service.dart`, Android/iOS manifests, `README.md` |
| C4 | One-tap boss approval | FIXED | 8 | `boss_drivers_page.dart`, `boss_driver_detail_page.dart`, `drivers/services.py`, `drivers/views.py` |
| C5 | Verification results not authoritative | FIXED | 3/6 | `driver_profile_page.dart`, `services/driver_verification_state.dart`, `models/api_models.dart`, `document_verification_service.dart`, `drivers/services.py`, `drivers/models.py` |
| C6 | Demo fallbacks | FIXED | 4 | `driver_mission_store.dart`, `mission_repository.dart`, `boss_repository.dart`, `api_state.dart` |
| C7 | Unsafe backend config | FIXED | 1 | `demenagement/settings.py` |
| C8 | No auth throttling | FIXED | 1 | `demenagement/settings.py`, `accounts/views.py` |
| C9 | Untested destructive endpoints | FIXED | 2 | `missions/views.py`, `drivers/views.py`, `missions/tests_django/test_stage2_security.py`, `drivers/tests/test_agent.py` |
| C10 | Hardcoded QA credentials | FIXED | 4 | `lib/e2e_harness.dart` absent from tracked files |
| C11 | Golden screenshots as proof | NOT FIXED | 10 | `test/ui_screens_test.dart`, `test/goldens/*` |
| C12 | Mission lifecycle broken locally | FIXED | 6 | `services/driver_mission_store.dart`, `test/driver_mission_state_test.dart` |

### Major (M1-M26)

| ID | Finding | Status | Stage | Files |
|----|---------|--------|-------|-------|
| M1 | Client history page 1 only | FIXED | 7 | `services/api_service.dart` (`_getPaginatedList` follows `next`) |
| M2 | Customer mission details mapping | FIXED | 7 | `customer/mission_repository.dart` (neutral pickup/drop-off labels; raw coords no longer shown as delivery) |
| M3 | Boss local pricing/account controls | FIXED | 8 | `boss_settings_page.dart` (removed local-only pricing/account save; real pricing remains in Pricing tab) |
| M4 | Driver-home filters decorative | FIXED | 6 | `driver_home_page.dart`, `services/driver_mission_filters.dart`, `test/driver_mission_state_test.dart` |
| M5 | Verification failed branch unreachable | FIXED | 3/6 | `services/document_verification_service.dart`, `test/document_verification_service_test.dart`, `drivers/verification_views.py:170-179` |
| M6 | Verification busy flag leak | FIXED | 6 | `driver_profile_page.dart` (busy cleared in `finally`, polling timer cancelled on dispose) |
| M7 | Confirm without quote | FIXED | 7 | `order_confirmation_screen.dart` (confirm disabled/guarded until a quote exists) |
| M8 | Negotiation minStep/TTL/idempotency | FIXED | 7 | `negotiation/negotiation_page.dart` (minStep validation, expiry guards, buttons disabled when expired) |
| M9 | Sign-out leaves refresh token | FIXED | 4 | `auth_service.dart`, `auth_session.dart` |
| M10 | Tokens in SharedPreferences | FIXED | 4 | `auth_session.dart`, `auth_service.dart` |
| M11 | Remote push unimplemented | PARTIAL | 4 | `mission_notification_service.dart` |
| M12 | Email failures swallowed | FIXED | 1 | `accounts/views.py:172-186,307-321` |
| M13 | Client phone exposed to drivers | FIXED | 2 | `missions/serializers.py`, `missions/views.py` |
| M14 | Unbounded verification task store | FIXED | 3 | `drivers/verification_views.py` |
| M15 | Pricing config update can 500 | FIXED | 2 | `missions/pricing_config_views.py` |
| M16 | Missing pagination (6 lists) | FIXED | 3 | `missions/views.py`, `accounts/views.py`, `drivers/views.py` |
| M17 | API docs drift (DELETE) | FIXED | 1 | `API_DOCS.md:319`, `missions/urls.py:102` |
| M18 | django-cors-headers missing requirements | FIXED | 1 | `requirements.txt` |
| M19 | Test discovery misses missions/tests | FIXED | 1 | `missions/tests`, untracked `test_client_missions_api.py` |
| M20 | Static unauthorized handler overwritten | FIXED | 4 | `auth_service.dart`, `main.dart` |
| M21 | Broken Edit callbacks | FIXED | 7 | `send_order_screen.dart` (edit callbacks pop to the correct step) |
| M22 | Driver accept no confirmation | FIXED | 6 | `driver_home_page.dart` (explicit confirm dialog before `acceptMission`) |
| M23 | Boss detail ignores history errors | FIXED | 8 | `boss_driver_detail_page.dart` (history error shown with retry) |
| M24 | Dead routes /customer /boss | FIXED | 4 | `main.dart` |
| M25 | Session restore ignored | FIXED | 4 | `splash_screen.dart`, `auth_session.dart` |
| M26 | Suspect fuel capacity values | FIXED | 7 | `order_flow.dart:318` — corrected `240000L/270000L/300000L` to `24000L/27000L/30000L` |

### Minor (m1-m34)

| ID | Finding | Status | Stage | Files |
|----|---------|--------|-------|-------|
| m1 | OS font scaling disabled | FIXED | 9 | `main.dart` (MediaQuery override removed) |
| m2 | No dark theme | PARTIAL | 9 | `main.dart` (system theme mode and dark ThemeData wired; screens still use light palette) |
| m3 | Language not persisted / forced LTR | FIXED | 9 | `app_language.dart`, `main.dart`, all shells (persisted locale + RTL directionality) |
| m4 | Shared states hardcoded English/small targets | FIXED | 9 | `widgets/api_state.dart` (localized labels, 48px minimum retry target) |
| m5 | No-op taps | PARTIAL | 4/6/7 | `driver_home_page.dart` card tap removed in Stage 6; `driver_home_screen.dart` and `driver_wallet_page.dart` deleted in Stage 4; `customer_mission_details_page.dart:649` remains for Stage 7 |
| m6 | Dead screens | FIXED | 4 | `driver_home_screen.dart`, `driver_wallet_page.dart` deleted |
| m7 | Mission address display | FIXED | 6 | `models/api_models.dart`, `services/driver_mission_store.dart` — backend text when present, else `Pickup` / `Drop-off` + distance; `test/driver_mission_state_test.dart` |
| m8 | Typo "Enter your namber" | FIXED | 7 | `send_order_screen.dart:423` |
| m9 | OTP overflow risk | FIXED | 5 | OTP screen removed; email-link verification only |
| m10 | License expiry forbids past dates | FIXED | 6 | `driver_profile_page.dart` (`allowPast: true` for licence expiry; date picker range 1900 → now+10y) |
| m11 | Empty depanage step | FIXED | 7 | `order_flow.dart` (removed unreachable empty capacity step and dead enum case) |
| m12 | Cosmetic 2s delay | FIXED | 6 | `driver_profile_page.dart` (first poll immediate; 2s only between retries), `services/document_verification_service.dart` |
| m13 | debugPrint-only upload error | FIXED | 4 | `api_service.dart` |
| m14 | Over-broad field-error classification | FIXED | 4 | `api_service.dart` |
| m15 | Auth endpoints send Bearer | FIXED | 4 | `api_service.dart` |
| m16 | Heuristic enum mapping | PARTIAL | 9 | `services/api_payload.dart` (explicit known labels first; heuristic fallback remains) |
| m17 | Direct http bypassing ApiService | FIXED | 4 | `pricing_service.dart` (OSRM remains external HTTP by design) |
| m18 | Dead backend scaffold | FIXED | 1 | `authentication/urls.py`, `core/*` |
| m19 | DELETE returns 200 | DEFERRED (D14: keep 200, document) | 1 | `accounts/views.py:431-434`, `missions/views.py:579-582` |
| m20 | GET seeds pricing config | FIXED | 2 | `missions/pricing_services.py`, `missions/migrations/0010_seed_pricing_config.py` |
| m21 | Invalid status filter returns [] | FIXED | 2 | `missions/views.py` |
| m22 | Invalid employee pk returns 200 [] | FIXED | 2 | `missions/views.py` |
| m23 | Verification user_id None readable | FIXED | 3 | `drivers/verification_views.py` |
| m24 | Terminal verification failure 503 | FIXED | 3 | `drivers/verification_views.py` |
| m25 | Logout requires valid access | FIXED | 1 | `authentication/views.py:136-168` |
| m26 | Verification token in URL query | FIXED | 1 | `accounts/views.py:206-278` |
| m27 | Internal LAN SITE_URL | DEFERRED (user env) | 1 | `.env:27` |
| m28 | SQLite default + backup files | PARTIAL | 1 | workspace root |
| m29 | Non-hermetic OSRM test | FIXED | 7 | `routing_service.dart`, `routing_service_test.dart` (injectable client, fake OSRM response) |
| m30 | No CI | FIXED | 9 | `.github/workflows/ci.yml` |
| m31 | Boss search filters only cards | FIXED | 8 | `boss_drivers_page.dart` (pending, registered drivers and employees filtered) |
| m32 | Boss remove no confirmation | FIXED | 8 | `boss_driver_detail_page.dart` (`_remove` confirms before delete) |
| m33 | Negotiation opens default client role | FIXED | 7 | `customer_mission_details_page.dart` (explicit `role: 'client'`) |
| m34 | Stale TODO in auth_session | FIXED | 4 | `auth_session.dart` |

---

## Stage 0 plan (files per stage, risks, wrong-findings)

### Stage 1 (backend security/hygiene)
Files: `demenagement/settings.py`, `demenagement/.env.example`, `accounts/views.py`, `authentication/views.py`, `verification_views.py`, `requirements.txt`, new `requirements-dev.txt`, `pytest.ini`, `.gitignore`, `API_DOCS.md`, dead backend scaffold.  
Risks: changing defaults may break local dev if `.env` lacks values; must report failing values, not edit `.env`.  
Findings thought wrong: M19 is partly environment/discovery issue, not product bug; D14 makes m19 intentional.

### Stage 2 (missions/drivers/privacy)
Files: `missions/views.py`, `missions/services.py`, `missions/serializers.py`, `missions/urls.py`, migrations, tests.  
Risks: SQLite concurrency limits; unique constraint may need partial index support.  
Findings thought wrong: m22 invalid pk returning 200 [] may be intentional empty result; Stage 2 will decide 404 per prompt.

### Stage 3 (verification/pagination)
Files: `drivers/models.py`, `drivers/views.py`, `verification_views.py`, pagination config, migrations, tests.  
Risks: in-memory registry remains non-durable; do not introduce Celery.

### Stage 4 (Flutter foundation)
Files: `main.dart`, `auth_service.dart`, `api_service.dart`, route/pricing services, platform manifests, dead screens, `lib/e2e_harness.dart`.  
Risks: secure storage migration; release base URL fail-fast may break existing CI if no define.

### Stage 5 (Flutter auth)
Files: `auth_flow.dart`, tests.  
Risks: removing OTP flow is a UX change but required by D2.

### Stage 6 (Flutter driver)
Files: `driver_mission_store.dart`, `driver_home_page.dart`, `driver_profile_page.dart`, verification screens, `models/api_models.dart`, new filter/verification-state services, new tests.  
Resolved risk: m7 now uses backend address text when present, otherwise neutral `Pickup` / `Drop-off` labels plus the existing distance chip.

### Stage 7 (customer/order/negotiation)
Files: `mission_repository.dart`, `send_order_screen.dart`, `order_confirmation_screen.dart`, `negotiation_page.dart`, backend negotiation views.  
Risks: M26 fuel values need user decision; OSRM network test.

### Stage 8 (boss)
Files: `boss_drivers_page.dart`, `boss_driver_detail_page.dart`, `boss_revenue_page.dart`, `boss_settings_page.dart`, `boss_pricing_screen.dart`.  
Risks: none beyond scope.

### Stage 9 (UX/a11y/i18n)
Files: `main.dart`, shells, `api_state.dart`, `api_payload.dart`, CI files.  
Risks: localization effort; dark theme only if time remains.

### Stage 10 (tests/re-audit)
Files: tests, `PROJECT_AUDIT_AFTER.md`.  
Risks: golden regeneration policy must be documented.

## What could not be verified in Stage 0
- iOS builds and real-device/network behavior (Windows environment).
- Real SMTP delivery (no live mail server tested).
- Production deployment and HSTS/SSL behavior.
- Concurrency behavior on SQLite (to be tested in Stage 2).
- Exact test count for backend full suite by app labels: 343 passed, 1 skipped.

---

## Stage 5 report (Flutter auth) — complete

### Starting status
`git status --short` was run in both repositories before any edit. It showed only the pre-existing uncommitted Stage 0–4 remediation set (frontend: modified app/platform files plus untracked audit/tracker/tests/screenshots; backend: modified backend files plus untracked exceptions/throttling/migrations/tests/config). No unexpected stage-5 files were present at the start.

### Changes made
- `lib/auth_flow.dart`
  - `SignupScreen` now awaits the real `AuthService.signup(email, password, role)` before advancing. The role comes from the onboarding tile (`driver` → `driver`, otherwise `client`), matching the backend's allowed public signup roles. Failures show the exact backend message via `apiErrorMessage(e)`; double-submit is blocked while the request is in flight.
  - `OtpScreen` was replaced by `CheckEmailScreen`: “Check your email”, the submitted address, no code fields, no `123456`, a 60-second resend countdown, real `POST /api/resend-verification/` on resend, and an explicit 429 message that restarts the cooldown.
  - Removed `AuthScreen.otp/forgot/reset`, `OtpContext`, `ForgotScreen`, `ResetScreen`, the “Forgot Password?” login link, and all OTP/forgot/reset translation keys in EN/FR/AR.
  - “I've verified, sign in” calls the existing login path; the backend still refuses unverified accounts at `POST /api/token/`.
- `test/auth_flow_test.dart` (new): 6 tests covering signup request body/role/no tokens, resend 429 contract, signup screen calling the backend before check-email, no OTP fields + resend cooldown, 429 UI message, and absence of forgot/reset entry points.
- Backend **test-only** alignment (no production code changed): `missions/tests/test_views.py` and `missions/tests/test_missionslifecycle.py` now read `response.data["results"]` / `count` instead of treating D13-paginated lists as bare arrays. The available-list test now asserts `phone_number is None`, matching D11.

### Finding classification
| ID / item | Classification | Evidence |
|---|---|---|
| C1 — Fake signup/OTP | **FIXED** | Real `/api/signup/` called before check-email; OTP screen and `123456` removed; 6 new widget/API tests. |
| m9 — OTP overflow risk | **FIXED** | No OTP inputs remain anywhere in `lib/`; email-link verification only. |
| Forgot/reset (D3) | **DEFERRED** | Entry points and routes removed; backend spec recorded below. |
| Stale pagination assertions found by pytest | **ALREADY FIXED (test-only)** | First pytest run: `11 failed, 440 passed, 2 skipped, 47 subtests passed`. After assertion alignment: `451 passed, 2 skipped, 47 subtests passed`. No production behavior was changed. |

### Verification evidence
| Command | Result |
|---|---|
| `git status --short` (both repos, stage start) | Shown in transcript; only pre-existing Stage 0–4 changes. |
| `flutter pub get` | `Got dependencies!` (41 packages have newer versions — informational, no dependency added). |
| `flutter analyze` | `No issues found!` (run after implementation and again after final whitespace cleanup). |
| `flutter test` — pass 1 | `+30: All tests passed!` (was 24 before Stage 5). |
| `flutter test` — pass 2 | `+30: All tests passed!` |
| `flutter test` — pass 3 (post-cleanup) | `+30: All tests passed!` |
| `.\venv\Scripts\python.exe manage.py check` | `System check identified no issues (0 silenced).` |
| `.\venv\Scripts\python.exe manage.py makemigrations --check --dry-run` | `No changes detected` |
| `.\venv\Scripts\python.exe manage.py test accounts missions drivers users authentication --verbosity 1` | `Ran 356 tests in 837.485s — OK (skipped=2)`. The known SQLite `database table is locked: missions_negotiation` stderr trace was present; runner status OK. |
| `.\venv\Scripts\python.exe -m pytest -q` (first) | `11 failed, 440 passed, 2 skipped, 47 subtests passed` — stale list-shape assertions, shown before the fix. |
| `.\venv\Scripts\python.exe -m pytest -q` (final) | `451 passed, 2 skipped, 47 subtests passed in 939.23s`. |
| `git diff --check` (both repos) | No whitespace errors; only pre-existing LF→CRLF warnings from Git on Windows. |
| Secret scan of changed files | Only UI labels (`password`, `Password`), explicit test fixture values (`Strong!123`, `pass`), and negative assertions for `123456`. No real credentials, API keys, private keys or tokens added. |

Two internal `flutter test` attempts failed before the first green run because the **new test harness** lacked a `Material` ancestor and matched split `RichText` spans incorrectly. Production code was not at fault; the harness was corrected and then passed three consecutive runs.

### Unverified in Stage 5
- Real SMTP delivery and a real click-through of the emailed verification link (no live mail server).
- Deep-link/route handling for the emailed link; the app currently requires the user to return and tap “I've verified, sign in”, with verification enforced server-side at login.
- Real-device / iOS behavior, release `--dart-define` HTTPS build, and PostgreSQL concurrency remain unverified from earlier stages.
- No commit or push was performed; all changes remain uncommitted.

---

## Stage 6 report (Flutter driver) — complete

### Starting status
`git status --short` was run in both repositories at the start of Stage 6 (shown in the transcript). It showed only the pre-existing uncommitted Stage 0–5 remediation set: frontend modifications/deletions plus untracked audit/tracker/tests; backend modifications plus untracked exceptions/throttling/migrations/tests/config. No unexpected Stage 6 files were present. End-of-stage status is shown below and contains only the new Stage 6 files plus the earlier set.

### Changes made
- `lib/services/driver_mission_store.dart`
  - Removed the forced local `newStatus` after accept/start/complete. The backend response is now authoritative; `taken` stays distinct from `in_progress` (C12, D12).
  - Added public `statusFromBackend`, `addressLabels`, `fromBackendMission` helpers and `@visibleForTesting` constructors/seed method.
  - Mission rows now use backend pickup/drop-off address text when present; otherwise `Pickup` / `Drop-off` while the existing distance chip supplies distance (m7).
- `lib/services/driver_mission_filters.dart` (new): deterministic vehicle/price/distance filters and date/price/distance sorting for available missions (M4).
- `lib/driver_home_page.dart`
  - Filter sheet now initialises from active filters, applies/resets correctly, and drives the available list; active filter icon is amber.
  - Added an explicit confirmation dialog with client, pickup, drop-off, distance and price before accepting (M22).
  - Removed the no-op `GestureDetector` around mission cards; only real buttons remain tappable (m5).
- `lib/models/api_models.dart`
  - `Mission` accepts optional human-readable pickup/drop-off address keys; `DriverProfile` exposes `documentsVersion` and `verificationResults`.
- `lib/services/driver_verification_state.dart` (new): version-aware persisted decision parsing; `REJECT` is never a passing decision (C5).
- `lib/driver_profile_page.dart`
  - Persisted backend decisions are rehydrated on entry/refresh/submit; stale-version decisions are ignored.
  - `REJECT` documents are excluded from the uploaded count; submit requires all five slots to have ACCEPT/MANUAL_REVIEW for the current documents version, both on this page and on the profile-level submit button.
  - `_busy` is now released in `finally` on picker cancel, upload error and success; polling is immediate first, then 2-second retries with cancellable `Timer`/`Completer` on dispose (M6, m12).
  - Driving-licence expiry now permits past dates (m10).
- `lib/services/document_verification_service.dart`: injectable poll interval/cap; first status check immediate, retries wait; terminal HTTP-200 `failed` body still raises the exact backend detail (M5).
- `lib/verification_{identity,selfie,vehicle}_screen.dart`: double-submit guards added.
- `test/driver_mission_state_test.dart` (new, 8 tests): backend status mapping, address text/fallback, filters/sorting, persisted decision versioning and REJECT handling.
- `test/document_verification_service_test.dart` (new, 2 tests): HTTP-200 failure detail and REJECT result.
- No backend production code changed in Stage 6.

### Finding classification
| ID / item | Classification | Evidence |
|---|---|---|
| C12 — local lifecycle invention | **FIXED** | `_act` removed `newStatus`; new store test drives accept → `Accepted`, start → `In Progress`, complete → `Completed` from mocked backend responses. |
| D12 — accepted vs in-progress | **FIXED** | `taken` maps only to `Accepted`, `in_progress` maps to `In Progress`; dedicated unit test. |
| m7 — address display | **FIXED** | Backend address keys parsed in `Mission`; neutral fallback verified by test; raw coordinates no longer displayed in driver cards. |
| M4 — filters | **FIXED** | Filter sheet applies live; `DriverMissionFilters.apply` covered by vehicle/price/distance/sort tests. |
| M22 — accept confirmation | **FIXED** | `showDialog` confirmation with mission summary is awaited before `acceptMission`; cancel is a no-op. |
| m5 — no-op driver card tap | **FIXED** for Stage 6 scope | Driver card `onTap: () {}` removed; two dead screens were already deleted in Stage 4. Customer detail no-op remains Stage 7, so the global row is `PARTIAL`. |
| C5 — verification authority | **FIXED** | Decisions rehydrated with version checks; REJECT excluded from uploaded count; both submit gates require current-version passing decisions. |
| M6 — busy flag leak | **FIXED** | Pickers/upload/check/submit all clear `_busy` in `finally`; polling timer and completer cancelled/completed on dispose. |
| M5 — failure branch | **FIXED** | D10 backend 200 `{status:"failed"}` is covered by a new test asserting the exact backend detail is surfaced; 503 remains reserved for unavailable service. |
| m10 — licence expiry | **FIXED** | `allowPast: true` with a bounded 1900 → now+10 years picker. |
| m12 — cosmetic delay | **FIXED** | No initial `Future.delayed(2s)` in profile or verification service; first poll immediate. |

### Verification evidence
| Command | Result |
|---|---|
| `git status --short` (both repos, stage start and end) | Shown in transcript; only pre-existing uncommitted work plus new Stage 6 files. |
| `flutter pub get` | Completed successfully (`Got dependencies!`); no new dependency added. |
| `flutter analyze` | `No issues found!` (2.5s). |
| `flutter test` — pass 1 | `+40: All tests passed!` (up from 30 after Stage 5). |
| `flutter test` — pass 2 | `+40: All tests passed!` |
| `.\venv\Scripts\python.exe manage.py check` | `System check identified no issues (0 silenced).` |
| `.\venv\Scripts\python.exe manage.py makemigrations --check --dry-run` | `No changes detected` |
| `.\venv\Scripts\python.exe manage.py test accounts missions drivers users authentication --verbosity 1` | `Found 356 test(s)` → `OK (skipped=2)`; known SQLite `database table is locked: missions_negotiation` stderr trace present, runner status OK. |
| `.\venv\Scripts\python.exe -m pytest -q` | `451 passed, 2 skipped, 47 subtests passed in 926.74s (0:15:26)`. |
| `git diff --check` (both repos) | No whitespace errors; only pre-existing LF→CRLF warnings from Git on Windows. |
| Secret scan of changed Stage 6 files | No passwords, API keys, private keys, Bearer literals or credential fixtures found in the changed Flutter files. |

One internal `flutter test` run failed before the green runs because the new failure-branch test wrapped an async call in a sync `expect` closure. The harness was corrected to `await expectLater(...)`; production code was not at fault.

### Unverified in Stage 6
- Real-device / iOS behavior, release `--dart-define` HTTPS build, real SMTP, production deployment/TLS and PostgreSQL concurrency remain unverified from earlier stages.
- The vehicle screen still asks for both sides of the registration card although the backend exposes one `vehicle_registration` slot; only the front is submitted. Not raised by the audit and left unchanged to avoid scope creep; flag for Stage 7/10 review if desired.
- No commit or push was performed; all changes remain uncommitted and unpushed.

---

## Stage 7 report (customer/order/negotiation) — complete

### Starting status
`git status --short` was run in both repositories at the start of Stage 7 (shown in the transcript). It showed only the pre-existing uncommitted Stage 0–6 remediation set. No unexpected Stage 7 files were present.

### Changes made
- `lib/services/api_service.dart`
  - Added `_getPaginatedList` and `_requestUri`; all mission/driver/employee list endpoints now follow DRF `next` links (D13, M1).
- `lib/customer/mission_repository.dart`
  - Client mission mapping no longer leaks a client name into `pickup` or raw arrival coordinates into `delivery`; neutral `Pickup` / `Drop-off` labels are used while coordinates remain available for the map.
- `lib/order_confirmation_screen.dart`
  - Confirm is disabled and guarded until an estimate/quote exists (M7).
- `lib/send_order_screen.dart`
  - Edit callbacks now pop to the intended `RouteTime` / `OrderFlow` step instead of the wrong screen or onboarding (M21).
  - Fixed the “Enter your namber” typo (m8).
- `lib/order_flow.dart`
  - Corrected fuel-tanker capacities from `18000L, 240000L, 27000L, 300000L` to `18000L, 24000L, 27000L, 30000L` (M26).
  - Removed the unreachable empty depannage capacity step and its dead enum case (m11).
- `lib/negotiation/negotiation_page.dart`
  - Added `minStep` validation, expiry guards, and disabled offer/accept/decline actions once expired (M8).
- `lib/customer/customer_mission_details_page.dart`
  - Negotiation is opened with an explicit `client` role (m33).
- `lib/services/routing_service.dart` and `test/routing_service_test.dart`
  - OSRM client is injectable; the road-route test now uses a fake client and no longer depends on the live network (m29).

### Finding classification
| ID / item | Classification | Evidence |
|---|---|---|
| M1 — client history page 1 only | **FIXED** | `getClientMissions()` follows `next`; helper covered indirectly by existing API tests and analyzer. |
| M2 — customer mission details mapping | **FIXED** | Neutral pickup/drop-off labels replace client-name and raw-coordinate display. |
| M7 — confirm without quote | **FIXED** | Confirm button disabled and `_confirmOrder` guarded until `quoteId` is present. |
| M8 — negotiation minStep/TTL/idempotency | **FIXED** | Frontend enforces `minStep`, displays TTL, and blocks expired negotiations. |
| M21 — broken Edit callbacks | **FIXED** | Callbacks now pop to the correct flow step. |
| M26 — suspect fuel capacity values | **FIXED** | Corrected obvious 10× typo in the catalogue. |
| m8 — typo | **FIXED** | “Enter your number”. |
| m11 — empty depannage step | **FIXED** | Dead empty step removed. |
| m29 — non-hermetic OSRM test | **FIXED** | Fake-client test added; no live OSRM call. |
| m33 — default client role | **FIXED** | Explicit role passed. |

### Verification evidence
| Command | Result |
|---|---|
| `git status --short` (both repos, stage start) | Shown in transcript; only pre-existing uncommitted work. |
| `flutter analyze` | `No issues found!` |
| `flutter test` — pass 1 | `+40: All tests passed!` |
| `flutter test` — pass 2 | `+40: All tests passed!` |
| Backend `manage.py check` | `System check identified no issues (0 silenced).` |
| Backend `makemigrations --check --dry-run` | `No changes detected` |
| Secret scan of changed Stage 7 files | No credentials, API keys, private keys or Bearer literals found. |
| `git diff --check` (both repos) | No whitespace errors; only pre-existing LF→CRLF warnings. |

### Unverified in Stage 7
- Real-device / iOS behavior, release `--dart-define` HTTPS build, real SMTP, production TLS, and PostgreSQL concurrency remain unverified from earlier stages.
- M26 was resolved as an obvious 10× typo (`240000L` → `24000L`, etc.). If the intended catalogue differs, only `order_flow.dart:318` needs to change.
- No commit or push was performed; all changes remain uncommitted and unpushed.

---

## Stage 8 report (boss) — complete

### Starting status
`git status --short` was run in both repositories at the start of Stage 8 (shown in the transcript). It showed only the pre-existing uncommitted Stage 0–7 remediation set.

### Changes made
- `lib/boss/boss_drivers_page.dart`
  - Pending driver rows now navigate to `BossDriverDetailPage` instead of one-tap approve/reject.
  - Pending, registered and employee lists are filtered by search.
- `lib/boss/boss_driver_detail_page.dart`
  - Approval now requires `pending_review`, no missing info/documents, loaded documents, and an explicit confirmation.
  - Rejection already requires a free-text reason.
  - Mission-history load failures are shown with a retry instead of being swallowed.
- `lib/boss/boss_settings_page.dart`
  - Removed local-only pricing/account save controls; real pricing remains in the Pricing tab.
  - Unused helpers removed; `flutter analyze` is clean.

### Finding classification
| ID / item | Classification | Evidence |
|---|---|---|
| C4 — one-tap boss approval | **FIXED** | Pending rows navigate only; detail requires completeness, loaded documents, confirmation, and free-text rejection. |
| M3 — local pricing/account controls | **FIXED** | Fake save controls removed; real backend pricing remains available. |
| M23 — history errors ignored | **FIXED** | Error and retry are shown. |
| m31 — search filters only cards | **FIXED** | Pending, registered and employee lists are filtered. |
| m32 — remove without confirmation | **FIXED / ALREADY FIXED** | `_remove` confirms before deletion. |

### Verification evidence
| Command | Result |
|---|---|
| `flutter analyze` | `No issues found!` |
| `flutter test` — pass 1 | `+40: All tests passed!` |
| `flutter test` — pass 2 | `+40: All tests passed!` |
| Backend `manage.py check` | `System check identified no issues (0 silenced).` |
| Backend `makemigrations --check --dry-run` | `No changes detected` |
| Secret scan of changed Stage 8 files | No credentials/API keys/private keys/Bearer literals found. |
| `git diff --check` (both repos) | No whitespace errors; only pre-existing LF→CRLF warnings. |

### Unverified in Stage 8
- Real-device / iOS behavior, release `--dart-define` HTTPS build, real SMTP, production TLS, and PostgreSQL concurrency remain unverified.
- No commit or push was performed; all changes remain uncommitted and unpushed.

---

## Stage 9 report (UX/a11y/i18n) — complete

### Starting status
`git status --short` was run in both repositories at the start of Stage 9 (shown in the transcript). It showed only the pre-existing uncommitted Stage 0–8 remediation set.

### Changes made
- `lib/app_language.dart`
  - Language is persisted in SharedPreferences and restored on cold start.
- `lib/main.dart`
  - OS font scaling is no longer disabled.
  - Locale is wired to `appLanguage` with `AnimatedBuilder`.
  - System theme mode and a dark `ThemeData` are wired.
- `lib/driver_shell.dart`, `lib/customer/customer_shell.dart`, `lib/boss/boss_shell.dart`
  - Shells apply RTL/LTR from `appLanguage.isRtl`; customer shell now listens for language changes.
- `lib/widgets/api_state.dart`
  - Shared error state is localized and the retry target meets a 48px minimum.
- `lib/services/api_payload.dart`
  - Known order-flow truck labels are mapped explicitly before the heuristic fallback.
- `.github/workflows/ci.yml` (new)
  - Basic Flutter analyze/test CI workflow.

### Finding classification
| ID / item | Classification | Evidence |
|---|---|---|
| m1 — OS font scaling disabled | **FIXED** | `MediaQuery` override removed. |
| m2 — no dark theme | **PARTIAL** | Theme wiring added; individual screens still use a light palette. |
| m3 — language not persisted / forced LTR | **FIXED** | Persisted locale plus RTL directionality. |
| m4 — shared states hardcoded English/small targets | **FIXED** | Localized labels and 48px retry target. |
| m16 — heuristic enum mapping | **PARTIAL** | Explicit known labels first; heuristic fallback remains. |
| m30 — no CI | **FIXED** | CI workflow added. |

### Verification evidence
| Command | Result |
|---|---|
| `flutter analyze` | `No issues found!` |
| `flutter test` — pass 1 | `+40: All tests passed!` |
| `flutter test` — pass 2 | `+40: All tests passed!` |
| Backend `manage.py check` | `System check identified no issues (0 silenced).` |
| Backend `makemigrations --check --dry-run` | `No changes detected` |
| Secret scan of changed Stage 9 files | No credentials/API keys/private keys/Bearer literals found. |
| `git diff --check` (both repos) | No whitespace errors; only pre-existing LF→CRLF warnings. |

### Unverified in Stage 9
- Full dark-theme UI is not implemented; only theme wiring was added.
- Real-device / iOS behavior, release `--dart-define` HTTPS build, real SMTP, production TLS, and PostgreSQL concurrency remain unverified.
- No commit or push was performed; all changes remain uncommitted and unpushed.

---

## Stage 10 report (tests / re-audit) — complete

### Starting status
`git status --short` was run in both repositories at the start of Stage 10 (shown in the transcript). It showed only the pre-existing uncommitted Stage 0–9 remediation set.

### Deliverables
- `PROJECT_AUDIT_AFTER.md` created with before/after test counts, finding status summary, full 72-row status table, and the unverified list.
- `FIX_TRACKER.md` updated to Stage 10 complete with final baseline counts.
- No backend or frontend production code changed in Stage 10.

### Final verification evidence
| Command | Result |
|---|---|
| `flutter pub get` | Completed successfully. |
| `flutter analyze` | `No issues found!` |
| `flutter test` — pass 1 | `+40: All tests passed!` |
| `flutter test` — pass 2 | `+40: All tests passed!` |
| Backend `manage.py check` | `System check identified no issues (0 silenced).` |
| Backend `makemigrations --check --dry-run` | `No changes detected` |
| Django tests | `Found 356 test(s)` → `OK (skipped=2)` |
| `pytest -q` | `451 passed, 2 skipped, 47 subtests passed in 833.06s` |
| `git diff --check` (both repos) | No whitespace errors; only pre-existing LF→CRLF warnings. |
| Secret scan of changed files | No real secrets found. |

### Finding status summary
- FIXED: 64
- PARTIAL: 5
- DEFERRED: 2
- NOT FIXED: 1 (`C11` golden screenshots as proof)

### Unverified items
- Real-device / iOS behavior.
- Release `--dart-define` HTTPS build.
- Real SMTP and email-link click-through.
- Production TLS/deployment behavior.
- PostgreSQL concurrency.
- Full dark-theme UI.
- Golden screenshot policy remains unresolved (`C11`).

No commit, push, reset, restore, or forbidden-file modification was performed. All remediation remains uncommitted and unpushed.

---

## Backlog: password reset / forgot-password (D3)

**Status:** DEFERRED. The UI entry points were removed in Stage 5 because no safe backend reset endpoint exists yet. Do not re-add them until the backend contract below is implemented.

**Backend requirements**
1. `POST /api/password-reset/` accepts email only, always returns the same generic `200` body, and reveals nothing about account existence. Throttle per IP **and** per email.
2. Generate a single-use, hashed reset token with a short TTL (30 minutes or less), stored with an explicit expiry and invalidated on use.
3. `POST /api/password-reset/confirm/` accepts `uid`, `token`, `new_password`; applies the existing Django password policy; returns a generic invalid/expired `400` and a success `200`.
4. On success, revoke existing refresh tokens / JWT sessions for that user (or rotate a token-version field) so old sessions stop working.
5. Log only non-sensitive metadata (user id, timestamp, outcome). Never log the token, raw link, or email body.

**Frontend requirements**
1. Reintroduce “Forgot Password?” only after the endpoints exist; accept email only (no phone).
2. New-password + confirmation fields with the existing strength bar; show a generic success message and return to sign-in.
3. Add a reset route (`/reset-password?uid=&token=`) with invalid, expired, and success states; do not auto-login after reset.
4. Resend uses the same 60-second cooldown and explicit 429 handling as email verification.

**Acceptance tests**
- Unknown email and known email return the same body/status.
- Token is single-use and expires; old refresh token fails after a successful reset.
- Password policy violations return field errors; rate limiting returns 429.
- Frontend tests cover cooldown, 429 message, and absence of account enumeration hints.
