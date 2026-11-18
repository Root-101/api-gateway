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

1. [ ] **Add-ons.** Options a route, or the whole gateway, can have on top of the routing, done and
   pending, in priority order.
   - [x] 1.1. **Maintenance** (`maintenance`), of a route and of the whole gateway: `503` to its clients
     while on, with a message and a return time. Gateway and console done in 6.1.0, decision 17 in
     `DECISIONS.md`.
   - [x] 1.2. **Health check** (`health_check`), routes only: a scheduler calls a path of the route
     (every 10 s to 1 h) and keeps the last result (time, status, ms) in the add-on's `state`;
     LIVE / DOWN and "Run now" in the console. Gateway and console done in 6.1.0, decision 18 in
     `DECISIONS.md`. A history (uptime) would be a new table in the gateway.
   - [x] 1.3. **Rate limit** (`rate_limit`), of a route and of the whole gateway: requests per client IP
     per second/minute/hour, with burst, `429` with `Retry-After`. Counters in memory, enough for one
     instance; Redis if there are ever several. Gateway and console done in 6.1.0, decision 19 in
     `DECISIONS.md`.
   - [ ] 1.4. **CORS per route.** Today one policy (`CORS_ALLOWED_ORIGINS`) for every path, and the
     services' own CORS headers are replaced. Let each route keep its service's CORS (forward the
     preflight to the upstream instead of answering it in the gateway) or set its own origins, as
     an add-on of the route, edited from the admin API and the console. See decision 15 in
     `DECISIONS.md`.
   - [ ] 1.5. **Circuit breaker and retries.** A service that keeps failing is cut and answered with a
     fast `503` instead of waiting for timeouts; `GET`s are retried on transient failures. Impact:
     high, stops cascading failures. Effort: medium. An add-on per route (thresholds, retries), new
     dependency (Resilience4j, delicate on GraalVM), native hints.
   - [ ] 1.6. **Header transformation.** Add, remove or rewrite request and response headers per route
     (hide `Server`, set `X-Forwarded-Prefix`, inject a fixed one). Impact: medium. Effort:
     low-medium. An add-on (list of rules) of a route and maybe of the whole gateway, a key-value
     list editor in the console, native hints.
   - [ ] 1.7. **Timeouts and max body size per route.** Today the timeouts are global
     (`GATEWAY_CONNECT_TIMEOUT_MS`, `GATEWAY_RESPONSE_TIMEOUT`), which stay as the default. Impact:
     medium. Effort: low. An add-on per route, route metadata in the mapper; no new dependencies.
2. [ ] **Authentication towards the services (JWT / API key).** The gateway validates the token
   before passing the request and forwards the identity in headers (`X-User-Id`), so the services
   stop validating it each on their own. Impact: high. Effort: high. It could be an add-on (the auth
   mode of a route), but for now it is its own item: design (issuer, JWKS, keys), an API keys table
   (a migration), a new API and console screen to manage keys, `SECURITY.md`.
3. [ ] **Request id / tracing.** Generate or forward an `X-Request-Id` (or `traceparent`) to the
   service, return it to the client and keep it in the log, to follow a request across services.
   Impact: high. Effort: low. A global filter, a migration (column in `http_log`), the field and a
   search filter in the API, a column and filter in the console. Not an add-on: always on.
4. [ ] **Latency in the logs and metrics per route.** Keep each request's duration and show p50/p95,
   error rate and volume per route in the console; optionally `/metrics` for Prometheus. Impact:
   high. Effort: medium. Migration (`duration_ms` and indexes), a new API for aggregates per route
   and time range, a dashboard screen designed in the canvas. Builds on 3. Not an add-on: always on.
5. [ ] **More predicates and filters.** `order`, `methods`, `hosts`, `headers`, all optional, in
   the admin API and the console form. Impact: medium-high. Effort: medium. Migration, API, route
   form redesign, native hints of each predicate, validation in `RouteRules`. Not an add-on: they
   decide which route a request matches, part of the route itself.
6. [ ] **Canary / traffic split.** Send a percentage of a route's traffic to another version of the
   service (`Weight` predicate), for gradual deploys. Impact: medium. Effort: medium. Design (route
   groups with weights), migration, API, console (grouping and weights), native hints. Not an
   add-on: it joins several routes in a group.
7. [ ] **Several admin users and an audit log.** Users with roles (read-only / admin) and a record
   of who created, edited or deleted each route. Impact: medium, grows with the team. Effort:
   high. Design (roles, user management), migration (users with hashed passwords, audit table),
   a new security model (today one user from variables), new API and screens, `SECURITY.md` and
   `DECISIONS.md`. Not an add-on: it is about the admins, not the traffic.

## Possible improvements

- [ ] Gateway: **HTTP/2 and gRPC** support, for a later version (not 6.0.0). gRPC needs HTTP/2 end
  to end (trailers, multiplexed streams): enable it on the gateway server (`server.http2.enabled`)
  and on the client to the upstreams, check the Railway edge forwards HTTP/2 to the container, and
  check the http logs filter with long-lived streams. Then update *Supported protocols* in the README.

- [ ] Gateway: **HTML maintenance page**, an extra of the maintenance add-on, not planned for now.
  Today a route in maintenance answers a Problem Details (JSON) to everyone. A browser
  (`Accept: text/html`) could get a page instead: first one built-in template (title, message,
  return time, in the request's language, no template engine), later the admin's own HTML in the
  maintenance add-on (served as is to the end users: review it as a security change).
