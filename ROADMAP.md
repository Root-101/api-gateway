# Roadmap — Api-Gateway 6.x

Only what is still pending, for the gateway (`gateway/`) and the web console (`console/`). What is
done is in `CHANGELOG.md`.

Rules:

- Every change is recorded in `CHANGELOG.md`, under the in-progress version (currently `6.1.2`).
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
   - [x] 1.4. **CORS** (`cors`), of the gateway and of each route: origins and credentials, edited
     from the admin API and the console; replaces `CORS_ALLOWED_ORIGINS`, migrated into the
     gateway's on the first start. Forwarding the preflight to the service was rejected. Gateway
     and console done in 6.1.0, decision 20 in `DECISIONS.md`.
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

- [ ] Gateway, 7.0: **remove `CORS_ALLOWED_ORIGINS`**, deprecated in 6.1.0. Only its read goes: the
  gateway's CORS add-on is still created with `*` on the first start (decision 20 in `DECISIONS.md`).
- [ ] Gateway: **HTTP/2 and gRPC** support, for a later version (not 6.0.0). gRPC needs HTTP/2 end
  to end (trailers, multiplexed streams): enable it on the gateway server (`server.http2.enabled`)
  and on the client to the upstreams, check the Railway edge forwards HTTP/2 to the container, and
  check the http logs filter with long-lived streams. Then update *Supported protocols* in the README.

- [ ] Gateway: **Performance tests and benchmarks**, not done yet. Measure what the gateway adds
  on top of calling the service directly: latency (p50/p95/p99) and throughput, CPU and memory, on
  the JVM and the native image, with no add-ons and with each one on (maintenance, rate limit), and
  the cost of the http logs (one db row per request). A load tool against a local stub service,
  run by hand, not in CI; the results and how to repeat them in the docs.

- [ ] Gateway: **Routes with the same path.** Today only the name is unique (`409`): two routes can
  have the same `path` (`/dumpling/**`), and only one gets the traffic, with no warning. Every
  route has order `0`, so which one wins isn't defined, and the other one's add-ons (a rate limit,
  a maintenance) never apply. Seen on 2026-11-18 with a copied route. Reject the same path with a
  `409` on create, edit, multi-add and restore (or at least warn in the console). Overlapping
  patterns (`/a/**` and `/a/b/**`) are a separate question: they need an explicit order (item 5).

- [ ] Gateway: **HTML maintenance page**, an extra of the maintenance add-on, not planned for now.
  Today a route in maintenance answers a Problem Details (JSON) to everyone. A browser
  (`Accept: text/html`) could get a page instead: first one built-in template (title, message,
  return time, in the request's language, no template engine), later the admin's own HTML in the
  maintenance add-on (served as is to the end users: review it as a security change).

- [ ] Console: **WebAssembly build** (`flutter build web --release --wasm`), not urgent. Checked on
  2026-11-17 with Flutter 3.47: it builds without changes (the code only uses `dart:js_interop` and
  `package:web`, no `dart:html`, and every dependency compiles). The Dart code becomes
  `main.dart.wasm` (3.6 MB, vs 4.0 MB of `main.dart.js`), drawn by skwasm (Skia in WASM, with a
  render thread) instead of CanvasKit. The build keeps both: `flutter_bootstrap.js` loads the
  WASM where WasmGC exists (Chrome/Edge 119+, Firefox 120+) and the JS elsewhere (some Safari
  versions). Gain: smoother frames and less jank in big tables and the map, a slightly faster
  start; moderate for an admin console. To do: `--wasm` in `console/Dockerfile`, and in
  `console/nginx.conf` `Cross-Origin-Opener-Policy: same-origin` and
  `Cross-Origin-Embedder-Policy: credentialless` (without them the browser gives no threads;
  `credentialless` rather than `require-corp` so CanvasKit and the fonts from gstatic still load).
  The CSP already has `'wasm-unsafe-eval'`, `no-cache` covers the `.wasm`, and nginx 1.28 serves it
  as `application/wasm`. Risk: COOP/COEP can block cross-origin resources; test in Chrome, Firefox
  and Safari against the real gateway before releasing (Flutter still labels WASM as new).
