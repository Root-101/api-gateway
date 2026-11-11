# The API

A tour of the admin HTTP API of the gateway, with real requests and responses (taken from a
running gateway). The console uses exactly these calls; [`console.md`](console.md) says which one
each screen makes.

The gateway serves two things on the same port (8080 by default):

- **Proxied traffic** at any path: each request goes to the service of the [route](#how-a-request-is-routed)
  whose path matches.
- **Admin API** at `/{ADMIN_PATH}` (`/_admin` by default): log in, manage the routes, search the
  logs. Always JSON in, JSON or plain text out. Don't give a route a path under it.

The examples use the default `ADMIN_PATH`; change it and every path below changes with it. Keys
are `snake_case`. Dates are ISO 8601 with the offset of the server's time zone
(`2026-11-10T21:29:12.096276-06:00`; `Z` in the Docker image, which runs in UTC).

The [Postman collection](#postman-collection) has every call below, with assertions.

## Authentication

| Who                                          | How                                                                                                    |
|----------------------------------------------|--------------------------------------------------------------------------------------------------------|
| The console (and anything else that logs in) | `Authorization: Bearer <token>`, from [`POST /_admin/auth/login`](#log-in)                             |
| Scripts and tools                            | `Authorization: Basic <base64(username:password)>`, with `ADMIN_USERNAME` and `ADMIN_PASSWORD`        |
| Nobody                                       | Only `POST /_admin/auth/login`, [`GET /_admin/health`](#health), `OPTIONS` preflights, and proxied traffic |

There is one user, the admin (`ADMIN_USERNAME`, `ADMIN_PASSWORD`; `admin` and `admin123**` by
default, with a warning in the server log). The token is opaque (not a JWT) and lasts
`ADMIN_TOKEN_MINUTES` (480 by default). Tokens live in memory: a restart of the gateway logs
everyone out, and there is no logout or refresh.

Without credentials, or with an unknown or expired token, the answer is a `401` with no body (and no
`WWW-Authenticate`, so browsers don't open their login popup):

```http
HTTP/1.1 401 Unauthorized
content-length: 0
```

Basic auth with a wrong password is a `403`:

```http
HTTP/1.1 403 Forbidden
Content-Type: text/plain;charset=UTF-8

Forbidden
```

Wrong credentials (in the login or in Basic auth) count per client IP. After
`ADMIN_MAX_FAILED_ATTEMPTS` (10 by default) within `ADMIN_LOCKOUT_MINUTES` (15 by default), that IP
gets a `429` on every admin path until the window ends: the login, a valid token, and the health
check too. Proxied traffic is not affected. A correct login resets the count. The client IP is the
first one of `X-Forwarded-For`, or the connection's IP without it.

```json
{"type": null, "title": "Too Many Requests", "status": 429, "detail": "Too many failed attempts, try again later", "instance": null, "properties": null}
```

There is no `Retry-After` header.

CORS allows the origins of `CORS_ALLOWED_ORIGINS` (`*` by default), any method and any header,
with credentials.

## Errors

The body of an error depends on where it comes from. There are four shapes.

**Plain text** for the errors of the gateway itself (`Content-Type: text/plain`): the message is
the whole body.

```http
HTTP/1.1 404 Not Found
Content-Type: text/plain;charset=UTF-8

Route does not exist: 00000000-0000-0000-0000-000000000001
```

```http
HTTP/1.1 409 Conflict
Content-Type: text/plain;charset=UTF-8

Route already exists: users-service
```

**A list of violations** for a body that breaks a rule, as a `422`. One entry per broken rule; a
field that breaks two rules comes twice:

```json
[
  {"source": "uri", "invalid_value": "not a url", "message": "must be a valid URL"},
  {"source": "name", "invalid_value": "", "message": "must not be blank"},
  {"source": "rewrite_path.replace_from", "invalid_value": "", "message": "must not be blank"}
]
```

| Field           | Type   | Description                                                                                  |
|-----------------|--------|----------------------------------------------------------------------------------------------|
| `source`        | string | The field, with its path: `rewrite_path.replace_from`, or `root[0].name` in a list body      |
| `invalid_value` | string | The value it had, as text (`"null"` when it was missing)                                     |
| `message`       | string | What is wrong, in English (`must not be blank`, `size must be between 0 and 255`…)           |

The order of the entries is not fixed.

**A Problem Details-like object** for a body that can't be read (broken JSON, a date that isn't a
date), as a `400`, and also for the `415` (no `Content-Type: application/json`) and the
[`429`](#authentication):

```json
{"type": null, "title": "Bad Request", "status": 400, "detail": "Failed to read HTTP message", "instance": null, "properties": null}
```

It doesn't say which field failed.

**No body** for the `401` of the [authentication](#authentication).

| Status | When                                                                                                 |
|--------|------------------------------------------------------------------------------------------------------|
| `400`  | The body can't be read, or a log search filter is wrong (`response_code must be a number`)           |
| `401`  | No credentials, an unknown or expired token, or a wrong login                                        |
| `403`  | Basic auth with wrong credentials                                                                    |
| `404`  | A route id that doesn't exist (any text, not only UUIDs), or a path no route matches                 |
| `409`  | A route name already taken, or the same name twice in one body                                       |
| `415`  | A body sent without `Content-Type: application/json`                                                 |
| `422`  | A body that breaks a rule                                                                            |
| `429`  | Too many failed logins from this IP                                                                  |
| `500`  | Anything unexpected: `Internal server error`, in plain text, with the stack trace in the server log |
| `502`  | Proxied traffic: the service can't be reached                                                        |
| `504`  | Proxied traffic: the service doesn't connect or answer in time                                       |

---

## Health

```http
GET /_admin/health
```

```json
{"groups": ["liveness", "readiness"], "status": "UP"}
```

`Content-Type: application/vnd.spring-boot.actuator.v3+json`. For load balancers and container
checks: no credentials, and it isn't saved in the logs. `UP` means the gateway answers and so does
its database; when the database doesn't, it is a `503`:

```json
{"groups": ["liveness", "readiness"], "status": "DOWN"}
```

## Log in

```http
POST /_admin/auth/login
Content-Type: application/json

{"username": "admin", "password": "admin123**"}
```

```json
{"token": "Y_3aeVbZ…", "expires_in": 28800}
```

| Field        | Type    | Description                                                         |
|--------------|---------|---------------------------------------------------------------------|
| `username`   | string  | Required, not blank. `ADMIN_USERNAME`                               |
| `password`   | string  | Required, not blank. `ADMIN_PASSWORD`                               |
| `token`      | string  | Send it as `Authorization: Bearer <token>`                          |
| `expires_in` | integer | Seconds until it expires (`ADMIN_TOKEN_MINUTES` × 60)               |

Wrong credentials:

```http
HTTP/1.1 401 Unauthorized
Content-Type: text/plain;charset=UTF-8

Wrong username or password
```

A blank field is a `422`:

```json
[
  {"source": "username", "invalid_value": "", "message": "must not be blank"},
  {"source": "password", "invalid_value": "null", "message": "must not be blank"}
]
```

Failed logins count for the [lockout](#authentication).

## Routes

A route sends every request whose path matches `path` to the service at `uri`. See
[how a request is routed](#how-a-request-is-routed).

The body of a route, in every call that sends one:

| Field                       | Type   | Rules                                     | Description                                                                 |
|-----------------------------|--------|-------------------------------------------|-----------------------------------------------------------------------------|
| `name`                      | string | Required, not blank, up to 255, unique    | A name for people (`users-service`)                                         |
| `path`                      | string | Required, not blank, up to 255            | The path pattern of the requests it takes (`/users/**`)                     |
| `uri`                       | string | Required, not blank, a URL, up to 255     | The base URL of the service (`http://users.internal:8080`)                  |
| `rewrite_path`              | object | Optional (`null` or left out: no rewrite) | Rewrites the path before it goes to the service                             |
| `rewrite_path.replace_from` | string | Required in the object, up to 255         | A Java regular expression, matched against the path                         |
| `rewrite_path.replace_to`   | string | Required in the object, up to 255         | The replacement; `${name}` is a named group of `replace_from`               |
| `description`               | string | Optional, no limit                        | Free text                                                                   |

A route that comes back also has:

| Field        | Type   | Description                                                                 |
|--------------|--------|-----------------------------------------------------------------------------|
| `id`         | string | A UUID, given by the gateway                                                |
| `created_at` | string | When it was created. Kept on an edit; new on a [replace](#replace-every-route) |

`rewrite_path` and `description` come back as `null` when the route has none. Unknown fields in a
body are ignored.

## List routes

```http
GET /_admin/routes
```

```json
[
  {
    "id": "a4937331-975d-4c0b-8fd2-eb97a0c2cc69",
    "name": "users-service",
    "path": "/users/**",
    "uri": "http://users.internal:8080",
    "rewrite_path": {"replace_from": "/users/(?<segment>.*)", "replace_to": "/${segment}"},
    "description": "Users and profiles",
    "created_at": "2026-11-10T21:29:12.096276-06:00"
  },
  {
    "id": "dfe1d847-16f3-44da-a668-830683f4ea5e",
    "name": "httpbin",
    "path": "/httpbin/**",
    "uri": "https://httpbin.org",
    "rewrite_path": {"replace_from": "/httpbin/(?<segment>.*)", "replace_to": "/${segment}"},
    "description": "Public echo service",
    "created_at": "2026-11-10T21:29:12.474555-06:00"
  },
  {
    "id": "68bb53b9-8198-4f0c-8ee2-0bb5ee57246b",
    "name": "orders-service",
    "path": "/orders/**",
    "uri": "http://orders.internal:8080",
    "rewrite_path": null,
    "description": null,
    "created_at": "2026-11-10T21:29:12.478794-06:00"
  }
]
```

Every route, in no fixed order and without pages. `[]` when there are none.

## Get a route

```http
GET /_admin/routes/a4937331-975d-4c0b-8fd2-eb97a0c2cc69
```

```json
{
  "id": "a4937331-975d-4c0b-8fd2-eb97a0c2cc69",
  "name": "users-service",
  "path": "/users/**",
  "uri": "http://users.internal:8080",
  "rewrite_path": {"replace_from": "/users/(?<segment>.*)", "replace_to": "/${segment}"},
  "description": "Users and profiles",
  "created_at": "2026-11-10T21:29:12.096276-06:00"
}
```

An id that doesn't exist, or isn't a UUID at all, is a `404`:

```http
HTTP/1.1 404 Not Found
Content-Type: text/plain;charset=UTF-8

Route does not exist: not-a-uuid
```

## Create a route

```http
POST /_admin/routes
Content-Type: application/json

{
  "name": "users-service",
  "path": "/users/**",
  "uri": "http://users.internal:8080",
  "rewrite_path": {"replace_from": "/users/(?<segment>.*)", "replace_to": "/${segment}"},
  "description": "Users and profiles"
}
```

`200` with no body: the answer doesn't carry the new id; [list the routes](#list-routes) to get
it. The route takes traffic right away. A name already taken:

```http
HTTP/1.1 409 Conflict
Content-Type: text/plain;charset=UTF-8

Route already exists: users-service
```

## Create several routes

```http
POST /_admin/routes/multi-add
Content-Type: application/json

[
  {
    "name": "httpbin",
    "path": "/httpbin/**",
    "uri": "https://httpbin.org",
    "rewrite_path": {"replace_from": "/httpbin/(?<segment>.*)", "replace_to": "/${segment}"},
    "description": "Public echo service"
  },
  {"name": "orders-service", "path": "/orders/**", "uri": "http://orders.internal:8080"}
]
```

`200` with no body. All or nothing: a name already taken (`409 Route already exists: …`), the same
name twice in the list, or a broken rule, and none is created.

```http
HTTP/1.1 409 Conflict
Content-Type: text/plain;charset=UTF-8

Duplicated route: a
```

The violations of a list name the item by its index:

```json
[{"source": "root[0].name", "invalid_value": "nnnn…", "message": "size must be between 0 and 255"}]
```

## Replace every route

```http
PUT /_admin/routes
Content-Type: application/json

[
  {
    "name": "users-service",
    "path": "/users/**",
    "uri": "http://users.internal:8080",
    "rewrite_path": {"replace_from": "/users/(?<segment>.*)", "replace_to": "/${segment}"},
    "description": "Users and profiles"
  },
  {
    "name": "httpbin",
    "path": "/httpbin/**",
    "uri": "https://httpbin.org",
    "rewrite_path": {"replace_from": "/httpbin/(?<segment>.*)", "replace_to": "/${segment}"},
    "description": "Public echo service"
  }
]
```

`200` with no body. After the call the gateway has exactly these routes: the others are deleted.
How the console restores a backup (the body of a backup is the answer of
[list routes](#list-routes); `id` and `created_at` are ignored). All or nothing: on any error the
current routes stay as they were. Every route gets a **new id** and a new `created_at`, also those
that didn't change, so searching the logs by the old id no longer finds them. `[]` deletes every
route. The same name twice is a `409 Duplicated route: …`.

## Edit a route

```http
PUT /_admin/routes/a4937331-975d-4c0b-8fd2-eb97a0c2cc69
Content-Type: application/json

{
  "name": "users-service",
  "path": "/users/**",
  "uri": "http://users-v2.internal:8080",
  "rewrite_path": {"replace_from": "/users/(?<segment>.*)", "replace_to": "/api/${segment}"},
  "description": "Users and profiles, v2"
}
```

`200` with no body. Every field is replaced (a field left out becomes `null`); the `id` and
`created_at` stay. `404` when the route doesn't exist, `409` when the new name belongs to another
route:

```http
HTTP/1.1 409 Conflict
Content-Type: text/plain;charset=UTF-8

Route already exists: orders-service
```

## Delete a route

```http
DELETE /_admin/routes/68bb53b9-8198-4f0c-8ee2-0bb5ee57246b
```

`200` with no body. Its path stops matching right away (`404`). A route that doesn't exist (also
the second time):

```http
HTTP/1.1 404 Not Found
Content-Type: text/plain;charset=UTF-8

Route does not exist: 68bb53b9-8198-4f0c-8ee2-0bb5ee57246b
```

The logs of a deleted route stay, with its id and name.

## Search the logs

```http
POST /_admin/http-log/search
Content-Type: application/json

{
  "page": 0,
  "size": 5,
  "query": "httpbin",
  "method": "GET",
  "response_code": "2",
  "route_id": "dfe1d847-16f3-44da-a668-830683f4ea5e",
  "from_date": "2026-11-10T00:00:00Z",
  "to_date": "2026-11-12T00:00:00Z"
}
```

```json
{
  "page": 0,
  "size": 5,
  "total_pages": 1,
  "total_elements": 1,
  "page_content": [
    {
      "id": "dcab8227-7148-47f8-9e5d-d4424f17f0c2",
      "source_ip": "0:0:0:0:0:0:0:1",
      "requested_at": "2026-11-10T21:29:31.916361-06:00",
      "user_agent": "curl/8.9.1",
      "http_method": "GET",
      "path": "/httpbin/get",
      "response_code": 200,
      "request_duration": 2900,
      "route": {
        "route_id": "dfe1d847-16f3-44da-a668-830683f4ea5e",
        "route_name": "httpbin",
        "route_path": "https://httpbin.org/get"
      }
    }
  ]
}
```

A `POST` so the filters go in the body. Newest first. Every filter is optional and they add up
(AND):

| Field           | Type    | Default | Description                                                                                                      |
|-----------------|---------|---------|------------------------------------------------------------------------------------------------------------------|
| `page`          | integer | `0`     | The page, from 0. `422` below 0                                                                                  |
| `size`          | integer | all     | Logs per page, more than 0. Left out: every log that matches, up to `MAX_LOGS_SEARCH_SIZE` (10000). Never more than that |
| `query`         | string  |         | Contained in the IP, the user agent, the path or the route (its id, name or final URL). Case-sensitive          |
| `method`        | string  |         | Contained in the method (`GET`, `POST`…). Case-sensitive                                                         |
| `response_code` | string  |         | Digits. Three are an exact code (`404`); fewer, a prefix (`4` is 400–499, `50` is 500–509). `400` if not a number |
| `route_id`      | string  |         | A route id; `00000000-0000-0000-0000-000000000000` for the admin API; `NO-ROUTE` for requests no route matched. `400` otherwise |
| `from_date`     | string  |         | ISO 8601 with offset, inclusive                                                                                  |
| `to_date`       | string  |         | ISO 8601 with offset, inclusive                                                                                  |

| Field              | Type    | Description                                                                                       |
|--------------------|---------|---------------------------------------------------------------------------------------------------|
| `page`             | integer | The page asked for                                                                                |
| `size`             | integer | The size asked for; without one, the number of logs returned                                      |
| `total_pages`      | integer | Pages of this size                                                                                |
| `total_elements`   | integer | Logs that match the filters                                                                       |
| `page_content[]`   | array   | The logs                                                                                          |
| `.id`              | string  | UUID of the log                                                                                   |
| `.source_ip`       | string  | Client IP: first of `X-Forwarded-For`, or the connection's IP. Up to 50 characters                |
| `.requested_at`    | string  | When the request arrived                                                                          |
| `.user_agent`      | string  | `User-Agent` header, or `null`                                                                    |
| `.http_method`     | string  | `GET`, `POST`…                                                                                    |
| `.path`            | string  | Path asked for, without the query string                                                          |
| `.response_code`   | integer | Status sent to the client; `0` when the connection broke before one                               |
| `.request_duration`| integer | Milliseconds, from arrival to the end of the response                                             |
| `.route`           | object  | The route that took it, or `null` when none matched                                               |
| `.route.route_id`  | string  | Id of the route; all zeros for the admin API                                                      |
| `.route.route_name`| string  | Name of the route when it was logged; `Admin` for the admin API                                   |
| `.route.route_path`| string  | Where it went: `uri` plus the rewritten path. For the admin API, the gateway's URL plus the path |

A request to the admin API, as it is logged:

```json
{
  "http_method": "POST",
  "path": "/_admin/routes",
  "response_code": 200,
  "route": {
    "route_id": "00000000-0000-0000-0000-000000000000",
    "route_name": "Admin",
    "route_path": "http://localhost:8080/_admin/routes"
  }
}
```

Wrong filters:

```json
[
  {"source": "size", "invalid_value": "0", "message": "must be greater than 0"},
  {"source": "page", "invalid_value": "-1", "message": "must be greater than or equal to 0"}
]
```

```http
HTTP/1.1 400 Bad Request
Content-Type: text/plain;charset=UTF-8

route_id must be a uuid or NO-ROUTE
```

A date that can't be read is the generic `400 Failed to read HTTP message`.

---

# Proxied traffic

## How a request is routed

Any request outside `/{ADMIN_PATH}` is matched against the `path` of every route, a Spring
path pattern: `/users/**` takes `/users` and everything below it, `/users/{id}` one segment, `*`
any characters inside a segment. The query string doesn't take part.

The first route that matches takes it. All routes have the same priority, so avoid overlapping
paths (`/users/**` and `/users/admin/**`): which one wins depends on the order they were loaded.

Without `rewrite_path`, the path goes to the service unchanged: `/orders/7` goes to
`http://orders.internal:8080/orders/7`. With it, the gateway replaces `replace_from` (a regular
expression) with `replace_to` first. With the routes above:

```http
GET /httpbin/get?page=2
User-Agent: curl/8.9.1
```

goes to `https://httpbin.org/get?page=2`, which answers:

```json
{
  "args": {"page": "2"},
  "headers": {"Accept": "*/*", "Host": "httpbin.org", "User-Agent": "curl/8.9.1"},
  "method": "GET",
  "origin": "<client public ip>",
  "url": "https://httpbin.org/get?page=2"
}
```

The method, the query string, the headers and the body go through; the `Host` becomes the
service's. The answer of the service comes back as it is, with its status, headers and body,
except the CORS headers the gateway already sets, which are not duplicated. Proxied traffic needs no credentials: the
service handles its own auth.

When something fails on the way, the gateway answers by itself, in plain text, without the host or
port of the service:

| Case                                                                            | Answer                                    |
|---------------------------------------------------------------------------------|-------------------------------------------|
| No route matches                                                                | `404`, the generic Problem Details-like body (`"detail": "No static resource nothing/here."`) |
| The host doesn't resolve, refuses the connection, or closes it before answering | `502 Bad gateway`                          |
| No connection within `GATEWAY_CONNECT_TIMEOUT_MS` (10 s by default)             | `504 Gateway timeout`                      |
| No answer within `GATEWAY_RESPONSE_TIMEOUT` (60 s by default; empty = no limit) | `504 Gateway timeout`                      |

```http
GET /users/42
```

```http
HTTP/1.1 502 Bad Gateway
Content-Type: text/plain;charset=UTF-8

Bad gateway
```

If the service fails after the status was sent (in the middle of the body), the connection is cut.

Route changes made through the API apply only to the gateway that got the call; other replicas
load them when they restart.

## What gets logged

Every request is saved in the logs, proxied or admin, with any status (`401`, `404`, `502`…),
except:

- `OPTIONS` requests (CORS preflights).
- `GET /_admin/health`.
- Anything under `/_admin/http-log` (searching the logs would fill them).
- `GET` under `/_admin/routes` (listing and reading routes).

So failed logins, route changes and their errors are logged; reads are not. The log keeps the
client IP, time, user agent, method, path (without the query string), status, duration and the
route ([fields](#search-the-logs)). It never keeps headers, the query string or bodies, so no
tokens or passwords.

Logs are written in the background: a queue in memory (10000 at most) saved in batches every
second. A log shows up in a search about a second after its request. If the database is slow or
down and the queue fills, new logs are dropped (with a warning in the server log) and the traffic
isn't slowed down. Logs older than `MAINTAIN_LOGS_FOR_DAYS` (14 by default) are deleted every day at midnight (server time).

---

## Postman collection

[`postman/Api-Gateway.postman_collection.json`](postman/Api-Gateway.postman_collection.json) has
every call of this page, with assertions on the status and the shape of each answer. It creates,
edits and deletes its own routes (names with a suffix per run) and reads their ids from the
answers, so it runs against any gateway and leaves nothing behind. Run it in order, with the
environment of the same folder (gateway URL, admin path, username and password):

```shell
postman collection run docs/postman/Api-Gateway.postman_collection.json -e "docs/postman/Api-Gateway - Local.postman_environment.json"
```

It sends 2 logins with wrong credentials on purpose: they count for the
[lockout](#authentication), and its correct login right after resets the count.
