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

- **Gateway:** follows the house Spring service standard (`spring-service-standard`), with the
  exceptions below. A feature is `core/feature/<name>/` with `rest/` (`{Name}Controller`) →
  `logic/usecase/` (the `{Name}UseCase` interface and its package-private `{Name}UseCase_Impl`) →
  `data/repo/` and `data/entity/`, its models in `logic/model/` (`{Name}Request`,
  `Search{Name}Request`, `{Name}Response` with a static `build(...)`). Controllers only bind, call the
  use case and return; they inject the interface, never an `_Impl` or a repo. A use case reaches
  another feature only through its interface. Errors are thrown with `core/error/Errors`
  (`Errors.notFound("error.route.not-found", id)`); a key is `error.{feature}.{rule}` in kebab-case,
  `error.{rule}` when shared (`error.conflict`), `status.{code}` for the titles, in both
  `messages*.properties`. Logs with Lombok's `@Slf4j`, beans by their single
  constructor (no `@Autowired`). Security is in `security/`, cross-cutting config in `config/`, the
  languages in `core/i18n/`. Schema changes are new Flyway migrations
  (`src/main/resources/db/migration/`), never an edit of an old one.
- **Known exceptions to the standard** (on purpose, never "fixed" without a decision):

  | Standard                                   | Gateway                                                        | Why                                              |
  |--------------------------------------------|----------------------------------------------------------------|--------------------------------------------------|
  | webmvc, JPA, `@Transactional`              | WebFlux, R2DBC, `TransactionalOperator`                        | Spring Cloud Gateway is reactive                 |
  | `{Name}JpaRepo`, Specifications, `clone()` | `{Name}Repo` (`ReactiveCrudRepository`), no `clone()`          | R2DBC has no managed entities                    |
  | `Long` ids                                 | `UUID` ids, a non-UUID id is a `400`                           | Existing data and API                            |
  | The `user` as the last parameter           | The `Locale` as the last parameter                             | One admin, no users (DECISIONS 4)                |
  | Context path `/latest`                     | The admin API under `ADMIN_PATH`, proxied paths at the root    | A gateway can't prefix the paths it proxies      |
  | Actuator health                            | `GET /{ADMIN_PATH}/health`                                     | Native image weight; deploy templates use it     |
  | `401` with `WWW-Authenticate`              | No `WWW-Authenticate`                                          | The browser's Basic popup (DECISIONS 9)          |
  | `POST /{names}/search`                     | `GET /http-logs?…`                                             | DECISIONS 14                                     |
  | Tests in `it/{Name}ApiTest`                | `*IT` classes                                                  | `build.gradle` splits the tasks by `*IT`         |
  | Filters and tasks in `core/`               | `core/feature/<name>/filter/` and `task/`                      | In a gateway the filter is the feature           |
  | Add-ons as flat features                   | `core/feature/addons/<type>/`, the shared parts in `base/`     | DECISIONS 17                                     |
  | `HttpLogWriter` with one constructor       | Two, the one Spring uses has `@Autowired`                      | Tests build it with a small queue                |
- **Native image:** a class read by reflection (JSON models, entities, gateway predicates and
  filters) needs its hint in `config/ReflectionConfig.java`; the CI builds the native image and
  runs a smoke test against it, which is where a missing hint shows up.
- **Console:** a feature is `data/rest` → `data/repo` → `logic/cubit` and `logic/model` → `view`,
  wired in its `<name>_init.dart`. No user-visible text is hardcoded (`lib/l10n/*.i18n.yaml`, both
  languages, then `fvm dart run slang`). See [`console/README.md`](console/README.md).
- **Both:** JSON keys are `snake_case`. A change to the contract of `/auth`, `/routes` or
  `/http-logs` changes both folders in the same change. Every error goes through
  `GlobalExceptionHandlerConfig` as a Problem Details; don't write an error body anywhere else.
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

The integration tests start the whole gateway on a random port with a real PostgreSQL and a fake
upstream service (`support/IntegrationTest`), and call it over HTTP like a client: every admin
endpoint, the proxying and what gets logged. `ValidationIT` has one row per broken field of every
request object, on every endpoint that takes it, pinning the `fieldName` and the message.

### Mutation testing

Coverage says a line ran, not that a test would notice it changing. `gateway/tool/mutate.py` breaks
one business rule at a time (drop a check, move a limit, remove a transaction, change a filter of
the log search) and runs the one test that must catch it:

```bash
python tool/mutate.py               # every mutation (about an hour)
python tool/mutate.py auth. logs.   # only the ids starting with these
python tool/mutate.py --list
```

**When:** only before merging to `master` (a release). While working on a feature or a fix, run
the unit and integration tests (`./gradlew check`), not the mutations.

- **One mutation per rule**, not per line, each naming the single test that must fail
  (`Class.method`). The rows of `ValidationIT` pin the annotations' output and are not mutated.
- **Verdicts:** `KILLED` is the expected one. `SURVIVED` means the test misses the rule: fix the
  test, never drop the mutation. `COMPILE ERROR`, `NO TESTS` or `BAD PATTERN` (the old text is not
  there exactly once) mean the mutation itself needs fixing.
- **A new rule gets its mutation** in the list, proven `KILLED` before the commit. It is run by
  hand, not in `check` or the CI.
- The script restores each file from the bytes it read, never with `git checkout` (it would wipe
  uncommitted work), and checks that `git diff -- src/main` is the same before and after. If it is
  killed midway, the current mutation stays applied: check that diff and undo it by hand.

The CI (`.github/workflows/ci.yml`) runs the tests and the coverage gate, analyzes and builds the
console, and builds the native image, starts it and runs a smoke test against it. A version tag
publishes both images to GHCR once the CI passes.

## Commits

One change per commit, with a message like the history's: `Fix [gateway]: …`, `Impr [console]: …`,
`Impr [docs]: …`. Work on a branch from `develop` (`feature/…`, `fix/…`) and open the pull request
against `develop`.

## Releasing

`master` is production; a release goes from `develop` to `master` with a version tag.

1. **Branch:** `release/<version>` from `develop`.
2. **Version, on both sides:** the gateway and the console always share the version, even when only
   one of them changed. Bump `gateway/build.gradle` and `console/pubspec.yaml`, the README's status
   line, the "currently" line in `ROADMAP.md` and the "needs gateway" note in `console/README.md`.
3. **Changelogs:** date the version in `CHANGELOG.md` and `console/CHANGELOG.md`. The root one also
   sums up the console's changes (`**Console**`); a side without changes says so.
4. **Tests:** the CI green on `develop`, and the [mutations](#mutation-testing) all `KILLED`. A test or
   mutation that fails is fixed on the release branch, which goes into `develop` again.
5. **Merge:** `release/<version>` into `develop`, then `develop` into `master`, both with `--no-ff`.
6. **Tag:** the bare version (`6.1.2`, or `6.2.0-rc.1` for a release candidate) on the merge in
   `master`, then push `master`, `develop` and the tag. The tag runs `.github/workflows/release.yml`:
   the CI again, then both images to GHCR (`ghcr.io/root-101/api-gateway` and
   `api-gateway-console`), tagged with the version; `latest` moves only without `-rc`.
