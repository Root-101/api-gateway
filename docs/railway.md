# Api-Gateway

A lightweight and cost-efficient ready-to-deploy **API Gateway**.
It centralizes client requests, routes them to internal services, logs traffic, and provides an admin UI for monitoring.

👉 Full docs, examples, screenshots and all you need to know, are available in the
official [GitHub Repo](https://github.com/Root-101/api-gateway).

---

# Deploy and Host Api-Gateway on Railway

An **API Gateway** acts as a single entry point for all client requests, routing them to the appropriate internal
services. Instead of clients communicating directly with multiple microservices, they only interact with the gateway,
which handles:

* 🔀 **Request routing** → Determines which service should handle the request based on the path.
* 📜 **Centralized logging** → Captures HTTP logs for monitoring and debugging.
* 🔒 **Service abstraction** → Clients don’t need to know the internal URLs of services. Services may not be public on
  the internet.
* 📈 **Scalability** → Easily connect more services.
* 🖥️ **Admin Dashboard** → Visual manage routes and review HTTP logs.

## About Hosting Api-Gateway

Hosting the Api-Gateway on Railway provisions a complete setup out-of-the-box. The deployment includes:

1. A **PostgreSQL database** to persist routes, configurations, and logs.
2. A **web admin client** to manage routes, logs and settings visually.
3. The **core gateway service**, which processes requests, applies configurations, and handles logging.

This setup isolates your internal microservices from the public internet while providing a single unified API endpoint.

> 📌 By default, the system uses around **200–250 MB RAM**, making it lightweight and cost-efficient.

---

## Common Use Cases

* **Unified API Endpoint** → Expose a single public URL while routing internally to multiple microservices.
* **Improved Security** → Keep microservices private and expose only the gateway to the internet.
* **Logging & Monitoring** → Store traffic logs for auditing.

> 📌 **Future Roadmap include** → Analytics, metrics and statistics, and advanced configuration options.

---

## Dependencies for Api-Gateway

### Core Dependencies:

* **PostgreSQL** → Primary database for storing routes, logs, and configurations.

### Deployment Dependencies

* Railway PostgreSQL Template: [https://railway.com/template/postgres](https://railway.com/template/postgres)
* Api-Gateway Core Service: [https://github.com/Root-101/api-gateway](https://github.com/Root-101/api-gateway)
* Api-Gateway Web
  Client: [api-gateway/console](https://github.com/Root-101/api-gateway/tree/master/console)

---

### Implementation Details (Optional)

* The admin credentials are generated at random when the template is deployed: find them in the **Variables** tab of
  the gateway service (`ADMIN_USERNAME` and `ADMIN_PASSWORD`).
* The **Core Service** and the **DB** are connected through **private networking**, so the project must have private
  networking enabled in order for it to work correctly.
* The **Web Client** calls the gateway through its public domain (`RAILWAY_PUBLIC_DOMAIN`), on the admin path set in
  `ADMIN_PATH`. Both services must have the same `ADMIN_PATH`.
* Deploy the gateway and the web client of the same version together: the client of a version relies on the API of
  that same version.
* Built from the repository, the services need their root directory: `/gateway` for the gateway and `/console` for
  the web client. Each version is also published as a ready image: `ghcr.io/root-101/api-gateway:<version>` and
  `ghcr.io/root-101/api-gateway-console:<version>`.

#### Gateway variables

| Variable                     | Template value                     | Description                                                                                       |
|------------------------------|------------------------------------|---------------------------------------------------------------------------------------------------|
| `PORT`                       | `8080`                             | Port the service listens on                                                                       |
| `DB_HOST`                    | `${{Postgres.PGHOST}}`             | Host of the database                                                                              |
| `DB_PORT`                    | `${{Postgres.PGPORT}}`             | Port of the database                                                                              |
| `DB_NAME`                    | `${{Postgres.PGDATABASE}}`         | Name of the database                                                                              |
| `DB_USERNAME`                | `${{Postgres.PGUSER}}`             | User of the database                                                                              |
| `DB_PASSWORD`                | `${{Postgres.PGPASSWORD}}`         | Password of the database user                                                                     |
| `ADMIN_USERNAME`             | random, 10 characters              | User of the admin API and the web client                                                          |
| `ADMIN_PASSWORD`             | random, 20 characters              | Password of the admin user                                                                        |
| `ADMIN_PATH`                 | `_admin`                           | Base path of the admin API. Same value on the web client                                          |
| `MAINTAIN_LOGS_FOR_DAYS`     | `14`                               | Days the HTTP logs are kept                                                                       |

Optional, with their default when not set:

| Variable                     | Default  | Description                                                                                                     |
|------------------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `GATEWAY_RESPONSE_TIMEOUT`   | `60s`    | Longest wait for a service to answer, then `504`. Empty = no limit. Raise it for services with slower endpoints |
| `GATEWAY_CONNECT_TIMEOUT_MS` | `10000`  | Longest wait to connect to a service, in milliseconds, then `504`                                               |
| `CORS_ALLOWED_ORIGINS`       | `*`      | Comma separated origins allowed by CORS, for the admin API and every route                                      |
| `ADMIN_MAX_FAILED_ATTEMPTS`  | `10`     | Failed logins from one IP before it's locked out. `0` disables the lockout                                      |
| `ADMIN_LOCKOUT_MINUTES`      | `15`     | Minutes a locked out IP waits                                                                                   |
| `ADMIN_TOKEN_MINUTES`        | `480`    | Minutes a login token lasts. Tokens live in memory: a restart logs everyone out                                 |
| `MAX_LOGS_SEARCH_SIZE`       | `10000`  | Most logs a search returns in one page                                                                          |

#### Web client variables

Read when the container starts, so changing them only needs a restart, not a new build.

| Variable                  | Template value                            | Description                                                         |
|---------------------------|-------------------------------------------|---------------------------------------------------------------------|
| `GATEWAY_SERVICE_URL`     | `https://${{api-gateway.RAILWAY_PUBLIC_DOMAIN}}` | Public URL of the gateway, without the admin path              |
| `ADMIN_PATH`              | `${{api-gateway.ADMIN_PATH}}`             | Admin path of the gateway                                           |
| `SESSION_TIMEOUT_MINUTES` | `0` (optional)                            | Minutes without activity before logging out. `0` = never            |

`api-gateway` is the name of the gateway service in the project: use the name it has in yours.

---

### Why Deploy Api-Gateway on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure, so you don't
have to deal with configuration, while allowing you to vertically scale it.

By deploying Api-Gateway on Railway via this template, you are one step closer to supporting a complete full-stack
application with minimal burden, you get a powerful, lightweight, fully configured ready to use,
super magic with sprinkles, and reliable api gateway, that would take you multi services architecture to the next level.

---

This is after all a project designed for deploy in railway as a template... so:

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/IR4lVv?referralCode=6_5_ta)