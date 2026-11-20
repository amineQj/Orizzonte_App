# ORIZZONTE Project Audit

**Audit date:** 2026-11-19  
**Scope:** Flutter frontend `C:\Users\THINKPAD\Desktop\Orizzonte_App` and Django backend `C:\Users\THINKPAD\Desktop\orizzonte-backend-app`.  
**Method:** Static source review of routes, views, serializers, services, screens, tests, settings, and platform manifests. Backend tests were **not executed** during this audit; "Tested?" reflects whether a discovered automated test exists. Line numbers are from the audited snapshot and may drift after edits.  
**Changes made:** None. No fixes, commits, or pushes were performed.

---

## 1. Executive Summary

- **Total endpoints:** 46 routed API method/path pairs, plus Django admin. A further 6 definitions exist in `authentication/urls.py` but are **not routed** (dead code).
- **Total screens:** 37 page/shell/screen classes in `lib/` (35 reachable, 2 dead code).
- **Connected endpoints:** 42 of 46 have a Flutter `ApiService`/service method. Only 4 agent endpoints are entirely unwired. However, several connected methods are **not called by any reachable screen** (signup, email verification, resend verification).
- **Broken/missing:** 12 critical, 26 major, and 34 minor findings (72 total).
- **Overall assessment:** **Critical**. The app works for the narrow happy path that was manually exercised (login → profile completion → document upload → submit → boss approve), but it has authentication bypasses, role-routing errors, fake registration/OTP/reset flows, demo-data fallbacks on API failure, a non-functional release configuration, and destructive one-tap boss actions without server-side completeness enforcement in the UI layer.

The most important message: the project is **not production-ready**. Several features that appear complete in screenshots are either fake, client-side-only, or silently fall back to hardcoded data.

---

## 2. Backend Endpoints (Complete List)

Permission shorthand: `Bearer` = JWT via DRF; `AgentKey` = `X-Agent-Key`; role checks from `missions/permissions.py` and `drivers/permissions.py`.

### 2.1 Accounts / authentication (10)

| # | Method | Path | Permission | Request → Response | Implemented? | Tested? | Notes |
|---|--------|------|------------|--------------------|--------------|---------|-------|
| 1 | POST | `/api/signup/` | public | `{username,email,password,role?}` → `{message,user}` | ✅ `accounts/views.py:143-186` | ✅ `accounts/tests.py:73-165,725-754` | Email failure swallowed; returns 201 even if verification email fails (`:172-186`). No throttle. |
| 2 | GET | `/api/verify-email/?uid=&token=` | public | query params → JSON/HTML `{message}` | ✅ `accounts/views.py:206-278` | ✅ `accounts/tests.py:172-217,611-657` | Token in URL query string; `SITE_URL` in `.env:27` is a private LAN address. |
| 3 | POST | `/api/resend-verification/` | public, scoped throttle | `{email}` → `{message}` | ✅ `accounts/views.py:281-321` | ✅ `accounts/tests.py:348-412` | Email failure swallowed. |
| 4 | POST | `/api/token/` | public | `{email,password}` → `{id,username,email,role,access,refresh}` | ✅ `accounts/views.py:324-347` | ✅ `accounts/tests.py:224-275,665-718` | **No throttle** → brute-force risk. |
| 5 | POST | `/api/token/refresh/` | public | `{refresh}` → `{access,refresh}` | ✅ SimpleJWT via `accounts/urls.py:41` | ✅ `accounts/tests.py:307-325,696-718` | Rotation + blacklist enabled. No throttle. |
| 6 | POST | `/api/logout/` | Bearer, authenticated | `{refresh}` → `{message}` | ✅ `authentication/views.py:136-168` | ✅ `accounts/tests.py:327-341,703-718` | Requires a *valid access token*; expired access + valid refresh cannot log out. |
| 7 | GET | `/api/users/me/` | Bearer, authenticated | — → `UserRO` | ✅ `accounts/views.py:350-367` | ✅ `accounts/tests.py:290-305,689-694` | OK. |
| 8 | GET | `/api/users/employees/` | Bearer, boss | — → `[DriverListRO]` | ✅ `accounts/views.py:374-392` | ✅ `accounts/tests.py:464-505` | No pagination. |
| 9 | GET | `/api/users/employees/<pk>/` | Bearer, boss | — → `DriverDetailRO` | ✅ `accounts/views.py:395-420` | ✅ `accounts/tests.py:464-488` | OK. |
| 10 | DELETE | `/api/users/employees/<pk>/` | Bearer, boss | — → `{message}` | ✅ `accounts/views.py:422-434` | ✅ `accounts/tests.py:484-493` | Returns 200 instead of 204. |

### 2.2 Missions / pricing / negotiation (21)

| # | Method | Path | Permission | Implemented? | Tested? | Notes |
|---|--------|------|------------|--------------|---------|-------|
| 11 | GET | `/api/pricing/rules/` | Bearer, authenticated | ✅ `missions/views.py:184-200` | ✅ `test_pricing_api.py:162-171` | GET writes DB by seeding default config (`pricing_services.py:106-118`). |
| 12 | GET | `/api/pricing/config/` | Bearer, boss | ✅ `pricing_config_views.py:20-30` | ✅ `test_pricing_config_api.py:31-44` | Same GET-side-effect. |
| 13 | POST | `/api/pricing/config/update/` | Bearer, boss, 5/min | ✅ `pricing_config_views.py:33-69` | ✅ `test_pricing_config_api.py:46-163` | Re-raises non-DRF exceptions → possible 500 (`:52-64`). |
| 14 | POST | `/api/missions/estimate/` | Bearer, client | ✅ `missions/views.py:90-151` | ✅ `test_pricing_api.py:37-200` | Quote TTL 30 min; quote IDs single-use. |
| 15 | POST | `/api/missions/confirm/` | Bearer, client | ✅ `missions/views.py:154-181` | ✅ `test_pricing_api.py:203-355` | OK. |
| 16 | GET | `/api/missions/client/my/` | Bearer, client | ✅ `missions/views.py:261-293` | ⚠️ Only untracked `test_client_missions_api.py` | Paginated 50/page; frontend reads only page 1. |
| 17 | GET | `/api/missions/available/` | Bearer, driver | ✅ `missions/views.py:207-231` | ✅ `test_missions_blocking.py:84-91` | No pagination; exposes client `phone_number` to all drivers. |
| 18 | GET | `/api/missions/my/` | Bearer, driver | ✅ `missions/views.py:234-250` | ✅ `test_missions_blocking.py:84-91` | No pagination. |
| 19 | POST | `/api/missions/<pk>/accept/` | Bearer, approved driver | ✅ `missions/views.py:296-339` | ✅ `test_missions_blocking.py:29-82` | 409 when already taken/not approved. Busy-check is concurrency-racy. |
| 20 | POST | `/api/missions/<pk>/start/` | Bearer, approved driver | ✅ `missions/views.py:342-382` | ✅ `test_missions_blocking.py:45-82` | OK. |
| 21 | POST | `/api/missions/<pk>/complete/` | Bearer, driver | ✅ `missions/views.py:385-419` | ✅ `test_missions_blocking.py:129-196` | OK. |
| 22 | GET | `/api/missions/<pk>/negotiation/` | Bearer, client or approved driver | ✅ `negotiation_views.py:45-58` | ✅ `test_negotiation_accept_decline.py:276-343` | Boss intentionally gets 403. |
| 23 | POST | `/api/missions/<pk>/negotiation/offer/` | Bearer, client or approved driver | ✅ `negotiation_views.py:61-81` | ✅ `test_negotiation_open.py`, `test_negotiation_offers.py` | Max 3 offers, idempotency key enforced. |
| 24 | POST | `/api/missions/<pk>/negotiation/accept/` | Bearer, client or approved driver | ✅ `negotiation_views.py:84-108` | ✅ `test_negotiation_accept_decline.py:30-177` | Returns `{negotiation,mission}`. |
| 25 | POST | `/api/missions/<pk>/negotiation/decline/` | Bearer, client or approved driver | ✅ `negotiation_views.py:111-124` | ✅ `test_negotiation_accept_decline.py:179-274` | OK. |
| 26 | GET | `/api/missions/all/` | Bearer, boss | ✅ `missions/views.py:426-449` | ⚠️ Status/permissions only; payload tests in undiscovered `missions/tests/test_views.py` | `?status=nonsense` silently returns `[]`. No pagination. |
| 27 | POST | `/api/missions/<pk>/assign/` | Bearer, boss | ✅ `missions/views.py:452-502` | ✅ `test_missions_blocking.py:94-126` | OK. |
| 28 | POST | `/api/missions/<pk>/cancel/` | Bearer, boss | ✅ `missions/views.py:553-568` | ❌ **Untested** | Destructive, untested. |
| 29 | DELETE | `/api/missions/<pk>/delete/` | Bearer, boss | ✅ `missions/views.py:571-584` | ❌ **Untested** | Docs wrongly say POST; real method is DELETE. Returns 200. |
| 30 | GET | `/api/missions/employee/<pk>/` | Bearer, boss | ✅ `missions/views.py:534-550` | ❌ **Untested** | Invalid `pk` returns `200 []`; N+1 queries; no pagination. |
| 31 | GET | `/api/missions/dashboard/` | Bearer, boss | ✅ `missions/views.py:505-531` | ⚠️ Status/permissions only; data tests in undiscovered `missions/tests/test_dashboard.py` | OK live shape. |

### 2.3 Drivers / verification / AI agent (15)

| # | Method | Path | Permission | Implemented? | Tested? | Notes |
|---|--------|------|------------|--------------|---------|-------|
| 32 | GET | `/api/drivers/me/profile/` | Bearer, driver | ✅ `drivers/views.py:76-89` | ✅ `test_profiles.py:56-81` | Returns authoritative `missing.info` / `missing.documents`. |
| 33 | PATCH | `/api/drivers/me/profile/` | Bearer, driver | ✅ `drivers/views.py:91-98` | ✅ `test_profiles.py:83-141,299-315` | Allowlist: 7 personal fields. |
| 34 | POST | `/api/drivers/me/documents/` | Bearer, driver, throttle | ✅ `drivers/views.py:101-124` | ✅ `test_documents.py:37-131` | Multipart `{type,file}`. |
| 35 | POST | `/api/drivers/me/submit/` | Bearer, driver | ✅ `drivers/views.py:127-150` | ✅ `test_profiles.py:196-222` | 409 on incomplete. |
| 36 | POST | `/api/verification/check/` | Bearer, driver | ✅ `verification_views.py:103-145` | ✅ `test_verification.py:272-478` | Returns 202 + `task_id`. **No throttle**; unbounded executor/task dict. |
| 37 | GET | `/api/verification/status/<task_id>/` | Bearer, driver | ✅ `verification_views.py:148-184` | ✅ `test_verification.py:287-298,328-478` | Terminal failure returns **503**; frontend expects a `failed` body (unreachable branch). |
| 38 | GET | `/api/drivers/pending/` | Bearer, boss | ✅ `drivers/views.py:201-213` | ✅ `test_profiles.py:167-181` | Paginated 20/100. |
| 39 | GET | `/api/drivers/<pk>/documents/<doc_type>/` | Bearer owner/boss or AgentKey | ✅ `drivers/views.py:157-194` | ✅ `test_documents.py:134-193` | Raw private image bytes; ownership checks present. |
| 40 | POST | `/api/drivers/<pk>/approve/` | Bearer, boss | ✅ `drivers/views.py:226-240` | ✅ `test_profiles.py:225-261` | 409 `invalid_profile_transition` if not `pending_review`. UI list bypasses this gate. |
| 41 | POST | `/api/drivers/<pk>/reject/` | Bearer, boss | ✅ `drivers/views.py:243-261` | ✅ `test_profiles.py:263-286` | Requires `{reason}`. |
| 42 | GET | `/api/drivers/<pk>/` | Bearer, boss | ✅ `drivers/views.py:216-223` | ✅ `test_profiles.py:183-193` | **Does not include `missing`** — boss page must derive it. |
| 43 | GET | `/api/agent/drivers/pending/` | AgentKey, agent | ✅ `drivers/views.py:268-282` | ✅ `test_agent.py:26-100` | No pagination. **Not connected to frontend.** |
| 44 | GET | `/api/agent/drivers/<pk>/documents/<doc_type>/` | AgentKey, agent | ✅ `drivers/views.py:293-322` | ❌ URL only; functionally untested | **Not connected to frontend.** |
| 45 | POST | `/api/agent/drivers/<pk>/review/` | AgentKey, agent | ✅ `drivers/views.py:325-358` | ✅ `test_agent.py:103-209` | Auto-approve disabled by default. **Not connected to frontend.** |
| 46 | GET | `/api/agent/drivers/<pk>/` | AgentKey, agent | ✅ `drivers/views.py:285-290` | ✅ `test_agent.py:81-92` | **Not connected to frontend.** |

**Admin:** `/admin/...` — `demenagement/urls.py:21`, staff/superuser session auth, untested.

**Dead/unrouted definitions:** `authentication/urls.py:11-20` declares `/api/signup/`, `/api/token/`, `/api/token/refresh/`, `/api/logout/`, `/api/profile/` pointing at older views; not included by the root URLconf. `core/settings.py` and `core/urls.py` are also unused scaffold.

**Critical backend configuration findings:** weak fallback `SECRET_KEY` (`demenagement/settings.py:19-22`), `DEBUG=True` default and in `.env:15` (`:24`), `ALLOWED_HOSTS=*` (`:28-30`, `.env:20`), `CORS_ALLOW_ALL_ORIGINS=True` **with** `CORS_ALLOW_CREDENTIALS=True` (`:186-191`), debug OCR tied to `DEBUG` (`:273-277`, `verification_views.py:130-134`), plaintext SMTP credentials in `.env:38-44`, `django-cors-headers` missing from `requirements.txt`, and SQLite + DB backup files present in the workspace.

---

## 3. Frontend Screens (Complete List)

`#` | Screen | File | Connected to API? | Uses Mock Data? | Issues
---|---|---|---|---|---
1 | Onboarding / role entry | `lib/main.dart:157` | No | Remote images | Shell chosen from tapped tile, not login role (`main.dart:633-643,730-737`).
2 | Splash | `lib/splash_screen.dart:14` | No | No | Always navigates to `/onboarding`; ignores restored session.
3 | AuthFlow host | `lib/auth_flow.dart:212` | Indirect | `demoRole` | OTP success bypasses auth (`auth_flow.dart:361-364`).
4 | Login | `lib/auth_flow.dart` | ✅ `POST /api/token/` | No | Only `boss` role special-cased (`auth_flow.dart:1082-1085`).
5 | Signup | `lib/auth_flow.dart:1409` | ❌ | Fake | Button only calls `onNext()`; real `signup()` never used.
6 | OTP | `lib/auth_flow.dart:1523` | ❌ | Hardcoded `123456` | Code displayed in UI (`:1579`); resend is cosmetic (`:1511-1521`).
7 | Forgot password | `lib/auth_flow.dart:1774` | ❌ | Navigation only | No backend reset endpoint exists.
8 | Reset password | `lib/auth_flow.dart:1887` | ❌ | Navigation only | Advertised but non-functional.
9 | CustomerShell | `lib/customer/customer_shell.dart:49` | Via children | No | Forces LTR in Arabic (`:51-53`).
10 | Customer home | `lib/customer/customer_home_page.dart` | ✅ repository | 4 demo missions on error | Demo banner (`:109-110`).
11 | Customer profile | `lib/customer/customer_profile_page.dart` | Partial | Static content | Limited real data.
12 | Customer mission details | `lib/customer/customer_mission_details_page.dart` | ✅ repository | No | Wrong pickup/delivery mapping in `mission_repository.dart:271-308`; no-op tap (`:649`).
13 | Customer service catalog | `lib/customer_screen.dart:14` | ❌ | Hardcoded categories | Static catalog.
14 | OrderFlow | `lib/order_flow.dart:22` | Local state | Hardcoded trucks | Suspect fuel capacities `240000L` (`:318`); empty depannage step (`:1120-1122`).
15 | Route/time | `lib/route_time_screen.dart:187` | Public OSRM | Haversine fallback | Bypasses `ApiService`; non-hermetic test.
16 | Send order | `lib/send_order_screen.dart` | ✅ estimate/confirm | Local form | Edit callbacks just pop (`send_order_screen.dart:119-121`).
17 | Order confirmation | `lib/order_confirmation_screen.dart` | Consumes quote | No | Confirm enabled without estimate (`:182-207,524-581`).
18 | Negotiation | `lib/negotiation/negotiation_page.dart:22` | ✅ 4 endpoints | No | `minStep`/TTL not enforced; opens with default `client` role; polling swallows errors.
19 | DriverShell | `lib/driver_shell.dart:168` | Via children | No | Forces LTR (`:175-177`).
20 | Driver home | `lib/driver_home_page.dart` | ✅ profile/store | 10 demo missions on error | No-op card tap (`:727`); filters do nothing (`:1034-1263`).
21 | Driver missions | `lib/driver_missions_page.dart` | ✅ store | Demo fallback | Accept/Start both set `In Progress`.
22 | Driver profile | `lib/driver_profile_page.dart` | ✅ profile/docs/submit | Hardcoded slot list | Verified results not restored; `_busy` leak; cosmetic delay (`:1132`).
23 | Driver Home (old) | `lib/driver_home_screen.dart:36` | ❌ | Static | **Dead code**, no call sites; no-op tap (`:490`).
24 | Driver wallet | `lib/driver_wallet_page.dart:20` | ❌ | **100% fabricated** balance/stats/transactions (`:51-57,107-118`) | **Unreachable**; Withdraw/History/Invoice no-op (`:151`).
25 | VerificationFlow | `lib/verification_flow_screen.dart:86` | Via children | No | 3-step IndexedStack.
26 | Verification identity | `lib/verification_identity_screen.dart:254` | ✅ upload/check/poll | No | OK.
27 | Verification selfie | `lib/verification_selfie_screen.dart:237` | ✅ upload/check/poll | No | OK.
28 | Verification vehicle | `lib/verification_vehicle_screen.dart:277` | ✅ upload/check/poll | No | OK.
29 | BossShell | `lib/boss/boss_shell.dart:48` | Via children | No | Forces LTR (`:55-57`).
30 | Boss dashboard | `lib/boss/boss_dashboard_page.dart:25` | ✅ dashboard | Stale fallback stats keys | `boss_repository.dart:74-79` keys don't match live keys.
31 | Boss requests | `lib/boss/boss_requests_page.dart:749` | ✅ repository | Demo missions on error | Demo banner (`:71-72`).
32 | Boss mission detail | `lib/boss/boss_mission_detail_page.dart` | ✅ all-missions scan + negotiation | No | Backend has no `GET /api/missions/<id>/`; documented workaround (`:19-22`).
33 | Boss drivers | `lib/boss/boss_drivers_page.dart` | ✅ pending/employees | 2 demo pending drivers | **One-tap Approve/Reject** (`:207-219,233-247`); search only filters cards; remove without confirmation.
34 | Boss driver detail | `lib/boss/boss_driver_detail_page.dart` | ✅ detail/docs/history/approve/reject | No | Approve gated on status only; mission-history errors silently ignored (`:127-133`).
35 | Boss revenue | `lib/boss/boss_revenue_page.dart:41` | ❌ direct | Computes revenue client-side | Ignores backend `monthly_revenue`/`monthly_overview`.
36 | Boss settings | `lib/boss/boss_settings_page.dart:63` | ❌ for pricing/account save | SharedPreferences only | Fake Save buttons; sign-out leaves refresh token.
37 | BossPricingScreen | `lib/screens/boss_pricing_screen.dart:95` | ✅ real config API | No | Password guard only on save; validation gaps.

**Notification feature (support screen):** `lib/notification/mission_notifications_page.dart` — local preferences only; `mission_notification_service.dart:30-61` throws `UnsupportedError` for every remote-push operation.

---

## 4. Endpoints NOT Connected to Frontend

| # | Endpoint | Reason | Impact |
|---|----------|--------|--------|
| 1 | GET `/api/agent/drivers/pending/` | No `ApiService` method; AI-agent integration intentionally not wired | Agent review workflow cannot be driven from the app (likely by design). |
| 2 | GET `/api/agent/drivers/<pk>/documents/<doc_type>/` | Same | No agent document preview in app. |
| 3 | POST `/api/agent/drivers/<pk>/review/` | Same | No agent decision submission. |
| 4 | GET `/api/agent/drivers/<pk>/` | Same | No agent detail view. |
| 5 | `/admin/...` | Django admin only | No in-app admin surface. |
| 6 | Dead routes in `authentication/urls.py:11-20` | Not included by root URLconf | Confusing duplicate definitions; harmless but should be deleted. |

**Connected but unused by any reachable screen:** `POST /api/signup/` (`api_service.dart:201-220`), `GET /api/verify-email/` and `POST /api/resend-verification/` (`api_service.dart:243-250`). The UI implements fake signup/OTP instead.

**Connected but incomplete:** `GET /api/verification/status/<task_id>/` is called, but the frontend's `failed` decision branch (`document_verification_service.dart:90-95`) is unreachable because the backend returns HTTP 503 for terminal failure.

---

## 5. Screens Using Mock/Demo Data

| # | Screen / File | Mock Data | Should Use |
|---|---------------|-----------|------------|
| 1 | Driver home `driver_mission_store.dart:195-236` | 10 hardcoded missions on role mismatch or **any API error** | `GET /api/missions/available/` / `/my/` only; show error instead of fake records |
| 2 | Driver missions `driver_missions_page.dart` | Same store fallback | Same |
| 3 | Customer home `customer/mission_repository.dart:249-252` | 4 hardcoded missions on API error | `GET /api/missions/client/my/` |
| 4 | Boss requests `customer/mission_repository.dart:216-254` | Demo missions on error | `GET /api/missions/all/` |
| 5 | Boss drivers `boss/boss_repository.dart:142-159` | `Demo Driver One/Two` | `GET /api/drivers/pending/` |
| 6 | Boss dashboard `boss/boss_repository.dart:72-83` | Stale stats keys `total_missions`, `active_missions`, `pending_drivers` | `GET /api/missions/dashboard/` live keys |
| 7 | Driver wallet `driver_wallet_page.dart:51-57,107-118` | Fake balance `25,000 DZD`, fake `+12.5%`, 5 fake transactions | No backend wallet exists — remove screen or implement API |
| 8 | Signup/OTP `auth_flow.dart:1409-1534,1579` | No API call; hardcoded `123456` | `POST /api/signup/`, `GET /api/verify-email/`, `POST /api/resend-verification/` |
| 9 | Forgot/Reset `auth_flow.dart:1774-1893` | Navigation only | No backend endpoint exists — remove or build endpoint |
| 10 | Boss settings `boss_settings_page.dart:63-87` | Local SharedPreferences pricing/account | Real `BossPricingScreen` / user API |
| 11 | Boss revenue `boss_revenue_page.dart:41-52` | Client-side revenue calculation | Backend `monthly_revenue`, `monthly_overview` |
| 12 | Notifications `mission_notification_service.dart:30-61` | Push backend stub throws | Real push service or remove preferences |
| 13 | E2E harness `lib/e2e_harness.dart:17-28` | Hardcoded QA credentials + driver id 52 | Delete from shipped `lib/` |
| 14 | Service catalog `customer_screen.dart:14-18`, `order_flow.dart:22-50` | Static categories/truck types | No backend catalog exists — acceptable static config, but document it |

---

## 6. Broken Buttons / Features

| # | Screen | Button/Feature | Issue | Severity |
|---|--------|----------------|-------|----------|
| 1 | Signup | Create account | Only `widget.onNext()`; no API call (`auth_flow.dart:1409-1418`) | Critical |
| 2 | OTP | Verify / Resend | Hardcoded `123456`; no verification API (`auth_flow.dart:1523-1534,1511-1521`) | Critical |
| 3 | Forgot/Reset | Continue / Reset | Navigation-only; no backend route (`auth_flow.dart:1774-1893`) | Critical |
| 4 | Onboarding/login | Role selection | Driver can land in CustomerShell and vice versa (`main.dart:633-643,730-737`; `auth_flow.dart:1082-1085`) | Critical |
| 5 | Boss drivers | Approve / Reject | One tap, no completeness/submission check, no confirmation, hardcoded reject reason (`boss_drivers_page.dart:207-219,233-247`) | Critical |
| 6 | Driver home | Mission card tap | `onTap: () {}` (`driver_home_page.dart:727`) | Major |
| 7 | Driver home | Filters | Chips mutate sheet-local state; Apply only pops (`driver_home_page.dart:1034-1263`) | Major |
| 8 | Send order / confirmation | Edit route/time/vehicle | Pop to wrong screen or onboarding (`send_order_screen.dart:119-121`; `order_confirmation_screen.dart:363,401,446`) | Major |
| 9 | Order confirmation | Confirm | Enabled without estimate/quote (`order_confirmation_screen.dart:182-207,524-581`) | Major |
| 10 | Boss settings | Save Pricing / Save Account | SharedPreferences only (`boss_settings_page.dart:63-87`) | Major |
| 11 | Boss settings | Sign out | Clears `AuthSession` but leaves refresh token (`auth_service.dart:15,51`) | Major |
| 12 | Driver profile | Upload flow | `_busy` leak on picker cancel; polling not cancelled on dispose; results lost on reopen (`driver_profile_page.dart:1071-1191,1002-1030`) | Major |
| 13 | Negotiation | Send/Accept/Decline | TTL/expiry and `minStep` ignored; accept/decline not idempotent (`negotiation_page.dart:128-155,305-383,498-525`) | Major |
| 14 | Driver wallet | Withdraw/History/Invoice | All `onTap: () {}` in unreachable screen (`driver_wallet_page.dart:151`) | Minor |
| 15 | Customer mission details | Unknown tap target | `onTap: () {}` (`customer_mission_details_page.dart:649`) | Minor |
| 16 | Notifications | Test notification | Local only; remote push throws (`mission_notification_service.dart:30-61`) | Major |
| 17 | Named routes | `/customer`, `/boss` | Not registered in `main.dart:148-152` but referenced at `:640,649,743` | Minor |

---

## 7. UI/UX Issues

| # | Screen | Issue | Recommendation |
|---|--------|-------|----------------|
| 1 | All screens | OS font scaling disabled globally (`main.dart:139-145` `textScaler: noScaling`) | Respect `MediaQuery.textScalerOf(context)`; accessibility blocker. |
| 2 | All screens | No dark theme; `MaterialApp` has no `locale` wiring (`main.dart:147`) | Add theme mode + `MaterialApp.locale` from `appLanguage`. |
| 3 | Shells | Language not persisted and shells force LTR (`app_language.dart:1-14`; `driver_shell.dart:175-177`, `customer_shell.dart:51-53`, `boss_shell.dart:55-57`) | Persist locale and apply `Directionality` per shell. |
| 4 | Shared states | `api_state.dart` hardcodes English and uses <44px retry targets (`api_state.dart:68,79-93,122-133`) | Localize strings; enlarge tap targets. |
| 5 | Driver home | Dead affordance: card looks tappable but is not (`driver_home_page.dart:727`) | Wire to mission detail or remove hover/pressed styling. |
| 6 | Driver home | Filter sheet is decorative (`driver_home_page.dart:1034-1263`) | Return a filter model from `Navigator.pop` and apply it. |
| 7 | Driver missions | Origin/destination shown as raw coordinates (`driver_mission_store.dart:178-179`) | Show human-readable addresses from backend. |
| 8 | Send order | Typo "Enter your namber" (`send_order_screen.dart:423`) | Fix copy. |
| 9 | Order flow | Fuel capacity `240000L/270000L/300000L` vs `18000L` (`order_flow.dart:318`) | Verify catalogue data. |
| 10 | OTP | 6×46px fields + 10px gaps in 24px padding can overflow small screens (`auth_flow.dart:1584-1648`) | Use flexible widths / `LayoutBuilder`. |
| 11 | Driver profile | License-expiry picker forbids past dates (`driver_profile_page.dart:918-927`) | Allow past dates for already-expired licenses, with validation. |
| 12 | Order flow | Depanage capacity step is `SizedBox.shrink()` (`order_flow.dart:1120-1122`) | Remove dead step. |
| 13 | All list screens | Demo-data banners are the only warning that data is fake (`widgets/api_state.dart:100-122`) | Prefer error state + retry; never silently show fabricated records. |
| 14 | Boss driver detail | Mission-history failures are silent (`boss_driver_detail_page.dart:127-133`) | Show inline error/retry. |
| 15 | Auth | Hardcoded OTP hint shown in UI (`auth_flow.dart:1579`) | Remove immediately. |

---

## 8. Business Logic Flaws

| # | Feature | Issue | Expected Behavior |
|---|---------|-------|-------------------|
| 1 | Release connectivity | `http://127.0.0.1:8000` hardcoded (`api_service.dart:22`, `pricing_service.dart:44`); no Android cleartext or iOS ATS exception | Configurable base URL + platform network config; physical devices cannot reach host loopback. |
| 2 | Boss approval | List-page Approve has no status/completeness/document check (`boss_drivers_page.dart:207-219`) | Only `pending_review` drivers, after document inspection, with confirmation. Backend already returns 409; UI should mirror it. |
| 3 | Boss approval | Detail page `_canApprove` checks only `status == 'pending_review'` (`boss_driver_detail_page.dart:183-188`), ignores document load errors | Require all 5 documents loaded and no `missing` items before enabling. |
| 4 | Driver submit | Main profile submit gate uses `missing` lists only (`driver_profile_page.dart:109-172,1201-1212`), not the verification decisions from `_results` | Require every document's final decision to be `ACCEPT`/`MANUAL_REVIEW`. |
| 5 | Verification | Upload happens before quality check; rejected files remain stored and counted as uploaded (`document_verification_service.dart:59-63`) | Only ACCEPT/MANUAL_REVIEW should mark a slot complete; REJECT must require retake. |
| 6 | Verification | Results are session-local; reopening the page loses them (`driver_profile_page.dart:1002-1030`) | Persist/reload decision state from backend. |
| 7 | Mission lifecycle | Accepted and started missions both become `In Progress`; local store overwrites backend status (`driver_mission_store.dart:120-124,129-151`) | Preserve backend `status`/`display_status`; distinguish accepted vs in-progress. |
| 8 | Driver accept | Client-side-only gate, no confirmation dialog (`driver_home_page.dart:142-171,923`) | Rely on backend 409 handling and add explicit confirmation. |
| 9 | Negotiation | `minStep` displayed but never validated client-side (`negotiation_page.dart:128-155,480-490`) | Enforce the same rules as backend before sending. |
| 10 | Negotiation | TTL/hold expiry rendered but actions ignore it (`negotiation_page.dart:305-383,498-525`) | Disable Send/Accept/Decline when closed/expired and refresh on expiry. |
| 11 | Negotiation | Idempotency key reused after amount change; accept/decline have none (`negotiation_page.dart:52-54,156-225`) | Regenerate key when payload changes; add keys for accept/decline. |
| 12 | Pricing | Confirm enabled without authoritative quote (`order_confirmation_screen.dart:182-207,524-581`) | Require a valid non-expired quote before mission creation. |
| 13 | Pricing config | Frontend validation gaps; no upper bounds/sanity (`boss_pricing_screen.dart:161-220`) | Mirror backend validation in UI. |
| 14 | Pricing config | GET endpoints seed DB (`pricing_services.py:106-118`) | Move seeding to management command/migration. |
| 15 |Auth | Static `ApiService.onUnauthorized` overwritten by every `AuthService()` construction (`auth_service.dart:8-11`, `main.dart:118`) | Register once explicitly or use DI. |
| 16 | Session restore | `AuthSession.load()` ignored by splash (`main.dart:113-118`, `splash_screen.dart:14-18`) | Route directly to role shell when a valid token exists. |
| 17 | Sign-out | Refresh token not cleared (`boss_settings_page.dart:89-95`) | Call `POST /api/logout/` and delete both tokens. |
| 18 | Token storage | Tokens in `SharedPreferences` (`auth_service.dart:35-38`) | Use platform secure storage. |
| 19 | Concurrency | Driver-busy check locks only mission row (`missions/services.py:328-358`) | Lock a driver-level resource or use a DB constraint. |
| 20 | Privacy | Client `phone_number` exposed to every driver (`missions/serializers.py:298-329`) | Expose only to assigned driver after acceptance. |
| 21 | Backend config | `DEBUG=True`, `ALLOWED_HOSTS=*`, wildcard CORS with credentials, weak fallback secret (`demenagement/settings.py:19-30,186-191`) | Fail-fast production settings. |
| 22 | Verification privacy | `?debug=1` can expose raw OCR text when `DEBUG=True` (`verification_views.py:130-134`) | Disable outside explicit dev flag. |
| 23 | Verification tasks | In-memory `_TASKS` never pruned; unbounded executor; no throttle (`verification_views.py:27-29,103-145`) | Bounded queue + TTL cleanup + throttling. |
| 24 | Error contracts | Mixed `message` / `detail` / `detail+code` / custom permission dicts | Standardize on `{detail, code, ...}`. |
| 25 | API errors | `_fromResponse` treats unknown success-body keys as field errors (`api_service.dart:51-109`) | Only map keys inside `errors`/serializer field objects. |
| 26 | API errors | Failed verification task returns 503, frontend expects `failed` body (`verification_views.py:170-179` vs `document_verification_service.dart:90-95`) | Align status/body contract. |

---

## 9. Critical Bugs (Must Fix Immediately)

1. **Signup, OTP, and password reset are fake** — `auth_flow.dart:1409-1534,1774-1893`. Hardcoded `123456` is displayed in the UI. Real signup/verification endpoints exist but are unused.
2. **Role-based routing is broken** — a driver logging in through the customer tile gets `CustomerShell`, and vice versa (`main.dart:633-643,730-737`; `auth_flow.dart:1082-1085`).
3. **Release app cannot reach the backend** — loopback base URL + missing Android cleartext/iOS ATS configuration (`api_service.dart:22`; platform manifests).
4. **One-tap boss approval from the drivers list** with no completeness check or confirmation (`boss_drivers_page.dart:207-219`).
5. **Verification results are not authoritative** client-side; rejected documents remain uploaded and the submit gate ignores quality decisions (`driver_profile_page.dart:109-172,1201-1212`; `document_verification_service.dart:59-63`).
6. **Any API error silently substitutes demo missions/drivers** (`driver_mission_store.dart:106-111`, `mission_repository.dart:56-89,216-254`, `boss_repository.dart:72-83`).
7. **Backend production config is unsafe** — `DEBUG=True`, `ALLOWED_HOSTS=*`, wildcard CORS with credentials, weak fallback secret key, debug OCR exposure (`demenagement/settings.py:19-30,186-191,273-277`).
8. **No login/signup/refresh throttling** (`accounts/views.py:158,346`; `settings.py:151-156` defines rates but no default throttle class).
9. **Untested destructive backend endpoints** — mission cancel/delete/employee history and agent document route (`missions/views.py:534-584`; `drivers/views.py:293-322`).
10. **Hardcoded QA credentials and driver id in shipped `lib/e2e_harness.dart:17-28`**.
11. **Golden screenshots are false proof** — canned fixtures, three screens, no interaction/logic assertions; failure artifacts were followed by golden regeneration (`test/ui_screens_test.dart:12-208`, `test/failures/*`, `test/goldens/*`).
12. **Mission lifecycle is broken locally** — Accept and Start both yield `In Progress`; backend status overwritten (`driver_mission_store.dart:120-124,129-151`).

---

## 10. Major Issues (Should Fix Soon)

1. Client mission history fetches only page 1 (`api_service.dart:404-407` vs backend pagination).
2. Customer mission details map client name → pickup and arrival coords → delivery (`mission_repository.dart:271-308`).
3. Boss local pricing/account controls save only to SharedPreferences (`boss_settings_page.dart:63-87`).
4. Driver-home filters do nothing (`driver_home_page.dart:1034-1263`).
5. Verification failed-task branch is unreachable due to 503 (`document_verification_service.dart:90-95`).
6. Verification `_busy` leak and uncancelled polling (`driver_profile_page.dart:1071-1191`).
7. Order confirmation allows submission without a quote (`order_confirmation_screen.dart:182-207,524-581`).
8. Negotiation `minStep`, TTL, and idempotency gaps (`negotiation_page.dart:128-225,305-383,498-525`).
9. Sign-out leaves refresh token usable (`boss_settings_page.dart:89-95`).
10. Tokens stored in non-secure storage (`auth_service.dart:35-38`).
11. Remote push notifications unimplemented but UI exposed (`mission_notification_service.dart:30-61`).
12. Email delivery failures swallowed while signup reports success (`accounts/views.py:172-186,307-321`).
13. Client phone numbers exposed to all drivers (`missions/serializers.py:298-329`).
14. Unbounded verification task store/executor (`verification_views.py:27-29`).
15. Pricing config update can 500 on unexpected exceptions (`pricing_config_views.py:52-64`).
16. Missing pagination on 6 list endpoints (backend report §M7).
17. API documentation drift: docs say POST for mission delete, actual is DELETE (`API_DOCS.md:319` vs `missions/urls.py:102`).
18. `django-cors-headers` missing from `requirements.txt`.
19. Test discovery misses `missions/tests/` (no `__init__.py`); `test_client_missions_api.py` is untracked.
20. Global static unauthorized handler overwritten by every `AuthService()` construction.
21. Broken order-review Edit callbacks (`send_order_screen.dart:119-121`; `order_confirmation_screen.dart:363,401,446`).
22. Driver accept has no confirmation and only client-side gating.
23. Boss detail ignores mission-history errors.
24. Dead route names `/customer` and `/boss` not registered in `main.dart:148-152`.
25. Session restore ignored at startup.
26. Suspect fuel-capacity catalogue values affecting quotes (`order_flow.dart:318`).

---

## 11. Minor Issues (Nice to Have)

1. OS font scaling disabled (`main.dart:139-145`).
2. No dark theme (`main.dart:147`).
3. Language not persisted; shells force LTR in Arabic.
4. Shared error/loading widgets hardcode English and use small tap targets (`api_state.dart`).
5. No-op taps in `driver_home_page.dart:727`, `driver_home_screen.dart:490`, `driver_wallet_page.dart:151`, `customer_mission_details_page.dart:649`.
6. Dead screens: `driver_home_screen.dart`, `driver_wallet_page.dart`.
7. Raw coordinate display in driver mission cards (`driver_mission_store.dart:178-179`).
8. Typo "Enter your namber" (`send_order_screen.dart:423`).
9. OTP row overflow risk on narrow devices (`auth_flow.dart:1584-1648`).
10. License-expiry picker forbids past dates (`driver_profile_page.dart:918-927`).
11. Depanage capacity step is empty (`order_flow.dart:1120-1122`).
12. Cosmetic 2-second delay in verification UI (`driver_profile_page.dart:1132`).
13. `debugPrint`-only upload error detail (`api_service.dart:330-331`).
14. Over-broad field-error classification (`api_service.dart:51-109`).
15. Auth endpoints send Bearer token when one exists (`api_service.dart:192-236`).
16. Heuristic enum mapping in `api_payload.dart:13-60` can silently misclassify unusual truck labels.
17. Direct `http` usage bypassing `ApiService` in route/pricing services.
18. Dead scaffold: `authentication/urls.py`, `authentication/views.py:80-188`, `core/settings.py`, `core/urls.py`, `users` app.
19. DELETE endpoints return 200 instead of 204 (`accounts/views.py:431-434`; `missions/views.py:579-582`).
20. GET requests write DB by seeding pricing config.
21. Invalid `?status=` filter silently returns `[]` (`missions/views.py:441-449`).
22. `GET /api/missions/employee/<pk>/` returns `200 []` for invalid pk and has N+1 queries.
23. Verification status allows `user_id=None` tasks to be read by any driver (`verification_views.py:157`).
24. Terminal verification failure returns 503 instead of a task result.
25. Logout requires valid access token even with valid refresh token.
26. Verification token in URL query string (history/log leakage).
27. Internal LAN `SITE_URL` in `.env:27`.
28. SQLite default + DB backup files in workspace.
29. Non-hermetic OSRM test (`routing_service_test.dart:40-48`).
30. No CI configuration; `pubspec.yaml:24-27` has no integration-test dependencies.
31. Boss list search filters only cards, not summary sections (`boss_drivers_page.dart:49-59,125-129`).
32. Boss list Remove has no confirmation (`boss_drivers_page.dart:339-363`).
33. Negotiation opens with default `client` role even from driver context (`customer_mission_details_page.dart:250,268`).
34. Stale TODO in `auth_session.dart:4-7` contradicting wired login.

---

## 12. Recommendations

### Priority 1 — Block release until fixed
- Replace fake signup/OTP/reset with real API flows; remove hardcoded `123456` from `auth_flow.dart`.
- Route shells from the authenticated `role` returned by `POST /api/token/`, not from onboarding tiles.
- Make base URL configurable and add Android cleartext / iOS ATS configuration.
- Gate boss approval on `status == pending_review`, complete `missing` lists, loaded documents, and explicit confirmation; enforce the same in the backend (already returns 409, so mirror it in UI).
- Make quality decisions authoritative before submit; persist verification results; require retake on REJECT.
- Remove or explicitly gate all demo-data fallbacks; show real errors with retry.
- Fix production backend settings: `DEBUG=False`, explicit `ALLOWED_HOSTS`, strong secret, restrictive CORS, disable debug OCR, add throttles.
- Delete `lib/e2e_harness.dart` or move it outside the shipped `lib/` tree.

### Priority 2 — Correctness and privacy
- Add pagination to client history and all large backend lists.
- Fix mission location mapping and mission status transitions; preserve backend statuses.
- Enforce negotiation `minStep`, TTL, idempotency, and closed-state action disabling.
- Require a valid quote before mission confirmation.
- Remove/mask client phone numbers from driver-visible mission payloads.
- Clear refresh token on sign-out; move tokens to secure storage.
- Bound verification task store/executor and add throttling; align 503 vs `failed` body contract.
- Add tests for mission cancel/delete/employee history and agent document route.
- Add `django-cors-headers` to `requirements.txt`; fix API docs; commit the untracked client-mission test.

### Priority 3 — Quality and maintainability
- Wire or delete dead screens, no-op taps, decorative filters, fake wallet/settings/revenue controls.
- Localize shared states, persist language, respect font scaling, add dark theme, fix small tap targets.
- Standardize error bodies around `{detail, code, ...}` and stop misclassifying non-error response keys.
- Replace golden fixtures with interaction tests that assert real behavior; treat screenshots as evidence of rendering only, not correctness.
- Remove dead scaffold apps/URLs and DB backups from deployable artifacts.

---

### Final note

Several issues above were partially mitigated during the most recent work (driver personal-info form, missing-items display, submit gating, boss status gate). Those changes improve the happy path but **do not resolve** the critical authentication, configuration, demo-fallback, and verification-authority problems listed here. No files were fixed or committed as part of this audit.
