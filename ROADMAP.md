# Roadmap — Api-Gateway 6.x

Only what is still pending, for the gateway (`gateway/`) and the web console (`console/`). What is
done is in `CHANGELOG.md`.

Rules:

- Every change is recorded in `CHANGELOG.md`, under the in-progress version (currently `6.0.0`).
- Everything in the project is written in English (code, comments, docs, changelog, roadmap).
- Console: keep its base (Cubit + DI with Get + go_router + Dio). Changes in the contract of
  `/{ADMIN_PATH}/auth|routes|http-log` must be applied in both folders.

---

## Possible improvements

- [ ] Routes: `order`, multiple predicates (`methods`, `hosts`, `headers`) and extra header filters,
  all optional, in the admin API and the console form. Needs its own migration and the GraalVM
  reflection hints of each predicate and filter.
- [ ] Gateway: **HTTP/2 and gRPC** support, for a later version (not 6.0.0). gRPC needs HTTP/2 end
  to end (trailers, multiplexed streams): enable it on the gateway server (`server.http2.enabled`)
  and on the client to the upstreams, check the Railway edge forwards HTTP/2 to the container, and
  check the http logs filter with long-lived streams. Then update README section 7.1.
- [ ] Gateway: mutation testing with **PIT** on the routes and logs logic, to measure test quality
  beyond coverage.

## 6.0.0 release

- [ ] **Last step:** migrate to images on **GHCR** (`ghcr.io`): `.github/workflows/release.yml`
  publishes them with each version tag. After the first tag, check they are public and use them in
  `docker-compose.yml` and the deploy docs instead of building locally.
