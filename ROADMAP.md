# Roadmap — Api-Gateway 6.x

Only what is still pending, for the gateway (`gateway/`) and the web console (`console/`). What is
done is in `CHANGELOG.md`.

Rules:

- Every change is recorded in `CHANGELOG.md`, under the in-progress version (currently `6.1.0`).
- Everything in the project is written in English (code, comments, docs, changelog, roadmap).
- Console: keep its base (Cubit + DI with Get + go_router + Dio). Changes in the contract of
  `/{ADMIN_PATH}/auth|routes|http-log` must be applied in both folders.

---

## Gateway features

After 6.0.0, in priority order. Impact and effort are estimates from how the project is built
today. An option of a route or of the gateway is an add-on: a new `type` of the `addon` table
(no migration, see decision 17 in `DECISIONS.md`), its own endpoints under `addons/`, its key in
`addons`, its block in the console's route panel, and GraalVM reflection hints for its records and
the predicates and filters it uses.

1. [ ] **Rate limiting per route.** Requests per IP (or API key) per route, `429` with
   `Retry-After`; protects the services from abuse and spikes. Impact: high, the first thing
   expected from a gateway. Effort: medium. An add-on (`rate_limit`: limit, per second/minute/hour,
   burst), its endpoints, its block in the route panel, native hints. Counters in memory are enough
   for one instance; Redis if there are ever several.
2. [ ] **Authentication towards the services (JWT / API key).** The gateway validates the token
   before passing the request and forwards the identity in headers (`X-User-Id`), so the services
   stop validating it each on their own. Impact: high. Effort: high. Design (issuer, JWKS, keys),
   migration (auth mode per route, API keys table), a new API and console screen to manage keys,
   `SECURITY.md`.
3. [ ] **Circuit breaker and retries.** A service that keeps failing is cut and answered with a
   fast `503` instead of waiting for timeouts; `GET`s are retried on transient failures. Impact:
   high, stops cascading failures. Effort: medium. New dependency (Resilience4j, delicate on
   GraalVM), migration, API, console fields, native hints.
4. [ ] **Request id / tracing.** Generate or forward an `X-Request-Id` (or `traceparent`) to the
   service, return it to the client and keep it in the log, to follow a request across services.
   Impact: high. Effort: low. A global filter, a migration (column in `http_log`), the field and a
   search filter in the API, a column and filter in the console.
5. [ ] **Latency in the logs and metrics per route.** Keep each request's duration and show p50/p95,
   error rate and volume per route in the console; optionally `/metrics` for Prometheus. Impact:
   high. Effort: medium. Migration (`duration_ms` and indexes), a new API for aggregates per route
   and time range, a dashboard screen designed in the canvas. Builds on 4.
6. [ ] **More predicates and filters.** `order`, `methods`, `hosts`, `headers`, all optional, in
   the admin API and the console form. Impact: medium-high. Effort: medium. Migration, API, route
   form redesign, native hints of each predicate, validation in `RouteRules`.
7. [ ] **Header transformation.** Add, remove or rewrite request and response headers per route
   (hide `Server`, set `X-Forwarded-Prefix`, inject a fixed one). Impact: medium. Effort: low-medium.
   Migration (list of rules per route), API, a key-value list editor in the console, native hints.
8. [ ] **Timeouts and max body size per route.** Today the timeouts are global. Impact: medium.
   Effort: low. Migration (2–3 columns), API, console fields, route metadata in the mapper; no new
   dependencies.
9. [ ] **Canary / traffic split.** Send a percentage of a route's traffic to another version of the
   service (`Weight` predicate), for gradual deploys. Impact: medium. Effort: medium. Design (route
   groups with weights), migration, API, console (grouping and weights), native hints.
10. [ ] **Several admin users and an audit log.** Users with roles (read-only / admin) and a record
    of who created, edited or deleted each route. Impact: medium, grows with the team. Effort:
    high. Design (roles, user management), migration (users with hashed passwords, audit table),
    a new security model (today one user from variables), new API and screens, `SECURITY.md` and
    `DECISIONS.md`.

## Possible improvements

- [ ] Gateway: **HTML maintenance page.** Today a route in maintenance answers a Problem Details
  (JSON) to everyone. A browser (`Accept: text/html`) could get a page instead: first one built-in
  template (title, message, return time, in the request's language, no template engine), later the
  admin's own HTML in the maintenance add-on (served as is to the end users: review it as a
  security change).

- [x] Gateway: **Health check add-on.** Each route can have a health check (`health_check`: path,
  every 10 s to 1 h): a scheduler calls it and keeps the last result (time, status, ms) in the
  add-on's `state`. Reviewed as a security change: decision 18 in `DECISIONS.md`. Done in 6.1.0.
- [ ] Console: **Health check add-on.** The gateway side is done (`docs/api.md`, "Health check"):
  show LIVE / DOWN per route from `addons.health_check.state`, set it (path, interval, on/off) and a
  "Run now" (`POST .../health-check/run`). A history (uptime) would be a new table in the gateway.

- [ ] Gateway: **HTTP/2 and gRPC** support, for a later version (not 6.0.0). gRPC needs HTTP/2 end
  to end (trailers, multiplexed streams): enable it on the gateway server (`server.http2.enabled`)
  and on the client to the upstreams, check the Railway edge forwards HTTP/2 to the container, and
  check the http logs filter with long-lived streams. Then update *Supported protocols* in the README.
- [ ] Gateway: **CORS per route**: today one policy (`CORS_ALLOWED_ORIGINS`) for every path, and
  the services' own CORS headers are replaced. Let each route keep its service's CORS (forward the
  preflight to the upstream instead of answering it in the gateway) or set its own origins, and
  maybe edit them from the admin API and the console. See decision 15 in `DECISIONS.md`.
