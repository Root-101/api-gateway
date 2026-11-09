# Roadmap — API Gateway Front (console)

Full review of `tools/api_gateway_front` (Flutter web, v1.1.1, 2026-11-02).
Rule: **don't change the base** (Cubit + DI with Get + go_router + Dio) **nor the API contract** (`/{ADMIN_PATH}/auth|routes|http-log`, Basic Auth, `env.js`).
Each item has `file:line` to jump straight to it. Items marked 🔗 depend on, or must be coordinated with, the backend.

Legend: **P0** bug that breaks/destroys data · **P1** visible bug or security · **P2** robustness/quality · **P3** improvement/cleanup

---

## Phase 1 — P0 bugs (data and session)

- [x] **Editing a route wipes its `description`.** The form always sent `description: ''` (`lib/features/routes/view/form/routes_form_screen.dart`). `PUT /routes/{id}` is a full replace (confirmed by back), so this was deleting data. Edit and duplicate now keep the existing description.
- [x] **Route delete without confirmation.** One click on the icon deleted it (`lib/features/routes/view/routes_screen.dart`). Now asks for confirmation with the route name.
- [x] **A network outage logged the user out and erased "Remember me".** `connectionError` was mapped as `auth` (`lib/exceptions/api_exception_converter.dart`) and `AuthCubit` logs out on any `auth` error → `storage.delete` of the credentials.
  - 🔗 Root cause fixed in back (api-gateway-8a), verified by tests: 401/403 now carry CORS headers and 401 has no `WWW-Authenticate`. Front now maps `connectionError` as `general`.
  - Startup with cached credentials only forgets them when the server rejects them (401/403), not on network errors (`lib/features/auth/logic/cubit/auth_cubit.dart`).
  - ⚠️ **Front and back must be deployed together**: with an old back, a 401 would arrive as a connection error and would no longer log out.
- [x] **Duplicated logs / lost page after logout→login or "Try again".** `LogsCubit.init()` didn't clear `items` nor reset `currentPage`. Now always restarts from page 0 with the active filters (`lib/features/logs/logic/cubit/logs_cubit.dart`).
- [x] **Previous user's data after logout.** `LogsCubit` (items, filters, routes) survived logout. Now included in `FeaturesInit.reset()` (`lib/features/features_init.dart`).
- [x] **Crash parsing 4xx errors with a JSON body.** `message: error.response!.data` assumed `String`; Spring `ErrorResponse` sends ProblemDetail JSON → `TypeError`. 422 assumed `List` and `ValidationError.invalidValue` assumed `String`. Now parsed defensively (string body, `detail`/`message`/`title`, fallback `Error <status>`).
- [x] **(new) A single route without `rewrite_path` broke the whole list.** `GET /routes` returns `rewrite_path: null` and `RewritePathEntity.fromJson(null)` threw. Now optional end to end; the request sends `null` (never `{"",""}`), as agreed with back.

## Phase 2 — P1 bugs (visible behaviour)

- [x] **401 in Logs doesn't log out.** `AuthCubit` only listens to `RoutesSearchErrorState`. Centralize: a Dio interceptor that calls `logout()` on 401 (covers routes, logs, form, restore, backup, export).
  - Done: Dio interceptor in `features_init.dart` (401/403 while logged in → `logout()`); the `RoutesSearchErrorState` bus listener was removed.
- [x] **Clicking a timestamp filters by the UTC day, not the local one.** `updateFilter(requestedAt: log.requestedAt)` (`lib/features/logs/view/logs_screen.dart:83`) passes the UTC DateTime and `startOfDay` (`lib/config/date_formatter.dart:33`) builds a local date from UTC components → wrong day near midnight. Use `log.requestedAtLocal`.
- [x] **"Redirected to" preview is wrong.** Computed with a literal `String.replaceAll` over `uri+path` (`lib/features/routes/logic/model/route_model.dart`, `route_form_model.dart`), but the gateway uses Spring's `RewritePath` filter (regex, `$\{segment}`) over the path. Use `RegExp`, convert `$\{x}` → named groups, apply only to the path.
- [x] **Rewrite path required in the form, optional in the API.** Now "both or none" (done with the `rewrite_path: null` fix; confirmed by back).
- [x] **Filters shown but not applied after re-init.** `init()` searched without filters while `filters` kept its values. Fixed with the Phase 1 `init()` change.
- [x] **Infinite-scroll errors in logs are unhandled.** `fetchNextPage` throws uncaught (`logs_cubit.dart`, `logs_screen.dart` `handleLoadMoreRows`). Catch, show a snack, allow retry. Use `totalPages` from the response instead of `length < pageSize`.
- [x] **Logs export asks for the whole table.** 🔗 Back now caps `size` with `MAX_LOGS_SEARCH_SIZE` (default 10000, truncates without error; `total_elements`/`total_pages` stay real). Paginate the export: `size=1000`, `page 0..total_pages-1`.
- [x] **`GET /routes/{id}` has a different shape** (flat `rewrite_path_from`/`rewrite_path_to`, confirmed by back, won't change in 5.x). `RoutesRepo.details` parses it as `RouteResponse`, so the rewrite would be lost; today unused because the form reuses the model from the list. Adapt before using it (e.g. edit by URL).
  - Done: `RouteResponse.fromJson` also reads `route_id` and the flat rewrite fields (the entity is serialized as-is).
- [x] **`search()` called inside `build()`** (`routes_screen.dart:84`). Move to `initState`.
- [x] **"No-Route" filter doesn't change language.** `noRoute` is top-level and initialized once with `app.intl` (`logs_cubit.dart:13-17`). Make it a getter.
- [x] **Untranslated error messages** (partial: `routes_form_cubit.dart` translated and the missing `emit` fixed; pending: `api_exception_converter.dart`/`exception_converter.dart` — they need intl without a `BuildContext`, e.g. `lookupAppLocalizations(locale)`, to stay unit-testable — and `'Need more space'` in `main.dart`) (all `//TODO: intl` in `api_exception_converter.dart`, `exception_converter.dart:11`, `'Need more space'` in `lib/main.dart`, `'Wrong Route id'` and the Spanish `'Accediendo a estado no soportado...'` in `routes_form_cubit.dart:42,73`). Also the `else` in `routes_form_cubit.dart:73` doesn't `emit`.
  - Done: texts migrated from `gen-l10n` (ARB) to **slang** (`lib/l10n/{en,es}.i18n.yaml`, `slang.yaml`, same setup as Feather console), grouped by screen (`app.intl.routes.nameLabel`). The converters and `'Need more space'` are translated; `app.intl` falls back to English without a navigator (unit tests). After changing a text: `fvm dart run slang` and commit the generated `messages*.g.dart`.
- [x] **Restore without feedback or pre-validation.** Generic error on invalid JSON; doesn't say how many routes will be created nor warn about duplicates. Show count + confirmation before `multi-add`. "Restore" button enabled with no file.
  - Done: the file is parsed on select (catch-all, `TypeError` used to escape), the dialog shows the count and the names that already exist, and Restore is disabled until a valid file is loaded.

## Phase 3 — Security (P1)

- [x] **Stored password recoverable in the browser.** "Remember me" stores username and password (base64) in `flutter_secure_storage`, which on web is `localStorage` encrypted with a key also reachable from JS (`lib/features/auth/data/repo/auth_repo.dart:23-29`). Any XSS or access to the machine gets it. Options without changing the API: `sessionStorage` (tab only), or a clear warning in the UI. Mid term 🔗 session token in the backend.
  - Done (UI only): warning under "Remember me" when checked. Storage unchanged; the real fix is still 🔗 a session token in the backend.
- [x] **`CredentialsModel.toString()` prints the password** (`lib/features/auth/logic/model/credentials_model.dart:9`). Remove it.
- [x] **No security headers in nginx.** The Dockerfile uses the default config. Add an `nginx.conf` with CSP, `X-Frame-Options: DENY`, `X-Content-Type-Options`, `Referrer-Policy`, and proper caching (`index.html`/`env.js` no-cache, hashed assets cacheable).
  - Done: `nginx.conf` (CSP, `X-Frame-Options: DENY`, `nosniff`, `Referrer-Policy: no-referrer`, `Cache-Control: no-cache` everywhere because Flutter file names aren't hashed). The inline splash script moved to `web/splash.js` so the CSP needs no `script-src 'unsafe-inline'`. `connect-src *` because the gateway url is only known at runtime.
- [x] **No session timeout.** Credentials live in memory forever. Optional configurable inactivity logout.
  - Done: optional `SESSION_TIMEOUT_MINUTES` in `env.js` (Dockerfile `ARG`, default 0 = disabled), `lib/features/auth/logic/inactivity_logout.dart`.

## Phase 4 — Robustness and architecture (P2)

- [x] **Navigation guard in go_router.** `initialLocation` is evaluated once and there is no `redirect` (`lib/config/route_config.dart:6-10`); it works by accident because `auth.current` throws and logs out. Add `redirect` with `refreshListenable` from `AuthCubit`, and an `errorBuilder` for 404.
  - Done: `redirect` + `refreshListenable` on the `AuthCubit` stream; unknown urls go to `/routes` via `onException` (and to login when logged out).
- [ ] **Dio interceptor for Basic Auth.** (Skipped in Phase 4: refactor of every client and repo signature with no behaviour change; do it together with 🔗 session tokens.) Each client receives `credential` and builds the header (`lib/features/base_client.dart`). An interceptor simplifies this and removes `auth.current` throwing from a getter (`auth_cubit.dart:12-21`).
- [x] **`dart:io` in a web app** (`base_client.dart:2`, `features_init.dart:1`). Use `dio` constants (`Headers.contentTypeHeader`, `Headers.jsonContentType`) or plain strings.
- [x] **Double subscription to the `AuthCubit` stream**, never cancelled (`features_init.dart:27,38`). Merge into one.
- [ ] **Language change via `reassembleApplication()`** (Evaluated, kept: widgets read `app.intl` through the global navigator context, so they don't depend on `Localizations` through their own context and wouldn't rebuild without it. Removing it means passing `context.intl` everywhere.) (`lib/features/language/logic/cubit/language_cubit.dart:66`) — a hot-reload API. `LanguageListener` already rebuilds `MaterialApp` with the new `locale`; the issue is `app.intl` through the global `navigatorKey`. Evaluate removing the hack.
- [x] **`LanguageCubit.init()` not awaited** (called in the constructor, `language_cubit.dart:29`) → language flicker on startup. `await cubit.init()` in `LanguageInit`.
- [x] **Artificial 1 s splash** (`lib/main.dart:25`). Remove or reduce.
  - Done: removed.
- [x] **Controllers/FocusNode never disposed**: login (`login_screen.dart:34-42`), route form (`routes_form_screen.dart:170-174`, and `CombinedValueNotifier` is created on every build without dispose), logs filter (`logs_filter_dialog.dart:66`), logs search (`logs_screen.dart:33`).
  - Done: login, route form (`Listenable.merge` replaces the per-build `CombinedValueNotifier`, class deleted), logs filter, logs search.
- [x] **`LogsDataSource` recreated on every `build`** (including every column-resize event, `logs_screen.dart:79`), resetting `hasMoreRows`. Create once and update.
  - Done: recreated only for a new `LogsSearchOkState`.
- [x] **No loading indicator when applying filters/search in logs** (`_executeSearchFilters` emits no loading state).
  - Done: new `LogsFilteringState` (not a search state, keeps the table) shows the loading overlay.
- [x] **`failValidations?.clear()` mutates the cubit state** (`routes_form_screen.dart`).
  - Done: local `_apiErrors` copy in the form widget.
- [x] **`DialogHelper.open` doesn't return the dialog `Future`** (`lib/adapter/dialog_helper.dart:16`). (The delete confirmation uses `showDialog` directly.)
- [x] **`CubitView` uses `Get.find` directly** (`lib/adapter/di.dart:52`), bypassing the `DI` facade.
- [x] **Route grid with fixed height** (`childAspectRatio: 2.1`, `routes_screen.dart`): long URLs get cut/overflow. Inconsistent width math (`~/ 475` vs `* 500`).
  - Done (minimal): urls on one line with ellipsis + tooltip, same 500 px tile width in both calculations, at least 1 column.
- [ ] **Full block below 800×400** (Pending: needs a responsive layout for the rail, logs table and form; not a small change.) (`main.dart:75`). At least allow login and list on medium screens.
- [x] **`env.js` not validated.** If missing or a field is `undefined`, the app fails silently (`lib/config/env.dart`). Show a clear config error. Normalize slashes (trailing `/` in URL, leading `/` in `ADMIN_PATH`).
  - Done: `Environment.configError` shows a plain error screen at startup; trailing `/` in the url and `/` around `ADMIN_PATH` are normalized.

## Phase 5 — Tests and CI (P2)

- [x] Created `test/` (`test/phase1_test.dart`; run with `fvm flutter test --platform chrome` — the app is web-only). Pending:
  - [x] `ApiExceptionConverter` (401, 403, 422, 404 with JSON, plain string, connection error).
  - [x] Null `rewrite_path` in parsing and request.
  - [x] Rewrite preview (Spring regex) — `test/phase2_test.dart`.
  - [x] `LogsCubit`: pagination, reset, filters with local/UTC dates — `test/phase5_test.dart`.
  - [x] Parsing of `HttpLogResponse` with null fields (`RouteLogResponse` made null-safe too).
- [x] `flutter analyze` with no warnings (unused `exc` variables, duplicated `dio` imports in `base_client.dart:5-6`).
- [x] CI job: `analyze` + `test` + `build web` (front job in the root `.github/workflows/ci.yml`, added by the backend session; not run on GitHub yet).
- [ ] ⚠️ The tests have never been executed: on the dev machine `flutter test --platform chrome` fails even for a trivial test ("Connection closed before test suite loaded", Chrome and Edge). First real run will be the CI.

## Phase 6 — Build, Docker and docs (P3)

- [x] **Dockerfile**: `debian:latest` and a full Flutter `git clone` → slow, non-reproducible build. Use a pinned image (`ghcr.io/cirruslabs/flutter:3.41.9`) or `git clone --depth 1 --branch 3.41.9`. Pin `nginx` to a current version (1.25.2 is from 2023). `flutter clean` is unnecessary.
  - Done: `debian:bookworm-slim` + `git clone --depth 1 --branch 3.41.9`, `pub get` layer cached before `COPY . .`, no `flutter clean`, `nginx:1.28-alpine`.
- [x] **`env.js` generated at *build* time (`ARG`)** → one image per environment. Generate it at *startup* from env vars (script in `/docker-entrypoint.d/`), keeping the same names `GATEWAY_SERVICE_URL` / `ADMIN_PATH`.
  - Done: `docker/40-env-js.sh` in `/docker-entrypoint.d/` writes it on start from the env vars; the `ARG`s stay as defaults so `args:` in docker-compose keeps working. `.gitattributes` forces LF on `*.sh`. Verified in a container (headers, SPA fallback, env.js).
- [x] Add `.dockerignore` (`build/`, `.dart_tool/`, `.idea/`, `.fvm/flutter_sdk`).
- [x] Local `.gitignore` is empty (everything is in the root one) — fine, but `l10n_errors.txt` is versioned and is a generated artifact.
  - Kept as is: `l10n_errors.txt` is written by `gen-l10n` (`untranslated-messages-file`) and is useful in review (`{}` = nothing untranslated).
  - Superseded: `gen-l10n` was replaced by slang, the file no longer exists.
- [x] `web/manifest.json`: `name`/`short_name` = `api_gateway_front`, `orientation: portrait-primary` on a desktop app. `index.html`: `user-scalable=no` meta (accessibility) and `apple-mobile-web-app-title`.
- [x] README: outdated Flutter version (says 3.35.1, uses 3.41.9); add how to run locally (add a `web/env.example.js`).
  - Done: version, runtime env vars with `docker run -e`, run locally with `web/env.example.js`.
- [x] `SplashScreen.splashImageUrl` points to a missing asset (`lib/features/global/splash_screen.dart:5`). Delete.
- [x] `DateFormatter` creates a new `DateFormat` on every access and `logsTime` uses `hh` + `a` (12 h) — consider `HH` or a locale-based format.
  - Done: formats created once, `logsTime` is 24 h (`HH:mm:ss`).
- [ ] Review dependencies (not done: optional, needs a decision): `get` is only used for DI and `firstWhereOrNull` (the latter exists in `package:collection`). Consider `get_it` as `di.dart` itself suggests — **only if decided**, not required.

## Phase 7 — Product improvements (optional, no API break)

- [x] `description` field visible/editable in the form and the card (the API already supports it).
  - Done: optional multi-line field in the form (also used by create/duplicate); in the card it is shown in the name tooltip because the tile has a fixed height.
- [x] Search/filter on the routes screen.
  - Done: local filter by name, path, URI or description (the API has no route search).
- [x] Edit route by URL (`/routes/:id/edit`) (Pending: the `GET /routes/{id}` adapter is ready; needs a route inside the shell that opens the form dialog.) — the code already has "the bases" (`routes_form_screen.dart:32`). Needs the `GET /routes/{id}` adapter (Phase 2).
  - Done: `/routes/:id/edit` is a child of `/routes` on the root navigator whose page is the form dialog (`DialogPage`). The Edit button pushes it with the model in `extra`; opening the url directly loads the route with `GET /routes/{id}`; closing the dialog goes back to `/routes`.
- [x] Copy entry/target URL to clipboard from the card.
- [x] Refresh logs (button / auto-refresh) and show the total (`totalElements`).
  - Done: Refresh button (same search and filters from page 0) and total of the last search. No auto-refresh.
  - 🔗 Logs are written async in ~1s batches: a request appears in `/http-log/search` 1-2 s later, so don't expect it on an immediate refresh.
- [x] Show the console version (and the gateway's, if there is an endpoint 🔗) in the rail.
  - Done for the console (read from the `version.json` that `flutter build web` generates). The gateway has no version endpoint.
- [x] "Backend reachable" indicator on the login screen using `GET /{ADMIN_PATH}/health` (🔗 new, no auth, `{"status":"UP"}`, 503 if the db is down). Would also tell "gateway down" apart from "wrong credentials".
  - Done: green/red dot under the login title, from `GET /{ADMIN_PATH}/health`.

---

### Backend coordination notes 🔗 (answered by api-gateway-8a)
1. ✅ 401/403 from admin now carry CORS and 401 has no `WWW-Authenticate`. Wrong credentials → 403, missing/invalid header → 401, malformed Basic → 401 (was 500). `/auth/login` must keep being called **without** an `Authorization` header.
2. ✅ `rewrite_path` may be `null` in create/edit/multi-add and comes `null` in `GET /routes`. Send both values or `null`, never empty strings.
3. ✅ `/http-log/search` `size` capped by `MAX_LOGS_SEARCH_SIZE` (default 10000). `response_code` accepts number or numeric string; non-numeric → 400. `%` and `_` in `query`/`method`/`route_id` are now matched literally (no wildcards).
4. ✅ `PUT /routes/{id}` is a full replace (incl. `description`); duplicated name now → 409 (was 500).
