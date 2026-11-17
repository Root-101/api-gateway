package dev.root101.api_gateway;

import dev.root101.api_gateway.features.addons.data.entity.AddonEntity;
import dev.root101.api_gateway.features.addons.data.entity.AddonJson;
import dev.root101.api_gateway.features.addons.data.repo.AddonRepo;
import dev.root101.api_gateway.features.addons.logic.usecase.AddonsUseCase;
import dev.root101.api_gateway.features.maintenance.logic.model.Maintenance;
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

/**
 * The maintenance add-on: of a route (`/routes/{id}/addons/maintenance`) and of the gateway (`/addons/maintenance`)
 */
class MaintenanceIT extends IntegrationTest {

    @Autowired
    private AddonRepo addonRepo;

    @Autowired
    private AddonsUseCase addonsUseCase;

    private static Map<String, Object> maintenance(Boolean enabled, String message, OffsetDateTime retryAfter) {
        Map<String, Object> body = new HashMap<>();
        body.put("enabled", enabled);
        body.put("message", message);
        body.put("retry_after", retryAfter != null ? retryAfter.toString() : null);
        return body;
    }

    private static String routePath(String routeId) {
        return "/routes/%s/addons/maintenance".formatted(routeId);
    }

    private void setRoute(String routeId, Map<String, Object> maintenance) {
        admin(HttpMethod.PUT, routePath(routeId)).bodyValue(maintenance).exchange().expectStatus().isOk();
    }

    private void setGateway(Map<String, Object> maintenance) {
        admin(HttpMethod.PUT, "/addons/maintenance").bodyValue(maintenance).exchange().expectStatus().isOk();
    }

    /**
     * A route in the json of a restore, with its add-ons as given (`null` = the key `addons` not sent)
     */
    private static Map<String, Object> restored(String name, Map<String, Object> addons) {
        Map<String, Object> route = new HashMap<>();
        route.put("name", name);
        route.put("path", "/" + name + "/**");
        route.put("uri", upstreamUrl());
        if (addons != null) route.put("addons", addons);
        return route;
    }

    /**
     * On: a `503` with its message, the service isn't reached, and the request is logged. Disable: the requests pass
     * again, and the message is kept. Enable: back on. Delete: back to `null`, and it can't be enabled any more.
     */
    @Test
    void routeMaintenance() {
        String id = unique();
        String routeId = createRoute(route("mt-" + id, "mt-" + id));
        admin(HttpMethod.GET, "/routes/" + routeId).exchange()
                .expectBody()
                .jsonPath("$.addons").exists()
                .jsonPath("$.addons.maintenance").isEmpty();

        admin(HttpMethod.PUT, routePath(routeId))
                .bodyValue(maintenance(true, "Back at 14:00", null))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.enabled").isEqualTo(true)
                .jsonPath("$.message").isEqualTo("Back at 14:00")
                .jsonPath("$.default_message").isEqualTo("The service is under maintenance, try again later")
                .jsonPath("$.state.enabled_at").isNotEmpty()
                .jsonPath("$.state.disabled_at").isEmpty();

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

        admin(HttpMethod.POST, routePath(routeId) + "/disable").exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.enabled").isEqualTo(false)
                .jsonPath("$.message").isEqualTo("Back at 14:00")
                .jsonPath("$.state.disabled_at").isNotEmpty();
        webTestClient.get().uri("/mt-%s/y".formatted(id)).exchange()
                .expectStatus().isOk()
                .expectBody(String.class).isEqualTo("/mt-%s/y|null".formatted(id));
        admin(HttpMethod.GET, "/routes/" + routeId).exchange()
                .expectBody()
                .jsonPath("$.addons.maintenance.enabled").isEqualTo(false)
                .jsonPath("$.addons.maintenance.message").isEqualTo("Back at 14:00");

        admin(HttpMethod.POST, routePath(routeId) + "/enable").exchange()
                .expectStatus().isOk()
                .expectBody().jsonPath("$.enabled").isEqualTo(true);
        webTestClient.get().uri("/mt-%s/z".formatted(id)).exchange()
                .expectStatus().isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);

        admin(HttpMethod.DELETE, routePath(routeId)).exchange().expectStatus().isNoContent();
        admin(HttpMethod.GET, "/routes/" + routeId).exchange()
                .expectBody().jsonPath("$.addons.maintenance").isEmpty();
        webTestClient.get().uri("/mt-%s/w".formatted(id)).exchange().expectStatus().isOk();
        //nothing to delete is fine; nothing to enable isn't
        admin(HttpMethod.DELETE, routePath(routeId)).exchange().expectStatus().isNoContent();
        admin(HttpMethod.POST, routePath(routeId) + "/enable").exchange().expectStatus().isNotFound();
        admin(HttpMethod.POST, routePath(routeId) + "/disable").exchange().expectStatus().isNotFound();
    }

    /**
     * No message: a default one, in the language of the request, also as `default_message`. `Retry-After` only while
     * `retry_after` is ahead; a past one is accepted.
     */
    @Test
    void defaultMessageAndRetryAfter() {
        String id = unique();
        String routeId = createRoute(route("mtd-" + id, "mtd-" + id));

        admin(HttpMethod.PUT, routePath(routeId))
                .header(HttpHeaders.ACCEPT_LANGUAGE, "es")
                .bodyValue(maintenance(true, null, OffsetDateTime.now().plusHours(1)))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.message").isEmpty()
                .jsonPath("$.default_message").isEqualTo("El servicio está en mantenimiento, inténtalo más tarde");
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
     * The gateway's maintenance stops every route and wins over a route's own one, but never the admin API or the
     * health check, and a path with no route stays a `404`. Turned off, a route's own one is in use again.
     */
    @Test
    void gatewayWins() {
        String id = unique();
        createRoute(route("mtg-" + id, "mtg-" + id));
        String ownId = createRoute(route("mto-" + id, "mto-" + id));
        setRoute(ownId, maintenance(true, "Own message", null));
        try {
            admin(HttpMethod.PUT, "/addons/maintenance")
                    .bodyValue(maintenance(true, "Gateway down", null))
                    .exchange()
                    .expectStatus().isOk()
                    .expectBody().jsonPath("$.message").isEqualTo("Gateway down");
            admin(HttpMethod.GET, "/addons").exchange()
                    .expectStatus().isOk()
                    .expectBody()
                    .jsonPath("$.maintenance.enabled").isEqualTo(true)
                    .jsonPath("$.maintenance.message").isEqualTo("Gateway down")
                    .jsonPath("$.maintenance.default_message").isNotEmpty();

            webTestClient.get().uri("/mtg-%s/x".formatted(id)).exchange()
                    .expectStatus().isEqualTo(HttpStatus.SERVICE_UNAVAILABLE)
                    .expectBody().jsonPath("$.detail").isEqualTo("Gateway down");
            webTestClient.get().uri("/mto-%s/x".formatted(id)).exchange()
                    .expectStatus().isEqualTo(HttpStatus.SERVICE_UNAVAILABLE)
                    .expectBody().jsonPath("$.detail").isEqualTo("Gateway down");
            //the route keeps its own one
            admin(HttpMethod.GET, "/routes/" + ownId).exchange()
                    .expectBody().jsonPath("$.addons.maintenance.message").isEqualTo("Own message");

            admin(HttpMethod.GET, "/routes").exchange().expectStatus().isOk();
            webTestClient.get().uri("/%s/health".formatted(ADMIN_PATH)).exchange().expectStatus().isOk();
            webTestClient.get().uri("/no-route-%s/x".formatted(id)).exchange().expectStatus().isNotFound();
        } finally {
            admin(HttpMethod.POST, "/addons/maintenance/disable").exchange().expectStatus().isOk();
        }
        webTestClient.get().uri("/mtg-%s/x".formatted(id)).exchange().expectStatus().isOk();
        webTestClient.get().uri("/mto-%s/x".formatted(id)).exchange()
                .expectStatus().isEqualTo(HttpStatus.SERVICE_UNAVAILABLE)
                .expectBody().jsonPath("$.detail").isEqualTo("Own message");
        admin(HttpMethod.GET, "/addons").exchange()
                .expectBody()
                .jsonPath("$.maintenance.enabled").isEqualTo(false)
                .jsonPath("$.maintenance.message").isEqualTo("Gateway down");
    }

    /**
     * Never set: `{"maintenance": null}`, and it can't be enabled
     */
    @Test
    void gatewayNotConfigured() {
        addonRepo.findByRouteIdIsNullAndType(Maintenance.TYPE).flatMap(addonRepo::delete).block();
        addonsUseCase.reload().block();

        admin(HttpMethod.GET, "/addons").exchange()
                .expectStatus().isOk()
                .expectBody(String.class).isEqualTo("{\"maintenance\":null}");
        admin(HttpMethod.POST, "/addons/maintenance/enable").exchange().expectStatus().isNotFound();
        admin(HttpMethod.POST, "/addons/maintenance/disable").exchange()
                .expectStatus().isNotFound()
                .expectBody().jsonPath("$.detail").isEqualTo("The gateway has no maintenance configured");
    }

    /**
     * `state` changes only when `enabled` really does: not on a message edit, not on a repeated enable or disable
     */
    @Test
    void stateOnlyOnRealChanges() {
        String routeId = createRoute(route("mts-" + unique(), "mts-" + unique()));

        setRoute(routeId, maintenance(false, "Off at first", null));
        admin(HttpMethod.GET, "/routes/" + routeId).exchange()
                .expectBody()
                .jsonPath("$.addons.maintenance.state.enabled_at").isEmpty()
                .jsonPath("$.addons.maintenance.state.disabled_at").isEmpty();

        String enabledAt = stateField(admin(HttpMethod.POST, routePath(routeId) + "/enable"), "enabled_at");
        assertThat(enabledAt).isNotNull();
        //a message edit, or enabling again, keeps it
        assertThat(stateField(admin(HttpMethod.PUT, routePath(routeId)).bodyValue(maintenance(true, "Edited", null)), "enabled_at"))
                .isEqualTo(enabledAt);
        assertThat(stateField(admin(HttpMethod.POST, routePath(routeId) + "/enable"), "enabled_at")).isEqualTo(enabledAt);

        String disabledAt = stateField(admin(HttpMethod.POST, routePath(routeId) + "/disable"), "disabled_at");
        assertThat(disabledAt).isNotNull();
        assertThat(stateField(admin(HttpMethod.POST, routePath(routeId) + "/disable"), "disabled_at")).isEqualTo(disabledAt);

        //on again: a new enabled_at, the last disabled_at kept
        Map<?, ?> state = (Map<?, ?>) admin(HttpMethod.POST, routePath(routeId) + "/enable").exchange()
                .expectStatus().isOk()
                .expectBody(Map.class).returnResult().getResponseBody().get("state");
        assertThat(state.get("enabled_at")).isNotEqualTo(enabledAt);
        assertThat(state.get("disabled_at")).isEqualTo(disabledAt);
    }

    private static String stateField(org.springframework.test.web.reactive.server.WebTestClient.RequestHeadersSpec<?> request, String field) {
        Map<?, ?> body = request.exchange().expectStatus().isOk().expectBody(Map.class).returnResult().getResponseBody();
        return (String) ((Map<?, ?>) body.get("state")).get(field);
    }

    @Test
    void invalidMaintenance() {
        String routeId = createRoute(route("mtv-" + unique(), "mtv-" + unique()));
        for (String path : List.of("/addons/maintenance", routePath(routeId))) {
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
        Map<String, Object> broken = restored("mtv-" + unique(), Map.of("maintenance", maintenance(null, null, null)));
        admin(HttpMethod.PUT, "/routes").bodyValue(List.of(broken)).exchange()
                .expectStatus().isEqualTo(HttpStatus.UNPROCESSABLE_CONTENT)
                .expectBody().jsonPath("$.violations[0].fieldName").isEqualTo("[0].addons.maintenance.enabled");

        for (String path : List.of(routePath("not-a-uuid"), routePath("not-a-uuid") + "/enable")) {
            admin(path.endsWith("enable") ? HttpMethod.POST : HttpMethod.PUT, path)
                    .bodyValue(maintenance(true, null, null)).exchange()
                    .expectStatus().isBadRequest();
        }
        admin(HttpMethod.DELETE, routePath("not-a-uuid")).exchange().expectStatus().isBadRequest();
        String unknown = UUID.randomUUID().toString();
        admin(HttpMethod.PUT, routePath(unknown)).bodyValue(maintenance(true, null, null)).exchange().expectStatus().isNotFound();
        admin(HttpMethod.DELETE, routePath(unknown)).exchange().expectStatus().isNotFound();
        admin(HttpMethod.POST, routePath(unknown) + "/disable").exchange()
                .expectStatus().isNotFound()
                .expectBody().jsonPath("$.detail").isEqualTo("Route does not exist: " + unknown);
    }

    /**
     * Create and edit ignore the add-ons (each type has its own endpoints) and edit keeps them
     */
    @Test
    void createAndEditIgnoreAddons() {
        String name = "mtw-" + unique();
        Map<String, Object> withAddons = restored(name, Map.of("maintenance", maintenance(true, "Ignored", null)));

        String routeId = (String) admin(HttpMethod.POST, "/routes").bodyValue(withAddons).exchange()
                .expectStatus().isCreated()
                .expectBody(Map.class).returnResult().getResponseBody().get("id");
        admin(HttpMethod.GET, "/routes/" + routeId).exchange().expectBody().jsonPath("$.addons.maintenance").isEmpty();

        setRoute(routeId, maintenance(true, "Kept", null));
        admin(HttpMethod.PUT, "/routes/" + routeId)
                .bodyValue(restored(name, Map.of("maintenance", maintenance(false, "Ignored", null))))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$.addons.maintenance.enabled").isEqualTo(true)
                .jsonPath("$.addons.maintenance.message").isEqualTo("Kept");
    }

    /**
     * The restore matches the routes by name. Per route: no `addons` keeps its own, a key with a value is saved, a
     * key `null` is deleted, a key not sent is kept, an unknown key is ignored, and the read-only fields of a backup
     * are ignored. A route not in the backup is deleted with its add-ons.
     */
    @Test
    void restore() {
        String id = unique();
        String keptId = createRoute(route("mtk-" + id, "mtk-" + id));
        String emptyId = createRoute(route("mte-" + id, "mte-" + id));
        String deletedId = createRoute(route("mtx-" + id, "mtx-" + id));
        String goneId = createRoute(route("mtz-" + id, "mtz-" + id));
        for (String routeId : List.of(keptId, emptyId, deletedId, goneId)) {
            setRoute(routeId, maintenance(true, "Before", null));
        }

        Map<String, Object> deleted = new HashMap<>();
        deleted.put("maintenance", null);
        Map<String, Object> fromBackup = maintenance(true, "Restored", null);
        fromBackup.put("default_message", "ignored");
        fromBackup.put("state", Map.of("enabled_at", "2020-01-01T00:00:00Z"));
        admin(HttpMethod.PUT, "/routes")
                .bodyValue(List.of(
                        restored("mtk-" + id, null),
                        restored("mte-" + id, Map.of("rate_limit", Map.of("limit", 5))),
                        restored("mtx-" + id, deleted),
                        restored("mtn-" + id, Map.of("maintenance", fromBackup))
                ))
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$[0].id").isEqualTo(keptId)
                .jsonPath("$[0].addons.maintenance.message").isEqualTo("Before")
                .jsonPath("$[1].id").isEqualTo(emptyId)
                .jsonPath("$[1].addons.maintenance.message").isEqualTo("Before")
                .jsonPath("$[1].addons.rate_limit").doesNotExist()
                .jsonPath("$[2].id").isEqualTo(deletedId)
                .jsonPath("$[2].addons.maintenance").isEmpty()
                .jsonPath("$[3].addons.maintenance.enabled").isEqualTo(true)
                .jsonPath("$[3].addons.maintenance.message").isEqualTo("Restored")
                .jsonPath("$[3].addons.maintenance.default_message").isEqualTo("The service is under maintenance, try again later")
                .jsonPath("$[3].addons.maintenance.state.enabled_at").value(at -> assertThat((String) at).doesNotStartWith("2020"));

        webTestClient.get().uri("/mtn-%s/x".formatted(id)).exchange()
                .expectStatus().isEqualTo(HttpStatus.SERVICE_UNAVAILABLE)
                .expectBody().jsonPath("$.detail").isEqualTo("Restored");
        webTestClient.get().uri("/mtx-%s/x".formatted(id)).exchange().expectStatus().isOk();
        //the route not in the backup is gone with its add-ons
        assertThat(addonRepo.findByRouteIdAndType(UUID.fromString(goneId), Maintenance.TYPE).block()).isNull();

        //deleting a route deletes its add-ons
        String restoredId = routeId("mtn-" + id);
        admin(HttpMethod.DELETE, "/routes/" + restoredId).exchange().expectStatus().isNoContent();
        assertThat(addonRepo.findByRouteIdAndType(UUID.fromString(restoredId), Maintenance.TYPE).block()).isNull();
    }

    /**
     * A row that can't be read (broken by hand, or of a type this version doesn't know) never stops the gateway: it
     * is skipped, as if it wasn't configured
     */
    @Test
    void unreadableRowsAreSkipped() {
        String id = unique();
        String routeId = createRoute(route("mtb-" + id, "mtb-" + id));
        String wrongTypeId = createRoute(route("mtt-" + id, "mtt-" + id));
        OffsetDateTime now = OffsetDateTime.now();
        //valid json without `enabled`, json of the wrong types, and a type this version doesn't know
        AddonEntity broken = addonRepo.save(new AddonEntity(null, UUID.fromString(routeId), Maintenance.TYPE,
                new AddonJson("{\"message\": \"no enabled\"}"), null, now, now)).block();
        AddonEntity wrongType = addonRepo.save(new AddonEntity(null, UUID.fromString(wrongTypeId), Maintenance.TYPE,
                new AddonJson("{\"enabled\": [1]}"), new AddonJson("{\"enabled_at\": [1]}"), now, now)).block();
        AddonEntity future = addonRepo.save(new AddonEntity(null, UUID.fromString(routeId), "future_addon",
                new AddonJson("{\"anything\": true}"), null, now, now)).block();
        try {
            addonsUseCase.reload().block();

            for (String skipped : List.of(routeId, wrongTypeId)) {
                admin(HttpMethod.GET, "/routes/" + skipped).exchange()
                        .expectStatus().isOk()
                        .expectBody().jsonPath("$.addons.maintenance").isEmpty();
            }
            webTestClient.get().uri("/mtb-%s/x".formatted(id)).exchange().expectStatus().isOk();
            webTestClient.get().uri("/mtt-%s/x".formatted(id)).exchange().expectStatus().isOk();
            admin(HttpMethod.POST, routePath(routeId) + "/enable").exchange().expectStatus().isNotFound();
            //a PUT fixes it
            setRoute(routeId, maintenance(true, "Fixed", null));
            webTestClient.get().uri("/mtb-%s/x".formatted(id)).exchange()
                    .expectStatus().isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        } finally {
            addonRepo.deleteById(broken.getAddonId()).block();
            addonRepo.deleteById(wrongType.getAddonId()).block();
            addonRepo.deleteById(future.getAddonId()).block();
            addonsUseCase.reload().block();
        }
    }
}
