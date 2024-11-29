package dev.root101.api_gateway.feature.controller;

import dev.root101.api_gateway.feature.model.RouteConfigModel;
import dev.root101.api_gateway.feature.service.DynamicRouteService;
import dev.root101.commons.validation.ValidationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;

/**
 * Route controller for managing the routes of gateway.
 * By default, is secured and only ROLE_GATEWAY_ADMIN can access (configured in global security config)
 */
@RestController
//if this value changes, change it in: dev.root101.api_gateway.security.securityWebFilterChain:pathMatchers("/_admin/**")
@RequestMapping("/${app.admin.base-path}/routes")
public class RoutesController {

    private final DynamicRouteService dynamicRouteService;
    private final ValidationService validationService;

    @Autowired
    public RoutesController(DynamicRouteService dynamicRouteService, ValidationService validationService) {
        this.dynamicRouteService = dynamicRouteService;
        this.validationService = validationService;
    }

    /**
     * Get all routes
     *
     * @return Flux with all the routes
     */
    @GetMapping
    public Flux<RouteConfigModel> getRoutes() {
        return dynamicRouteService.getRoutes();
    }

    /**
     * Create multiple routes at the same time
     *
     * @param routeDefinition List of routes to create
     * @return Void
     */
    @PostMapping("/multi-add")
    public Mono<Void> addAllRoutes(@RequestBody List<RouteConfigModel> routeDefinition) {
        this.validationService.validateRecursiveAndThrow(routeDefinition);

        return dynamicRouteService.addAllRoutes(routeDefinition);
    }

    /**
     * Add a single route
     *
     * @param routeDefinition The route to add
     * @return Void
     */
    @PostMapping
    public Mono<Void> addRoute(@RequestBody RouteConfigModel routeDefinition) {
        this.validationService.validateRecursiveAndThrow(routeDefinition);

        return dynamicRouteService.addRoute(routeDefinition);
    }

    /**
     * Edit a route
     *
     * @param routeId         The id of the route to edit
     * @param routeDefinition The new route data to set up
     * @return Void
     */
    @PutMapping("/{route-id}")
    public Mono<Void> editRoute(@PathVariable("route-id") String routeId, @RequestBody RouteConfigModel routeDefinition) {
        this.validationService.validateRecursiveAndThrow(routeDefinition);

        return dynamicRouteService.editRoute(routeId, routeDefinition);
    }

    /**
     * Delete a route
     *
     * @param routeId The id of the route to delete
     * @return Void
     */
    @DeleteMapping("/{route-id}")
    public Mono<Void> deleteRoute(@PathVariable("route-id") String routeId) {
        return dynamicRouteService.deleteRoute(routeId);
    }
}
