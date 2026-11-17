package dev.root101.api_gateway.features.maintenance.logic.usecase;

import dev.root101.api_gateway.features.maintenance.logic.model.Maintenance;
import reactor.core.publisher.Mono;

import java.util.UUID;

public interface MaintenanceUseCase {

    /**
     * The maintenance of the whole gateway, or null if it was never set. No db request.
     */
    Maintenance global();

    /**
     * Saves the maintenance of the whole gateway, in use right away
     */
    Mono<Maintenance> setGlobal(Maintenance maintenance);

    /**
     * The maintenance of a route, or null if it was never set. No db request.
     */
    Maintenance ofRoute(String routeId);

    /**
     * The maintenance that stops the requests to this route right now: its own when it is on (the more specific
     * one wins), else the gateway's when it is on, else null. No db request.
     */
    Maintenance active(String routeId);

    /**
     * Saves the maintenance of a route in db, without putting it in use: to join the transaction of the caller, who
     * calls {@link #reload()} after it
     */
    Mono<Void> save(UUID routeId, Maintenance maintenance);

    /**
     * Reads every maintenance from db into use
     */
    Mono<Void> reload();
}
