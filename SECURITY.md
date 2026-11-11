# Security

## Reporting a vulnerability

Please don't open a public issue. Report it privately through
[GitHub's security advisories](https://github.com/Root-101/api-gateway/security/advisories/new),
with the steps to reproduce it and the version. You'll get an answer as soon as possible; this is a
side project, maintained in free time.

## The model

The gateway has two faces on the same port:

- **Proxied traffic**, at any path that isn't the admin path: public by design. The gateway doesn't
  authenticate it; each service behind does its own. What the gateway adds is that the services
  don't need to be reachable from the internet.
- **The admin API**, at `/{ADMIN_PATH}`: everything there needs the admin's credentials, except the
  login, the health check and CORS preflights.

| Piece                 | How it is protected                                                                                                      |
|-----------------------|--------------------------------------------------------------------------------------------------------------------------|
| Admin credentials     | One user, `ADMIN_USERNAME` / `ADMIN_PASSWORD`, compared in constant time; never logged or printed                        |
| Tokens                | Random and opaque, given by the login, valid `ADMIN_TOKEN_MINUTES` (480); in memory: a restart revokes them all          |
| Brute force           | `ADMIN_MAX_FAILED_ATTEMPTS` (10) tries of the credentials from one IP without a correct one within `ADMIN_LOCKOUT_MINUTES` (15) lock its new tries: `429` with `Retry-After`. Each try is counted before the check, and only correct credentials reset the count |
| Audit                 | Every request is logged, also the admin requests the security layer rejects (401, 429)                                   |
| CORS                  | Only on the admin API, without credentials; proxied services keep their own policy                                      |
| Errors                | A `500` says only `Internal server error`; the detail stays in the server log                                            |
| Defaults              | The gateway warns in its log when it runs with the default admin or database password                                    |
| Container             | The image runs as a non-root user                                                                                        |
| Console               | A strict Content Security Policy, `X-Frame-Options: DENY`; it keeps only the token (with *Remember me*), never the password |

## Deploying it safely

- **Change the passwords.** `ADMIN_PASSWORD` and `DB_PASSWORD` have public defaults.
- **Put a proxy in front for TLS**, and make it overwrite `X-Forwarded-For` (Railway does; with
  nginx, `proxy_set_header X-Forwarded-For $remote_addr`). The client IP of the logs and the
  lockout is the first one of that header, which the client can set: exposed directly, the IP in
  the logs can be faked and the lockout dodged by changing it.
- **Know what the lockout blocks.** A locked IP gets `429` (with `Retry-After`) only on new tries
  of the credentials: the login and Basic auth. A token it already has and the health check keep
  working. Behind a proxy that doesn't set `X-Forwarded-For`, every client shares the proxy's IP,
  so a few wrong passwords keep every admin from logging in until the window ends.
- **Restrict CORS** with `CORS_ALLOWED_ORIGINS` to the console's origin: the default `*` lets any
  page call the admin API with a token it has. It never applies to proxied services.
- **Rename the admin path** (`ADMIN_PATH`) if you want it off the default `_admin`; it is not a
  secret, only a way to keep it out of the way of the services.
- **Run one instance.** Tokens, the lockout count and the routes in use live in memory per
  instance: a route changed through one replica is applied only there until the others restart.
- **Keep the database private.** Only the gateway needs to reach it. `docker-compose.yml` publishes
  every port on `127.0.0.1` only; its sample passwords are public.

## What is logged

Every request through the gateway keeps its method, path (without the query string), route,
status, duration, source IP and user agent, for `MAINTAIN_LOGS_FOR_DAYS` (14). Not its headers or
body, so tokens and passwords never reach the logs. See [`docs/api.md`](docs/api.md#what-gets-logged).
