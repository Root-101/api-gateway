package dev.root101.api_gateway.features.routes.rest;

import dev.root101.api_gateway.config.I18n;
import dev.root101.api_gateway.features.addons.base.logic.usecase.AddonsUseCase;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigRequest;
import dev.root101.api_gateway.features.routes.logic.model.RouteConfigResponse;
import dev.root101.api_gateway.features.routes.logic.usecase.RouteUseCase;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Locale;

/**
 * Route controller for managing the routes of gateway.
 * By default, is secured and only ROLE_GATEWAY_ADMIN can access (configured in global security config)
 */
@RestController
@RequestMapping("/${app.admin.base-path}/routes")
public class RoutesController {

    private final RouteUseCase routeUseCase;
    private final AddonsUseCase addonsUseCase;

    @Autowired
    public RoutesController(RouteUseCase routeUseCase, AddonsUseCase addonsUseCase) {
        this.routeUseCase = routeUseCase;
        this.addonsUseCase = addonsUseCase;
    }

    //the add-ons are added here: their texts are in the request's language
    private RouteConfigResponse withAddons(RouteConfigResponse route, Locale locale) {
        route.setAddons(addonsUseCase.ofRoute(route.getId(), locale));
        return route;
    }

    private List<RouteConfigResponse> withAddons(List<RouteConfigResponse> routes, Locale locale) {
        routes.forEach(route -> withAddons(route, locale));
        return routes;
    }

    /**
     * Get all routes
     *
     * @return Flux with all the routes
     */
    @GetMapping
    public Flux<RouteConfigResponse> getRoutes(ServerWebExchange exchange) {
        Locale locale = I18n.locale(exchange);
        return routeUseCase.getRoutes().map(route -> withAddons(route, locale));
    }

    /**
     * Create multiple routes at the same time
     *
     * @param routeDefinition List of routes to create
     * @return The created routes
     */
    @PostMapping("/batch")
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<List<RouteConfigResponse>> addAllRoutes(@RequestBody List<@Valid RouteConfigRequest> routeDefinition, ServerWebExchange exchange) {
        return routeUseCase.addAllRoutes(routeDefinition).map(routes -> withAddons(routes, I18n.locale(exchange)));
    }

    /**
     * Replace every route with the given ones, all or nothing
     *
     * @param routeDefinition The routes that will exist after the call
     * @return The routes, as saved
     */
    @PutMapping
    public Mono<List<RouteConfigResponse>> replaceAllRoutes(@RequestBody List<@Valid RouteConfigRequest> routeDefinition, ServerWebExchange exchange) {
        return routeUseCase.replaceAllRoutes(routeDefinition).map(routes -> withAddons(routes, I18n.locale(exchange)));
    }

    /**
     * Add a single route
     *
     * @param routeDefinition The route to add
     * @return The created route
     */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<RouteConfigResponse> addRoute(@Valid @RequestBody RouteConfigRequest routeDefinition, ServerWebExchange exchange) {
        return routeUseCase.addRoute(routeDefinition).map(route -> withAddons(route, I18n.locale(exchange)));
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
    public Mono<Void> validateRoute(@Valid @RequestBody RouteConfigRequest routeDefinition) {

        return Mono.empty();
    }

    /**
     * Get a route
     *
     * @param routeId The id of the route to find
     * @return The route
     */
    @GetMapping("/{route-id}")
    public Mono<RouteConfigResponse> getRoute(@PathVariable("route-id") String routeId, ServerWebExchange exchange) {
        return routeUseCase.findById(routeId).map(route -> withAddons(route, I18n.locale(exchange)));
    }

    /**
     * Edit a route
     *
     * @param routeId         The id of the route to edit
     * @param routeDefinition The new route data to set up
     * @return The edited route
     */
    @PutMapping("/{route-id}")
    public Mono<RouteConfigResponse> editRoute(@PathVariable("route-id") String routeId, @Valid @RequestBody RouteConfigRequest routeDefinition, ServerWebExchange exchange) {
        return routeUseCase.editRoute(routeId, routeDefinition).map(route -> withAddons(route, I18n.locale(exchange)));
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
