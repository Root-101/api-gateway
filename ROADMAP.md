# Improvement roadmap — Api-Gateway 5.x

Goal: fix problems and harden the service **without breaking the public API or the current front**.
Each item says whether it's compatible (✅), changes something visible (⚠️ review), or would be breaking (❌ only for 6.x).

Suggested order: Phase 1 → 2 → 3 → 4. Inside each phase, top to bottom. The testing section moves forward in parallel.

Rules:
- Every change is recorded in `CHANGELOG.md`, under the in-progress version (currently `5.1.0`).
- Everything in the project is written in English (code, comments, docs, changelog, roadmap).

---

## Phase 1 — Real bugs (high impact, low risk)

- [x] **Requests to routes WITHOUT rewrite-path are not logged.** ✅
  `HttpLogUseCaseImpl.saveHttpLog` does `.replaceAll(routeEntity.getRewritePathFrom(), ...)`; if the route has no rewrite it's `null` → `NullPointerException` → falls into the `catch` and the log is silently lost.
  Fix: apply the replace only if `rewritePathFrom/To != null`.
- [x] **The log's "final route" applies the regex to `uri + path`**, not only to the path (as Spring Cloud Gateway really does). ✅
  Fix: `uri + path.replaceAll(from, to)`. `${segment}` works the same in Java, checked with a test.
- [x] **Logs lost when `X-Forwarded-For` is long.** ✅
  `X-Forwarded-For` can be `"ip1, ip2, ip3"` (>50 chars) → `@Size(max=50)` fails → log discarded. Also `http_method` is `varchar(25)` in db and `@Size(max=50)` in the entity.
  Fix: take only the first IP of the header (trimmed) and truncate/align sizes.
- [x] **The admin auth filter uses `path.contains(adminBasePath)`.** ✅
  Any proxied route containing `_admin` in the path (ej. `/svc/_admin/x`) that sends its own `Basic` header for the target service is intercepted by the gateway and gets a 403.
  Same `contains` in `HttpLogUseCaseImpl` (marks logs as "Admin" when they are not).
  Fix: `path.startsWith("/" + adminBasePath + "/")` in `AdminAuthenticationWebFilter` and `HttpLogUseCaseImpl`.
- [x] **`AdminAuthenticationWebFilter` runs twice.** ✅
  Being a `@Component` and a `WebFilter`, Spring registers it in the global chain **and** it's added to the security chain. Fix: not a bean anymore, created inside `SecurityConfig`.
- [x] **Malformed Basic header → 500.** ✅
  `Base64.getDecoder().decode(...)` throws `IllegalArgumentException` → 500. Also the manager threw synchronous exceptions instead of `Mono.error(...)`. Fix: catch it and return 401.
- [x] **Deleting a route with an uppercase UUID leaves the route active.** ✅
  `deleteRoute` used the raw `routeId` for `cache.remove` and `routeDefinitionWriter.delete`. With `ABC...` in uppercase, it was deleted from db but not from the gateway (kept routing until restart). Fix: use `route.getRouteId().toString()`.
- [x] **Editing a route with a name already in use returns 500.** ✅ (⚠️ status goes from 500 to 409)
  `editRoute` didn't check `name` uniqueness → db constraint violation. Same in a race condition in `addRoute`. Fix: check `findByName` excluding its own id, and map `DataIntegrityViolationException` → 409.
- [x] **`addAllRoutes` is not transactional.** ✅
  If `saveAll` fails halfway, half the routes stay in db without being loaded in the gateway. Fix: `TransactionalOperator` around the save.
- [x] **Log search with null `size` loads the WHOLE table in memory.** ⚠️
  `size == null` → `Integer.MAX_VALUE`. With millions of logs → OOM. Also `page > 0` with `MAX_VALUE` overflows the offset.
  The front uses it to "export all", so: keep the contract but with a configurable cap (`MAX_LOGS_SEARCH_SIZE`, default 10 000), documented.
- [x] **`response_code` filter.** ✅
  The request receives it as `String` and the column is `integer`. Now parsed to `Integer` (non numeric → 400).
- [x] **Escape `%` and `_` in the `LIKE` filters** of the log search. ✅
- [x] **Admin 401/403 without CORS headers** (the browser hides the status and the front sees a connection error), and 401 with `WWW-Authenticate: Basic` (browser native popup). ⚠️
  Fix: CORS inside the Spring Security chain (`http.cors(...)`) and a 401 entry point without `WWW-Authenticate`.

> Phase 1 is covered by `ServiceTest` (Testcontainers + fake upstream). Pending: a test of `multi-add` failing halfway (the transactional fix has no test).

## Testing and coverage (cross-cutting, in parallel to the phases)

Goal: the highest possible coverage (target: ≥ 85 % lines and ≥ 75 % branches in `src/main`), with tests that fail if the API contract breaks.
Every fix of any phase ships with its regression test.

### Infrastructure
- [x] Integration tests with **Testcontainers** (real Postgres) and a fake upstream with reactor-netty (no local Postgres).
- [x] **JaCoCo**: HTML/XML report on `./gradlew test` and a minimum coverage gate (start at the current coverage and raise it each phase up to the target).
  Done: `jacocoTestReport` (unit + integration together) and `jacocoTestCoverageVerification` in `check`: 90 % lines / 85 % branches (current: 95 % / 90.6 %).
- [x] Split `ServiceTest` into classes per feature (`RoutesIT`, `HttpLogsIT`, `SecurityIT`, `GatewayProxyIT`) with a base class and **a single shared container** (reuses the Spring context).
  Done: `RoutesIT`, `HttpLogsIT`, `SecurityIT`, `GatewayProxyIT`, `CustomAdminPathIT` on `support/IntegrationTest`.
- [x] Clean state between tests: empty tables and gateway routes in `@BeforeEach`, instead of relying on unique names.
  Decided not to: every test uses unique names/paths, so they are independent without resetting the gateway routes (documented in `IntegrationTest`).
- [x] Builders/fixtures for requests (`RouteConfigRequest`, log searches) and a helper to wait for async logs.
- [x] Separate unit tests (fast, no Spring) from integration tests (`*IT`), each with its own Gradle task.
  Done: `./gradlew test` (unit, ~15 s) and `./gradlew integrationTest` (`*IT`, Docker); `check` runs both + the coverage gate.

### Unit tests (no Spring)
- [x] `RouteDefinitionMapper`: with and without rewrite, id, uri, `Path` predicate, args order.
- [x] `HttpLogUseCaseImpl.buildFinalRoute`: no rewrite, named groups, `$\{segment}`, uri with and without trailing `/`.
- [x] `HttpLogSearchRepo.contains`: escaping of `%`, `_` and `\`.
- [x] `HttpLogsWebFilter`: client IP (no XFF, single XFF, list, empty, IPv6, >50 chars) and `getServerIp` (X-Forwarded-Proto/Host/Port, ports 80/443).
- [x] `AdminAuthenticationManager`: valid, wrong password, invalid base64, no `:`, empty user or password, password containing `:`, UTF-8.
- [x] `GlobalExceptionHandler`: status and body per exception type (`ValidationException`, `ApiException`, `DataIntegrityViolationException`, `ErrorResponse`, generic) and already committed response.
- [x] `HttpLogEntity.RouteLog`: JSON round trip; null or blank `route`.
- [x] `CleanUpOldLogs`: deletes only what's older than the limit (exact edge included).

### Integration — Routes (`/_admin/routes`)
- [x] Full CRUD: list, get by id, create, edit, delete. The response keeps snake_case and the current shape (including `GET /{id}` with flat `rewrite_path_from/to`).
- [x] 422 validations per field (blank `name`/`path`/`uri`, invalid uri, >255 chars) with the `{source, invalid_value, message}` format.
- [x] `POST` with duplicated name → 409; `multi-add` with duplicates in the list → 409 and with a duplicate in db → 409.
- [x] `multi-add` failing halfway → nothing saved in db nor in the gateway (rollback).
- [x] Non existing id or invalid UUID in GET/PUT/DELETE → 404.
- [x] Editing `path`/`uri`/rewrite really changes the routing (old one gives 404, new one reaches the upstream).
- [x] On startup, the routes saved in db are loaded in the gateway (before accepting traffic).

### Integration — Logs (`/_admin/http-log`)
- [x] Request to a route without and with rewrite is logged with its final route; long XFF.
- [x] Search: `size` cap, `response_code` filter, escaped wildcards.
- [x] What is NOT logged: `GET /_admin/routes*`, `/_admin/http-log*` and `OPTIONS`. What is: the rest of admin requests (as "Admin" route) and requests without route (null `route`).
- [x] The upstream status (4xx/5xx) and the "no route" 404 are stored in the log.
- [x] Each search filter alone and combined (`method`, `query`, `route_id`, `NO-ROUTE`, `from_date`/`to_date`), pagination and order by date desc.
- [x] Cleanup of old logs (`MAINTAIN_LOGS_FOR_DAYS`).

### Integration — Security
- [x] 401 without credentials (no `WWW-Authenticate`), 401 with malformed Basic, 403 with wrong credentials, all with CORS; login OK and wrong login.
- [x] Proxied path containing `_admin` with its own Basic reaches the upstream untouched.
- [x] Parametrized test: **all** admin endpoints require auth and no proxied route does.
- [x] Preflight `OPTIONS` (admin and proxied routes) answers with CORS without auth.
- [x] Custom `ADMIN_PATH`: the admin moves and `_admin` is no longer special.
- [x] Login with empty fields → 422.

### Integration — Gateway behavior
- [x] End-to-end proxy against the fake upstream (route created by API → request → upstream response).
- [x] Query string, headers, body (POST/PUT) and upstream status are forwarded unchanged.
- [x] Upstream down or slow: pin the current status, then the new one from Phase 2 (502/504).
- [x] Routes with overlapping paths: document with a test which one wins.
  Done: the first created wins at runtime; after a restart it depends on the db order. Documented in the README: avoid overlapping paths.

### Contract and native build
- [x] Run the Postman collection from `doc/` with **Postman CLI** against `docker-compose` in CI (catches contract breaks for external clients).
  Done: the collection now has assertions on every request (20 requests, 32 assertions: status codes, JSON shapes, error bodies), reads the route ids from the responses and uses per-run names, deleting what it creates. Runs in the CI job `native-image` against the native image (the same image `docker-compose` builds). Verified locally with Postman CLI 1.73 (repeatable, exit code 1 on any failure).
- [x] Smoke test of the **native image** in CI: build the Dockerfile, start with Postgres, login + create route + proxied request (catches GraalVM reflection problems that JVM tests don't see).
  Done in `.github/workflows/ci.yml` (job `native-image`, on `master`): health, login, create a route to itself, proxied request, logs search. Not run yet (it runs on GitHub).
- [ ] (Optional) Mutation testing with **PIT** on the routes and logs logic, to measure test quality beyond coverage.

> The front (`tools/api_gateway_front/`) has its own roadmap and tests, handled by the front agent.

## Phase 2 — Security and robustness

- [x] **Don't leak internal messages to the client on 500 errors.** ✅
  `GlobalExceptionHandler` returns `rawEx.getMessage()` (can include SQL, internal hosts, etc.). Return a generic message and **log** the stacktrace (today no error is logged at all).
- [x] **Map upstream errors to 502/503/504 instead of 500.** ⚠️
  `ConnectException`, timeouts, load balancer `NotFoundException` → today they come out as 500 with the internal message ("Connection refused: 10.0.0.5:8081").
- [x] **Configure the gateway HTTP client timeouts.** ✅
  Without `connect-timeout`/`response-timeout` a hung upstream holds connections forever. Add them with env vars and sensible defaults (ej. 5s / 60s).
- [x] **`GlobalExceptionHandler`: check `response.isCommitted()`**, use explicit `UTF-8` in `getBytes()` and set `Content-Type: text/plain` on string responses. ✅
- [x] **Constant-time credentials comparison** (`MessageDigest.isEqual`) in `AdminAuthenticationManager` and `AuthUseCaseImpl`; merge the duplicated logic in a single place. ✅
- [x] **Rate-limit / temporary lockout on `/auth/login` and on failed Basic auth** (brute force). ✅
  Done: in-memory lockout per client ip → `429` (`ADMIN_MAX_FAILED_ATTEMPTS`, `ADMIN_LOCKOUT_MINUTES`). Per instance (see Multi-instance in Phase 3).
- [x] **Don't print the default password to the console** (`AdminAuthenticationManager`). Warn without showing it. ✅
- [x] **Don't keep the password in `CustomUserDetails`** (it's not used). ✅
- [x] **`X-Forwarded-*` is blindly trusted** (spoofable IP in logs). Use `ForwardedHeaderTransformer` / `server.forward-headers-strategy` and document it. ⚠️
  Done: documented in the README (only trustworthy behind a proxy that overwrites the header). No transformer: it would change the `X-Forwarded-*` the upstreams receive.
- [x] **CORS "allow all + credentials" for everything, admin included.** ⚠️
  Make it configurable by env var (`CORS_ALLOWED_ORIGINS`, default `*` to not break anything). Also check CORS headers are not duplicated with the ones the upstream already returns (`DedupeResponseHeader`).
- [x] **Front: "Remember me" stores username and password** (on web, `flutter_secure_storage` = localStorage encrypted with a key also stored in the browser). Minimum: warn about it in the UI; later, a session token (see Future). ✅ (front agent)
- [x] **Remove default credentials from `application.yml`** (`DB_PASSWORD:admin123`) or at least warn on startup, same as with the admin. ✅
  Done: startup warning (removing the default breaks the native build, see comment in the yml).

## Phase 3 — Performance and operations

- [x] **Log writing out of the hot path.** ✅
  Today each request does `repo.save(entity).subscribe()` (fire-and-forget, unbounded, no error handling). Under load it saturates the R2DBC pool and affects real traffic.
  Fix: bounded queue (`Sinks.many().unicast().onBackpressureBuffer(...)` + `bufferTimeout` → batch insert), dropping with a metric when full.
  Done: `HttpLogWriter` (bounded `ArrayBlockingQueue` + batch insert every 1s, drop counter logged as a warning). No metric (no actuator metrics yet).
- [x] **Indexes on `http_log`.** ✅
  New migration `V3__http_log_indexes.sql`: index on `requested_at` (sorted search + daily cleanup) and optionally `response_code`.
  Done: `V3__http_log_indexes_20261102.sql` (`requested_at`). Not `CONCURRENTLY`: it deadlocks with the Flyway transactional lock.
- [x] **Logs cleanup in batches** (delete in chunks instead of one giant `DELETE` in a single transaction). ✅
- [x] **Routes available before accepting traffic.** ✅
  `initRoutes` runs async on `ApplicationReadyEvent` → a window of 404s after each deploy. Simple option: load them blocking before ready. Better option: a db-backed `RouteDefinitionRepository` (also removes the manual cache).
  Done: simple option (blocking load in `afterSingletonsInstantiated`, before the web server starts).
- [x] **Multi-instance:** route changes are applied only on the replica that receives the call. Document it as single-instance, or refresh periodically / Postgres `LISTEN/NOTIFY`. ✅
  Done: documented as single-instance in the README.
- [x] **Measure duration with `System.nanoTime()`** in `HttpLogsWebFilter`. ✅
- [x] **Health check:** add `spring-boot-starter-actuator` (only `health`, outside auth) and `HEALTHCHECK` in Docker / Railway. ✅ (check native image compatibility)
  Done: `/{ADMIN_PATH}/health` (actuator, only `health`). `processAot` ok, native image not built yet. No Docker `HEALTHCHECK`: the runtime image has no curl; use the platform health check (Railway healthcheck path).
- [x] **Logging with SLF4J** instead of `System.out/err.println` (levels, format, and seeing real errors). ✅
- [x] **Graceful shutdown.** ✅ Already enabled by default since Spring Boot 3.4 (seen in the test logs), nothing to do.

## Phase 4 — Cleanup, build and quality

### Build / dependencies
- [x] Use the **Spring Cloud BOM** (`spring-cloud-dependencies`) instead of loose versions (`4.3.4` / `4.3.2`) to avoid misalignment with Boot 3.5. ✅
- [x] Remove `spring-cloud-gateway-server` (legacy artifact) and keep only `spring-cloud-gateway-server-webflux`. ✅
- [x] **Test dependencies in `implementation`** (`spring-boot-starter-test`, testcontainers, reactor-test) → move them to `testImplementation`. Today they ship inside the production binary. ✅
- [x] Lombok only as `compileOnly` + `annotationProcessor` (remove the `implementation`). ✅
- [x] Check that the `commons` dependency via `sourceControl` (git) is pinned to a tag/commit, not a branch. ✅ Already pinned: Gradle resolves `5.5.2` to the git tag `5.5.2`.

### Code
- [x] Remove `@SpringBootTest` from `App.java` (test annotation on the main class). ✅
- [x] `ServiceConfig` is `@Service` → `@Configuration`; remove unused imports. ✅
- [x] `AuthController.addRoute` → rename to `login`. ✅
- [x] `RouteUpdater.updateRoutes()` unnecessary generic → `Mono<Void>`. ✅
- [x] `HttpLogEntity` uses its own static `ObjectMapper`: use the bean or document why. ✅
- [x] `HttpLogSearchRepo`: don't mutate the request in `HttpLogUseCaseImpl.search`; unify column vs property names in `Criteria`. ✅
- [x] `application.yml`: remove `spring.jpa.*` config (there's no JPA). ✅
- [x] `ReflectionConfig`: add the http-logs models (`HttpLogSearchRequest/Response`, `HttpLogResponse`, `RouteLog`) if not covered — verify in native. ✅
- [ ] `GET /routes/{id}` returns the **entity** (flat `rewrite_path_from/to`) and `GET /routes` returns `RouteConfigResponse` (`rewrite_path` object). ❌ unify only in 6.x; document it for now. Documented in the README.

### Tests
See the **Testing and coverage** section.

### Docker / CI
- [x] Add `.dockerignore` (today `.git`, `build/`, `tools/` are copied into the native build context). ✅
- [x] Final image: non-root user; pin image versions (`debian:bookworm-slim` OK, the front uses `debian:latest`). ✅
- [x] Front Dockerfile: `nginx` with SPA fallback (`try_files $uri /index.html`) and no-cache headers for `env.js`. ✅ (front agent)
  Done by the front agent: `tools/api_gateway_front/nginx.conf` (SPA fallback, `no-cache`, CSP and security headers).
- [x] CI (GitHub Actions): build + tests on each PR; native build on `main`. ✅ `.github/workflows/ci.yml` (native = `docker build` on `master`, the main branch of the remote).

### Future (6.x, contract changes)
- [ ] Login returning a token (JWT/session) instead of sending user/password on every request. Keep Basic in parallel during the transition.
- [ ] `login` with wrong credentials → 401 (today 403).
- [ ] Routes with `order`, multiple predicates (method, host, headers) and extra filters.
- [ ] `http_log.route` column as `jsonb` (or a `route_id` column) to filter by route without `LIKE` over JSON.
