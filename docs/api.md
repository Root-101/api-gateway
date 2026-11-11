# The API

A tour of the admin HTTP API of the gateway, with real requests and responses (taken from a
running gateway). The console uses exactly these calls; [`console.md`](console.md) says which one
each screen makes.

The gateway serves two things on the same port (8080 by default):

- **Proxied traffic** at any path: each request goes to the service of the [route](#how-a-request-is-routed)
  whose path matches.
- **Admin API** at `/{ADMIN_PATH}` (`/_admin` by default): log in, manage the routes, search the
  logs. Always JSON in and out; errors are [Problem Details](#errors). Don't give a route a path
  under it.

The examples use the default `ADMIN_PATH`; change it and every path below changes with it. Keys
are `snake_case`. Dates are ISO 8601 in UTC (`2026-11-11T04:05:31.267144Z`), whatever the time
zone of the server.

The [Postman collection](#postman-collection) has every call below, to import and try by hand.

## Authentication

| Who                                          | How                                                                                                    |
|----------------------------------------------|--------------------------------------------------------------------------------------------------------|
| The console (and anything else that logs in) | `Authorization: Bearer <access_token>`, from [`POST /_admin/auth/login`](#log-in)                      |
| Scripts and tools                            | `Authorization: Basic <base64(username:password)>`, with `ADMIN_USERNAME` and `ADMIN_PASSWORD`        |
| Nobody                                       | Only `POST /_admin/auth/login`, [`GET /_admin/health`](#health), `OPTIONS` preflights, and proxied traffic |

There is one user, the admin (`ADMIN_USERNAME`, `ADMIN_PASSWORD`; `admin` and `admin123**` by
default, with a warning in the server log). The token is opaque (not a JWT) and lasts
`ADMIN_TOKEN_MINUTES` (480 by default). Tokens live in memory: a restart of the gateway logs
everyone out, and there is no logout or refresh.

Without credentials, or with an unknown or expired token, the answer is a `401` (with no
`WWW-Authenticate`, so browsers don't open their login popup):

```http
HTTP/1.1 401 Unauthorized
Content-Type: application/problem+json

{"type":"about:blank","title":"Unauthorized","status":401,"detail":"Authentication required","instance":"/_admin/routes"}
```

Basic auth with a wrong username or password is also a `401`:

```json
{"type":"about:blank","title":"Unauthorized","status":401,"detail":"Wrong username or password","instance":"/_admin/routes"}
```

A `Basic` header that isn't `base64(username:password)` has `"detail":"Invalid Basic credentials"`.

Tries of the credentials count per client IP: each `POST /_admin/auth/login` and each request with
Basic auth (not the health check, which ignores the header). The try is counted before the password
is checked, so concurrent guesses can't slip past the limit. After `ADMIN_MAX_FAILED_ATTEMPTS`
(10 by default) tries without a correct one within `ADMIN_LOCKOUT_MINUTES` (15 by default), that IP
can't try credentials again until the window ends: the login and every request with Basic auth get
a `429`, also with the right password. A valid token keeps working from that IP, and so does the
health check. Proxied traffic is not affected. Only correct credentials reset the count. The client
IP is the first one of `X-Forwarded-For`, or the connection's IP without it.

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 900
Content-Type: application/problem+json

{"type":"about:blank","title":"Too Many Requests","status":429,"detail":"Too many failed attempts, try again in 15 min","instance":"/_admin/auth/login"}
```

`Retry-After` is the seconds left in the window; `detail` says it in minutes, rounded up (in seconds under one minute).

CORS applies to the admin API only (`/_admin/**`): the origins of `CORS_ALLOWED_ORIGINS` (`*` by
default), any method and any header, without credentials (tokens go in a header, never a cookie).
Proxied paths get no CORS headers from the gateway: each service keeps its own policy.

## Errors

Every error, of the admin API or of proxied traffic the gateway answers by itself, is a Problem
Details ([RFC 9457](https://www.rfc-editor.org/rfc/rfc9457)) with
`Content-Type: application/problem+json`:

```http
HTTP/1.1 404 Not Found
Content-Type: application/problem+json

{"type":"about:blank","title":"Not Found","status":404,"detail":"Route does not exist: 00000000-0000-0000-0000-000000000001","instance":"/_admin/routes/00000000-0000-0000-0000-000000000001"}
```

| Field        | Type    | Description                                                     |
|--------------|---------|-----------------------------------------------------------------|
| `type`       | string  | Always `about:blank`: the status says what kind of error it is  |
| `title`      | string  | The name of the status (`Not Found`, `Conflict`…)               |
| `status`     | integer | The HTTP status, again                                          |
| `detail`     | string  | What went wrong, for people                                     |
| `instance`   | string  | The path of the request                                         |
| `violations` | array   | Only in a `422`: one entry per broken rule                      |

**Language.** `title`, `detail` and each violation's `message` follow the request's
`Accept-Language`: `es` (or `es-ES`…) answers in Spanish, anything else, or no header, in English.
Only the texts change: the statuses, the keys and the `fieldName`s are the same in every language.

```http
GET /_admin/routes/00000000-0000-0000-0000-000000000001
Accept-Language: es

HTTP/1.1 404 Not Found
Content-Type: application/problem+json

{"type":"about:blank","title":"No encontrado","status":404,"detail":"La ruta no existe: 00000000-0000-0000-0000-000000000001","instance":"/_admin/routes/00000000-0000-0000-0000-000000000001"}
```

The texts are in `gateway/src/main/resources/messages.properties` (English) and
`messages_es.properties` (Spanish).

A body that breaks a rule is a `422` with `violations`. A field that breaks two rules comes twice;
the order of the entries is not fixed:

```json
{
  "type": "about:blank",
  "title": "Unprocessable Content",
  "status": 422,
  "detail": "The request has invalid fields",
  "instance": "/_admin/routes",
  "violations": [
    {"fieldName": "name", "message": "Must not be blank"},
    {"fieldName": "uri", "message": "Must be a valid URL"},
    {"fieldName": "rewrite_path.replace_from", "message": "Must not be blank"}
  ]
}
```

| Field       | Type   | Description                                                                          |
|-------------|--------|--------------------------------------------------------------------------------------|
| `fieldName` | string | The field, as a JSON path: `rewrite_path.replace_from`, or `[1].name` in a list body |
| `message`   | string | What is wrong (`Must not be blank`, `Size must be between 0 and 255`…)               |

A body that can't be read is a `400` that names the field when it can, never the Java types:
`"detail":"Invalid value for name"` (a list where a text goes), or `"The body is not valid JSON"`.

| Status | When                                                                                                 |
|--------|------------------------------------------------------------------------------------------------------|
| `400`  | The body can't be read, a route id isn't a UUID, or a log search filter is wrong                     |
| `401`  | No credentials, an unknown or expired token, or wrong credentials (login or Basic)                   |
| `403`  | Authenticated without the admin role (`Not allowed`); can't happen with the built-in user            |
| `404`  | A route id that doesn't exist, or a path no route matches                                            |
| `409`  | A route name already taken, or the same name twice in one body                                       |
| `415`  | A body sent without `Content-Type: application/json`                                                 |
| `422`  | A body that breaks a rule                                                                            |
| `429`  | Too many failed credentials from this IP, with `Retry-After`                                         |
| `500`  | Anything unexpected: `Internal server error`, with the stack trace in the server log                 |
| `502`  | Proxied traffic: the service can't be reached, or it closed the connection                           |
| `503`  | Only the [health check](#health), when the database doesn't answer                                  |
| `504`  | Proxied traffic: the service doesn't connect or answer in time                                       |

---

## Health

```http
GET /_admin/health
```

```json
{"status": "up"}
```

For load balancers and container checks: no credentials, never blocked by the lockout, and it
isn't saved in the logs. `up` means the gateway answers and so does its database (within 3 s);
when the database doesn't, it is a `503`:

```http
HTTP/1.1 503 Service Unavailable
Content-Type: application/json

{"status": "down"}
```

## Log in

```http
POST /_admin/auth/login
Content-Type: application/json

{"username": "admin", "password": "admin123**"}
```

```json
{"access_token": "7Et5codt…", "expires_in": 28800000, "expire_at": 1794398730785}
```

| Field          | Type    | Description                                                         |
|----------------|---------|---------------------------------------------------------------------|
| `username`     | string  | Required, not blank. `ADMIN_USERNAME`                               |
| `password`     | string  | Required, not blank. `ADMIN_PASSWORD`                               |
| `access_token` | string  | Send it as `Authorization: Bearer <access_token>`                   |
| `expires_in`   | integer | Milliseconds it lasts (`ADMIN_TOKEN_MINUTES` × 60000)               |
| `expire_at`    | integer | When it expires, as epoch milliseconds                              |

Wrong credentials:

```http
HTTP/1.1 401 Unauthorized
Content-Type: application/problem+json

{"type":"about:blank","title":"Unauthorized","status":401,"detail":"Wrong username or password","instance":"/_admin/auth/login"}
```

A blank or missing field is a `422`:

```json
{
  "type": "about:blank",
  "title": "Unprocessable Content",
  "status": 422,
  "detail": "The request has invalid fields",
  "instance": "/_admin/auth/login",
  "violations": [
    {"fieldName": "password", "message": "Must not be blank"},
    {"fieldName": "username", "message": "Must not be blank"}
  ]
}
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
| `created_at` | string | When it was created. Kept on an edit, and on a [replace](#replace-every-route) of a route with the same name |

`rewrite_path` and `description` come back as `null` when the route has none. Unknown fields in a
body are ignored.

## List routes

```http
GET /_admin/routes
```

```json
[
  {
    "id": "687b86ec-7c3b-4c78-9f82-69e82ebb8338",
    "name": "users-service",
    "path": "/users/**",
    "uri": "http://users.internal:8080",
    "rewrite_path": {"replace_from": "/users/(?<segment>.*)", "replace_to": "/${segment}"},
    "description": "Users and profiles",
    "created_at": "2026-11-11T04:05:31.267144Z"
  },
  {
    "id": "48390ce8-8633-4c04-8a4d-b5b4694f6d4b",
    "name": "httpbin",
    "path": "/httpbin/**",
    "uri": "https://httpbin.org",
    "rewrite_path": {"replace_from": "/httpbin/(?<segment>.*)", "replace_to": "/${segment}"},
    "description": "Public echo service",
    "created_at": "2026-11-11T04:05:31.590127Z"
  },
  {
    "id": "f5f1ab1b-0430-4c01-b653-7dd0ebf3bb11",
    "name": "orders-service",
    "path": "/orders/**",
    "uri": "http://orders.internal:8080",
    "rewrite_path": null,
    "description": null,
    "created_at": "2026-11-11T04:05:31.593383Z"
  }
]
```

Every route, in no fixed order and without pages. `[]` when there are none.

## Get a route

```http
GET /_admin/routes/687b86ec-7c3b-4c78-9f82-69e82ebb8338
```

```json
{
  "id": "687b86ec-7c3b-4c78-9f82-69e82ebb8338",
  "name": "users-service",
  "path": "/users/**",
  "uri": "http://users.internal:8080",
  "rewrite_path": {"replace_from": "/users/(?<segment>.*)", "replace_to": "/${segment}"},
  "description": "Users and profiles",
  "created_at": "2026-11-11T04:05:31.267144Z"
}
```

An id that doesn't exist is a `404` (`"detail":"Route does not exist: …"`, see [errors](#errors)).
An id that isn't a UUID is a `400`, here and in the edit and delete:

```json
{"type":"about:blank","title":"Bad Request","status":400,"detail":"Route id must be a UUID: not-a-uuid","instance":"/_admin/routes/not-a-uuid"}
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

`201` with the new route, its `id` included. The route takes traffic right away.

```json
{
  "id": "687b86ec-7c3b-4c78-9f82-69e82ebb8338",
  "name": "users-service",
  "path": "/users/**",
  "uri": "http://users.internal:8080",
  "rewrite_path": {"replace_from": "/users/(?<segment>.*)", "replace_to": "/${segment}"},
  "description": "Users and profiles",
  "created_at": "2026-11-11T04:05:31.267144Z"
}
```

A name already taken:

```http
HTTP/1.1 409 Conflict
Content-Type: application/problem+json

{"type":"about:blank","title":"Conflict","status":409,"detail":"Route already exists: users-service","instance":"/_admin/routes"}
```

## Validate a route

```http
POST /_admin/routes/validate
Content-Type: application/json

{"name": "users-service", "path": "/users/{x", "uri": "http://users.internal:8080"}
```

Checks a route with the same rules as [create](#create-a-route) and [edit](#edit-a-route), without
saving anything: `204` when it's valid, or the same [`422`](#errors) with every broken field. A name
already taken is not checked here (that `409` only comes when saving). The console validates each
step of its route form with it, so the rules live only in the gateway. Not logged.

```http
HTTP/1.1 422 Unprocessable Content
Content-Type: application/problem+json

{"type":"about:blank","title":"Unprocessable Content","status":422,"detail":"The request has invalid fields","instance":"/_admin/routes/validate","violations":[{"fieldName":"path","message":"Must be a valid path pattern"}]}
```

## Create several routes

```http
POST /_admin/routes/batch
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

`201` with the new routes, in the order sent:

```json
[
  {
    "id": "48390ce8-8633-4c04-8a4d-b5b4694f6d4b",
    "name": "httpbin",
    "path": "/httpbin/**",
    "uri": "https://httpbin.org",
    "rewrite_path": {"replace_from": "/httpbin/(?<segment>.*)", "replace_to": "/${segment}"},
    "description": "Public echo service",
    "created_at": "2026-11-11T04:05:31.590127Z"
  },
  {
    "id": "f5f1ab1b-0430-4c01-b653-7dd0ebf3bb11",
    "name": "orders-service",
    "path": "/orders/**",
    "uri": "http://orders.internal:8080",
    "rewrite_path": null,
    "description": null,
    "created_at": "2026-11-11T04:05:31.593383Z"
  }
]
```

All or nothing: a name already taken (`409 Route already exists: …`), the same name twice in the
list, or a broken rule, and none is created.

```json
{"type":"about:blank","title":"Conflict","status":409,"detail":"Duplicated route: a","instance":"/_admin/routes/batch"}
```

The violations of a list name the item by its index:

```json
{
  "type": "about:blank",
  "title": "Unprocessable Content",
  "status": 422,
  "detail": "The request has invalid fields",
  "instance": "/_admin/routes/batch",
  "violations": [{"fieldName": "[1].name", "message": "Must not be blank"}]
}
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

`200` with the routes as saved. After the call the gateway has exactly these routes: the others
are deleted. How the console restores a backup (the body of a backup is the answer of
[list routes](#list-routes); `id` and `created_at` are ignored). All or nothing: on any error the
current routes stay as they were. A route whose **name** already exists keeps its `id` and
`created_at`, so its logs still find it; the others get a new id. `[]` deletes every route. The same
name twice is a `409 Duplicated route: …`.

```json
[
  {
    "id": "687b86ec-7c3b-4c78-9f82-69e82ebb8338",
    "name": "users-service",
    "path": "/users/**",
    "uri": "http://users.internal:8080",
    "rewrite_path": {"replace_from": "/users/(?<segment>.*)", "replace_to": "/${segment}"},
    "description": "Users and profiles",
    "created_at": "2026-11-11T04:05:31.267144Z"
  },
  {
    "id": "48390ce8-8633-4c04-8a4d-b5b4694f6d4b",
    "name": "httpbin",
    "path": "/httpbin/**",
    "uri": "https://httpbin.org",
    "rewrite_path": {"replace_from": "/httpbin/(?<segment>.*)", "replace_to": "/${segment}"},
    "description": "Public echo service",
    "created_at": "2026-11-11T04:05:31.590127Z"
  }
]
```

## Edit a route

```http
PUT /_admin/routes/687b86ec-7c3b-4c78-9f82-69e82ebb8338
Content-Type: application/json

{
  "name": "users-service",
  "path": "/users/**",
  "uri": "http://users-v2.internal:8080",
  "rewrite_path": {"replace_from": "/users/(?<segment>.*)", "replace_to": "/api/${segment}"},
  "description": "Users and profiles, v2"
}
```

`200` with the edited route. Every field is replaced (a field left out becomes `null`); the `id` and
`created_at` stay.

```json
{
  "id": "687b86ec-7c3b-4c78-9f82-69e82ebb8338",
  "name": "users-service",
  "path": "/users/**",
  "uri": "http://users-v2.internal:8080",
  "rewrite_path": {"replace_from": "/users/(?<segment>.*)", "replace_to": "/api/${segment}"},
  "description": "Users and profiles, v2",
  "created_at": "2026-11-11T04:05:31.267144Z"
}
```

`404` when the route doesn't exist, `409` when the new name belongs to another route:

```json
{"type":"about:blank","title":"Conflict","status":409,"detail":"Route already exists: orders-service","instance":"/_admin/routes/687b86ec-7c3b-4c78-9f82-69e82ebb8338"}
```

## Delete a route

```http
DELETE /_admin/routes/f5f1ab1b-0430-4c01-b653-7dd0ebf3bb11
```

`204` with no body. Its path stops matching right away (`404`). A route that doesn't exist (also
the second time):

```json
{"type":"about:blank","title":"Not Found","status":404,"detail":"Route does not exist: f5f1ab1b-0430-4c01-b653-7dd0ebf3bb11","instance":"/_admin/routes/f5f1ab1b-0430-4c01-b653-7dd0ebf3bb11"}
```

The logs of a deleted route stay, with its id and name.

## Search the logs

```http
GET /_admin/http-logs?page=0&size=5&query=HTTPBIN&method=get&status=2&route_id=48390ce8-8633-4c04-8a4d-b5b4694f6d4b&from=2026-11-10T00:00:00Z&to=2026-11-12T00:00:00Z
```

```json
{
  "page": 0,
  "size": 5,
  "total_pages": 1,
  "total_elements": 1,
  "items": [
    {
      "id": "1fbfd37e-b0a7-4e95-aebf-e9f990e433c8",
      "source_ip": "203.0.113.10",
      "requested_at": "2026-11-11T04:05:49.171519Z",
      "user_agent": "curl/8.9.1",
      "http_method": "GET",
      "path": "/httpbin/get",
      "response_code": 200,
      "request_duration": 1465,
      "route": {
        "route_id": "48390ce8-8633-4c04-8a4d-b5b4694f6d4b",
        "route_name": "httpbin",
        "route_path": "https://httpbin.org/get"
      }
    }
  ]
}
```

Newest first. Every filter is an optional query parameter, an empty one (`status=`) is no filter,
and they add up (AND). Encode the values: a `+` in a date offset must go as `%2B`.

| Parameter  | Type    | Default | Description                                                                                                      |
|------------|---------|---------|------------------------------------------------------------------------------------------------------------------|
| `page`     | integer | `0`     | The page, from 0. `400` below 0                                                                                  |
| `size`     | integer | `50`    | Logs per page, 1 or more (`400` below). Never more than `MAX_LOGS_SEARCH_SIZE` (10000): a bigger one is cut to it |
| `query`    | string  |         | Contained in the IP, the user agent, the path or the route (its id, name or final URL). Ignores the case        |
| `method`   | string  |         | Contained in the method (`GET`, `POST`…). Ignores the case                                                       |
| `status`   | string  |         | Digits. Three are an exact code (`404`); fewer, a prefix (`4` is 400–499, `50` is 500–509). `400` if not a number |
| `route_id` | string  |         | A route id; `00000000-0000-0000-0000-000000000000` for the admin API; `NO-ROUTE` for requests no route matched. `400` otherwise |
| `from`     | string  |         | ISO 8601 date-time with offset (`2026-11-10T00:00:00Z`), inclusive                                               |
| `to`       | string  |         | ISO 8601 date-time with offset, inclusive                                                                        |

| Field               | Type    | Description                                                                                       |
|---------------------|---------|---------------------------------------------------------------------------------------------------|
| `page`              | integer | The page asked for                                                                                |
| `size`              | integer | The size used (after the cap)                                                                     |
| `total_pages`       | integer | Pages of this size                                                                                |
| `total_elements`    | integer | Logs that match the filters, counted up to 100000                                                 |
| `total_capped`      | boolean | `true` when more than 100000 match: `total_elements` and `total_pages` stop there                 |
| `items[]`           | array   | The logs                                                                                          |
| `.id`               | string  | UUID of the log                                                                                   |
| `.source_ip`        | string  | Client IP: first of `X-Forwarded-For`, or the connection's IP. Up to 50 characters                |
| `.requested_at`     | string  | When the request arrived                                                                          |
| `.user_agent`       | string  | `User-Agent` header, or `null`                                                                    |
| `.http_method`      | string  | `GET`, `POST`…                                                                                    |
| `.path`             | string  | Path asked for, without the query string                                                          |
| `.response_code`    | integer | Status sent to the client; `0` when the connection broke before one                               |
| `.request_duration` | integer | Milliseconds, from arrival to the end of the response                                             |
| `.route`            | object  | The route that took it, or `null` when none matched                                               |
| `.route.route_id`   | string  | Id of the route; all zeros for the admin API                                                      |
| `.route.route_name` | string  | Name of the route when it was logged; `Admin` for the admin API                                   |
| `.route.route_path` | string  | Where it went: `uri` plus the rewritten path. For the admin API, the gateway's URL plus the path |

A request to the admin API, as it is logged:

```json
{
  "http_method": "PUT",
  "path": "/_admin/routes",
  "response_code": 409,
  "route": {
    "route_id": "00000000-0000-0000-0000-000000000000",
    "route_name": "Admin",
    "route_path": "http://localhost:8080/_admin/routes"
  }
}
```

Wrong filters are a `400`, with what is wrong in `detail`: `status must be a number`,
`route_id must be a uuid or NO-ROUTE`, `page must be 0 or more`, `size must be 1 or more`.

```json
{"type":"about:blank","title":"Bad Request","status":400,"detail":"status must be a number","instance":"/_admin/http-logs"}
```

A date that can't be read is a `400` naming its parameter (`"detail":"Invalid value for from"`).

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
  "origin": "203.0.113.10",
  "url": "https://httpbin.org/get?page=2"
}
```

The method, the query string, the headers and the body go through; the `Host` becomes the
service's. The answer of the service comes back as it is, with its status, headers and body,
CORS included: the gateway adds no CORS headers to proxied traffic. The service handles its own
auth.

When something fails on the way, the gateway answers by itself, with a [Problem Details](#errors)
that never shows the host or port of the service:

| Case                                                                            | Answer                                      |
|---------------------------------------------------------------------------------|---------------------------------------------|
| No route matches                                                                | `404`, `No route matches /the/path`         |
| The host doesn't resolve or refuses the connection                              | `502`, `The service can't be reached`       |
| The service closes the connection before answering                              | `502`, `The service closed the connection`  |
| No connection within `GATEWAY_CONNECT_TIMEOUT_MS` (10 s by default)             | `504`, `The service didn't connect in time` |
| No answer within `GATEWAY_RESPONSE_TIMEOUT` (60 s by default; empty = no limit) | `504`, `The service didn't answer in time`  |

```http
GET /users/42
```

```http
HTTP/1.1 502 Bad Gateway
Content-Type: application/problem+json

{"type":"about:blank","title":"Bad Gateway","status":502,"detail":"The service can't be reached","instance":"/users/42"}
```

```http
GET /nothing/here
```

```http
HTTP/1.1 404 Not Found
Content-Type: application/problem+json

{"type":"about:blank","title":"Not Found","status":404,"detail":"No route matches /nothing/here","instance":"/nothing/here"}
```

If the service fails after the status was sent (in the middle of the body), the connection is cut.

Route changes made through the API apply only to the gateway that got the call; other replicas
load them when they restart.

## What gets logged

Every request is saved in the logs, proxied or admin, with any status (`401`, `404`, `429`, `502`…),
including the admin requests the security layer rejects (no credentials, wrong Basic, the lockout),
except:

- CORS preflights (`OPTIONS` with `Origin` and `Access-Control-Request-Method`); any other `OPTIONS` is logged.
- `GET /_admin/health`.
- `GET /_admin/http-logs` (searching the logs would fill them).
- `GET` under `/_admin/routes` (listing and reading routes).
- `POST /_admin/routes/validate` (it changes nothing).

So failed logins, route changes and their errors are logged; reads are not. The log keeps the
client IP, time, user agent, method, path (without the query string), status, duration and the
route ([fields](#search-the-logs)). It never keeps headers, the query string or bodies, so no
tokens or passwords.

Logs are written in the background: a queue in memory (10000 at most) saved in batches every
second. A log shows up in a search about a second after its request. If the database is slow or
down and the queue fills, new logs are dropped (with a warning in the server log) and the traffic
isn't slowed down. Logs older than `MAINTAIN_LOGS_FOR_DAYS` (14 by default) are deleted every day at midnight UTC (the gateway runs in UTC).

---

## Postman collection

[`postman/Api-Gateway.postman_collection.json`](postman/Api-Gateway.postman_collection.json) has
every call of this page, to import in Postman and send by hand, with the environment of the same
folder (gateway URL, admin path, username and password). It creates, edits and deletes its own
routes (names with a suffix per run) and reads their ids from the answers, so sent in order it
works against any gateway and leaves nothing behind. Each request checks its status and the shape
of its answer (the Test Results tab).

It sends 2 requests with wrong credentials on purpose (a login and a Basic one): they count for
the [lockout](#authentication), and the correct login at the start of each run resets the count.
