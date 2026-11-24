package dev.root101.api_gateway.core.feature.addons.rate_limit.rest;

import dev.root101.api_gateway.core.feature.addons.rate_limit.logic.model.RateLimit;
import dev.root101.api_gateway.core.feature.addons.rate_limit.logic.usecase.RateLimitUseCase;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

/**
 * The rate limit add-on: of the whole gateway (`/addons/rate-limit`) and of a route (`/routes/{id}/addons/rate-limit`).
 * Every change is in use right away, and the counts start again.
 */
@RestController
@RequestMapping("/${app.admin.base-path}")
public class RateLimitController {

    private final RateLimitUseCase rateLimitUseCase;

    public RateLimitController(RateLimitUseCase rateLimitUseCase) {
        this.rateLimitUseCase = rateLimitUseCase;
    }

    //--------- GATEWAY ---------\\

    /**
     * Creates or replaces the rate limit of the gateway
     */
    @PutMapping("/addons/rate-limit")
    public Mono<RateLimit> setGateway(@Valid @RequestBody RateLimit rateLimit) {
        return rateLimitUseCase.setGateway(rateLimit);
    }

    /**
     * Removes the rate limit of the gateway: back to `null`
     */
    @DeleteMapping("/addons/rate-limit")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> deleteGateway() {
        return rateLimitUseCase.deleteGateway();
    }

    /**
     * Turns the rate limit of the gateway on: `404` if it isn't configured
     */
    @PostMapping("/addons/rate-limit/enable")
    public Mono<RateLimit> enableGateway() {
        return rateLimitUseCase.enableGateway(true);
    }

    /**
     * Turns the rate limit of the gateway off, keeping the rest: `404` if it isn't configured
     */
    @PostMapping("/addons/rate-limit/disable")
    public Mono<RateLimit> disableGateway() {
        return rateLimitUseCase.enableGateway(false);
    }

    //--------- ROUTE ---------\\

    /**
     * Creates or replaces the rate limit of a route
     */
    @PutMapping("/routes/{route-id}/addons/rate-limit")
    public Mono<RateLimit> setRoute(@PathVariable("route-id") String routeId, @Valid @RequestBody RateLimit rateLimit) {
        return rateLimitUseCase.setRoute(routeId, rateLimit);
    }

    /**
     * Removes the rate limit of a route: back to `null`
     */
    @DeleteMapping("/routes/{route-id}/addons/rate-limit")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> deleteRoute(@PathVariable("route-id") String routeId) {
        return rateLimitUseCase.deleteRoute(routeId);
    }

    /**
     * Turns the rate limit of a route on: `404` if it isn't configured
     */
    @PostMapping("/routes/{route-id}/addons/rate-limit/enable")
    public Mono<RateLimit> enableRoute(@PathVariable("route-id") String routeId) {
        return rateLimitUseCase.enableRoute(routeId, true);
    }

    /**
     * Turns the rate limit of a route off, keeping the rest: `404` if it isn't configured
     */
    @PostMapping("/routes/{route-id}/addons/rate-limit/disable")
    public Mono<RateLimit> disableRoute(@PathVariable("route-id") String routeId) {
        return rateLimitUseCase.enableRoute(routeId, false);
    }
}
