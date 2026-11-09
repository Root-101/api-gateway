package dev.root101.api_gateway;

import dev.root101.api_gateway.features.routes.data.entity.RouteEntity;
import dev.root101.api_gateway.features.routes.logic.model.RewritePathModel;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigRequest;
import dev.root101.api_gateway.features.routes.logic.model.RouteFilterModel;
import dev.root101.api_gateway.features.routes.logic.model.RouteHeaderModel;
import dev.root101.api_gateway.support.IntegrationTest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.r2dbc.core.DatabaseClient;
import org.springframework.test.web.reactive.server.WebTestClient;
import org.testcontainers.postgresql.PostgreSQLContainer;
import reactor.test.StepVerifier;

import java.util.List;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

class RoutesIT extends IntegrationTest {

    @Autowired
    private DatabaseClient db;

    @Test
    void saveSingleRoute() {
        String id = unique();
        RouteConfigRequest request = new RouteConfigRequest(
                "abc-" + id, "/abc-" + id + "/**", "http://localhost:8080",
                new RewritePathModel("/abc-" + id + "/", "/"), "description"
        );

        createRoute(request);

        StepVerifier.create(routeRepo.findByName(request.getName()))
                .assertNext(routeEntity -> {
                    assertThat(routeEntity.getRouteId()).isNotNull();
                    assertThat(routeEntity.getName()).isEqualTo(request.getName());
                    assertThat(routeEntity.getPath()).isEqualTo(request.getPath());
                    assertThat(routeEntity.getUri()).isEqualTo(request.getUri());
                    assertThat(routeEntity.getRewritePathFrom()).isEqualTo(request.getRewritePath().getReplaceFrom());
                    assertThat(routeEntity.getRewritePathTo()).isEqualTo(request.getRewritePath().getReplaceTo());
                    assertThat(routeEntity.getDescription()).isEqualTo(request.getDescription());
                    assertThat(routeEntity.getCreatedAt()).isNotNull();
                })
                .verifyComplete();
    }

    /**
     * Pins the response shape (used by the web console and external clients), the same in both endpoints.
     */
    @Test
    void listAndGetKeepTheirShape() {
        String id = unique();
        createRoute(new RouteConfigRequest(
                "shape-" + id, "/shape-" + id + "/**", upstreamUrl(),
                new RewritePathModel("/shape-" + id + "/(?<segment>.*)", "/${segment}"), "desc"
        ));
        String routeId = routeId("shape-" + id);

        admin(HttpMethod.GET, "/routes").exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$[?(@.name == 'shape-%s')].id".formatted(id)).isEqualTo(routeId)
                .jsonPath("$[?(@.name == 'shape-%s')].path".formatted(id)).isEqualTo("/shape-" + id + "/**")
                .jsonPath("$[?(@.name == 'shape-%s')].uri".formatted(id)).isEqualTo(upstreamUrl())
                .jsonPath("$[?(@.name == 'shape-%s')].rewrite_path.replace_from".formatted(id)).isEqualTo("/shape-" + id + "/(?<segment>.*)")
                .jsonPath("$[?(@.name == 'shape-%s')].rewrite_path.replace_to".formatted(id)).isEqualTo("/${segment}")
                .jsonPath("$[?(@.name == 'shape-%s')].description".formatted(id)).isEqualTo("desc")
                .jsonPath("$[?(@.name == 'shape-%s')].created_at".formatted(id)).exists();

        admin(HttpMethod.GET, "/routes/" + routeId).exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.id").isEqualTo(routeId)
                .jsonPath("$.name").isEqualTo("shape-" + id)
                .jsonPath("$.path").isEqualTo("/shape-" + id + "/**")
                .jsonPath("$.uri").isEqualTo(upstreamUrl())
                .jsonPath("$.rewrite_path.replace_from").isEqualTo("/shape-" + id + "/(?<segment>.*)")
                .jsonPath("$.rewrite_path.replace_to").isEqualTo("/${segment}")
                .jsonPath("$.description").isEqualTo("desc")
                .jsonPath("$.created_at").exists()
                .jsonPath("$.route_id").doesNotExist()
                .jsonPath("$.rewrite_path_from").doesNotExist();
    }

    private static RouteConfigRequest rules(String name, String path, Integer order, List<String> methods, List<String> hosts,
                                            List<RouteHeaderModel> headers, List<RouteFilterModel> filters) {
        return new RouteConfigRequest(name, path, upstreamUrl(), null, null, order, methods, hosts, headers, filters);
    }

    private static RouteFilterModel marker(String value) {
        return new RouteFilterModel("AddRequestHeader", List.of("X-Test", value));
    }

    /**
     * The lower order wins even when created later.
     */
    @Test
    void orderDecidesBetweenOverlappingRoutes() {
        String id = unique();
        createRoute(rules("general-" + id, "/ord-" + id + "/**", 5, null, null, null, List.of(marker("general"))));
        createRoute(rules("specific-" + id, "/ord-" + id + "/echo/**", 1, null, null, null, List.of(marker("specific"))));

        webTestClient.get().uri("/ord-%s/echo/x".formatted(id)).exchange()
                .expectStatus().isOk()
                .expectBody(String.class).value(body -> assertThat(body).contains("|specific|"));
    }

    @Test
    void methodHostAndHeaderPredicates() {
        String id = unique();
        createRoute(rules("preds-" + id, "/preds-" + id + "/**", null, List.of("POST"), List.of(id + ".example.com"),
                List.of(new RouteHeaderModel("X-Number", "\\d+"), new RouteHeaderModel("X-Present", null)), null));
        String path = "/preds-%s/x".formatted(id);

        webTestClient.post().uri(path).header("Host", id + ".example.com").header("X-Number", "12").header("X-Present", "any")
                .exchange().expectStatus().isOk();
        //each one failing
        webTestClient.get().uri(path).header("Host", id + ".example.com").header("X-Number", "12").header("X-Present", "any")
                .exchange().expectStatus().isNotFound();
        webTestClient.post().uri(path).header("Host", "other.example.com").header("X-Number", "12").header("X-Present", "any")
                .exchange().expectStatus().isNotFound();
        webTestClient.post().uri(path).header("Host", id + ".example.com").header("X-Number", "abc").header("X-Present", "any")
                .exchange().expectStatus().isNotFound();
        webTestClient.post().uri(path).header("Host", id + ".example.com").header("X-Number", "12")
                .exchange().expectStatus().isNotFound();
    }

    @Test
    void extraFilters() {
        String id = unique();
        createRoute(rules("filters-" + id, "/filters-" + id + "/**", null, null, null, null, List.of(
                marker("added"),
                new RouteFilterModel("AddResponseHeader", List.of("X-Resp", "yes"))
        )));

        webTestClient.get().uri("/filters-%s/echo".formatted(id)).exchange()
                .expectStatus().isOk()
                .expectHeader().valueEquals("X-Resp", "yes")
                .expectBody(String.class).value(body -> assertThat(body).contains("|added|"));
    }

    /**
     * Both reads return the new fields, and a `PUT` without them resets them.
     */
    @Test
    void rulesAreReturnedAndReplacedOnEdit() {
        String id = unique();
        createRoute(rules("ret-" + id, "/ret-" + id + "/**", 7, List.of("GET"), List.of("a.com"),
                List.of(new RouteHeaderModel("X-A", "b")), List.of(new RouteFilterModel("RemoveRequestHeader", List.of("X-C")))));
        String routeId = routeId("ret-" + id);

        admin(HttpMethod.GET, "/routes/" + routeId).exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.order").isEqualTo(7)
                .jsonPath("$.methods[0]").isEqualTo("GET")
                .jsonPath("$.hosts[0]").isEqualTo("a.com")
                .jsonPath("$.headers[0].name").isEqualTo("X-A")
                .jsonPath("$.headers[0].regexp").isEqualTo("b")
                .jsonPath("$.headers[0].valid_regexp").doesNotExist()
                .jsonPath("$.filters[0].name").isEqualTo("RemoveRequestHeader")
                .jsonPath("$.filters[0].args[0]").isEqualTo("X-C")
                .jsonPath("$.filters[0].supported").doesNotExist();

        admin(HttpMethod.PUT, "/routes/" + routeId).bodyValue(route("ret-" + id, "ret-" + id)).exchange().expectStatus().isOk();

        admin(HttpMethod.GET, "/routes/" + routeId).exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.order").isEqualTo(0)
                .jsonPath("$.methods.length()").isEqualTo(0)
                .jsonPath("$.hosts.length()").isEqualTo(0)
                .jsonPath("$.headers.length()").isEqualTo(0)
                .jsonPath("$.filters.length()").isEqualTo(0);
    }

    static Stream<RouteConfigRequest> invalidRules() {
        return Stream.of(
                rules("n", "/x/**", null, List.of("get"), null, null, null),
                rules("n", "/x/**", null, null, List.of(" "), null, null),
                rules("n", "/x/**", null, null, null, List.of(new RouteHeaderModel(" ", null)), null),
                rules("n", "/x/**", null, null, null, List.of(new RouteHeaderModel("X-A", "(")), null),
                rules("n", "/x/**", null, null, null, null, List.of(new RouteFilterModel("StripPrefix", List.of("1")))),
                rules("n", "/x/**", null, null, null, null, List.of(new RouteFilterModel("AddRequestHeader", List.of("only-name")))),
                rules("n", "/x/**", null, null, null, null, List.of(new RouteFilterModel("RemoveRequestHeader", null)))
        );
    }

    /**
     * A route the gateway can't build must never get saved: it would break the refresh of every route.
     */
    @ParameterizedTest
    @MethodSource("invalidRules")
    void invalidRulesAre422(RouteConfigRequest request) {
        admin(HttpMethod.POST, "/routes").bodyValue(request).exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody()
                .jsonPath("$.length()").isEqualTo(1)
                .jsonPath("$[0].source").exists()
                .jsonPath("$[0].message").exists();
    }

    static Stream<RouteConfigRequest> invalidRoutes() {
        String ok = "http://localhost:8080";
        return Stream.of(
                new RouteConfigRequest(" ", "/x/**", ok, null, null),
                new RouteConfigRequest("n", "", ok, null, null),
                new RouteConfigRequest("n", "/x/**", null, null, null),
                new RouteConfigRequest("n", "/x/**", "not a url", null, null),
                new RouteConfigRequest("n".repeat(256), "/x/**", ok, null, null)
        );
    }

    @ParameterizedTest
    @MethodSource("invalidRoutes")
    void invalidRouteIs422WithFieldErrors(RouteConfigRequest request) {
        admin(HttpMethod.POST, "/routes").bodyValue(request).exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody()
                .jsonPath("$[0].source").exists()
                .jsonPath("$[0].message").exists();
    }

    @Test
    void duplicatedNamesAre409() {
        String id = unique();
        createRoute(route("dup-" + id, "dup-" + id));

        admin(HttpMethod.POST, "/routes").bodyValue(route("dup-" + id, "other-" + id)).exchange()
                .expectStatus().isEqualTo(HttpStatus.CONFLICT);

        //duplicated inside the list
        admin(HttpMethod.POST, "/routes/multi-add")
                .bodyValue(List.of(route("m-" + id, "m1-" + id), route("m-" + id, "m2-" + id)))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.CONFLICT);

        //one of them already in db: nothing is created
        admin(HttpMethod.POST, "/routes/multi-add")
                .bodyValue(List.of(route("new-" + id, "new-" + id), route("dup-" + id, "x-" + id)))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.CONFLICT);
        assertThat(routeRepo.findByName("new-" + id).block()).isNull();
        assertThat(routeRepo.findByName("m-" + id).block()).isNull();
    }

    @Test
    void multiAddCreatesAllTheRoutes() {
        String id = unique();
        admin(HttpMethod.POST, "/routes/multi-add")
                .bodyValue(List.of(route("ma1-" + id, "ma1-" + id), route("ma2-" + id, "ma2-" + id)))
                .exchange()
                .expectStatus().isOk();

        webTestClient.get().uri("/ma1-%s/x".formatted(id)).exchange().expectStatus().isOk();
        webTestClient.get().uri("/ma2-%s/x".formatted(id)).exchange().expectStatus().isOk();
    }

    /**
     * A db error in the middle of a multi-add (here forced with a trigger) must not leave half the routes saved.
     */
    @Test
    void multiAddFailingHalfwayRollsBack() {
        String id = unique();
        db.sql("""
                CREATE OR REPLACE FUNCTION fail_route_insert() RETURNS trigger AS $$
                BEGIN
                    IF NEW.name LIKE 'boom-%' THEN
                        RAISE EXCEPTION 'forced failure' USING ERRCODE = 'unique_violation';
                    END IF;
                    RETURN NEW;
                END $$ LANGUAGE plpgsql
                """).then().block();
        db.sql("DROP TRIGGER IF EXISTS fail_route_insert ON route").then().block();
        db.sql("CREATE TRIGGER fail_route_insert BEFORE INSERT ON route FOR EACH ROW EXECUTE FUNCTION fail_route_insert()").then().block();
        try {
            admin(HttpMethod.POST, "/routes/multi-add")
                    .bodyValue(List.of(route("ok-" + id, "ok-" + id), route("boom-" + id, "boom-" + id)))
                    .exchange()
                    .expectStatus().isEqualTo(HttpStatus.CONFLICT);
        } finally {
            db.sql("DROP TRIGGER IF EXISTS fail_route_insert ON route").then().block();
        }

        assertThat(routeRepo.findByName("ok-" + id).block()).isNull();
        webTestClient.get().uri("/ok-%s/x".formatted(id)).exchange().expectStatus().isNotFound();
    }

    @Test
    void unknownOrInvalidIdIs404() {
        String body = "{\"name\":\"n-%s\",\"path\":\"/n/**\",\"uri\":\"http://localhost:8080\"}".formatted(unique());
        for (String routeId : List.of("00000000-0000-0000-0000-000000000001", "not-a-uuid")) {
            admin(HttpMethod.GET, "/routes/" + routeId).exchange().expectStatus().isNotFound();
            admin(HttpMethod.DELETE, "/routes/" + routeId).exchange().expectStatus().isNotFound();
            admin(HttpMethod.PUT, "/routes/" + routeId)
                    .header("Content-Type", "application/json")
                    .bodyValue(body)
                    .exchange()
                    .expectStatus().isNotFound();
        }
    }

    /**
     * Editing the path, uri and rewrite really changes the routing.
     */
    @Test
    void editChangesTheRouting() {
        String id = unique();
        createRoute(route("edit-" + id, "before-" + id));
        webTestClient.get().uri("/before-%s/x".formatted(id)).exchange().expectStatus().isOk();

        admin(HttpMethod.PUT, "/routes/" + routeId("edit-" + id))
                .bodyValue(rewriteRoute("edit-" + id, "after-" + id))
                .exchange()
                .expectStatus().isOk();

        webTestClient.get().uri("/before-%s/x".formatted(id)).exchange().expectStatus().isNotFound();
        webTestClient.get().uri("/after-%s/y".formatted(id)).exchange()
                .expectStatus().isOk()
                .expectBody(String.class).value(body -> assertThat(body).startsWith("/y|"));
    }

    @Test
    void editRouteWithDuplicatedName() {
        String id = unique();
        createRoute(route("first-" + id, "f-" + id));
        createRoute(route("second-" + id, "s-" + id));

        admin(HttpMethod.PUT, "/routes/" + routeId("second-" + id))
                .bodyValue(route("first-" + id, "s-" + id))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.CONFLICT);

        //keeping its own name is fine
        admin(HttpMethod.PUT, "/routes/" + routeId("second-" + id))
                .bodyValue(new RouteConfigRequest("second-" + id, "/s-" + id + "/**", upstreamUrl(), null, "edited"))
                .exchange()
                .expectStatus().isOk();
        assertThat(routeRepo.findByName("second-" + id).map(RouteEntity::getDescription).block()).isEqualTo("edited");
    }

    /**
     * Deleting a route with its id in uppercase must also remove it from the gateway.
     */
    @Test
    void deleteRouteWithUppercaseId() {
        String id = unique();
        createRoute(route("delete-upper-" + id, "du-" + id));
        webTestClient.get().uri("/du-%s/x".formatted(id)).exchange().expectStatus().isOk();

        admin(HttpMethod.DELETE, "/routes/" + routeId("delete-upper-" + id).toUpperCase()).exchange()
                .expectStatus().isOk();

        webTestClient.get().uri("/du-%s/x".formatted(id)).exchange().expectStatus().isNotFound();
        assertThat(routeRepo.findByName("delete-upper-" + id).block()).isNull();
    }

    /**
     * Routes saved in db are already in the gateway when the server starts accepting traffic
     * (they used to be loaded async after startup: a window of 404s after each deploy).
     */
    @Test
    void routesLoadedBeforeTraffic() {
        String id = unique();
        createRoute(route("startup-" + id, "st-" + id));

        //a second instance of the gateway on the same db.
        //Never closed: closing it disposes the global reactor-netty resources the other test contexts also use,
        //it ends with the JVM
        var secondInstance = new SpringApplicationBuilder(App.class)
                .properties(
                        "server.port=0",
                        "DB_HOST=" + POSTGRES.getHost(),
                        "DB_PORT=" + POSTGRES.getMappedPort(PostgreSQLContainer.POSTGRESQL_PORT),
                        "DB_NAME=" + POSTGRES.getDatabaseName(),
                        "DB_USERNAME=" + POSTGRES.getUsername(),
                        "DB_PASSWORD=" + POSTGRES.getPassword()
                )
                .run();
        String port = secondInstance.getEnvironment().getProperty("local.server.port");
        WebTestClient.bindToServer().baseUrl("http://localhost:" + port).build()
                .get().uri("/st-%s/x".formatted(id))
                .exchange()
                .expectStatus().isOk();
    }
}
