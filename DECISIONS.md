# Design decisions

Why the gateway behaves the way it does where that is not obvious from the code. When a decision
changes, update it here.

## 1. The database in parts, not as a URL

The connection is set with `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME` and `DB_PASSWORD`, never
with a connection string.

The gateway needs two URLs to the same database: R2DBC (`r2dbc:postgresql://…`) for its reactive
queries, and JDBC (`jdbc:postgresql://…`) for Flyway, which has no reactive driver. Asking for two
strings would mean writing the same database twice, and a deploy where they differ would migrate
one database and use another. From the parts, `application.yml` builds both.

## 2. Routes ready before the first request

The routes are loaded from the database before the server accepts traffic; if they can't be loaded,
the start fails.

Before 6.0.0 they were loaded after the start, and every deploy answered `404` for a moment to the
requests that came in first. A gateway that starts without its routes is worse than one that
doesn't start: the orchestrator keeps the old one running.

## 3. Logs never slow down the traffic

Each request's log goes to an in-memory queue (10 000 at most), saved in batches every second, out
of the path of the request.

| Decision                         | Why                                                                                                        |
|----------------------------------|------------------------------------------------------------------------------------------------------------|
| Batches, not one insert each     | One round trip to the database per second instead of one per request                                       |
| A bounded queue that drops       | With the database slow or down, losing logs (with a warning) is better than holding requests or running out of memory |
| Saved on a graceful shutdown     | A deploy doesn't lose the logs still in the queue                                                          |
| Method, path, route, status, IP, user agent; no query, headers or body | Enough to follow the traffic; nothing that carries tokens or personal data            |
| A `route_id` column with its index | Searching by route was a `LIKE` over JSON                                                                |

## 4. Tokens in memory

The login gives an opaque random token, kept in memory with its expiry; Basic auth with the same
credentials keeps working for scripts.

There is one user and, by design, one instance (§6), so a store shared between instances, or a
signed JWT that can't be revoked, would add weight for nothing. The price is known and accepted: a
restart logs everyone out, and the console handles it (a dialog asks for the password again).

## 5. One port, the admin API under a path

The proxied traffic and the admin API share the port; the admin API lives under `ADMIN_PATH`
(`_admin`).

One port is one thing to expose and one health check. The path is configurable so it can't steal
a path a service needs. Admin auth applies to paths that *start* with it, not that contain it.

## 6. One instance

Routes in use, tokens and the lockout count live in each instance. A route changed through the API
is applied in the instance that got the call; the others load it when they restart.

The gateway is meant for small and medium deployments, where one instance (~150 MB) is plenty.
Sharing that state would need a message bus or a shared store for every replica.

## 7. A native image

The gateway is built with GraalVM as a native binary, on `debian:trixie-slim`.

It cuts memory from ~350–500 MB on a JVM to ~150 MB, and on platforms that bill memory that is most
of the cost. The price is a slow build and reflection hints for what Spring can't see
(`ReflectionConfig`). HTTPS upstreams need `-H:+SharedArenaSupport`: without it every route to an
`https://` service answered `500`.

## 8. The console is its own image, configured at start

The console is served by nginx in a separate image; an entrypoint writes `env.js` from
`GATEWAY_SERVICE_URL`, `ADMIN_PATH` and `SESSION_TIMEOUT_MINUTES` when the container starts.

The console is optional: the admin API is enough for scripts, and a gateway without it serves
nothing a stranger could load. Read at start, the same image works in every environment, without a
build per URL.

## 9. Errors that don't help the browser log in

`401` and `403` carry the CORS headers and no `WWW-Authenticate`.

Without the CORS headers the browser hides the status from the console, which can't tell an
expired session from a network error. With `WWW-Authenticate: Basic`, the browser opens its own
login popup over the console.

## 10. Upstream failures with their own status

A service that can't be reached answers `502`; one that doesn't connect or answer in time
(`GATEWAY_CONNECT_TIMEOUT_MS`, `GATEWAY_RESPONSE_TIMEOUT`), `504`.

Before 6.0.0 both were a `500` with the internal host in the message: wrong status, and a leak of
the private network. The response timeout only covers the wait until the answer starts, so SSE and
WebSocket keep working.

## 11. The same JSON as before Jackson 3

Spring Boot 4 brings Jackson 3, with other defaults (dates, unknown fields). The mapper keeps the
Jackson 2 defaults, so the admin API's JSON didn't change with the upgrade.

## 12. Bounded log searches

`size` is capped by `MAX_LOGS_SEARCH_SIZE` (10 000), and `response_code` with fewer than three
digits is a prefix (`4` = 4xx, `50` = 500–509).

An unbounded page could read the whole table into memory. The prefix gives the console its
families (2xx…5xx) without another field. The console's export walks every page instead of asking
for one huge one.
