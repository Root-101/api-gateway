package dev.root101.api_gateway.features.addons.rate_limit.logic.usecase;

import dev.root101.api_gateway.features.addons.rate_limit.logic.model.RateLimit;
import reactor.core.publisher.Mono;

import java.util.UUID;

/**
 * The rate limit add-on of the gateway and of each route. The ones that take a route id as it comes in a path answer
 * `400` if it isn't a UUID and `404` if there is no such route.
 */
public interface RateLimitUseCase {

    /**
     * The rate limit of the gateway, or null if it isn't configured. No db request.
     */
    RateLimit ofGateway();

    /**
     * The rate limit of a route, or null if it isn't configured. No db request.
     */
    RateLimit ofRoute(String routeId);

    /**
     * Takes one request of this client ip to this route, from the gateway's limit and then the route's, the ones
     * that are on: 0 when it can go, else the seconds until it could (at least 1). No db request.
     */
    long acquire(String routeId, String clientIp);

    /**
     * Creates or replaces the rate limit of the gateway, in use right away (the counts start again)
     */
    Mono<RateLimit> setGateway(RateLimit rateLimit);

    /**
     * Turns the rate limit of the gateway on or off, keeping the rest: `404` if it isn't configured
     */
    Mono<RateLimit> enableGateway(boolean enabled);

    /**
     * Removes the rate limit of the gateway (back to `null`), in use right away. Nothing to remove is fine.
     */
    Mono<Void> deleteGateway();

    /**
     * Creates or replaces the rate limit of a route, in use right away (the counts start again)
     */
    Mono<RateLimit> setRoute(String routeId, RateLimit rateLimit);

    /**
     * Turns the rate limit of a route on or off, keeping the rest: `404` if it isn't configured
     */
    Mono<RateLimit> enableRoute(String routeId, boolean enabled);

    /**
     * Removes the rate limit of a route (back to `null`), in use right away. Nothing to remove is fine.
     */
    Mono<Void> deleteRoute(String routeId);

    /**
     * Saves (or deletes, when null) the rate limit of a route in db, without putting it in use: to join the
     * transaction of the caller, who calls {@link #reload()} after it
     */
    Mono<Void> save(UUID routeId, RateLimit rateLimit);

    /**
     * Reads every rate limit from db into use, the counts start again
     */
    Mono<Void> reload();
}
