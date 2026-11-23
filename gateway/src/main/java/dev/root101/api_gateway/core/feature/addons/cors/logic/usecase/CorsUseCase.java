package dev.root101.api_gateway.core.feature.addons.cors.logic.usecase;

import dev.root101.api_gateway.core.feature.addons.cors.logic.model.Cors;
import dev.root101.api_gateway.core.feature.addons.cors.logic.model.CorsResponse;
import reactor.core.publisher.Mono;

import java.util.UUID;

/**
 * The CORS add-on of the gateway and of each route. The ones that take a route id as it comes in a path answer `400`
 * if it isn't a UUID and `404` if there is no such route.
 */
public interface CorsUseCase {

    /**
     * The CORS of the gateway, or null if its row can't be read. No db request.
     */
    Cors ofGateway();

    /**
     * The CORS of the gateway as answered, with the deprecated env var when it is set; null if its row can't be
     * read. No db request.
     */
    CorsResponse gatewayResponse();

    /**
     * The CORS of a route, or null if it isn't configured. No db request.
     */
    Cors ofRoute(String routeId);

    /**
     * The CORS a request to this route gets right now: the route's own when it is on, else the gateway's (null when
     * none can be read: no CORS headers). No db request.
     */
    Cors active(String routeId);

    /**
     * Replaces the CORS of the gateway, in use right away. `400` when it is turned off, has credentials, or doesn't
     * allow `origin` (of the browser that sends it; null without one).
     */
    Mono<CorsResponse> setGateway(Cors cors, String origin);

    /**
     * Creates or replaces the CORS of a route, in use right away. `400` with credentials and any origin.
     */
    Mono<Cors> setRoute(String routeId, Cors cors);

    /**
     * Turns the CORS of a route on or off, keeping the rest: `404` if it isn't configured
     */
    Mono<Cors> enableRoute(String routeId, boolean enabled);

    /**
     * Removes the CORS of a route (back to `null`: the gateway's), in use right away. Nothing to remove is fine.
     */
    Mono<Void> deleteRoute(String routeId);

    /**
     * Saves (or deletes, when null) the CORS of a route in db, without putting it in use: to join the transaction of
     * the caller, who calls {@link #reload()} after it. `400` with credentials and any origin.
     */
    Mono<Void> save(UUID routeId, Cors cors);

    /**
     * Reads every CORS from db into use
     */
    Mono<Void> reload();
}
