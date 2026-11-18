package dev.root101.api_gateway.features.maintenance.logic.usecase;

import dev.root101.api_gateway.features.maintenance.logic.model.Maintenance;
import dev.root101.api_gateway.features.maintenance.logic.model.MaintenanceResponse;
import reactor.core.publisher.Mono;

import java.util.Locale;
import java.util.UUID;

/**
 * The maintenance add-on of the gateway and of each route. The ones that take a route id as it comes in a path answer
 * `400` if it isn't a UUID and `404` if there is no such route.
 */
public interface MaintenanceUseCase {

    /**
     * The maintenance of the gateway, or null if it isn't configured. No db request.
     */
    MaintenanceResponse ofGateway(Locale locale);

    /**
     * The maintenance of a route, or null if it isn't configured. No db request.
     */
    MaintenanceResponse ofRoute(String routeId, Locale locale);

    /**
     * The maintenance that stops the requests to this route right now: the gateway's when it is on (it wins), else
     * the route's own when it is on, else null. No db request.
     */
    Maintenance active(String routeId);

    /**
     * Creates or replaces the maintenance of the gateway, in use right away
     */
    Mono<MaintenanceResponse> setGateway(Maintenance maintenance, Locale locale);

    /**
     * Turns the maintenance of the gateway on or off, keeping the rest: `404` if it isn't configured
     */
    Mono<MaintenanceResponse> enableGateway(boolean enabled, Locale locale);

    /**
     * Removes the maintenance of the gateway (back to `null`), in use right away. Nothing to remove is fine.
     */
    Mono<Void> deleteGateway();

    /**
     * Creates or replaces the maintenance of a route, in use right away
     */
    Mono<MaintenanceResponse> setRoute(String routeId, Maintenance maintenance, Locale locale);

    /**
     * Turns the maintenance of a route on or off, keeping the rest: `404` if it isn't configured
     */
    Mono<MaintenanceResponse> enableRoute(String routeId, boolean enabled, Locale locale);

    /**
     * Removes the maintenance of a route (back to `null`), in use right away. Nothing to remove is fine.
     */
    Mono<Void> deleteRoute(String routeId);

    /**
     * Saves (or deletes, when null) the maintenance of a route in db, without putting it in use: to join the
     * transaction of the caller, who calls {@link #reload()} after it
     */
    Mono<Void> save(UUID routeId, Maintenance maintenance);

    /**
     * Reads every maintenance from db into use
     */
    Mono<Void> reload();
}
