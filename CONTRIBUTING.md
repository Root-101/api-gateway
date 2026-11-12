# Contributing

Thanks for helping. This is a monorepo with two packages that share nothing but the HTTP contract
of the admin API: `gateway/` (Java, Spring Boot and Spring Cloud Gateway) and `console/` (Flutter
Web).

## Setup

- **Gateway:** a **JDK 25** (Gradle finds it through its toolchain, it doesn't need to be the one in
  `JAVA_HOME`) and Docker for the integration tests. Run `./gradlew` from `gateway/`. The native
  image needs GraalVM 25, or just the `Dockerfile`.
- **Console:** Flutter pinned with [FVM](https://fvm.app) in `console/.fvmrc`; prefix every command
  with `fvm`.

How to run each one locally is in the [README](README.md#locally).

## How the code is organized

- **Gateway:** a feature is `features/<name>/` with `rest/` (controllers) → `logic/usecase/` (the
  logic) → `data/repo/` and `data/entity/`, its request and response models in `logic/model/`; only
  controllers know about HTTP. Security is in `security/`, cross-cutting config in `config/`.
  Schema changes are new Flyway migrations (`src/main/resources/db/migration/`), never an edit of
  an old one.
- **Native image:** a class read by reflection (JSON models, entities, gateway predicates and
  filters) needs its hint in `config/ReflectionConfig.java`; the CI builds the native image and
  runs a smoke test against it, which is where a missing hint shows up.
- **Console:** a feature is `data/rest` → `data/repo` → `logic/cubit` and `logic/model` → `view`,
  wired in its `<name>_init.dart`. No user-visible text is hardcoded (`lib/l10n/*.i18n.yaml`, both
  languages, then `fvm dart run slang`). See [`console/README.md`](console/README.md).
- **Both:** JSON keys are `snake_case`. A change to the contract of `/auth`, `/routes` or
  `/http-logs` changes both folders in the same change. Every error goes through
  `GlobalExceptionHandler` as a Problem Details; don't write an error body anywhere else.
- Don't add a dependency for something Java, Spring or Flutter already does.

## Documentation, in the same change

- Everything in the repository is written in English: code, comments, docs, changelog.
- Every change goes into [`CHANGELOG.md`](CHANGELOG.md) (the console's into
  `console/CHANGELOG.md`), under the version in progress.
- An endpoint added or changed updates [`docs/api.md`](docs/api.md) and the
  [Postman collection](docs/postman/Api-Gateway.postman_collection.json); a new environment
  variable, the table in the [README](README.md#configuration).
- A change to authentication, limits or what the logs keep updates [`SECURITY.md`](SECURITY.md).
- A non-obvious decision goes into [`DECISIONS.md`](DECISIONS.md); a finished roadmap task leaves
  [`ROADMAP.md`](ROADMAP.md).
- **Any change to what the console looks like:** the design canvas first, then its export
  regenerated ([`docs/design/`](docs/design/README.md)), [`docs/console.md`](docs/console.md)
  updated, and what was built compared in the browser with the canvas until they match.

## Tests

From `gateway/`:

```bash
./gradlew test                       # unit tests, fast, no Docker
./gradlew integrationTest            # *IT: PostgreSQL with Testcontainers, Docker required
./gradlew check jacocoTestReport     # both, plus the coverage gate
```

The coverage report is in `gateway/build/reports/jacoco/test/html`. A bug fix comes with the test
that would have caught it.

The CI (`.github/workflows/ci.yml`) runs the tests and the coverage gate, analyzes and builds the
console, and builds the native image, starts it and runs a smoke test against it. A version tag
publishes both images to GHCR once the CI passes.

## Commits

One change per commit, with a message like the history's: `Fix [gateway]: …`, `Impr [console]: …`,
`Impr [docs]: …`. Open the pull request against `main`.
