# Roadmap — Api-Gateway 6.x

Only what is still pending, for the gateway (`gateway/`) and the web console (`console/`). What is done is in `CHANGELOG.md`.

Rules:
- Every change is recorded in `CHANGELOG.md`, under the in-progress version (currently `6.0.0`).
- Everything in the project is written in English (code, comments, docs, changelog, roadmap).
- Console: keep its base (Cubit + DI with Get + go_router + Dio). Changes in the contract of `/{ADMIN_PATH}/auth|routes|http-log` must be applied in both folders.

---

## Console

- [ ] **Full block below 800×400** (`console/lib/main.dart:93`). Needs a responsive layout for the rail, logs table and form; not a small change. At least allow login and list on medium screens.
- [ ] ⚠️ The tests have never been executed: on the dev machine `flutter test --platform chrome` fails even for a trivial test ("Connection closed before test suite loaded", Chrome and Edge). First real run will be the CI.

## Possible improvements

- [ ] Rename the Dart package `api_gateway_front` (`console/pubspec.yaml` and every `package:` import) to match the `console` folder.
- [ ] Console: remove `reassembleApplication()` in the language change (`console/lib/features/language/logic/cubit/language_cubit.dart:64`), a hot-reload API. Evaluated and kept for now: widgets read `app.intl` through the global navigator context and wouldn't rebuild without it. Removing it means passing `context.intl` everywhere.
- [ ] Console: `get` is only used for DI and `firstWhereOrNull` (the latter exists in `package:collection`). Consider `get_it`, as `console/lib/adapter/di.dart` itself suggests.
- [ ] Gateway: mutation testing with **PIT** on the routes and logs logic, to measure test quality beyond coverage.

## 6.0.0 release

- [ ] Review the CI on GitHub, after all the changes above. The `native-image` job, with the smoke test and the Postman collection, only runs on `master`.
- [ ] Review the deployments: from the repository they need the new root directories (Railway: `/gateway` and `/console`).
- [ ] Set `version = '6.0.0'` in `gateway/build.gradle` and the release date in `CHANGELOG.md`.
- [ ] **Last step:** migrate to images on **GHCR** (`ghcr.io`): publish the docker images from the CI and use them in `docker-compose.yml` and the deploy docs instead of building locally.
