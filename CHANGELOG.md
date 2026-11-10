* 6.x:
    * 6.0.0:
        * **DATE** :date: : 2026-11-10.
        * **Deploy** :warning: : Deploy together with the web console (`console`) of this same release: it relies on the `401`/`403` with CORS headers to log out. Building now needs a **JDK 25** (Gradle finds the installed ones).
        * **Structure** :file_folder: : Repository split in two folders: `gateway` (backend, with its Gradle build and `Dockerfile`) and `console` (web console, was `tools/api_gateway_front`). :warning: Deploys from the repository need the new root directories (Railway: `/gateway` and `/console`). Run `./gradlew` from `gateway`. A single `ROADMAP.md` in the root for both.
        * **Versions** :arrow_up: : Upgrade to the latest versions: Java `21` → `25` (LTS), GraalVM CE `25` for the native image, Spring Boot `3.5.14` → `4.1.2` (Spring Framework `7.0.10`, Spring Security `7.1.2`, Jackson `3.1.7`), Spring Cloud `2025.0.2` → `2025.1.4` (Gateway `4.3.4` → `5.0.4`), Gradle `8.14.2` → `9.8.2`, native build tools `0.11.3` → `1.1.18`, `dev.root101.commons` `5.5.3`, Flutter `3.47.9`, GitHub Actions to their latest majors. From the Spring Boot BOM (no hardcoded versions): Flyway `12.4.0`, Postgres driver `42.7.14`, r2dbc-postgresql `1.1.3`, Lombok `1.18.48`, Testcontainers `2.0.5`, JUnit `6.0.3`. Same API contract: the json mapper keeps the Jackson 2 defaults.
        * **Logs** :memo: : Fixes: requests to routes without rewrite-path were not logged, the final route applied the rewrite to `uri + path`, and logs were lost with a long `X-Forwarded-For` (now the first ip is used).
        * **Logs** :memo: : Saved out of the request path: bounded in-memory queue, inserted in batches (if full, logs are dropped with a warning; pending ones are saved on shutdown). New index on `requested_at` (migration `V3`) and old logs deleted in batches.
        * **Logs** :memo: : `POST /http-log/search`: `size` capped by the new `MAX_LOGS_SEARCH_SIZE` (default `10000`), `response_code` with fewer than 3 digits is a prefix (`4` = `400`..`499`, `47` = `470`..`479`), non numeric → `400`, `%` and `_` are literal.
        * **Routes** :twisted_rightwards_arrows: : Loaded before the server accepts traffic, no more `404`s after each deploy (if they can't be loaded, the startup fails). `multi-add` is all or nothing. Fixes: editing with the name of another route → `409` (was `500`), deleting with an uppercase id kept the route active until restart. New `PUT /routes`: replaces every route with the ones in the body, all or nothing.
        * **Auth** :lock: : Fixes: admin auth was applied to any path *containing* the admin path, malformed `Basic` header → `401` (was `500`), the auth filter ran twice. `401`/`403` include the CORS headers and no longer trigger the browser popup.
        * **API** :warning: : Breaking changes in the admin api. `GET /routes/{id}` returns the same object as `GET /routes` (`id` and `rewrite_path`, no more `route_id` and flat rewrite fields). `POST /auth/login` with wrong credentials → `401` (was `403`). `POST /http-log/search`: `route_id` is an exact match, `400` if it's not a uuid or `NO-ROUTE`.
        * **Auth** :lock: : `POST /auth/login` returns a token (`token`, `expires_in`) to send as `Authorization: Bearer`, valid for the new `ADMIN_TOKEN_MINUTES` (default `480`). In memory: a restart invalidates them. Basic auth still works. A correct login resets the failed attempts.
        * **Logs** :memo: : New `route_id` column generated from `route`, with its index (migration `V4`): the search by route no longer uses `LIKE` over the json.
        * **Auth** :lock: : Brute force lockout per client ip → `429` (new `ADMIN_MAX_FAILED_ATTEMPTS`, default `10`, and `ADMIN_LOCKOUT_MINUTES`, default `15`). Credentials compared in constant time. The default password is no longer printed, and there are warnings when running with default admin or db credentials.
        * **Errors** :rotating_light: : `500`s no longer expose internal messages and are logged. Upstream down → `502`, upstream too slow → `504` (was `500` with the internal host). String errors sent as UTF-8 `text/plain`; nothing is written over a response already sent.
        * **Gateway** :hourglass: : New `GATEWAY_CONNECT_TIMEOUT_MS` (default `10000`) and `GATEWAY_RESPONSE_TIMEOUT` (default `60s`, empty = no timeout). :warning: Before there was no response timeout: raise it for services with slower endpoints.
        * **Gateway** :hourglass: : New `CORS_ALLOWED_ORIGINS` (default `*`, same as before). CORS headers sent by an upstream are no longer duplicated.
        * **Ops** :stethoscope: : Health check `GET /{ADMIN_PATH}/health` (no auth, not logged). Server logs with SLF4J. The docker image runs as non-root and has a `.dockerignore`.
        * **Docker** :whale: : `docker-compose`: the gateway waits for Postgres to be healthy, the new env vars are listed, and the web console gets its config at runtime (`environment:`, one image for every environment). Final image on `debian:trixie-slim`. Native image built with `-H:+SharedArenaSupport`: without it every route to an HTTPS upstream returned `500`.
        * **Code** :broom: : Dependencies cleanup (test libraries out of the production binary, Lombok only at compile time, Spring Cloud from its BOM) and code cleanup without behavior changes.
        * **Tests** :test_tube: : Unit tests (`./gradlew test`) and integration tests with Testcontainers (`./gradlew integrationTest`, Docker required): 94 tests, 95.5 % lines / 90.2 % branches, with a coverage gate in `check`.
        * **CI** :construction_worker: : GitHub Actions: tests and coverage gate, web console build and tests, and the native docker image with a smoke test and the Postman collection. A version tag publishes the images on GHCR (`api-gateway` and `api-gateway-console`, amd64) once the CI passes. The console's `pubspec.lock` is now versioned and enforced in the CI and the docker build.
        * **Docs** :books: : README: new env vars, security and timeouts, health check, single-instance note, how to run the tests, and a new documentation improvements section, starting with the supported protocols (HTTP, SSE and WebSocket yes; HTTP/2, gRPC and raw TCP/UDP no). Postman collection (`doc/`) rewritten as a test suite: assertions on every request, no fixed ids, cleans up after itself.
        * **Web console** :computer: : Bug fixes, security, robustness and tests. The docker image generates `env.js` at container start (`GATEWAY_SERVICE_URL`, `ADMIN_PATH`, `SESSION_TIMEOUT_MINUTES`), so one image works for every environment. Texts migrated to slang, and routes can be edited by url (`/routes/:id/edit`).
* 5.x:
    * 5.0.1:
        * **DATE** :date: : 2026-05-17.
        * **General** :hammer_and_wrench: : Upgrade all dependencies.
        * **General** :hammer_and_wrench: : Add @Size validations in routes.
    * 5.0.0:
        * **DATE** :date: : 2025-09-10.
        * **General** :hammer_and_wrench: : Added the Http Logs system
        * **Docker** :whale: : Added the `docker-compose.yml` to run all the services at once
* 4.x:
    * 4.2.0:
        * **DATE** :date: : 2025-06-05.
        * **General** :hammer_and_wrench: : Created a UI client to handle admin api with ease. (details
          in `console/CHANGELOG.md`)
        * **Auth** :lock: : Add needed endpoint to client (like `auth/login` to validate correct user)
    * 4.1.0:
        * **DATE** :date: : 2025-05-05.
        * **Docker** :whale: : Migrated to dockerfile to use/build-run the project as a native image using graalvm,
          using image: `gradle:jdk-21-and-22-graal-jammy`.
        * **General** :hammer_and_wrench: : Migrated all project to handle specific of native image
    * 4.0.1:
        * **DATE** :date: : 2025-04-04.
        * **Docker** :whale: : Change sdk image in Dockerfile, from `openjdk:21-jdk-oracle`
          to `eclipse-temurin:21-jre-alpine` (lighter image, like 15-20% less ram usage and like 50% size reduction)
    * 4.0.0:
        * **DATE** :date: : 2024-12-25.
        * **General** :hammer_and_wrench: : Initial version 4.0.0 (first of tag 4.x).

* 3.x:
    * 3.0.0:
        * **DATE** :date: : 2024-12-02.
        * **General** :hammer_and_wrench: : Initial version 3.0.0 (first of tag 3.x).

* 2.x:
    * 2.2.0:
        * **DATE** :date: : 2024-11-20.
        * **General** :hammer_and_wrench: : Initial version/deploy of lib as a (little) more formal project.