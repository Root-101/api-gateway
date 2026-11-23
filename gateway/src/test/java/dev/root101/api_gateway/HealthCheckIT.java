package dev.root101.api_gateway;

import dev.root101.api_gateway.core.feature.addons.base.data.entity.AddonEntity;
import dev.root101.api_gateway.core.feature.addons.base.data.entity.AddonJson;
import dev.root101.api_gateway.core.feature.addons.base.data.repo.AddonRepo;
import dev.root101.api_gateway.core.feature.addons.base.logic.usecase.AddonsUseCase;
import dev.root101.api_gateway.core.feature.addons.health_check.logic.model.HealthCheck;
import dev.root101.api_gateway.core.feature.routes.logic.model.RouteRequest;
import dev.root101.api_gateway.support.IntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;

import java.time.Duration;
import java.time.OffsetDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;

/**
 * The health check add-on of a route (`/routes/{id}/addons/health-check`)
 */
class HealthCheckIT extends IntegrationTest {

    @Autowired
    private AddonRepo addonRepo;

    @Autowired
    private AddonsUseCase addonsUseCase;

    private static Map<String, Object> healthCheck(Boolean enabled, String path, Integer intervalSeconds) {
        Map<String, Object> body = new HashMap<>();
        body.put("enabled", enabled);
        body.put("path", path);
        body.put("interval_seconds", intervalSeconds);
        return body;
    }

    private static String routePath(String routeId) {
        return "/routes/%s/addons/health-check".formatted(routeId);
    }

    private void set(String routeId, Map<String, Object> healthCheck) {
        admin(HttpMethod.PUT, routePath(routeId)).bodyValue(healthCheck).exchange().expectStatus().isOk();
    }

    /**
     * Set: no result yet. Run: calls `{uri}{path}`, `up` on a `2xx`, down with the status otherwise. Disable and
     * enable keep the rest, delete is back to `null` and then there is nothing to enable or run.
     */
    @Test
    void routeHealthCheck() {
        String id = unique();
        String routeId = createRoute(route("hc-" + id, "hc-" + id));
        admin(HttpMethod.GET, "/routes/" + routeId).exchange()
                .expectBody().jsonPath("$.addons.health_check").isEmpty();

        admin(HttpMethod.PUT, routePath(routeId))
                .bodyValue(healthCheck(false, "/health?full=1", 60))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.enabled").isEqualTo(false)
                .jsonPath("$.path").isEqualTo("/health?full=1")
                .jsonPath("$.interval_seconds").isEqualTo(60)
                .jsonPath("$.state").exists()
                .jsonPath("$.state.checked_at").isEmpty();

        admin(HttpMethod.POST, routePath(routeId) + "/run").exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.state.checked_at").isNotEmpty()
                .jsonPath("$.state.up").isEqualTo(true)
                .jsonPath("$.state.status").isEqualTo(200)
                .jsonPath("$.state.millis").isNumber();
        admin(HttpMethod.GET, "/routes/" + routeId).exchange()
                .expectBody().jsonPath("$.addons.health_check.state.up").isEqualTo(true);

        //a new path keeps the last result until the next call
        set(routeId, healthCheck(false, "/status/503", 60));
        admin(HttpMethod.GET, "/routes/" + routeId).exchange()
                .expectBody().jsonPath("$.addons.health_check.state.status").isEqualTo(200);
        admin(HttpMethod.POST, routePath(routeId) + "/run").exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.state.up").isEqualTo(false)
                .jsonPath("$.state.status").isEqualTo(503);

        admin(HttpMethod.POST, routePath(routeId) + "/enable").exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.enabled").isEqualTo(true)
                .jsonPath("$.path").isEqualTo("/status/503")
                .jsonPath("$.interval_seconds").isEqualTo(60)
                .jsonPath("$.state.status").isEqualTo(503);
        admin(HttpMethod.POST, routePath(routeId) + "/disable").exchange()
                .expectStatus().isOk()
                .expectBody().jsonPath("$.enabled").isEqualTo(false);

        admin(HttpMethod.DELETE, routePath(routeId)).exchange().expectStatus().isNoContent();
        admin(HttpMethod.GET, "/routes/" + routeId).exchange()
                .expectBody().jsonPath("$.addons.health_check").isEmpty();
        //nothing to delete is fine; nothing to enable or run isn't
        admin(HttpMethod.DELETE, routePath(routeId)).exchange().expectStatus().isNoContent();
        for (String action : List.of("/enable", "/disable", "/run")) {
            admin(HttpMethod.POST, routePath(routeId) + action).exchange()
                    .expectStatus().isNotFound()
                    .expectBody().jsonPath("$.detail").isEqualTo("The route has no health check configured: " + routeId);
        }
    }

    /**
     * An edit that points the route to another service calls its health check again (on or off) before answering:
     * never the last result of the old one. An edit that keeps the uri keeps the result.
     */
    @Test
    void editedUri() {
        String id = unique();
        String routeId = createRoute(route("hce-" + id, "hce-" + id));
        set(routeId, healthCheck(false, "/health", 3600));
        admin(HttpMethod.POST, routePath(routeId) + "/run").exchange()
                .expectBody().jsonPath("$.state.up").isEqualTo(true);

        admin(HttpMethod.PUT, "/routes/" + routeId)
                .bodyValue(new RouteRequest("hce-" + id, "/hce-" + id + "/**", "http://localhost:1", null, null, null))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.addons.health_check.state.up").isEqualTo(false)
                .jsonPath("$.addons.health_check.state.status").isEmpty();

        //same uri, other path: nothing called, the result stays
        AtomicReference<Object> checkedAt = new AtomicReference<>();
        admin(HttpMethod.GET, "/routes/" + routeId).exchange()
                .expectBody().jsonPath("$.addons.health_check.state.checked_at").value(checkedAt::set);
        admin(HttpMethod.PUT, "/routes/" + routeId)
                .bodyValue(new RouteRequest("hce-" + id, "/hce2-" + id + "/**", "http://localhost:1", null, null, null))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.addons.health_check.state.checked_at").isEqualTo(checkedAt.get());
    }

    /**
     * A service that doesn't answer is down, without a status. The host is always the route's, whatever the path.
     */
    @Test
    void unreachableAndSameHost() {
        String id = unique();
        String downId = createRoute(new RouteRequest("hcd-" + id, "/hcd-" + id + "/**", "http://localhost:1", null, null, null));
        set(downId, healthCheck(false, "/health", 60));
        admin(HttpMethod.POST, routePath(downId) + "/run").exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.state.up").isEqualTo(false)
                .jsonPath("$.state.status").isEmpty()
                .jsonPath("$.state.checked_at").isNotEmpty();

        //`//host` and `@host` in the path stay in the path of the route's own host: the fake upstream answers
        String routeId = createRoute(route("hch-" + id, "hch-" + id));
        for (String path : List.of("//localhost:1/x", "/@localhost:1/x")) {
            set(routeId, healthCheck(false, path, 60));
            admin(HttpMethod.POST, routePath(routeId) + "/run").exchange()
                    .expectStatus().isOk()
                    .expectBody().jsonPath("$.state.status").isEqualTo(200);
        }
    }

    /**
     * On: the scheduler calls it by itself, and writes only the state (the admin's `updated_at` doesn't move). Off: it
     * isn't called. On but checked less than its interval ago: it isn't called again.
     */
    @Test
    void scheduler() {
        String id = unique();
        String onId = createRoute(route("hcs-" + id, "hcs-" + id));
        String offId = createRoute(route("hco-" + id, "hco-" + id));
        String notDueId = createRoute(route("hcn-" + id, "hcn-" + id));
        set(offId, healthCheck(false, "/health", 10));
        //run by hand while off, then on: the scheduler never has a call of its own on the way
        set(notDueId, healthCheck(false, "/health", 3600));
        Object notDueAt = admin(HttpMethod.POST, routePath(notDueId) + "/run").exchange()
                .expectStatus().isOk()
                .expectBody(Map.class).returnResult().getResponseBody().get("state");
        admin(HttpMethod.POST, routePath(notDueId) + "/enable").exchange().expectStatus().isOk();
        set(onId, healthCheck(true, "/health", 10));
        AddonEntity before = addonRepo.findByRouteIdAndType(UUID.fromString(onId), HealthCheck.TYPE).block();

        await().atMost(Duration.ofSeconds(15)).until(
                () -> admin(HttpMethod.GET, "/routes/" + onId).exchange()
                        .expectBody(Map.class).returnResult().getResponseBody(),
                route -> checkedAt(route) != null
        );
        AddonEntity after = addonRepo.findByRouteIdAndType(UUID.fromString(onId), HealthCheck.TYPE).block();
        assertThat(after.getUpdatedAt()).isEqualTo(before.getUpdatedAt());
        assertThat(after.getConfig()).isEqualTo(before.getConfig());
        assertThat(after.getState().json()).contains("\"up\": true");

        //more than one tick of the scheduler (every 5 s): neither the off nor the not due one is called
        await().during(Duration.ofSeconds(7)).atMost(Duration.ofSeconds(8)).until(
                () -> checkedAt(getRoute(offId)) == null
                        && ((Map<?, ?>) ((Map<?, ?>) getRoute(notDueId).get("addons")).get("health_check")).get("state").equals(notDueAt)
        );
    }

    private Map<?, ?> getRoute(String routeId) {
        return admin(HttpMethod.GET, "/routes/" + routeId).exchange()
                .expectStatus().isOk()
                .expectBody(Map.class).returnResult().getResponseBody();
    }

    private static Object checkedAt(Map<?, ?> route) {
        Map<?, ?> addons = (Map<?, ?>) route.get("addons");
        Map<?, ?> healthCheck = (Map<?, ?>) addons.get("health_check");
        return ((Map<?, ?>) healthCheck.get("state")).get("checked_at");
    }

    @Test
    void invalidHealthCheck() {
        String routeId = createRoute(route("hcv-" + unique(), "hcv-" + unique()));
        admin(HttpMethod.PUT, routePath(routeId))
                .bodyValue(healthCheck(null, "health", 9))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody()
                .jsonPath("$.violations.length()").isEqualTo(3)
                .jsonPath("$.violations[?(@.fieldName == 'enabled')].message").isEqualTo("Must not be null")
                .jsonPath("$.violations[?(@.fieldName == 'path')].message").isEqualTo("Must start with / and have no spaces")
                .jsonPath("$.violations[?(@.fieldName == 'interval_seconds')].message").isEqualTo("Must be 10 or more");
        admin(HttpMethod.PUT, routePath(routeId))
                .header("Accept-Language", "es")
                .bodyValue(healthCheck(true, "/a b", 3601))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody()
                .jsonPath("$.violations[?(@.fieldName == 'path')].message").isEqualTo("Debe empezar con / y no tener espacios")
                .jsonPath("$.violations[?(@.fieldName == 'interval_seconds')].message").isEqualTo("Debe ser 3600 o menos");
        admin(HttpMethod.PUT, routePath(routeId))
                .bodyValue(healthCheck(true, null, null))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody().jsonPath("$.violations.length()").isEqualTo(2);
        admin(HttpMethod.PUT, routePath(routeId))
                .bodyValue(healthCheck(true, "/" + "a".repeat(2000), 3601))
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody()
                .jsonPath("$.violations[?(@.fieldName == 'path')].message").isEqualTo("Size must be between 0 and 2000")
                .jsonPath("$.violations[?(@.fieldName == 'interval_seconds')].message").isEqualTo("Must be 3600 or less");
        //the limits are inclusive
        set(routeId, healthCheck(false, "/", 10));
        set(routeId, healthCheck(false, "/" + "a".repeat(1999), 3600));

        //the one of a restored route is checked too
        Map<String, Object> broken = restored("hcv-" + unique(), Map.of("health_check", healthCheck(true, "health", 60)));
        admin(HttpMethod.PUT, "/routes").bodyValue(List.of(broken)).exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody().jsonPath("$.violations[0].fieldName").isEqualTo("[0].addons.health_check.path");

        admin(HttpMethod.PUT, routePath("not-a-uuid")).bodyValue(healthCheck(true, "/", 10)).exchange().expectStatus().isBadRequest();
        String unknown = UUID.randomUUID().toString();
        admin(HttpMethod.PUT, routePath(unknown)).bodyValue(healthCheck(true, "/", 10)).exchange().expectStatus().isNotFound();
        admin(HttpMethod.POST, routePath(unknown) + "/run").exchange()
                .expectStatus().isNotFound()
                .expectBody().jsonPath("$.detail").isEqualTo("Route does not exist: " + unknown);
    }

    /**
     * Routes only: the gateway has none. The restore saves, deletes and keeps it as the other add-ons, and
     * deleting the route deletes it.
     */
    @Test
    void gatewayAndRestore() {
        admin(HttpMethod.GET, "/addons").exchange()
                .expectStatus().isOk()
                .expectBody().jsonPath("$.health_check").doesNotExist();

        String id = unique();
        String keptId = createRoute(route("hck-" + id, "hck-" + id));
        String deletedId = createRoute(route("hcx-" + id, "hcx-" + id));
        set(keptId, healthCheck(false, "/kept", 60));
        set(deletedId, healthCheck(false, "/deleted", 60));

        Map<String, Object> deleted = new HashMap<>();
        deleted.put("health_check", null);
        admin(HttpMethod.PUT, "/routes")
                .bodyValue(List.of(
                        restored("hck-" + id, Map.of("maintenance", Map.of("enabled", false))),
                        restored("hcx-" + id, deleted),
                        restored("hcn-" + id, Map.of("health_check", healthCheck(false, "/restored", 30)))
                ))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$[0].addons.health_check.path").isEqualTo("/kept")
                .jsonPath("$[0].addons.maintenance.enabled").isEqualTo(false)
                .jsonPath("$[1].addons.health_check").isEmpty()
                .jsonPath("$[2].addons.health_check.path").isEqualTo("/restored")
                .jsonPath("$[2].addons.health_check.interval_seconds").isEqualTo(30);

        String restoredId = routeId("hcn-" + id);
        admin(HttpMethod.DELETE, "/routes/" + restoredId).exchange().expectStatus().isNoContent();
        assertThat(addonRepo.findByRouteIdAndType(UUID.fromString(restoredId), HealthCheck.TYPE).block()).isNull();
    }

    /**
     * A row that can't be read (broken by hand) never stops the gateway: it is skipped, as if it wasn't configured,
     * so it can't be enabled or run, and a `PUT` fixes it
     */
    @Test
    void unreadableRowsAreSkipped() {
        String id = unique();
        String missingId = createRoute(route("hcb-" + id, "hcb-" + id));
        String wrongTypeId = createRoute(route("hct-" + id, "hct-" + id));
        OffsetDateTime now = OffsetDateTime.now();
        //valid json without `path`, and json of the wrong types
        addonRepo.save(new AddonEntity(null, UUID.fromString(missingId), HealthCheck.TYPE,
                new AddonJson("{\"enabled\": true, \"interval_seconds\": 60}"), null, now, now)).block();
        addonRepo.save(new AddonEntity(null, UUID.fromString(wrongTypeId), HealthCheck.TYPE,
                new AddonJson("{\"enabled\": [1]}"), new AddonJson("{\"checked_at\": [1]}"), now, now)).block();
        addonsUseCase.reload().block();

        for (String skipped : List.of(missingId, wrongTypeId)) {
            admin(HttpMethod.GET, "/routes/" + skipped).exchange()
                    .expectStatus().isOk()
                    .expectBody().jsonPath("$.addons.health_check").isEmpty();
            admin(HttpMethod.POST, routePath(skipped) + "/run").exchange().expectStatus().isNotFound();
            admin(HttpMethod.POST, routePath(skipped) + "/enable").exchange().expectStatus().isNotFound();
        }
        set(missingId, healthCheck(false, "/health", 60));
        admin(HttpMethod.GET, "/routes/" + missingId).exchange()
                .expectBody().jsonPath("$.addons.health_check.path").isEqualTo("/health");
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
