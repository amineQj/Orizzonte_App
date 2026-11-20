# PROJECT_AUDIT_AFTER.md

**Project:** ORIZZONTE (Flutter frontend + Django backend)
**Audit source:** `PROJECT_AUDIT.md`
**Re-audit date:** 2026-11-20 (Stage 10)
**Status:** All remediation remains uncommitted and unpushed. Not claimed production-ready.

## Test counts

| Suite | Before remediation | After Stage 10 | Notes |
|---|---:|---:|---|
| Flutter `flutter test` | 24 passed | 40 passed | +16 tests added across Stages 5-9. |
| Django `manage.py test` | 343 passed, 1 skipped | 356 passed, 2 skipped | SQLite lock tracebacks appear only in concurrency/error-path tests; runner status OK. |
| pytest | not run at Stage 0 baseline | 451 passed, 2 skipped, 47 subtests passed | Dev-only pytest/pytest-django added in Stage 1. |

## Verification summary
- `flutter pub get`: completed successfully.
- `flutter analyze`: `No issues found!`
- `flutter test`: `+40: All tests passed!` (run twice).
- Backend `manage.py check`: `System check identified no issues (0 silenced).`
- Backend `makemigrations --check --dry-run`: `No changes detected`
- Backend Django suite: `Found 356 test(s)` -> `OK (skipped=2)`.
- Backend pytest: `451 passed, 2 skipped, 47 subtests passed`.
- `git diff --check` (both repos): no whitespace errors; only pre-existing LF->CRLF warnings.
- Secret scan: no real secrets found in changed files.

## Finding status summary
- FIXED: 64
- PARTIAL: 5
- DEFERRED: 2
- NOT FIXED: 1 (`C11` golden screenshots as proof)

## All findings (72 rows)

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

## Unverified items
- Real-device / iOS behavior.
- Release `--dart-define` HTTPS build.
- Real SMTP delivery and email-link click-through.
- Production TLS/deployment behavior.
- PostgreSQL concurrency.
- Full dark-theme UI.
- Golden screenshot policy remains unresolved (`C11`).
