package dev.root101.api_gateway.features.routes.rest;

import dev.root101.api_gateway.features.routes.logic.model.RouteConfigRequest;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigResponse;
import dev.root101.api_gateway.features.routes.logic.usecase.RouteUseCase;
import dev.root101.commons.validation.ValidationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;

/**
 * Route controller for managing the routes of gateway.
 * By default, is secured and only ROLE_GATEWAY_ADMIN can access (configured in global security config)
 */
@RestController
@RequestMapping("/${app.admin.base-path}/routes")
public class RoutesController {

    private final RouteUseCase routeUseCase;
    private final ValidationService validationService;

    @Autowired
    public RoutesController(RouteUseCase routeUseCase, ValidationService validationService) {
        this.routeUseCase = routeUseCase;
        this.validationService = validationService;
    }

    /**
     * Get all routes
     *
     * @return Flux with all the routes
     */
    @GetMapping
    public Flux<RouteConfigResponse> getRoutes() {
        return routeUseCase.getRoutes();
    }

    /**
     * Create multiple routes at the same time
     *
     * @param routeDefinition List of routes to create
     * @return The created routes
     */
    @PostMapping("/batch")
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<List<RouteConfigResponse>> addAllRoutes(@RequestBody List<RouteConfigRequest> routeDefinition) {
        this.validationService.validate(routeDefinition);

        return routeUseCase.addAllRoutes(routeDefinition);
    }

    /**
     * Replace every route with the given ones, all or nothing
     *
     * @param routeDefinition The routes that will exist after the call
     * @return The routes, as saved
     */
    @PutMapping
    public Mono<List<RouteConfigResponse>> replaceAllRoutes(@RequestBody List<RouteConfigRequest> routeDefinition) {
        this.validationService.validate(routeDefinition);

        return routeUseCase.replaceAllRoutes(routeDefinition);
    }

    /**
     * Add a single route
     *
     * @param routeDefinition The route to add
     * @return The created route
     */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<RouteConfigResponse> addRoute(@RequestBody RouteConfigRequest routeDefinition) {
        this.validationService.validate(routeDefinition);

        return routeUseCase.addRoute(routeDefinition);
    }

    /**
     * Get a route
     *
     * @param routeId The id of the route to find
     * @return The route
     */
    @GetMapping("/{route-id}")
    public Mono<RouteConfigResponse> getRoute(@PathVariable("route-id") String routeId) {
        return routeUseCase.findById(routeId);
    }

    /**
     * Edit a route
     *
     * @param routeId         The id of the route to edit
     * @param routeDefinition The new route data to set up
     * @return The edited route
     */
    @PutMapping("/{route-id}")
    public Mono<RouteConfigResponse> editRoute(@PathVariable("route-id") String routeId, @RequestBody RouteConfigRequest routeDefinition) {
        this.validationService.validate(routeDefinition);

        return routeUseCase.editRoute(routeId, routeDefinition);
    }

    /**
     * Delete a route
     *
     * @param routeId The id of the route to delete
     * @return Nothing (204)
     */
    @DeleteMapping("/{route-id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> deleteRoute(@PathVariable("route-id") String routeId) {
        return routeUseCase.deleteRoute(routeId);
    }
}
