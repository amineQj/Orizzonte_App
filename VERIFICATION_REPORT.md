# ORIZZONTE Flutter ↔ Django integration — verification report

Date: 2026-11-19

## 1. Static / build / test proof

| Command | Result |
|---|---|
| `flutter analyze` | `No issues found!` |
| `flutter build web --no-tree-shake-icons --no-wasm-dry-run` | `√ Built build\web` |
| `flutter test` | `All tests passed!` — **21 tests** (was 12) |
| Backend `.\venv\Scripts\python.exe manage.py test -v 1` (from `C:\Users\THINKPAD\Desktop\orizzonte-backend-app`) | `Ran 343 tests` — `OK (skipped=1)` |

New/updated frontend tests:
- `test/api_errors_test.dart` — 6 tests: exact backend `detail` preserved on 403/409, machine `code` appended (`driver_not_approved`), friendly 409 fallback, `getMissionById()` uses `/api/missions/all/`, `getDocumentBytes()` uses the private document URL.
- `test/ui_screens_test.dart` — 3 golden/widget tests rendering real screens with canned API data, producing the screenshots in `screenshots/`.
- Existing `api_payload_test.dart`, `api_upload_test.dart`, `routing_service_test.dart`, `widget_test.dart` still pass.

## 2. Files changed

Frontend (`C:\Users\THINKPAD\Desktop\Orizzonte_App`):
- `lib/services/api_service.dart` — exact backend error preservation (`detail`, `code`, field errors), centralized 401 refresh, `getMissionById()`, boss/driver document + approval endpoints, multipart contract.
- `lib/models/api_models.dart` — `apiErrorMessage()` appends backend machine code.
- `lib/widgets/api_state.dart` — messenger-safe success/error snackbars; shared Poppins helper.
- `lib/widgets/app_text_style.dart` — **new** shared text style with offline fallback for golden tests.
- `lib/driver_profile_page.dart` — Bug 2 verification flow.
- `lib/driver_home_page.dart` — Bug 3 accept guard/loading/retry/refresh; passes negotiation role.
- `lib/services/driver_mission_store.dart` — invalid demo-ID failure handling.
- `lib/boss/boss_driver_detail_page.dart` — **new** Bug 1 document review screen.
- `lib/boss/boss_mission_detail_page.dart` — **new** Bug 4 mission detail screen.
- `lib/boss/boss_requests_page.dart` — wires cards/Details button to Bug 4 screen.
- `lib/boss/boss_dashboard_page.dart` — Bug 6 live stats + pull/manual refresh.
- `lib/boss/boss_drivers_page.dart`, `lib/boss/boss_repository.dart` — registered drivers + repository error propagation.
- `lib/negotiation/negotiation_page.dart` — Bug 5 timeline/range/idempotency/loading/refresh.
- `test/api_errors_test.dart`, `test/ui_screens_test.dart`, `test/goldens/*.png` — **new** proof tests/artifacts.

Backend (`C:\Users\THINKPAD\Desktop\orizzonte-backend-app`):
- `missions/urls.py`, `missions/views.py` — client mission history endpoint used by the app.
- `missions/tests_django/test_client_missions_api.py` — 7 API tests.
- `opencode.json` — tooling config.

## 3. Per-bug confirmation

### Bug 1 — Boss can view/approve/reject driver documents
`lib/boss/boss_driver_detail_page.dart` loads the registered driver via `GET /api/drivers/<id>/`, fetches all five required documents as raw bytes via `GET /api/drivers/<id>/documents/<type>/` and renders `Image.memory` previews with full-screen `InteractiveViewer`. Each document has independent loading, error + retry. Approve posts to `/api/drivers/<id>/approve/` (no body); Reject posts `{"reason": "..."}` to `/api/drivers/<id>/reject/`. Mission history loads through `getDriverMissionHistory()`.
- Proof: `flutter test` golden `boss_driver_detail screenshot` ✓
- Screenshot: `screenshots/boss_driver_detail.png`

### Bug 2 — Driver uploads documents and polls verification
`lib/driver_profile_page.dart` uploads with the `file` multipart field, calls `POST /api/verification/check/` with the same bytes, polls the returned `task_id` up to 90×2s, and displays `ACCEPT` / `MANUAL_REVIEW` / `REJECT` plus `reason_codes`. Per-slot `_DocVerification` state tracks each of the five documents; `REJECT` exposes a retake action. Submit is gated on five uploads and five passes, and shows exact backend errors with retry.
- Proof: backend audit + existing multipart regression tests; UI covered by the profile screen implementation.
- Live visual proof requires a running backend with the external verification service (see Limitations).

### Bug 3 — Driver mission Accept actually works
`lib/driver_home_page.dart` loads the driver profile and approval banner. Accept is disabled when the profile is not approved; otherwise it calls `POST /api/missions/<id>/accept/`, handles 403 `driver_not_approved` and 409 conflicts with exact backend text, shows per-mission loading, a success snackbar, and refreshes `DriverMissionStore` + profile.
- Proof: `api_errors_test.dart` 403/409 tests ✓
- Live visual proof requires an approved driver account (see Limitations).

### Bug 4 — Boss mission detail
`lib/boss/boss_mission_detail_page.dart` resolves missions via `getMissionById()` (`GET /api/missions/all/`, as the backend has no single-mission route) and shows client name/email/phone, assigned driver, negotiation timeline and Assign/Cancel/Delete actions. Boss negotiation history gracefully reports “not available for boss role” on 403 (endpoint is client/approved-driver only).
- Proof: `flutter test` golden `boss mission detail screenshot` ✓; `api_errors_test.dart` `getMissionById` ✓
- Screenshot: `screenshots/boss_mission_detail.png`

### Bug 5 — Negotiation UI
`lib/negotiation/negotiation_page.dart` shows the live amount, currency, allowed range, minimum step, offers left, your-turn chip, expiry countdown, acceptance-hold countdown, offer timeline with sequence numbers and timestamps (role-aware alignment on client vs driver), and Send offer / Accept / Decline buttons with in-button spinners. Amounts are validated client-side against backend min/max/offers-left. Each offer intent keeps a stable `idempotency_key` across retries. Background polling (8s) and pull-to-refresh keep the timeline live.
- Proof: `flutter test` golden `negotiation screenshot` ✓
- Screenshot: `screenshots/negotiation.png`

### Bug 6 — Boss dashboard real stats + refresh
`lib/boss/boss_dashboard_page.dart` derives counters from `BossRepository.instance.stats` (`total_missions_month`, `completed_missions`, `completion_percentage`, `today_missions`, `monthly_revenue`) plus pending/active from live `/api/missions/all/`. Adds pull-to-refresh and a header refresh button with a loading indicator.
- Proof: `flutter analyze` ✓; repository error/retry wiring.
- Live visual proof requires a boss account (see Limitations).

### Bug 7 — Loading / exact errors / retry on all API calls
Shared normalization keeps backend `detail`, `code`, and field errors; `apiErrorMessage()` appends the machine code. `showApiErrorWithMessenger()` / `showSuccessWithMessenger()` avoid stale-context crashes after awaits. Boss, driver, mission and negotiation repositories all surface `apiErrorMessage(e)` with retry actions.
- Proof: `api_errors_test.dart` — 6/6 ✓

## 4. Manual test plan (run with backend + seeded users)

| # | Flow | Steps | Expected |
|---|---|---|---|
| 1 | Boss documents | Log in as boss → Drivers → open a registered driver → wait for five previews | All five slots render; tap one → zoomable full-screen image. Kill backend mid-load → per-document Retry appears. |
| 2 | Boss approve/reject | Same screen → Approve | Success snackbar, status becomes approved. Reject → enter reason → success; driver sees reason. |
| 3 | Driver verification | Log in as driver → Profile → upload five valid images | Each upload shows a spinner, then `ACCEPT`/`MANUAL_REVIEW`/`REJECT` with reason codes. Rejected slot → Retake. Submit disabled until 5/5 passes. |
| 4 | Driver accept (guard) | Use a *pending* driver → open an available mission → Accept | Button greyed; banner “profile must be approved”. Approve the driver, reload → Accept enabled → success snackbar, mission moves to My Missions. |
| 5 | Driver accept (conflict) | Two drivers accept the same mission | Second sees exact backend 409 detail, not a generic message. |
| 6 | Boss mission detail | Boss → Requests → tap a mission card / Details | Client email/phone, assigned driver, negotiation timeline, Assign/Cancel/Delete visible. |
| 7 | Negotiation | Client and driver on the same mission | Amount/range/offers-left update live; your-turn chip switches; sequence+timestamps shown; rapid double Send creates one offer (idempotency key); expiry countdown decreases; Accept/Decline show spinners. |
| 8 | Dashboard refresh | Boss dashboard | Stats match API payload; pull-to-refresh and header refresh both show a spinner and reload. Force a 500 → error view with Retry. |

Screenshots for flows 1, 6 and 7 are in `screenshots/` (canned-data widget-test rendering). Screenshots for flows 2–5 and 8 require the live backend session.

## 5. Limitations

- The backend at `http://127.0.0.1:8000` was **unreachable** during this session (`UNREACHABLE: Impossible de se connecter au serveur distant`), and no seeded boss/driver/client accounts were available. Live end-to-end screenshots for Approve/Reject, verification polling, Accept guards and dashboard stats could not be captured. The manual plan above is provided for your verification.
- The three supplied screenshots are golden-test renderings of the actual screens with canned API responses (real widgets, real layout), not captures of a live backend session. Poppins falls back to the default font in these offline golden tests; production builds still use Poppins.
- `getClientMissions()`, `getEmployees()` and `getDriverMissionHistory()` load the first page only; deeper pagination needs `?page=` support.
- Boss negotiation history intentionally degrades to “not available for boss role” on 403 because the backend endpoint is restricted to client/approved-driver roles.
- No backend endpoint was added or modified for the seven bugs beyond the earlier client-mission-history endpoint; no commit or push was performed.
