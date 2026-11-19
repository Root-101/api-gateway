package dev.root101.api_gateway.features.addons.health_check.logic.usecase;

import dev.root101.api_gateway.features.addons.health_check.logic.model.HealthCheck;
import dev.root101.api_gateway.features.addons.health_check.logic.model.HealthCheckResponse;
import reactor.core.publisher.Mono;

import java.util.UUID;

/**
 * The health check add-on of each route. The ones that take a route id as it comes in a path answer `400` if it isn't
 * a UUID and `404` if there is no such route.
 */
public interface HealthCheckUseCase {

    /**
     * The health check of a route, or null if it isn't configured. No db request.
     */
    HealthCheckResponse ofRoute(String routeId);

    /**
     * Creates or replaces the health check of a route, in use right away. Its last result is kept.
     */
    Mono<HealthCheckResponse> setRoute(String routeId, HealthCheck healthCheck);

    /**
     * Turns the health check of a route on or off, keeping the rest: `404` if it isn't configured
     */
    Mono<HealthCheckResponse> enableRoute(String routeId, boolean enabled);

    /**
     * Removes the health check of a route (back to `null`). Nothing to remove is fine.
     */
    Mono<Void> deleteRoute(String routeId);

    /**
     * Calls the health check of a route now, on or off, and answers with its new result: `404` if it isn't configured
     */
    Mono<HealthCheckResponse> run(String routeId);

    /**
     * Saves (or deletes, when null) the health check of a route in db, without putting it in use: to join the
     * transaction of the caller, who calls {@link #reload()} after it
     */
    Mono<Void> save(UUID routeId, HealthCheck healthCheck);

    /**
     * Reads every health check from db into use
     */
    Mono<Void> reload();
}
