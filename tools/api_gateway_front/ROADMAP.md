# Roadmap — API Gateway Front (console)

Pending work only; what is already done is in `CHANGELOG.md`.
Rule: **don't change the base** (Cubit + DI with Get + go_router + Dio) **nor the API contract** (`/{ADMIN_PATH}/auth|routes|http-log`, Basic Auth, `env.js`).
Items marked 🔗 depend on, or must be coordinated with, the backend.

Legend: **P2** robustness/quality · **P3** improvement/cleanup

---

## Phase 4 — Robustness and architecture (P2)

- [ ] **Dio interceptor for Basic Auth.** Each client receives `credential` and builds the header (`lib/features/base_client.dart`). An interceptor simplifies this and removes `auth.current` throwing from a getter (`lib/features/auth/logic/cubit/auth_cubit.dart:12`). It refactors every client and repo signature with no behaviour change, so do it together with 🔗 session tokens.
- [ ] **Language change via `reassembleApplication()`** (`lib/features/language/logic/cubit/language_cubit.dart:64`), a hot-reload API. Evaluated and kept for now: widgets read `app.intl` through the global navigator context, so they don't depend on `Localizations` through their own context and wouldn't rebuild without it. Removing it means passing `context.intl` everywhere.
- [ ] **Full block below 800×400** (`lib/main.dart:93`). Needs a responsive layout for the rail, logs table and form; not a small change. At least allow login and list on medium screens.

## Phase 5 — Tests and CI (P2)

- [ ] ⚠️ The tests have never been executed: on the dev machine `flutter test --platform chrome` fails even for a trivial test ("Connection closed before test suite loaded", Chrome and Edge). First real run will be the CI (it runs on pull requests and on pushes to `develop`/`master`).

## Phase 6 — Build, Docker and docs (P3)

- [ ] Review dependencies (optional, needs a decision): `get` is only used for DI and `firstWhereOrNull` (the latter exists in `package:collection`). Consider `get_it` as `lib/adapter/di.dart` itself suggests — **only if decided**, not required.
