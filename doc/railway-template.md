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
  Client: [api-gateway/tools/api_gateway_front](https://github.com/Root-101/api-gateway/tree/master/tools/api_gateway_front)

---

### Implementation Details (Optional)

* Default admin credentials:

    * **Username:** `admin`
    * **Password:** `admin123**`

> ⚠️ Update `ADMIN_USERNAME` and `ADMIN_PASSWORD` environment variables in Railway before production use.

* The **Core Service** and the **DB** are connected through **private networking**, so the project must have private
  networking enabled in order for it to work correctly.
* The **Web Client** is connected to the api gateway through **RAILWAY_PUBLIC_DOMAIN**, pointing to the admin path
  defined in the env **ADMIN_PATH** of the gateway service.

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