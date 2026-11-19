package dev.root101.api_gateway.features.addons.health_check.rest;

import dev.root101.api_gateway.features.addons.health_check.logic.model.HealthCheck;
import dev.root101.api_gateway.features.addons.health_check.logic.model.HealthCheckResponse;
import dev.root101.api_gateway.features.addons.health_check.logic.usecase.HealthCheckUseCase;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

/**
 * The health check add-on of a route (`/routes/{id}/addons/health-check`). Every change is in use right away.
 */
@RestController
@RequestMapping("/${app.admin.base-path}/routes/{route-id}/addons/health-check")
public class HealthCheckController {

    private final HealthCheckUseCase healthCheckUseCase;

    public HealthCheckController(HealthCheckUseCase healthCheckUseCase) {
        this.healthCheckUseCase = healthCheckUseCase;
    }

    /**
     * Creates or replaces the health check of a route, keeping its last result
     */
    @PutMapping
    public Mono<HealthCheckResponse> set(@PathVariable("route-id") String routeId, @Valid @RequestBody HealthCheck healthCheck) {
        return healthCheckUseCase.setRoute(routeId, healthCheck);
    }

    /**
     * Removes the health check of a route: back to `null`
     */
    @DeleteMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> delete(@PathVariable("route-id") String routeId) {
        return healthCheckUseCase.deleteRoute(routeId);
    }

    /**
     * Turns the health check of a route on: `404` if it isn't configured
     */
    @PostMapping("/enable")
    public Mono<HealthCheckResponse> enable(@PathVariable("route-id") String routeId) {
        return healthCheckUseCase.enableRoute(routeId, true);
    }

    /**
     * Turns the health check of a route off, keeping its path, interval and last result: `404` if it isn't configured
     */
    @PostMapping("/disable")
    public Mono<HealthCheckResponse> disable(@PathVariable("route-id") String routeId) {
        return healthCheckUseCase.enableRoute(routeId, false);
    }

    /**
     * Calls it now, on or off, and answers with the new result: `404` if it isn't configured
     */
    @PostMapping("/run")
    public Mono<HealthCheckResponse> run(@PathVariable("route-id") String routeId) {
        return healthCheckUseCase.run(routeId);
    }
}
