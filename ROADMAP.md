# Roadmap — Api-Gateway

Only what is still pending. What is done is in `CHANGELOG.md`.

Rules:
- Every change is recorded in `CHANGELOG.md`, under the in-progress version (currently `5.1.0`).
- Everything in the project is written in English (code, comments, docs, changelog, roadmap).

> The front (`tools/api_gateway_front/`) has its own roadmap and tests, handled by the front agent.

---

## 5.1.0 release

- [ ] First real run of the CI on GitHub (never executed yet). The `native-image` job, with the smoke test and the Postman collection, only runs on `master`.
- [ ] Set `version = '5.1.0'` in `build.gradle` and the release date in `CHANGELOG.md`.

## Optional

- [ ] Mutation testing with **PIT** on the routes and logs logic, to measure test quality beyond coverage.

## Future (6.x, contract changes)

- [ ] Unify `GET /routes/{id}`, which returns the **entity** (flat `rewrite_path_from/to`), with `GET /routes`, which returns `RouteConfigResponse` (`rewrite_path` object). Documented in the README for now.
- [ ] Login returning a token (JWT/session) instead of sending user/password on every request. Keep Basic in parallel during the transition.
- [ ] `login` with wrong credentials → 401 (today 403).
- [ ] Routes with `order`, multiple predicates (method, host, headers) and extra filters.
- [ ] `http_log.route` column as `jsonb` (or a `route_id` column) to filter by route without `LIKE` over JSON.
