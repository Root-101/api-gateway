# API-Gateway Front

This project is the **Web UI client** for the **API Gateway**, providing an **easy-to-use interface** to manage routes,
view HTTP logs, and handle administrative tasks.

It is designed to **sync with the latest version** of the API Gateway and provides a visual complement to the REST API.

## Table of Contents

- [1 - Overview](#1)
- [2 - Configuration](#2)
- [3 - Flutter](#3)
- [4 - Screenshots](#4)

---

## Overview<a name="1"></a>

This is the **next iteration** of the integration with the API Gateway.

It allows administrators to:

* 🔀 **Manage routes** — Create, edit, delete, backup, and restore routes.
* 📜 **View HTTP logs** — Filter, search, and inspect requests passing through the gateway.
* 🔐 **Authenticate safely** — Login using the same credentials as the gateway admin endpoints.

> ⚡ **Note:** This version is tied to the corresponding v5.x API Gateway endpoints. Future UI versions will update
> automatically to remain compatible with the latest gateway releases.

---

## Configuration — Environment Variables<a name="2"></a>

The client can be customized using the following **environment variables**:

| Env Variable        | Description                                                                    | Expected | Default value (example)                              | Added in version |
|---------------------|--------------------------------------------------------------------------------|----------|------------------------------------------------------|------------------|
| GATEWAY_SERVICE_URL | Base URL of the API Gateway service                                            | text     | [https://gateway-url.test](https://gateway-url.test) | 1.0.0            |
| ADMIN_PATH          | Admin path of the gateway service (must match `ADMIN_PATH` in the API Gateway) | text     | \_admin                                              | 1.0.0            |
| SESSION_TIMEOUT_MINUTES | Optional. Minutes without mouse/keyboard activity before the console logs out. `0` or missing = disabled | number | 0 | next |

> ⚡ **Tip:** Ensure that the `ADMIN_PATH` matches the API Gateway configuration to allow proper authentication and
> routing of admin requests.

The variables are read at **container start** (an entrypoint script writes `env.js`), so one image works for every
environment:

```bash
docker build -t api-gateway-web ./console
docker run -p 80:80   -e GATEWAY_SERVICE_URL=https://gateway-url.test   -e ADMIN_PATH=_admin   api-gateway-web
```

Build args with the same names still work as defaults (e.g. `args:` in `docker-compose.yml`).

### Run locally

```bash
cp web/env.example.js web/env.js   # web/env.js is git-ignored, edit it for your gateway
fvm flutter pub get
fvm flutter run -d chrome
```

---

## Flutter<a name="3"></a>

This project is developed using **Flutter**, currently version `3.47.9` (pinned in `.fvmrc` and the `Dockerfile`).

> 💡 **Note:** Flutter was chosen for rapid development and cross-platform compatibility.
> As a single developer project, it allows quick updates while maintaining a clean and responsive admin interface.

## Screenshots<a name="4"></a>

#### Login screen

![screenshot-1](../doc/images/web-client-1.png)

#### Routes screen

![screenshot-2](../doc/images/web-client-2.png)

#### Create route dialog

![screenshot-3](../doc/images/web-client-3.png)

#### Edit route dialog

![screenshot-4](../doc/images/web-client-4.png)

#### Delete route

![screenshot-5](../doc/images/web-client-5.png)

#### Backup routes

![screenshot-6](../doc/images/web-client-6.png)

#### Restore routes

![screenshot-7](../doc/images/web-client-7.png)

#### Logs Screen

![screenshot-8](../doc/images/web-client-8.png)

#### Logs Filter Dialog

![screenshot-9](../doc/images/web-client-9.png)

#### Change Language

![screenshot-10](../doc/images/web-client-10.png)

#### Logout

![screenshot-11](../doc/images/web-client-11.png)