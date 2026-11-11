package dev.root101.api_gateway;

import dev.root101.api_gateway.features.http_logs.data.entity.HttpLogEntity;
import dev.root101.api_gateway.features.http_logs.task.CleanUpOldLogs;
import dev.root101.api_gateway.support.IntegrationTest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;

import java.time.Duration;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;

class HttpLogsIT extends IntegrationTest {

    @Autowired
    private CleanUpOldLogs cleanUpOldLogs;

    /**
     * Requests to a route WITHOUT rewrite-path must be logged (it used to fail with a NPE and the log was lost).
     * Also, a long `X-Forwarded-For` must not make the log be lost.
     */
    @Test
    void logRouteWithoutRewriteAndLongForwardedFor() {
        String id = unique();
        createRoute(route("no-rewrite-" + id, "nr-" + id));

        webTestClient.get()
                .uri("/nr-%s/hello".formatted(id))
                .header("X-Forwarded-For", "203.0.113.7, 10.0.0.1, 10.0.0.2, 10.0.0.3, 10.0.0.4, 10.0.0.5")
                .header("User-Agent", "it-agent")
                .exchange()
                .expectStatus().isOk();

        HttpLogEntity log = awaitLog("/nr-" + id + "/hello");
        assertThat(log.getSourceIp()).isEqualTo("203.0.113.7");
        assertThat(log.getUserAgent()).isEqualTo("it-agent");
        assertThat(log.getHttpMethod()).isEqualTo("GET");
        assertThat(log.getResponseCode()).isEqualTo(200);
        assertThat(log.getRequestDuration()).isGreaterThanOrEqualTo(0);
        assertThat(log.getRoute().routeId()).isEqualTo(routeId("no-rewrite-" + id));
        assertThat(log.getRoute().routeName()).isEqualTo("no-rewrite-" + id);
        assertThat(log.getRoute().routePath()).isEqualTo(upstreamUrl() + "/nr-%s/hello".formatted(id));
    }

    /**
     * The final route in the log applies the rewrite only to the path, like the gateway does.
     */
    @Test
    void logRouteWithRewrite() {
        String id = unique();
        createRoute(rewriteRoute("rewrite-" + id, "rw-" + id));

        webTestClient.get().uri("/rw-%s/a/b".formatted(id)).exchange()
                .expectStatus().isOk()
                .expectBody(String.class).value(body -> assertThat(body).startsWith("/a/b|"));

        assertThat(awaitLog("/rw-" + id + "/a/b").getRoute().routePath()).isEqualTo(upstreamUrl() + "/a/b");
    }

    /**
     * The upstream status and the "no route" 404 are what get stored.
     */
    @Test
    void storesUpstreamStatusAndNoRoute() {
        String id = unique();
        createRoute(route("status-" + id, "status-" + id));

        webTestClient.get().uri("/status-%s/status/418".formatted(id)).exchange().expectStatus().isEqualTo(418);
        webTestClient.get().uri("/status-%s/status/503".formatted(id)).exchange().expectStatus().isEqualTo(503);
        webTestClient.get().uri("/no-route-%s/x".formatted(id)).exchange().expectStatus().isNotFound();

        assertThat(awaitLog("/status-" + id + "/status/418").getResponseCode()).isEqualTo(418);
        assertThat(awaitLog("/status-" + id + "/status/503").getResponseCode()).isEqualTo(503);
        HttpLogEntity noRoute = awaitLog("/no-route-" + id);
        assertThat(noRoute.getResponseCode()).isEqualTo(404);
        assertThat(noRoute.getRoute()).isNull();
    }

    /**
     * NOT logged: admin `GET /routes*`, `/http-logs`, CORS preflights and the health check.
     * Logged: the rest of the admin requests (as the "Admin" route), and an OPTIONS that is not a preflight.
     */
    @Test
    void whatIsAndIsNotLogged() {
        String id = unique();
        String marker = "/" + ADMIN_PATH + "/routes/00000000-0000-0000-0000-0000" + id;

        admin(HttpMethod.GET, "/routes").exchange().expectStatus().isOk();
        admin(HttpMethod.GET, "/http-logs").exchange().expectStatus().isOk();
        webTestClient.get().uri("/%s/health".formatted(ADMIN_PATH)).exchange().expectStatus().isOk();
        admin(HttpMethod.GET, marker.substring(ADMIN_PATH.length() + 1)).exchange().expectStatus().isNotFound();
        webTestClient.options().uri("/opt-%s/x".formatted(id))
                .header(HttpHeaders.ORIGIN, "http://console.example.com")
                .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "POST")
                .exchange();
        webTestClient.options().uri("/plain-opt-%s/x".formatted(id)).exchange();
        //logged: a DELETE to the admin
        admin(HttpMethod.DELETE, marker.substring(ADMIN_PATH.length() + 1)).exchange().expectStatus().isNotFound();

        HttpLogEntity adminLog = awaitLog(log -> log.getPath().equals(marker) && log.getHttpMethod().equals("DELETE"));
        assertThat(awaitLog("/plain-opt-" + id + "/x").getHttpMethod()).isEqualTo("OPTIONS");
        assertThat(adminLog.getRoute().routeName()).isEqualTo("Admin");
        assertThat(adminLog.getRoute().routeId()).isEqualTo("00000000-0000-0000-0000-000000000000");

        //the DELETE is saved, so the previous requests (if logged) would be saved too by now
        await().pollDelay(Duration.ofSeconds(2)).atMost(Duration.ofSeconds(5)).until(() -> true);
        List<HttpLogEntity> logs = httpLogRepo.findAll().collectList().block();
        assertThat(logs).noneMatch(log -> log.getPath().equals(marker) && log.getHttpMethod().equals("GET"));
        assertThat(logs).noneMatch(log -> log.getPath().equals("/opt-%s/x".formatted(id)));
        assertThat(logs).noneMatch(log -> log.getPath().startsWith("/" + ADMIN_PATH + "/http-logs"));
        assertThat(logs).noneMatch(log -> log.getPath().equals("/" + ADMIN_PATH + "/health"));
    }

    /**
     * Admin requests the security layer rejects are logged too: no credentials (401), wrong Basic (401) and
     * the lockout (429). Otherwise guessing the password over Basic would leave no trace.
     */
    @Test
    void rejectedAdminRequestsAreLogged() {
        String id = unique();
        String ip = "192.0.2." + (int) (Math.random() * 200);
        String noAuth = "/" + ADMIN_PATH + "/unknown-noauth-" + id;
        String wrongBasic = "/" + ADMIN_PATH + "/unknown-basic-" + id;
        String wrong = "Basic " + HttpHeaders.encodeBasicAuth("admin", "wrong-" + id, null);

        webTestClient.get().uri(noAuth).exchange().expectStatus().isUnauthorized();
        for (int i = 0; i < 5; i++) {
            webTestClient.get().uri(wrongBasic).header("X-Forwarded-For", ip).header(HttpHeaders.AUTHORIZATION, wrong)
                    .exchange().expectStatus().isUnauthorized();
        }
        webTestClient.get().uri(wrongBasic).header("X-Forwarded-For", ip).header(HttpHeaders.AUTHORIZATION, wrong)
                .exchange().expectStatus().isEqualTo(HttpStatus.TOO_MANY_REQUESTS);

        assertThat(awaitLog(noAuth).getResponseCode()).isEqualTo(401);
        await().atMost(Duration.ofSeconds(10)).untilAsserted(() -> {
            List<HttpLogEntity> logs = httpLogRepo.findAll().filter(log -> log.getPath().equals(wrongBasic)).collectList().block();
            assertThat(logs).extracting(HttpLogEntity::getResponseCode).containsExactlyInAnyOrder(401, 401, 401, 401, 401, 429);
            assertThat(logs).allMatch(log -> ip.equals(log.getSourceIp()));
        });
    }

    /**
     * Search without `size` is capped (max-search-size=2 in the tests), but totals are real.
     * Every filter alone and combined, LIKE wildcards escaped, pagination and order by date desc.
     */
    @Test
    @SuppressWarnings("unchecked")
    void searchLogs() {
        String id = unique();
        createRoute(route("search-" + id, "se-" + id));
        for (int i = 0; i < 3; i++) {
            webTestClient.get().uri("/se-%s/item-%d".formatted(id, i)).exchange().expectStatus().isOk();
        }
        webTestClient.post().uri("/se-%s/status/500".formatted(id)).exchange().expectStatus().is5xxServerError();
        webTestClient.get().uri("/se-none-%s/x".formatted(id)).exchange().expectStatus().isNotFound();
        await().atMost(Duration.ofSeconds(10)).until(
                () -> httpLogRepo.findAll().filter(log -> log.getPath().contains("/se-")
                        && log.getPath().contains(id)).count().block() == 5
        );
        String routeId = routeId("search-" + id);

        //size cap and real totals
        Map<String, Object> page = searchLogs(Map.of("query", "/se-" + id));
        assertThat(((Number) page.get("total_elements")).longValue()).isEqualTo(4);
        assertThat(page.get("total_pages")).isEqualTo(2);
        assertThat(page.get("total_capped")).isEqualTo(false);
        assertThat(page.get("page")).isEqualTo(0);
        assertThat(page.get("size")).isEqualTo(2);
        List<Map<String, Object>> items = (List<Map<String, Object>>) page.get("items");
        assertThat(items).hasSize(2);
        //newest first
        assertThat((String) items.get(0).get("requested_at")).isGreaterThanOrEqualTo((String) items.get(1).get("requested_at"));
        assertThat(items.get(0)).containsKeys("id", "source_ip", "user_agent", "http_method", "path", "response_code", "request_duration", "route");

        //pagination, a size over the cap is capped too
        Map<String, Object> second = searchLogs(Map.of("page", 1, "size", 50, "query", "/se-" + id));
        assertThat((List<Object>) second.get("items")).hasSize(2);
        assertThat(second.get("size")).isEqualTo(2);

        //each filter, an empty one is no filter
        assertThat(totalLogs(Map.of("query", "/se-" + id, "status", 200))).isEqualTo(3);
        assertThat(totalLogs(Map.of("query", "/se-" + id, "status", "500"))).isEqualTo(1);
        assertThat(totalLogs(Map.of("query", "/se-" + id, "status", "", "method", "", "route_id", ""))).isEqualTo(4);
        //fewer than 3 digits is a prefix
        assertThat(totalLogs(Map.of("query", "/se-" + id, "status", "2"))).isEqualTo(3);
        assertThat(totalLogs(Map.of("query", "/se-" + id, "status", "50"))).isEqualTo(1);
        assertThat(totalLogs(Map.of("query", "/se-" + id, "status", "4"))).isZero();
        assertThat(totalLogs(Map.of("query", "/se-" + id, "method", "POST"))).isEqualTo(1);
        assertThat(totalLogs(Map.of("route_id", routeId))).isEqualTo(4);
        assertThat(totalLogs(Map.of("query", id, "route_id", "NO-ROUTE"))).isEqualTo(1);
        //`_` would match any char if not escaped
        assertThat(totalLogs(Map.of("query", "/se_" + id))).isZero();

        //dates (the `+` of the offset must arrive encoded)
        String tomorrow = OffsetDateTime.now().plusDays(1).toString();
        String yesterday = OffsetDateTime.now().minusDays(1).toString();
        assertThat(totalLogs(Map.of("route_id", routeId, "from", tomorrow))).isZero();
        assertThat(totalLogs(Map.of("route_id", routeId, "to", yesterday))).isZero();
        assertThat(totalLogs(Map.of("route_id", routeId, "from", yesterday, "to", tomorrow))).isEqualTo(4);

        //combined
        assertThat(totalLogs(Map.of("route_id", routeId, "method", "GET", "status", 200, "query", "item-1"))).isEqualTo(1);
    }

    /**
     * `method` and `query` don't care about the case
     */
    @Test
    void searchIsCaseInsensitive() {
        String id = unique();
        createRoute(route("case-" + id, "case-" + id));
        webTestClient.post().uri("/case-%s/Mixed-Path".formatted(id)).exchange().expectStatus().isOk();
        awaitLog("/case-" + id + "/Mixed-Path");

        assertThat(totalLogs(Map.of("query", "/CASE-" + id.toUpperCase() + "/mixed-path", "method", "post"))).isEqualTo(1);
        assertThat(totalLogs(Map.of("query", "/case-" + id + "/MIXED-PATH", "method", "Post"))).isEqualTo(1);
        assertThat(totalLogs(Map.of("query", "/case-" + id, "method", "get"))).isZero();
    }

    @ParameterizedTest
    @CsvSource({
            "status, abc, status must be a number",
            "route_id, not-a-uuid, route_id must be a uuid or NO-ROUTE",
            "page, -1, page must be 0 or more",
            "size, 0, size must be 1 or more",
    })
    void searchWithInvalidParamIs400(String param, String value, String detail) {
        webTestClient.get().uri("/%s/http-logs?%s=%s".formatted(ADMIN_PATH, param, value))
                .header(HttpHeaders.AUTHORIZATION, adminAuth())
                .exchange()
                .expectStatus().isBadRequest()
                .expectHeader().contentType(MediaType.APPLICATION_PROBLEM_JSON)
                .expectBody()
                .jsonPath("$.status").isEqualTo(400)
                .jsonPath("$.detail").isEqualTo(detail)
                .jsonPath("$.instance").isEqualTo("/%s/http-logs".formatted(ADMIN_PATH));
    }

    @Test
    void searchWithInvalidDateIs400() {
        webTestClient.get().uri("/%s/http-logs?from=yesterday".formatted(ADMIN_PATH))
                .header(HttpHeaders.AUTHORIZATION, adminAuth())
                .exchange()
                .expectStatus().isBadRequest()
                .expectHeader().contentType(MediaType.APPLICATION_PROBLEM_JSON)
                .expectBody().jsonPath("$.detail").isEqualTo("Invalid value for from");
    }

    /**
     * The clean up deletes only the logs older than MAINTAIN_LOGS_FOR_DAYS (14 by default).
     */
    @Test
    void cleanUpOldLogs() {
        String id = unique();
        OffsetDateTime now = OffsetDateTime.now();
        httpLogRepo.saveAll(List.of(
                new HttpLogEntity(null, "127.0.0.1", now.minusDays(30), null, "GET", "/old-" + id, 200, 1, null),
                new HttpLogEntity(null, "127.0.0.1", now.minusDays(14).minusMinutes(1), null, "GET", "/old-" + id, 200, 1, null),
                new HttpLogEntity(null, "127.0.0.1", now.minusDays(14).plusMinutes(1), null, "GET", "/recent-" + id, 200, 1, null)
        )).blockLast();

        cleanUpOldLogs.cleanUpLogs().block();

        assertThat(httpLogRepo.findAll().filter(log -> log.getPath().equals("/old-" + id)).count().block()).isZero();
        assertThat(httpLogRepo.findAll().filter(log -> log.getPath().equals("/recent-" + id)).count().block()).isEqualTo(1);
    }
}
