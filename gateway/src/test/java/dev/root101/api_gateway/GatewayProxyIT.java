package dev.root101.api_gateway;

import dev.root101.api_gateway.support.IntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;

import static org.assertj.core.api.Assertions.assertThat;

class GatewayProxyIT extends IntegrationTest {

    /**
     * Method, path, query string, headers, body and status go through unchanged.
     */
    @Test
    void forwardsRequestAndResponseUnchanged() {
        String id = unique();
        createRoute(route("proxy-" + id, "px-" + id));

        webTestClient.put()
                //the template variable is encoded: `two words` → `two%20words`
                .uri("/px-" + id + "/echo/a?x=1&y={y}", "two words")
                .header("X-Test", "header-value")
                .bodyValue("the body")
                .exchange()
                .expectStatus().isOk()
                .expectBody(String.class).isEqualTo("PUT|/px-%s/echo/a?x=1&y=two%%20words|header-value|the body".formatted(id));

        webTestClient.get().uri("/px-%s/status/404".formatted(id)).exchange().expectStatus().isNotFound();
        webTestClient.get().uri("/px-%s/status/418".formatted(id)).exchange().expectStatus().isEqualTo(418);
    }

    /**
     * Upstream down → 502, upstream slower than the response-timeout → 504. The internal host/port is never exposed.
     */
    @Test
    void upstreamErrors() {
        String id = unique();
        var closed = reactor.netty.http.server.HttpServer.create().port(0).bindNow();
        int closedPort = closed.port();
        closed.disposeNow();
        createRoute(new dev.root101.api_gateway.features.routes.logic.model.RouteConfigRequest(
                "down-" + id, "/down-" + id + "/**", "http://localhost:" + closedPort, null, null));
        createRoute(route("slow-" + id, "slow-" + id));

        webTestClient.get().uri("/down-%s/x".formatted(id)).exchange()
                .expectStatus().isEqualTo(HttpStatus.BAD_GATEWAY)
                .expectHeader().contentType(MediaType.APPLICATION_PROBLEM_JSON)
                .expectBody(String.class).value(body -> assertThat(body)
                        .doesNotContain(String.valueOf(closedPort))
                        .contains("\"detail\":\"The service can't be reached\""));

        webTestClient.get().uri("/slow-%s/x".formatted(id)).exchange()
                .expectStatus().isEqualTo(HttpStatus.GATEWAY_TIMEOUT)
                .expectBody().jsonPath("$.detail").isEqualTo("The service didn't answer in time");

        assertThat(awaitLog("/down-" + id).getResponseCode()).isEqualTo(502);
    }

    /**
     * A path no route matches: 404 Problem Details, without the Spring "static resource" message
     */
    @Test
    void noRouteIs404ProblemDetails() {
        String path = "/no-route-%s/x".formatted(unique());
        webTestClient.get().uri(path).exchange()
                .expectStatus().isNotFound()
                .expectHeader().contentType(MediaType.APPLICATION_PROBLEM_JSON)
                .expectBody(String.class).value(body -> assertThat(body)
                        .doesNotContainIgnoringCase("static resource")
                        .contains("\"detail\":\"No route matches %s\"".formatted(path))
                        .contains("\"instance\":\"%s\"".formatted(path)));
    }

    /**
     * When the upstream also sends CORS headers, the client gets a single value (the gateway one).
     */
    @Test
    void corsHeadersNotDuplicated() {
        String id = unique();
        String origin = "http://console.example.com";
        createRoute(route("cors-" + id, "cors-" + id));

        webTestClient.get().uri("/cors-%s/x".formatted(id))
                .header(HttpHeaders.ORIGIN, origin)
                .exchange()
                .expectStatus().isOk()
                .expectHeader().valuesMatch(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, origin)
                .expectHeader().valuesMatch(HttpHeaders.ACCESS_CONTROL_ALLOW_CREDENTIALS, "true");
    }

    /**
     * Overlapping paths: the route created first wins (all routes have the same order, the gateway keeps
     * the insertion order). After a restart the order is the db one: avoid overlapping routes (see README).
     */
    @Test
    void overlappingPathsFirstCreatedWins() {
        String id = unique();
        createRoute(route("wide-" + id, "ov-" + id));
        createRoute(rewriteRoute("narrow-" + id, "ov-" + id + "/narrow"));

        webTestClient.get().uri("/ov-%s/narrow/x".formatted(id)).exchange()
                .expectStatus().isOk()
                //the wide route doesn't rewrite
                .expectBody(String.class).value(body -> assertThat(body).startsWith("/ov-%s/narrow/x|".formatted(id)));
    }
}
