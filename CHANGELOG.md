* 5.x:
    * 5.1.0 (in progress, see `ROADMAP.md`):
        * **DATE** :date: : not released yet (started 2026-11-02).
        * **Deploy** :warning: : Deploy together with the web console `tools/api_gateway_front` of this same release. The new console relies on the `401`/`403` with CORS headers to log out; against an older backend an expired/wrong session is shown as a connection error and does not log out.
        * **Logs** :memo: : Fix: requests to routes without rewrite-path were not logged (NPE building the final route).
        * **Logs** :memo: : Fix: the final route of the log applies the rewrite only to the path (same as the gateway), not to `uri + path`.
        * **Logs** :memo: : Fix: logs were lost when `X-Forwarded-For` had several IPs (>50 chars). Now the first IP (the client) is used.
        * **Logs** :memo: : `POST /http-log/search`: `size` is capped by the new env var `MAX_LOGS_SEARCH_SIZE` (default `10000`), also when `size` is null. `total_elements` and `total_pages` are still the real ones.
        * **Logs** :memo: : `POST /http-log/search`: `response_code` parsed as a number (non numeric → `400`). `%` and `_` in `query`, `method` and `route_id` are now literal, not wildcards.
        * **Auth** :lock: : Fix: admin auth was applied to any path *containing* the admin path (ej: `/svc/_admin/x`), breaking proxied services with their own Basic auth. Now only paths starting with `/{ADMIN_PATH}/`.
        * **Auth** :lock: : Fix: malformed `Basic` header (not base64) returns `401` instead of `500`.
        * **Auth** :lock: : `401`/`403` responses include the CORS headers (CORS applied inside the Spring Security chain) and the `401` no longer sends `WWW-Authenticate: Basic` (browser native popup).
        * **Auth** :lock: : The admin auth filter no longer runs twice per request.
        * **Routes** :twisted_rightwards_arrows: : Fix: deleting a route with its id in uppercase removed it from db, but it kept working in the gateway until restart.
        * **Routes** :twisted_rightwards_arrows: : Fix: editing a route with the name of another route returns `409` instead of `500`. Any unique constraint violation is now a `409`.
        * **Routes** :twisted_rightwards_arrows: : `POST /routes/multi-add` saves all the routes in a single transaction (all or nothing).
        * **Errors** :rotating_light: : Unexpected errors (`500`) no longer return the internal message (SQL, hosts...), only `Internal server error`, and they are logged with their stacktrace (before, nothing was logged).
        * **Errors** :rotating_light: : Upstream service down or unreachable → `502 Bad gateway` (before: `500` with the internal host and port). Upstream slower than the response timeout → `504`.
        * **Errors** :rotating_light: : String error bodies are sent as `text/plain;charset=UTF-8` (before: no content type, platform charset). Errors after the response was already sent are no longer written over it.
        * **Gateway** :hourglass: : New env vars `GATEWAY_CONNECT_TIMEOUT_MS` (default `10000`) and `GATEWAY_RESPONSE_TIMEOUT` (default `60s`, empty = no timeout). :warning: Before there was no response timeout: raise it for services with slower endpoints.
        * **Gateway** :hourglass: : CORS headers sent by an upstream service are no longer duplicated in the response (the gateway ones are kept), browsers reject duplicated values.
        * **CORS** :globe_with_meridians: : New env var `CORS_ALLOWED_ORIGINS` (comma separated origin patterns, default `*` = same as before).
        * **Auth** :lock: : Brute force lockout: after `ADMIN_MAX_FAILED_ATTEMPTS` (default `10`, `0` disables it) wrong credentials from the same client ip within `ADMIN_LOCKOUT_MINUTES` (default `15`), the admin endpoints answer `429` to that ip.
        * **Auth** :lock: : Credentials compared in constant time, in a single place for login and Basic auth. The password is no longer kept in the authenticated user.
        * **Auth** :lock: : The default admin password is no longer printed on startup (only a warning), and there is a new warning when running with the default db password.
        * **Docs** :books: : README: new env vars and how the client ip is resolved (`X-Forwarded-For` is only trustworthy behind a proxy that overwrites it).
        * **Logs** :memo: : Logs are saved out of the request path: bounded in-memory queue (10 000) inserted in batches of 500 every second, using at most one db connection. Before, each request opened its own unbounded insert, which under load could take the whole db pool and slow down the real traffic. If the queue is full, logs are dropped with a warning. Pending logs are saved on shutdown.
        * **Logs** :memo: : New migration `V3`: index on `http_log.requested_at` (logs search sort and old logs clean up).
        * **Logs** :memo: : Old logs clean up deletes in batches of 10 000 (no huge transaction on a big table), and logs how many were deleted.
        * **Logs** :memo: : Request duration measured with a monotonic clock (`System.nanoTime()`).
        * **Routes** :twisted_rightwards_arrows: : Fix: after each deploy/restart there was a window of `404`s until the routes were loaded from db (async, after startup). Now they are loaded before the server accepts traffic; if they can't be loaded, the startup fails.
        * **Ops** :stethoscope: : Health check `GET /{ADMIN_PATH}/health` (no auth, not logged, `503` if the db is down), with `spring-boot-starter-actuator` (only `health` exposed). Under the admin path so it never shadows a proxied `/actuator/**`.
        * **Ops** :stethoscope: : Server logs with SLF4J (levels and stacktraces) instead of `System.out/err`.
        * **Docs** :books: : README: health check, single-instance note and async logs.
        * **Build** :package: : Spring Cloud versions from the BOM `spring-cloud-dependencies:2025.0.2` (same versions as before: gateway `4.3.4`, loadbalancer `4.3.2`). Removed the explicit `spring-cloud-gateway-server` (already a dependency of `-webflux`).
        * **Build** :package: : Test dependencies (`spring-boot-starter-test`, testcontainers, reactor-test) moved to `testImplementation`, they were shipped inside the production binary. Lombok only at compile time. `reactor-test` version from Spring Boot (was `3.8.5` over reactor-core `3.7.x`).
        * **Build** :package: : `.dockerignore` (the native build context no longer includes `.git`, `build/`, `tools/`...), and the final image runs as a non-root user.
        * **CI** :construction_worker: : GitHub Actions: tests + `processAot` on each PR and push to `develop`/`master`; native docker image build on `master`.
        * **Code** :broom: : Cleanup without behavior changes: `@SpringBootTest` removed from `App`, `ServiceConfig` is a `@Configuration`, `AuthController.login` (was `addRoute`), `RouteUpdater.updateRoutes()` returns `Mono<Void>`, the logs search no longer mutates the request and uses the entity property names, `spring.jpa` config removed (no JPA), http-logs models registered for native reflection.
        * **Docs** :books: : README: `GET /routes/{id}` and `GET /routes` return different shapes (kept for compatibility, unified in 6.x).
        * **Tests** :test_tube: : Tests run with Testcontainers (Docker required, no local Postgres) against a fake upstream. `processTestAot` disabled (only used by `nativeTest`).
        * **Tests** :test_tube: : `./gradlew test` runs only the unit tests (no Spring, no Docker), `./gradlew integrationTest` the `*IT` ones (routes, logs, security, proxy behavior, custom `ADMIN_PATH`), `check` runs both. JaCoCo coverage (unit + integration): 95 % lines / 90.6 % branches, with a gate of 90 % / 85 % in `check`.
        * **CI** :construction_worker: : The CI runs `check` (tests + coverage gate), builds and tests the web console, and on `master` smoke-tests the native docker image (health, login, route, proxied request, logs).
        * **Docs** :books: : README: how to run the tests, and a warning about routes with overlapping paths.
        * **Docs** :books: : Postman collection (`doc/`) rewritten as a test suite: assertions on every request (status codes, JSON shapes, `401`/`403`/`404`/`409`/`422`/`400` errors), route ids read from the responses (no fixed ids), per-run route names and cleanup. Same requests as before plus the error cases; `login` uses the environment credentials. The CI runs it with Postman CLI against the native image.
        * **Versions** :arrow_up: : Java `21` → `25` (LTS, gradle toolchain: a JDK 25 is needed to build, gradle detects the installed ones). Native image built with GraalVM CE `25` (`ghcr.io/graalvm/native-image-community:25`, before `gradle:jdk-21-and-22-graal-jammy` with GraalVM 21.0.2, too old for the new native build tools).
        * **Versions** :arrow_up: : Spring Boot `3.5.14` → `4.1.2` (Spring Framework 7, Spring Security 7, Jackson 3), Spring Cloud `2025.0.2` → `2025.1.4` (Gateway `4.3.4` → `5.0.4`), Gradle `8.14.2` → `9.8.2`, GraalVM native build tools `0.11.3` → `1.1.18`, `dev.root101.commons` `5.5.2` → `5.5.3` (Jackson 3). Flyway `11.12.0` → `12.4.0`, Postgres driver `42.7.14`, r2dbc-postgresql `1.1.3`, Lombok `1.18.48` and Testcontainers `2.0.5`, now taken from the Spring Boot BOM (no hardcoded versions). GitHub Actions to their latest majors.
        * **Versions** :arrow_up: : Same API contract after the Jackson 3 upgrade: the json mapper keeps the Jackson 2 defaults (snake_case, ISO dates, unknown properties ignored). Flyway auto-configuration now comes from `spring-boot-starter-flyway` (Spring Boot 4 split it into its own module).
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
          in `tools/api_gateway_front/CHANGELOG.MD`)
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