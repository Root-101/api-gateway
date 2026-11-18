package dev.root101.api_gateway;

import dev.root101.api_gateway.features.addons.base.data.entity.AddonEntity;
import dev.root101.api_gateway.features.addons.base.data.entity.AddonJson;
import dev.root101.api_gateway.features.addons.base.data.repo.AddonRepo;
import dev.root101.api_gateway.features.addons.base.logic.usecase.AddonsUseCase;
import dev.root101.api_gateway.features.addons.rate_limit.logic.model.RateLimit;
import dev.root101.api_gateway.support.IntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.reactive.server.WebTestClient;

import java.time.OffsetDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * The rate limit add-on: of a route (`/routes/{id}/addons/rate-limit`) and of the gateway (`/addons/rate-limit`).
 * Each test uses its own client ips (`X-Forwarded-For`, believed with the default `TRUSTED_PROXIES`), so the counts
 * never mix. The gateway's is always removed at the end: it would limit the other tests.
 */
class RateLimitIT extends IntegrationTest {

    @Autowired
    private AddonRepo addonRepo;

    @Autowired
    private AddonsUseCase addonsUseCase;

    private static Map<String, Object> rateLimit(Boolean enabled, Integer limit, String period, Integer burst) {
        Map<String, Object> body = new HashMap<>();
        body.put("enabled", enabled);
        body.put("limit", limit);
        body.put("period", period);
        body.put("burst", burst);
        return body;
    }

    private static String routePath(String routeId) {
        return "/routes/%s/addons/rate-limit".formatted(routeId);
    }

    private void setRoute(String routeId, Map<String, Object> rateLimit) {
        admin(HttpMethod.PUT, routePath(routeId)).bodyValue(rateLimit).exchange().expectStatus().isOk();
    }

    private void setGateway(Map<String, Object> rateLimit) {
        admin(HttpMethod.PUT, "/addons/rate-limit").bodyValue(rateLimit).exchange().expectStatus().isOk();
    }

    private void removeGateway() {
        admin(HttpMethod.DELETE, "/addons/rate-limit").exchange().expectStatus().isNoContent();
    }

    private WebTestClient.ResponseSpec get(String path, String clientIp) {
        return webTestClient.get().uri(path).header("X-Forwarded-For", clientIp).exchange();
    }

    private static String ip() {
        return "10.%d.%d.%d".formatted((int) (Math.random() * 250), (int) (Math.random() * 250), (int) (Math.random() * 250));
    }

    /**
     * Over the limit: a `429` with `Retry-After` and the service isn't reached, logged. Each ip has its own count.
     * Disable: passes. Enable: counts again from zero. Delete: back to `null`, nothing to enable.
     */
    @Test
    void routeRateLimit() {
        String id = unique();
        String routeId = createRoute(route("rl-" + id, "rl-" + id));
        admin(HttpMethod.GET, "/routes/" + routeId).exchange()
                .expectBody(String.class).value(body -> assertThat(body).contains("\"rate_limit\":null"));

        admin(HttpMethod.PUT, routePath(routeId))
                .bodyValue(rateLimit(true, 2, "minute", null))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.enabled").isEqualTo(true)
                .jsonPath("$.limit").isEqualTo(2)
                .jsonPath("$.period").isEqualTo("minute")
                .jsonPath("$.burst").isEmpty();

        String ana = ip();
        get("/rl-%s/1".formatted(id), ana).expectStatus().isOk();
        get("/rl-%s/2".formatted(id), ana).expectStatus().isOk();
        get("/rl-%s/3".formatted(id), ana)
                .expectStatus().isEqualTo(HttpStatus.TOO_MANY_REQUESTS)
                .expectHeader().contentType(MediaType.APPLICATION_PROBLEM_JSON)
                .expectHeader().value(HttpHeaders.RETRY_AFTER, value -> assertThat(Integer.parseInt(value)).isBetween(1, 30))
                .expectBody()
                .jsonPath("$.status").isEqualTo(429)
                .jsonPath("$.title").isEqualTo("Too Many Requests")
                .jsonPath("$.detail").value(detail -> assertThat((String) detail).matches("Too many requests, try again in \\d+ s"))
                .jsonPath("$.instance").isEqualTo("/rl-%s/3".formatted(id));
        assertThat(awaitLog("/rl-" + id + "/3").getResponseCode()).isEqualTo(429);
        //another ip has its own count
        get("/rl-%s/4".formatted(id), ip()).expectStatus().isOk();

        admin(HttpMethod.POST, routePath(routeId) + "/disable").exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.enabled").isEqualTo(false)
                .jsonPath("$.limit").isEqualTo(2)
                .jsonPath("$.period").isEqualTo("minute");
        get("/rl-%s/5".formatted(id), ana).expectStatus().isOk();
        get("/rl-%s/6".formatted(id), ana).expectStatus().isOk();
        get("/rl-%s/7".formatted(id), ana).expectStatus().isOk();

        //on again, from zero
        admin(HttpMethod.POST, routePath(routeId) + "/enable").exchange()
                .expectStatus().isOk()
                .expectBody().jsonPath("$.enabled").isEqualTo(true);
        get("/rl-%s/8".formatted(id), ana).expectStatus().isOk();
        get("/rl-%s/9".formatted(id), ana).expectStatus().isOk();
        get("/rl-%s/10".formatted(id), ana).expectStatus().isEqualTo(HttpStatus.TOO_MANY_REQUESTS);

        admin(HttpMethod.DELETE, routePath(routeId)).exchange().expectStatus().isNoContent();
        admin(HttpMethod.GET, "/routes/" + routeId).exchange().expectBody().jsonPath("$.addons.rate_limit").isEmpty();
        get("/rl-%s/11".formatted(id), ana).expectStatus().isOk();
        //nothing to delete is fine; nothing to enable isn't
        admin(HttpMethod.DELETE, routePath(routeId)).exchange().expectStatus().isNoContent();
        admin(HttpMethod.POST, routePath(routeId) + "/enable").exchange()
                .expectStatus().isNotFound()
                .expectBody().jsonPath("$.detail").isEqualTo("The route has no rate limit configured: " + routeId);
        admin(HttpMethod.POST, routePath(routeId) + "/disable").exchange().expectStatus().isNotFound();
    }

    /**
     * `burst` is how many at once; then one every `1 / limit` of the period. A changed limit counts from zero.
     */
    @Test
    void burstAndRefill() throws InterruptedException {
        String id = unique();
        String routeId = createRoute(route("rlb-" + id, "rlb-" + id));
        setRoute(routeId, rateLimit(true, 1, "second", 3));
        String ana = ip();
        for (int i = 0; i < 3; i++) get("/rlb-%s/x".formatted(id), ana).expectStatus().isOk();
        get("/rlb-%s/x".formatted(id), ana)
                .expectStatus().isEqualTo(HttpStatus.TOO_MANY_REQUESTS)
                .expectHeader().valueEquals(HttpHeaders.RETRY_AFTER, "1");

        Thread.sleep(1_100);
        get("/rlb-%s/x".formatted(id), ana).expectStatus().isOk();
        get("/rlb-%s/x".formatted(id), ana).expectStatus().isEqualTo(HttpStatus.TOO_MANY_REQUESTS);

        setRoute(routeId, rateLimit(true, 1, "hour", null));
        get("/rlb-%s/x".formatted(id), ana).expectStatus().isOk();
        get("/rlb-%s/x".formatted(id), ana)
                .expectStatus().isEqualTo(HttpStatus.TOO_MANY_REQUESTS)
                //a bit less than an hour left, rounded up: never tells to come back before the time
                .expectHeader().valueEquals(HttpHeaders.RETRY_AFTER, "3600");
    }

    /**
     * The gateway's counts each ip on every route together, and works with a route's own: both apply. The admin API
     * is never limited. Delete: back to `null`. Not configured: `404` to enable, deleting it again is fine.
     */
    @Test
    void gatewayRateLimit() {
        removeGateway();
        admin(HttpMethod.GET, "/addons").exchange()
                .expectStatus().isOk()
                .expectBody(String.class).value(body -> assertThat(body).contains("\"rate_limit\":null"));
        admin(HttpMethod.POST, "/addons/rate-limit/enable").exchange()
                .expectStatus().isNotFound()
                .expectBody().jsonPath("$.detail").isEqualTo("The gateway has no rate limit configured");

        String id = unique();
        createRoute(route("rlg1-" + id, "rlg1-" + id));
        createRoute(route("rlg2-" + id, "rlg2-" + id));
        String limitedId = createRoute(route("rlg3-" + id, "rlg3-" + id));
        setRoute(limitedId, rateLimit(true, 1, "minute", null));
        try {
            admin(HttpMethod.PUT, "/addons/rate-limit")
                    .bodyValue(rateLimit(true, 3, "minute", null))
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody().jsonPath("$.limit").isEqualTo(3);
            admin(HttpMethod.GET, "/addons").exchange().expectBody().jsonPath("$.rate_limit.limit").isEqualTo(3);

            //every route together
            String ana = ip();
            get("/rlg1-%s/x".formatted(id), ana).expectStatus().isOk();
            get("/rlg2-%s/x".formatted(id), ana).expectStatus().isOk();
            get("/rlg1-%s/x".formatted(id), ana).expectStatus().isOk();
            get("/rlg2-%s/x".formatted(id), ana).expectStatus().isEqualTo(HttpStatus.TOO_MANY_REQUESTS);
            get("/rlg2-%s/x".formatted(id), ip()).expectStatus().isOk();

            //both apply: the route's stops the second one, the gateway's still had room
            String luis = ip();
            get("/rlg3-%s/x".formatted(id), luis).expectStatus().isOk();
            get("/rlg3-%s/x".formatted(id), luis).expectStatus().isEqualTo(HttpStatus.TOO_MANY_REQUESTS);

            //the gateway's stops a route that has room of its own
            String eva = ip();
            for (int i = 0; i < 3; i++) get("/rlg1-%s/x".formatted(id), eva).expectStatus().isOk();
            get("/rlg3-%s/x".formatted(id), eva).expectStatus().isEqualTo(HttpStatus.TOO_MANY_REQUESTS);
            admin(HttpMethod.POST, "/addons/rate-limit/disable").exchange()
                    .expectStatus().isOk()
                    .expectBody().jsonPath("$.enabled").isEqualTo(false);
            //off: only the route's own, from zero
            get("/rlg1-%s/x".formatted(id), eva).expectStatus().isOk();
            get("/rlg3-%s/x".formatted(id), eva).expectStatus().isOk();
            get("/rlg3-%s/x".formatted(id), eva).expectStatus().isEqualTo(HttpStatus.TOO_MANY_REQUESTS);

            //the admin API is never limited
            admin(HttpMethod.POST, "/addons/rate-limit/enable").exchange().expectStatus().isOk();
            for (int i = 0; i < 5; i++) {
                admin(HttpMethod.GET, "/addons").header("X-Forwarded-For", ana).exchange().expectStatus().isOk();
            }

            //deleted: back to `null` right away, only the routes' own limits
            admin(HttpMethod.DELETE, "/addons/rate-limit").exchange().expectStatus().isNoContent();
            admin(HttpMethod.GET, "/addons").exchange()
                    .expectBody(String.class).value(body -> assertThat(body).contains("\"rate_limit\":null"));
            for (int i = 0; i < 5; i++) get("/rlg1-%s/x".formatted(id), ana).expectStatus().isOk();
            admin(HttpMethod.POST, "/addons/rate-limit/enable").exchange().expectStatus().isNotFound();
        } finally {
            removeGateway();
        }
    }

    /**
     * A route in maintenance answers `503` before the rate limit: those requests never count
     */
    @Test
    void maintenanceFirst() {
        String id = unique();
        String routeId = createRoute(route("rlm-" + id, "rlm-" + id));
        setRoute(routeId, rateLimit(true, 1, "minute", null));
        admin(HttpMethod.PUT, "/routes/%s/addons/maintenance".formatted(routeId))
                .bodyValue(Map.of("enabled", true)).exchange().expectStatus().isOk();
        String ana = ip();
        get("/rlm-%s/x".formatted(id), ana).expectStatus().isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        get("/rlm-%s/x".formatted(id), ana).expectStatus().isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);

        admin(HttpMethod.POST, "/routes/%s/addons/maintenance/disable".formatted(routeId)).exchange().expectStatus().isOk();
        get("/rlm-%s/x".formatted(id), ana).expectStatus().isOk();
    }

    @Test
    void invalidRateLimit() {
        String routeId = createRoute(route("rlv-" + unique(), "rlv-" + unique()));
        for (String path : List.of("/addons/rate-limit", routePath(routeId))) {
            admin(HttpMethod.PUT, path)
                    .bodyValue(rateLimit(null, 0, "day", 0))
                    .exchange()
                    .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                    .expectBody()
                    .jsonPath("$.violations.length()").isEqualTo(4)
                    .jsonPath("$.violations[?(@.fieldName == 'enabled')].message").isEqualTo("Must not be null")
                    .jsonPath("$.violations[?(@.fieldName == 'limit')].message").isEqualTo("Must be 1 or more")
                    .jsonPath("$.violations[?(@.fieldName == 'period')].message").isEqualTo("Must be second, minute or hour")
                    .jsonPath("$.violations[?(@.fieldName == 'burst')].message").isEqualTo("Must be 1 or more");
            admin(HttpMethod.PUT, path)
                    .header("Accept-Language", "es")
                    .bodyValue(rateLimit(true, 1_000_001, null, 1_000_001))
                    .exchange()
                    .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                    .expectBody()
                    .jsonPath("$.violations.length()").isEqualTo(3)
                    .jsonPath("$.violations[?(@.fieldName == 'limit')].message").isEqualTo("Debe ser 1000000 o menos")
                    .jsonPath("$.violations[?(@.fieldName == 'period')].message").isEqualTo("Es obligatorio")
                    .jsonPath("$.violations[?(@.fieldName == 'burst')].message").isEqualTo("Debe ser 1000000 o menos");
            admin(HttpMethod.PUT, path)
                    .header("Accept-Language", "es")
                    .bodyValue(rateLimit(true, 1, "Minute", null))
                    .exchange()
                    .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                    .expectBody()
                    .jsonPath("$.violations[?(@.fieldName == 'period')].message").isEqualTo("Debe ser second, minute u hour");
        }
        //the limits are inclusive (off: it never limits the other tests)
        setRoute(routeId, rateLimit(false, 1, "second", 1));
        setRoute(routeId, rateLimit(false, 1_000_000, "hour", 1_000_000));
        try {
            setGateway(rateLimit(false, 1_000_000, "second", null));
        } finally {
            removeGateway();
        }

        //the one of a restored route is checked too
        Map<String, Object> broken = restored("rlv-" + unique(), Map.of("rate_limit", rateLimit(true, 1, "day", null)));
        admin(HttpMethod.PUT, "/routes").bodyValue(List.of(broken)).exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody().jsonPath("$.violations[0].fieldName").isEqualTo("[0].addons.rate_limit.period");

        admin(HttpMethod.PUT, routePath("not-a-uuid")).bodyValue(rateLimit(true, 1, "second", null)).exchange().expectStatus().isBadRequest();
        admin(HttpMethod.DELETE, routePath("not-a-uuid")).exchange().expectStatus().isBadRequest();
        String unknown = UUID.randomUUID().toString();
        admin(HttpMethod.PUT, routePath(unknown)).bodyValue(rateLimit(true, 1, "second", null)).exchange().expectStatus().isNotFound();
        admin(HttpMethod.POST, routePath(unknown) + "/enable").exchange()
                .expectStatus().isNotFound()
                .expectBody().jsonPath("$.detail").isEqualTo("Route does not exist: " + unknown);
    }

    /**
     * The restore keeps, saves and deletes it as the other add-ons; deleting the route deletes it
     */
    @Test
    void restore() {
        String id = unique();
        String keptId = createRoute(route("rlk-" + id, "rlk-" + id));
        String deletedId = createRoute(route("rlx-" + id, "rlx-" + id));
        setRoute(keptId, rateLimit(false, 5, "minute", null));
        setRoute(deletedId, rateLimit(false, 5, "minute", null));

        Map<String, Object> deleted = new HashMap<>();
        deleted.put("rate_limit", null);
        admin(HttpMethod.PUT, "/routes")
                .bodyValue(List.of(
                        restored("rlk-" + id, Map.of("maintenance", Map.of("enabled", false))),
                        restored("rlx-" + id, deleted),
                        restored("rln-" + id, Map.of("rate_limit", rateLimit(true, 1, "minute", 2)))
                ))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$[0].addons.rate_limit.limit").isEqualTo(5)
                .jsonPath("$[1].addons.rate_limit").isEmpty()
                .jsonPath("$[2].addons.rate_limit.burst").isEqualTo(2);

        //restored and in use
        String ana = ip();
        get("/rln-%s/x".formatted(id), ana).expectStatus().isOk();
        get("/rln-%s/x".formatted(id), ana).expectStatus().isOk();
        get("/rln-%s/x".formatted(id), ana).expectStatus().isEqualTo(HttpStatus.TOO_MANY_REQUESTS);

        String restoredId = routeId("rln-" + id);
        admin(HttpMethod.DELETE, "/routes/" + restoredId).exchange().expectStatus().isNoContent();
        assertThat(addonRepo.findByRouteIdAndType(UUID.fromString(restoredId), RateLimit.TYPE).block()).isNull();
    }

    /**
     * A row that can't be read (broken by hand) never stops the gateway: it is skipped, as if it wasn't configured
     */
    @Test
    void unreadableRowsAreSkipped() {
        String id = unique();
        String unknownPeriodId = createRoute(route("rlu-" + id, "rlu-" + id));
        String wrongTypeId = createRoute(route("rlw-" + id, "rlw-" + id));
        OffsetDateTime now = OffsetDateTime.now();
        addonRepo.save(new AddonEntity(null, UUID.fromString(unknownPeriodId), RateLimit.TYPE,
                new AddonJson("{\"enabled\": true, \"limit\": 1, \"period\": \"day\"}"), null, now, now)).block();
        addonRepo.save(new AddonEntity(null, UUID.fromString(wrongTypeId), RateLimit.TYPE,
                new AddonJson("{\"enabled\": true, \"limit\": [1]}"), null, now, now)).block();
        addonsUseCase.reload().block();

        String ana = ip();
        for (String prefix : List.of("rlu-", "rlw-")) {
            get("/%s%s/x".formatted(prefix, id), ana).expectStatus().isOk();
            get("/%s%s/x".formatted(prefix, id), ana).expectStatus().isOk();
        }
        for (String skipped : List.of(unknownPeriodId, wrongTypeId)) {
            admin(HttpMethod.GET, "/routes/" + skipped).exchange()
                    .expectBody().jsonPath("$.addons.rate_limit").isEmpty();
            admin(HttpMethod.POST, routePath(skipped) + "/enable").exchange().expectStatus().isNotFound();
        }
        //a PUT fixes it
        setRoute(unknownPeriodId, rateLimit(true, 1, "minute", null));
        get("/rlu-%s/y".formatted(id), ana).expectStatus().isOk();
        get("/rlu-%s/y".formatted(id), ana).expectStatus().isEqualTo(HttpStatus.TOO_MANY_REQUESTS);
    }

    private static Map<String, Object> restored(String name, Map<String, Object> addons) {
        Map<String, Object> route = new HashMap<>();
        route.put("name", name);
        route.put("path", "/" + name + "/**");
        route.put("uri", upstreamUrl());
        route.put("addons", addons);
        return route;
    }
}
