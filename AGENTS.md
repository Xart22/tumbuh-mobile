# AGENTS.md — tumbuh_mobile

Flutter POS app (cashier / KDS / owner) for Tumbuh POS. Primary target Android; all platforms scaffolded.
Package name `tumbuh_mobile`; import via `package:tumbuh_mobile/...`.

## Commands
- `flutter pub get`
- `flutter analyze` — required gate; `flutter_lints` via `analysis_options.yaml`
- `flutter test` — full suite; single file: `flutter test test/order_math_test.dart`
- `dart run build_runner build --delete-conflicting-outputs` — only needed after editing Drift tables in `lib/data/local/db/app_database.dart` (regenerates `app_database.g.dart`)

No CI workflows exist (`.github/` only has unrelated modernization hooks). Run analyze + test manually.

## Docs vs reality (read before trusting)
- `README.md` is untouched Flutter boilerplate — ignore.
- `MOBILE.md` is the aspirational spec/plan (Indonesian), not implemented state. Do not treat its endpoints, minSdk, or "models generated from Swagger" as current truth.
- Current reality: `features/kds` and `features/owner` are entirely mock-data-driven (`features/kds/data/mock`, `features/owner/data/mock`). Auth, shifts, and POS catalog/checkout are wired to the backend (`tumbuh-be`, sibling repo at `../tumbuh-be`) — the seed catalog in `PosRepository` is now only an offline fallback. Wiring a screen to the backend means adding it, not "fixing" it.
- `tumbuh-be` source is the contract truth. Two conventions that bite: every JSON response is wrapped `{success, data, meta}` (unwrapped centrally in `ApiClient`), and errors are `{success:false, error:{code,message}}`. Outlet-scoped routes need `X-Outlet-Id`; order/payment creation needs `Idempotency-Key`.

## Wiring & DI
- All object graph is hand-wired in `lib/main.dart` (no service locator). New repositories/blocs must be constructed there and root `BlocProvider`s added to `TumbuhApp`.
- Routing is `lib/routing/app_router.dart` (go_router, constants for paths). Screens are `features/<domain>/presentation/screens`, business logic in `features/<domain>/bloc`.

## Networking & offline contract
- Base URL in `lib/core/config/app_config.dart` (`AppConfig.defaultBaseUrl`), overridable via `--dart-define=API_BASE_URL=...` (default `http://localhost:3000`; Android emulator reaches host at `http://10.0.2.2:3000`). No `.env`, no flavors.
- `ApiClient` interceptors auto-attach `Authorization`, `X-Outlet-Id`, `X-Device-Id`, and a fresh `Idempotency-Key` on POST/PUT/PATCH/DELETE. 401 clears auth. Use `getWithRetry` for idempotent GET.
- Offline-first: mutating calls that fail are enqueued to the Drift `OutboxEvents` table (`OutboxDao.enqueue`) and replayed by `SyncEngine` on connectivity change. Keep idempotency keys stable across replay (409 is treated as already-processed).
- The **server is authoritative** for totals/tax/service/rounding. `lib/shared/math/order_math.dart` is client-side preview only — keep it in sync with backend semantics, don't treat it as source of truth.

## Money & formatting
- Money is integer rupiah everywhere (Drift `IntColumn`, `OrderTotals` ints). Never use `double` for currency. Use `OrderMath.formatCurrency` / `shared/formatters`.

## Design system
- `DESIGN.md` is the visual SSOT. Tokens map to `lib/shared/theme/` (`LpColors`, `AppTheme`, `AppTypography`). Pull colors from `LpColors`, not inline hex.
- App defaults to `ThemeMode.dark` (tactile POS/KDS shell).

## Testing
- `test/*.dart`. Widget tests construct the whole app with an in-memory Drift DB (`AppDatabase(NativeDatabase.memory())`); follow that pattern instead of mocking.
- Android app id is still placeholder `com.example.tumbuh_mobile`; release builds sign with debug keys (`android/app/build.gradle.kts`).
