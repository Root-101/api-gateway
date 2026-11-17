package dev.root101.api_gateway;

import dev.root101.api_gateway.features.maintenance.logic.model.Maintenance;
import dev.root101.api_gateway.features.maintenance.logic.usecase.MaintenanceUseCase;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigRequest;
import dev.root101.api_gateway.features.settings.data.repo.SettingRepo;
import dev.root101.api_gateway.support.IntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;

import java.time.OffsetDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class MaintenanceIT extends IntegrationTest {

    @Autowired
    private SettingRepo settingRepo;

    @Autowired
    private MaintenanceUseCase maintenanceUseCase;

    private static Map<String, Object> maintenance(Boolean enabled, String message, OffsetDateTime retryAfter) {
        Map<String, Object> body = new HashMap<>();
        body.put("enabled", enabled);
        body.put("message", message);
        body.put("retry_after", retryAfter != null ? retryAfter.toString() : null);
        return body;
    }

    private void setRoute(String routeId, Map<String, Object> maintenance) {
        admin(HttpMethod.PUT, "/routes/%s/maintenance".formatted(routeId)).bodyValue(maintenance).exchange().expectStatus().isOk();
    }

    private void setGlobal(Map<String, Object> maintenance) {
        admin(HttpMethod.PUT, "/maintenance").bodyValue(maintenance).exchange().expectStatus().isOk();
    }

    /**
     * On: a `503` with its message, the service isn't reached, and the request is logged. Off: the requests pass
     * again, and the message is kept for the next time.
     */
    @Test
    void routeInMaintenance() {
        String id = unique();
        String routeId = createRoute(route("mt-" + id, "mt-" + id));
        admin(HttpMethod.GET, "/routes/" + routeId).exchange().expectBody().jsonPath("$.maintenance").isEmpty();

        admin(HttpMethod.PUT, "/routes/%s/maintenance".formatted(routeId))
                .bodyValue(maintenance(true, "Back at 14:00", null))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.enabled").isEqualTo(true)
                .jsonPath("$.message").isEqualTo("Back at 14:00");

        webTestClient.get().uri("/mt-%s/x".formatted(id)).exchange()
                .expectStatus().isEqualTo(HttpStatus.SERVICE_UNAVAILABLE)
                .expectHeader().contentType(MediaType.APPLICATION_PROBLEM_JSON)
                .expectHeader().doesNotExist(HttpHeaders.RETRY_AFTER)
                .expectBody()
                .jsonPath("$.status").isEqualTo(503)
                .jsonPath("$.title").isEqualTo("Service Unavailable")
                .jsonPath("$.detail").isEqualTo("Back at 14:00")
                .jsonPath("$.instance").isEqualTo("/mt-%s/x".formatted(id));
        assertThat(awaitLog("/mt-" + id + "/x").getResponseCode()).isEqualTo(503);

        setRoute(routeId, maintenance(false, "Back at 14:00", null));
        webTestClient.get().uri("/mt-%s/y".formatted(id)).exchange()
                .expectStatus().isOk()
                .expectBody(String.class).isEqualTo("/mt-%s/y|null".formatted(id));
        //off, the message is kept
        admin(HttpMethod.GET, "/routes/" + routeId).exchange()
                .expectBody()
                .jsonPath("$.maintenance.enabled").isEqualTo(false)
                .jsonPath("$.maintenance.message").isEqualTo("Back at 14:00");
    }

    /**
     * No message: a default one, in the language of the request. `Retry-After` only while `retry_after` is ahead.
     */
    @Test
    void defaultMessageAndRetryAfter() {
        String id = unique();
        String routeId = createRoute(route("mtd-" + id, "mtd-" + id));

        setRoute(routeId, maintenance(true, null, OffsetDateTime.now().plusHours(1)));
        String retryAfter = webTestClient.get().uri("/mtd-%s/x".formatted(id))
                .header(HttpHeaders.ACCEPT_LANGUAGE, "es")
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.SERVICE_UNAVAILABLE)
                .expectBody()
                .jsonPath("$.title").isEqualTo("Servicio no disponible")
                .jsonPath("$.detail").isEqualTo("El servicio está en mantenimiento, inténtalo más tarde")
                .returnResult().getResponseHeaders().getFirst(HttpHeaders.RETRY_AFTER);
        assertThat(Long.parseLong(retryAfter)).isBetween(3500L, 3600L);

        //the time passed: still in maintenance, without the header
        setRoute(routeId, maintenance(true, " ", OffsetDateTime.now().minusMinutes(1)));
        webTestClient.get().uri("/mtd-%s/x".formatted(id)).exchange()
                .expectStatus().isEqualTo(HttpStatus.SERVICE_UNAVAILABLE)
                .expectHeader().doesNotExist(HttpHeaders.RETRY_AFTER)
                .expectBody().jsonPath("$.detail").isEqualTo("The service is under maintenance, try again later");
    }

    /**
     * The gateway's maintenance stops every route (the route's own one wins when both are on), but never the admin
     * API or the health check, and a path with no route stays a `404`.
     */
    @Test
    void globalMaintenance() {
        String id = unique();
        createRoute(route("mtg-" + id, "mtg-" + id));
        String ownId = createRoute(route("mto-" + id, "mto-" + id));
        setRoute(ownId, maintenance(true, "Own message", null));
        try {
            admin(HttpMethod.PUT, "/maintenance")
                    .bodyValue(maintenance(true, "Gateway down", null))
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody().jsonPath("$.message").isEqualTo("Gateway down");
            admin(HttpMethod.GET, "/maintenance").exchange()
                    .expectStatus().isOk()
                    .expectBody().jsonPath("$.enabled").isEqualTo(true).jsonPath("$.message").isEqualTo("Gateway down");

            webTestClient.get().uri("/mtg-%s/x".formatted(id)).exchange()
                    .expectStatus().isEqualTo(HttpStatus.SERVICE_UNAVAILABLE)
                    .expectBody().jsonPath("$.detail").isEqualTo("Gateway down");
            webTestClient.get().uri("/mto-%s/x".formatted(id)).exchange()
                    .expectStatus().isEqualTo(HttpStatus.SERVICE_UNAVAILABLE)
                    .expectBody().jsonPath("$.detail").isEqualTo("Own message");

            admin(HttpMethod.GET, "/routes").exchange().expectStatus().isOk();
            webTestClient.get().uri("/%s/health".formatted(ADMIN_PATH)).exchange().expectStatus().isOk();
            webTestClient.get().uri("/no-route-%s/x".formatted(id)).exchange().expectStatus().isNotFound();
        } finally {
            setGlobal(maintenance(false, "Gateway down", null));
        }
        webTestClient.get().uri("/mtg-%s/x".formatted(id)).exchange().expectStatus().isOk();
        admin(HttpMethod.GET, "/maintenance").exchange()
                .expectBody().jsonPath("$.enabled").isEqualTo(false).jsonPath("$.message").isEqualTo("Gateway down");
    }

    /**
     * Never set: `null`, not an empty body
     */
    @Test
    void globalNeverSetIsNull() {
        settingRepo.findByRouteIdIsNullAndKey(Maintenance.KEY).flatMap(settingRepo::delete).block();
        maintenanceUseCase.reload().block();

        admin(HttpMethod.GET, "/maintenance").exchange()
                .expectStatus().isOk()
                .expectBody(String.class).isEqualTo("null");
    }

    @Test
    void invalidMaintenance() {
        String routeId = createRoute(route("mtv-" + unique(), "mtv-" + unique()));
        for (String path : List.of("/maintenance", "/routes/%s/maintenance".formatted(routeId))) {
            admin(HttpMethod.PUT, path)
                    .bodyValue(maintenance(null, "a".repeat(501), null))
                    .exchange()
                    .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                    .expectBody()
                    .jsonPath("$.violations.length()").isEqualTo(2)
                    .jsonPath("$.violations[?(@.fieldName == 'enabled')].message").isEqualTo("Must not be null")
                    .jsonPath("$.violations[?(@.fieldName == 'message')].message").isEqualTo("Size must be between 0 and 500");
            admin(HttpMethod.PUT, path)
                    .bodyValue(Map.of("enabled", true, "retry_after", "tomorrow"))
                    .exchange()
                    .expectStatus().isBadRequest()
                    .expectBody().jsonPath("$.detail").isEqualTo("Invalid value for retry_after");
        }
        //the limit is inclusive
        setRoute(routeId, maintenance(false, "a".repeat(500), null));

        //the one of a restored route is checked too
        RouteConfigRequest restored = route("mtv-" + unique(), "mtv-" + unique());
        restored.setMaintenance(new Maintenance(null, null, null));
        admin(HttpMethod.PUT, "/routes").bodyValue(List.of(restored)).exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody().jsonPath("$.violations[0].fieldName").isEqualTo("[0].maintenance.enabled");

        admin(HttpMethod.PUT, "/routes/not-a-uuid/maintenance").bodyValue(maintenance(true, null, null)).exchange()
                .expectStatus().isBadRequest();
        admin(HttpMethod.PUT, "/routes/%s/maintenance".formatted(UUID.randomUUID())).bodyValue(maintenance(true, null, null)).exchange()
                .expectStatus().isNotFound();
    }

    /**
     * Create and edit ignore the maintenance (it has its own endpoint) and edit keeps it; the restore saves the one
     * of each route, and keeps the current one when it doesn't come. Deleting a route deletes its maintenance.
     */
    @Test
    void routeWritesAndRestore() {
        String id = unique();
        Maintenance on = new Maintenance(true, "Restored", null);

        RouteConfigRequest created = route("mtw-" + id, "mtw-" + id);
        created.setMaintenance(on);
        String routeId = createRoute(created);
        admin(HttpMethod.GET, "/routes/" + routeId).exchange().expectBody().jsonPath("$.maintenance").isEmpty();

        setRoute(routeId, maintenance(true, "Kept", null));
        admin(HttpMethod.PUT, "/routes/" + routeId).bodyValue(created).exchange()
                .expectStatus().isOk()
                .expectBody().jsonPath("$.maintenance.message").isEqualTo("Kept");

        //restore: the route without maintenance keeps it, the one with it gets it
        RouteConfigRequest restored = route("mtr-" + id, "mtr-" + id);
        restored.setMaintenance(on);
        admin(HttpMethod.PUT, "/routes")
                .bodyValue(List.of(route("mtw-" + id, "mtw-" + id), restored))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$[0].maintenance.message").isEqualTo("Kept")
                .jsonPath("$[1].maintenance.enabled").isEqualTo(true)
                .jsonPath("$[1].maintenance.message").isEqualTo("Restored");
        webTestClient.get().uri("/mtr-%s/x".formatted(id)).exchange()
                .expectStatus().isEqualTo(HttpStatus.SERVICE_UNAVAILABLE)
                .expectBody().jsonPath("$.detail").isEqualTo("Restored");

        String restoredId = routeId("mtr-" + id);
        admin(HttpMethod.DELETE, "/routes/" + restoredId).exchange().expectStatus().isNoContent();
        assertThat(settingRepo.findByRouteIdAndKey(UUID.fromString(restoredId), Maintenance.KEY).block()).isNull();
    }
}
