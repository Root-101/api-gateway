package dev.root101.api_gateway.core.feature.routes.rest;

import dev.root101.api_gateway.core.i18n.I18n;
import dev.root101.api_gateway.core.feature.routes.logic.model.RouteRequest;
import dev.root101.api_gateway.core.feature.routes.logic.model.RouteResponse;
import dev.root101.api_gateway.core.feature.routes.logic.usecase.RouteUseCase;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;

/**
 * Route controller for managing the routes of gateway.
 * By default, is secured and only ROLE_GATEWAY_ADMIN can access (configured in global security config)
 */
@RestController
@RequestMapping("/${app.admin.base-path}/routes")
public class RouteController {

    private final RouteUseCase routeUseCase;

    public RouteController(RouteUseCase routeUseCase) {
        this.routeUseCase = routeUseCase;
    }

    /**
     * Get all routes
     *
     * @return Flux with all the routes
     */
    @GetMapping
    public Flux<RouteResponse> getRoutes(ServerWebExchange exchange) {
        return routeUseCase.getRoutes(I18n.locale(exchange));
    }

    /**
     * Create multiple routes at the same time
     *
     * @param routeDefinition List of routes to create
     * @return The created routes
     */
    @PostMapping("/batch")
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<List<RouteResponse>> addAllRoutes(@RequestBody List<@Valid RouteRequest> routeDefinition, ServerWebExchange exchange) {
        return routeUseCase.addAllRoutes(routeDefinition, I18n.locale(exchange));
    }

    /**
     * Replace every route with the given ones, all or nothing
     *
     * @param routeDefinition The routes that will exist after the call
     * @return The routes, as saved
     */
    @PutMapping
    public Mono<List<RouteResponse>> replaceAllRoutes(@RequestBody List<@Valid RouteRequest> routeDefinition, ServerWebExchange exchange) {
        return routeUseCase.replaceAllRoutes(routeDefinition, I18n.locale(exchange));
    }

    /**
     * Add a single route
     *
     * @param routeDefinition The route to add
     * @return The created route
     */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<RouteResponse> addRoute(@Valid @RequestBody RouteRequest routeDefinition, ServerWebExchange exchange) {
        return routeUseCase.addRoute(routeDefinition, I18n.locale(exchange));
    }

    /**
     * Check a route with the same rules as create and edit, without saving it. The console validates each
     * step of its form here, so it never keeps its own copy of the rules. The name being taken is not checked.
     *
     * @param routeDefinition The route to check
     * @return Nothing (204), or a `422` with every broken field
     */
    @PostMapping("/validate")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> validateRoute(@Valid @RequestBody RouteRequest routeDefinition) {
        return Mono.empty();
    }

    /**
     * Get a route
     *
     * @param routeId The id of the route to find
     * @return The route
     */
    @GetMapping("/{route-id}")
    public Mono<RouteResponse> getRoute(@PathVariable("route-id") String routeId, ServerWebExchange exchange) {
        return routeUseCase.findById(routeId, I18n.locale(exchange));
    }

    /**
     * Edit a route
     *
     * @param routeId         The id of the route to edit
     * @param routeDefinition The new route data to set up
     * @return The edited route
     */
    @PutMapping("/{route-id}")
    public Mono<RouteResponse> editRoute(@PathVariable("route-id") String routeId, @Valid @RequestBody RouteRequest routeDefinition, ServerWebExchange exchange) {
        return routeUseCase.editRoute(routeId, routeDefinition, I18n.locale(exchange));
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
