package dev.root101.api_gateway;

import dev.root101.api_gateway.features.routes.data.entity.RouteEntity;
import dev.root101.api_gateway.features.routes.logic.model.RewritePathModel;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigRequest;
import dev.root101.api_gateway.support.IntegrationTest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.r2dbc.core.DatabaseClient;
import org.springframework.test.web.reactive.server.WebTestClient;
import org.testcontainers.postgresql.PostgreSQLContainer;
import reactor.test.StepVerifier;

import java.util.List;
import java.util.Map;
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

        //201 with the created route, its id included
        admin(HttpMethod.POST, "/routes").bodyValue(request).exchange()
                .expectStatus().isCreated()
                .expectBody()
                //evaluated after the exchange: the route is already saved
                .jsonPath("$.id").isEqualTo(routeId(request.getName()))
                .jsonPath("$.name").isEqualTo(request.getName())
                .jsonPath("$.rewrite_path.replace_to").isEqualTo("/")
                .jsonPath("$.created_at").exists();

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
                .expectHeader().contentType(MediaType.APPLICATION_PROBLEM_JSON)
                .expectBody()
                .jsonPath("$.status").isEqualTo(422)
                .jsonPath("$.detail").isEqualTo("The request has invalid fields")
                .jsonPath("$.instance").isEqualTo("/%s/routes".formatted(ADMIN_PATH))
                .jsonPath("$.violations[0].fieldName").isNotEmpty()
                .jsonPath("$.violations[0].message").isNotEmpty();
    }

    /**
     * `fieldName` is the JSON path as the client sent it: snake_case, `[i].` in a list
     */
    @Test
    void violationsNameTheJsonField() {
        admin(HttpMethod.POST, "/routes")
                .bodyValue(new RouteConfigRequest("n-" + unique(), "/x/**", "not a url", null, null))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody()
                .jsonPath("$.violations.length()").isEqualTo(1)
                .jsonPath("$.violations[0].fieldName").isEqualTo("uri");

        admin(HttpMethod.POST, "/routes/batch")
                .bodyValue(List.of(route("ok-" + unique(), "ok-" + unique()), new RouteConfigRequest(" ", "/x/**", upstreamUrl(), null, null)))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody()
                .jsonPath("$.violations[0].fieldName").isEqualTo("[1].name");

        admin(HttpMethod.POST, "/routes")
                .bodyValue(new RouteConfigRequest("n-" + unique(), "/x/**", upstreamUrl(), new RewritePathModel("", "/"), null))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody()
                .jsonPath("$.violations[0].fieldName").isEqualTo("rewrite_path.replace_from");
    }

    /**
     * Values the gateway can't use are rejected before saving: a broken regex or path pattern used to be saved
     * and then fail the refresh of every route; a path in the uri used to be silently dropped.
     */
    @Test
    void unusableRoutesAre422() {
        String id = unique();
        admin(HttpMethod.POST, "/routes")
                .bodyValue(new RouteConfigRequest("re-" + id, "/re-" + id + "/**", upstreamUrl(), new RewritePathModel("/a/(?<x.*)", "/"), null))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody()
                .jsonPath("$.violations[0].fieldName").isEqualTo("rewrite_path.replace_from")
                .jsonPath("$.violations[0].message").isEqualTo("must be a valid regular expression");

        admin(HttpMethod.POST, "/routes")
                .bodyValue(new RouteConfigRequest("pp-" + id, "/pp-" + id + "/{x", upstreamUrl(), null, null))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody().jsonPath("$.violations[0].fieldName").isEqualTo("path");

        admin(HttpMethod.PUT, "/routes")
                .bodyValue(List.of(new RouteConfigRequest("up-" + id, "/up-" + id + "/**", upstreamUrl() + "/api", null, null)))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody()
                .jsonPath("$.violations[0].fieldName").isEqualTo("[0].uri")
                .jsonPath("$.violations[0].message").isEqualTo("must not have a path, use rewrite_path to add a prefix");

        assertThat(routeRepo.findByName("re-" + id).block()).isNull();
        //a uri ending in `/` is fine
        createRoute(new RouteConfigRequest("slash-" + id, "/slash-" + id + "/**", upstreamUrl() + "/", null, null));
    }

    /**
     * A body that can't be read is a 400 naming the field, never the Java types
     */
    @Test
    void unreadableBodyIs400() {
        admin(HttpMethod.POST, "/routes")
                .header("Content-Type", "application/json")
                .bodyValue("{\"name\": [1, 2]}")
                .exchange()
                .expectStatus().isBadRequest()
                .expectBody().jsonPath("$.detail").isEqualTo("Invalid value for name");

        admin(HttpMethod.POST, "/routes")
                .header("Content-Type", "application/json")
                .bodyValue("{not json")
                .exchange()
                .expectStatus().isBadRequest()
                .expectBody().jsonPath("$.detail").isEqualTo("The body is not valid JSON");
    }

    @Test
    void duplicatedNamesAre409() {
        String id = unique();
        createRoute(route("dup-" + id, "dup-" + id));

        admin(HttpMethod.POST, "/routes").bodyValue(route("dup-" + id, "other-" + id)).exchange()
                .expectStatus().isEqualTo(HttpStatus.CONFLICT);

        //duplicated inside the list
        admin(HttpMethod.POST, "/routes/batch")
                .bodyValue(List.of(route("m-" + id, "m1-" + id), route("m-" + id, "m2-" + id)))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.CONFLICT);

        //one of them already in db: nothing is created
        admin(HttpMethod.POST, "/routes/batch")
                .bodyValue(List.of(route("new-" + id, "new-" + id), route("dup-" + id, "x-" + id)))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.CONFLICT);
        assertThat(routeRepo.findByName("new-" + id).block()).isNull();
        assertThat(routeRepo.findByName("m-" + id).block()).isNull();
    }

    @Test
    void batchCreatesAllTheRoutes() {
        String id = unique();
        admin(HttpMethod.POST, "/routes/batch")
                .bodyValue(List.of(route("ma1-" + id, "ma1-" + id), route("ma2-" + id, "ma2-" + id)))
                .exchange()
                .expectStatus().isCreated()
                .expectBody()
                .jsonPath("$.length()").isEqualTo(2)
                .jsonPath("$[0].name").isEqualTo("ma1-" + id)
                .jsonPath("$[0].id").isEqualTo(routeId("ma1-" + id))
                .jsonPath("$[1].id").isEqualTo(routeId("ma2-" + id));

        webTestClient.get().uri("/ma1-%s/x".formatted(id)).exchange().expectStatus().isOk();
        webTestClient.get().uri("/ma2-%s/x".formatted(id)).exchange().expectStatus().isOk();
    }

    /**
     * A db error in the middle of a batch (here forced with a trigger) must not leave half the routes saved.
     */
    @Test
    void batchFailingHalfwayRollsBack() {
        String id = unique();
        whileBoomRoutesFailToInsert(() -> admin(HttpMethod.POST, "/routes/batch")
                .bodyValue(List.of(route("ok-" + id, "ok-" + id), route("boom-" + id, "boom-" + id)))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.CONFLICT));

        assertThat(routeRepo.findByName("ok-" + id).block()).isNull();
        webTestClient.get().uri("/ok-%s/x".formatted(id)).exchange().expectStatus().isNotFound();
    }

    private void whileBoomRoutesFailToInsert(Runnable action) {
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
            action.run();
        } finally {
            db.sql("DROP TRIGGER IF EXISTS fail_route_insert ON route").then().block();
        }
    }

    /**
     * A name that already exists is not a conflict, that route is being replaced: it keeps its id and creation date.
     * The others get new ids, the missing ones are deleted.
     */
    @Test
    void replaceSwapsAllTheRoutes() {
        String id = unique();
        createRoute(route("gone-" + id, "gone-" + id));
        String keptId = createRoute(route("kept-" + id, "before-" + id));
        String keptCreatedAt = (String) admin(HttpMethod.GET, "/routes/" + keptId).exchange()
                .expectBody(Map.class).returnResult().getResponseBody().get("created_at");

        admin(HttpMethod.PUT, "/routes")
                .bodyValue(List.of(route("kept-" + id, "after-" + id), route("fresh-" + id, "fresh-" + id)))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.length()").isEqualTo(2)
                .jsonPath("$[0].id").isEqualTo(keptId)
                .jsonPath("$[0].path").isEqualTo("/after-" + id + "/**")
                .jsonPath("$[0].created_at").isEqualTo(keptCreatedAt)
                .jsonPath("$[1].name").isEqualTo("fresh-" + id)
                .jsonPath("$[1].id").isEqualTo(routeId("fresh-" + id));

        webTestClient.get().uri("/gone-%s/x".formatted(id)).exchange().expectStatus().isNotFound();
        webTestClient.get().uri("/before-%s/x".formatted(id)).exchange().expectStatus().isNotFound();
        webTestClient.get().uri("/after-%s/x".formatted(id)).exchange().expectStatus().isOk();
        webTestClient.get().uri("/fresh-%s/x".formatted(id)).exchange().expectStatus().isOk();
        assertThat(routeRepo.count().block()).isEqualTo(2);
        assertThat(routeId("kept-" + id)).isEqualTo(keptId);
        admin(HttpMethod.GET, "/routes/" + keptId).exchange()
                .expectStatus().isOk()
                .expectBody().jsonPath("$.created_at").isEqualTo(keptCreatedAt);
    }

    @Test
    void replaceWithDuplicatedNamesIs409AndChangesNothing() {
        String id = unique();
        createRoute(route("stay-" + id, "stay-" + id));

        admin(HttpMethod.PUT, "/routes")
                .bodyValue(List.of(route("r-" + id, "r1-" + id), route("r-" + id, "r2-" + id)))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.CONFLICT);

        assertThat(routeRepo.findByName("stay-" + id).block()).isNotNull();
        webTestClient.get().uri("/stay-%s/x".formatted(id)).exchange().expectStatus().isOk();
    }

    /**
     * A db error in the middle of a replace must undo the delete of the current routes too.
     */
    @Test
    void replaceFailingHalfwayRollsBack() {
        String id = unique();
        createRoute(route("stay-" + id, "stay-" + id));

        whileBoomRoutesFailToInsert(() -> admin(HttpMethod.PUT, "/routes")
                .bodyValue(List.of(route("ok-" + id, "ok-" + id), route("boom-" + id, "boom-" + id)))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.CONFLICT));

        assertThat(routeRepo.findByName("stay-" + id).block()).isNotNull();
        assertThat(routeRepo.findByName("ok-" + id).block()).isNull();
        webTestClient.get().uri("/stay-%s/x".formatted(id)).exchange().expectStatus().isOk();
        webTestClient.get().uri("/ok-%s/x".formatted(id)).exchange().expectStatus().isNotFound();
    }

    @ParameterizedTest
    @CsvSource({"GET", "PUT", "DELETE"})
    void unknownIdIs404(String method) {
        String routeId = "00000000-0000-0000-0000-000000000001";
        idRequest(method, routeId)
                .expectStatus().isNotFound()
                .expectHeader().contentType(MediaType.APPLICATION_PROBLEM_JSON)
                .expectBody()
                .jsonPath("$.title").isEqualTo("Not Found")
                .jsonPath("$.detail").isEqualTo("Route does not exist: " + routeId)
                .jsonPath("$.instance").isEqualTo("/%s/routes/%s".formatted(ADMIN_PATH, routeId));
    }

    @ParameterizedTest
    @CsvSource({"GET", "PUT", "DELETE"})
    void nonUuidIdIs400(String method) {
        idRequest(method, "not-a-uuid")
                .expectStatus().isBadRequest()
                .expectHeader().contentType(MediaType.APPLICATION_PROBLEM_JSON)
                .expectBody()
                .jsonPath("$.detail").isEqualTo("Route id must be a UUID: not-a-uuid");
    }

    private WebTestClient.ResponseSpec idRequest(String method, String routeId) {
        String body = "{\"name\":\"n-%s\",\"path\":\"/n/**\",\"uri\":\"http://localhost:8080\"}".formatted(unique());
        WebTestClient.RequestBodySpec request = admin(HttpMethod.valueOf(method), "/routes/" + routeId);
        return method.equals("PUT")
                ? request.header("Content-Type", "application/json").bodyValue(body).exchange()
                : request.exchange();
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
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.id").isEqualTo(routeId("edit-" + id))
                .jsonPath("$.path").isEqualTo("/after-" + id + "/**");

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
                .expectStatus().isNoContent()
                .expectBody().isEmpty();

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
                        //PORT, not server.port: application.yml sets server.port from it and wins over these defaults
                        "PORT=0",
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
